import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tenant/tenant_common_widgets.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:mobile_app/config/api_config.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:io';


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String _token = '';
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;
  late Timer _conversationTimer;
  

  @override
void initState() {
  super.initState();
  _loadToken();
  _conversationTimer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchConversations());
}

Future<void> _loadToken() async {
  final prefs = await SharedPreferences.getInstance();
  _token = prefs.getString('tenant_token') ?? '';
  _fetchConversations();
}

  Future<void> _fetchConversations() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/chat/conversations'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        setState(() {
          _conversations = List<Map<String, dynamic>>.from(jsonDecode(res.body)['data']);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('fetchConversations error: $e');
      setState(() => _loading = false);
    }
  }
     
  @override
  void dispose() {
  _conversationTimer.cancel();
  super.dispose();
}
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: const Text('Messages'),
        automaticallyImplyLeading: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(child: Text('No conversations yet', style: TextStyle(color: AppTheme.textMid)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _conversations.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = _conversations[i];
                    final isAdmin = c['type'] == 'admin';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: AvatarWidget(
                        name: c['name'],
                        size: 48,
                        backgroundColor: isAdmin ? AppTheme.primary : AppTheme.secondary,
                      ),
                      title: Row(
                        children: [
                          Text(c['name'], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.text(context))),
                          if (isAdmin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
                              child: const Text('Admin', style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(c['last_message'] ?? 'Start a conversation...',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMid),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: c['unread_count'] > 0
                          ? Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(11)),
                              child: Center(child: Text('${c['unread_count']}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                            )
                          : null,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChatDetailScreen(
                          name: c['name'],
                          receiverId: c['id'],
                          receiverType: c['type'],
                          color: isAdmin ? AppTheme.primary : AppTheme.secondary,
                          token: _token,
                        )),
                      ).then((_) => _fetchConversations()),
                    );
                  },
                ),
    );
  }
}

class ChatDetailScreen extends StatefulWidget {
  final String name;
  final int receiverId;
  final String receiverType;
  final Color color;
  final String token;

  const ChatDetailScreen({
    super.key,
    required this.name,
    required this.receiverId,
    required this.receiverType,
    required this.color,
    required this.token,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {

  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController   = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  IO.Socket? _socket;
  bool _loading = true;
  int? _myId;
  late Timer _timer;
  final ImagePicker _picker = ImagePicker();
  

  @override
  void initState() {
    super.initState();
    _getMyId();
    _fetchMessages();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchMessages());
  }

  void _getMyId() {
    try {
      final parts  = widget.token.split('.');
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      _myId = payload['id'];
    } catch (_) {}
  }

  Future<void> _fetchMessages() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/chat/messages/${widget.receiverId}?type=${widget.receiverType}'),
       headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(jsonDecode(res.body)['data']);
          _loading  = false;
        });
        _scrollToBottom();
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('fetchMessages error: $e');
      setState(() => _loading = false);
    }
  }

  void _connectSocket() {
    _socket = IO.io(ApiConfig.socketUrl, {
  'transports': ['websocket'],
  'auth': {'token': widget.token},
});

    _socket!.on('connect', (_) => debugPrint('Socket connected'));

    _socket!.on('receive_message', (data) {
      final msg = Map<String, dynamic>.from(data);
      if (msg['sender_id'] == widget.receiverId) {
        setState(() => _messages.add(msg));
        _scrollToBottom();
      }
    });

    _socket!.on('message_sent', (data) {
      // Already added optimistically, update with server id
      final msg = Map<String, dynamic>.from(data);
      setState(() {
        final idx = _messages.indexWhere((m) => m['_temp'] == true);
        if (idx != -1) _messages[idx] = msg;
      });
    });

    _socket!.on('disconnect', (_) => debugPrint('Socket disconnected'));
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    // Optimistic UI
    final tempMsg = {
      'sender_id': _myId,
      'sender_type': 'tenant',
      'receiver_id': widget.receiverId,
      'message': text,
      'created_at': DateTime.now().toIso8601String(),
    };
    setState(() => _messages.add(tempMsg));
    _msgController.clear();
    _scrollToBottom();

    // Save to database via HTTP POST
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/chat/messages'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'receiver_id': widget.receiverId,
          'receiver_type': widget.receiverType,
          'message': text,
        }),
      );
      await _fetchMessages();
    }     
    catch (e) {
      debugPrint('sendMessage error: $e');
    }
  }
  
  Future<void> _sendImage() async {
  final XFile? image = await _picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 70,
  );
  if (image == null) return;

  try {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/chat/messages/image'),
    );
    request.headers['Authorization'] = 'Bearer ${widget.token}';
    request.fields['receiver_id'] = widget.receiverId.toString();
    request.fields['receiver_type'] = widget.receiverType;
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    final response = await request.send();
    if (response.statusCode == 201) {
      await _fetchMessages();
    }
  } catch (e) {
    debugPrint('sendImage error: $e');
  }
}

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _socket?.disconnect();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AvatarWidget(name: widget.name, size: 36, backgroundColor: widget.color),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

               Text(widget.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.text(context))),
               Text(widget.receiverType == 'admin' ? 'Admin / Warden' : 'Roommate',
               style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context))), 

              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('No messages yet. Say hi! 👋', style: TextStyle(color: AppTheme.textMid)))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final m   = _messages[i];
                          final isMe = m['sender_id'] == _myId && m['sender_type'] == 'tenant';
                          return _buildBubble(m, isMe, m['created_at']);
                        },
                      ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
  color: AppTheme.card(context),
  border: Border(top: BorderSide(color: AppTheme.borderColor(context))),
),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppTheme.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true, fillColor: AppTheme.bg(context),
                    ),
                  ),
                ),
     const SizedBox(width: 8),
GestureDetector(
  onTap: _sendImage,
  child: Container(
    width: 44, height: 44,
    decoration: BoxDecoration(color: AppTheme.secondary, borderRadius: BorderRadius.circular(22)),
    child: const Icon(Icons.image, color: Colors.white, size: 20),
  ),
),
const SizedBox(width: 8),
GestureDetector(
  onTap: _sendMessage,
  child: Container(
    width: 44, height: 44,
    decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(22)),
    child: const Icon(Icons.send, color: Colors.white, size: 20),
  ),
),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildBubble(Map<String, dynamic> m, bool isMe, dynamic time) {
  final message = m['message'] ?? '';
  final imageUrl = m['image_url'] ?? '';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primary : AppTheme.card(context),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: imageUrl.isNotEmpty
    ? ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(imageUrl, width: 200, fit: BoxFit.cover),
      )
    : Text(message, style: TextStyle(color: isMe ? Colors.white : AppTheme.text(context), fontSize: 14)),

      ),  
    );
  }
}