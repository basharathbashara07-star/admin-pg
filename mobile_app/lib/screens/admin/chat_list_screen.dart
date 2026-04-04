import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'chat_screen.dart';
import 'dart:async';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isLoading = true;
  List<dynamic> _tenants = [];
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _fetchTenants();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
    _fetchTenants();
  });
  }

  @override
  void dispose() {
  _timer.cancel();
  super.dispose();
}

  Future<void> _fetchTenants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final data = await ApiService.fetchChatTenants(token);
      
      if (data['success'] == true) {
        setState(() {
          _tenants = data['tenants'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('CHAT ERROR: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '';
    try {
      final dt = DateTime.parse(timeStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Messages',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tenants.isEmpty
              ? const Center(
                  child: Text('No active tenants',
                      style: TextStyle(color: Colors.grey)),
                )
              : RefreshIndicator(
                  onRefresh: _fetchTenants,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _tenants.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 0.5, indent: 72, color: Color(0xFFEEEEEE)),
                    itemBuilder: (context, index) {
                      final tenant = _tenants[index];
                      final unread = tenant['unread_count'] ?? 0;
                      final lastMsg =
                          tenant['last_message'] ?? 'No messages yet';
                      final lastTime =
                          _formatTime(tenant['last_message_time']);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFF2196F3),
                          child: Text(
                            tenant['name'][0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                tenant['name'],
                                style: TextStyle(
                                  fontWeight: unread > 0
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 15,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                            ),
                            Text(
                              lastTime,
                              style: TextStyle(
                                fontSize: 12,
                                color: unread > 0
                                    ? const Color(0xFF2196F3)
                                    : Colors.grey,
                                fontWeight: unread > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text(
                                lastMsg,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: unread > 0
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                      : Colors.grey,
                                  fontWeight: unread > 0
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (unread > 0)
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2196F3),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unread.toString(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                tenantId: tenant['id'],
                                tenantName: tenant['name'],
                                roomNo: tenant['room_no'] ?? '',
                              ),
                            ),
                          );
                          _fetchTenants();
                        },
                      );
                    },
                  ),
                ),
    );
  }
}