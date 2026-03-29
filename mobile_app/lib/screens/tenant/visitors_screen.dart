import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tenant/tenant_common_widgets.dart';
import '../../config/api_config.dart';

class VisitorsScreen extends StatefulWidget {
  const VisitorsScreen({super.key});

  @override
  State<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends State<VisitorsScreen> {
 

  String token = '';
  List<dynamic> visitors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('tenant_token') ?? '';
    await _fetchVisitors();
  }

  Future<void> _fetchVisitors() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/visitors'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (data['success']) {
        setState(() => visitors = data['data']);
      }
    } catch (e) {
      debugPrint('fetchVisitors error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addVisitor(String name, String phone, String purpose, String visitDate) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/visitors'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'purpose': purpose,
          'visit_date': visitDate,
        }),
      );
      final data = jsonDecode(res.body);
      if (data['success']) {
        await _fetchVisitors(); // refresh list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message']),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message']), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint('addVisitor error: $e');
    }
  }

  Future<void> _deleteVisitor(int id) async {
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/visitors/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (data['success']) {
        await _fetchVisitors();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Visitor cancelled.'), backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      debugPrint('deleteVisitor error: $e');
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'visited':  return Colors.blue;
      default:         return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Visitors'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => _showAddVisitorDialog(context),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchVisitors,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PrimaryButton(
                      text: 'Pre-Register a Visitor',
                      onTap: () => _showAddVisitorDialog(context),
                      icon: Icons.person_add,
                    ),
                    const SizedBox(height: 20),
                    const SectionHeader(title: 'Visitor History'),
                    const SizedBox(height: 12),

                    if (visitors.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.people_outline, size: 60, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('No visitors yet', style: TextStyle(color: Colors.grey, fontSize: 15)),
                              SizedBox(height: 4),
                              Text('Register a visitor using the button above', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...visitors.map((visitor) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  AvatarWidget(name: visitor['name'] ?? '', size: 44),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          visitor['name'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textDark),
                                        ),
                                        Text(
                                          visitor['purpose'] ?? 'No purpose specified',
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textMid),
                                        ),
                                        Text(
                                          _formatDate(visitor['visit_date'] ?? ''),
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(visitor['status']).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: _statusColor(visitor['status'])),
                                    ),
                                    child: Text(
                                      visitor['status'].toString().toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: _statusColor(visitor['status']),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // QR Code button — only if approved
                              if (visitor['status'] == 'approved') ...[
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () => _showQRCode(context, visitor),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF3B82F6)]),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.qr_code, color: Colors.white, size: 18),
                                          SizedBox(width: 8),
                                          Text('View QR Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              // Cancel button — only if pending
                              if (visitor['status'] == 'pending') ...[
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () => _deleteVisitor(visitor['id']),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      border: Border.all(color: Colors.red.shade200),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Text('Cancel Visitor', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13)),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  void _showQRCode(BuildContext context, dynamic visitor) {
    // QR code data — this string is what gets encoded into QR
    final qrData = visitor['qr_code'] ?? 'VIS-${visitor['id']}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'QR Code — ${visitor['name']}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // REAL QR CODE using qr_flutter package
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              padding: const EdgeInsets.all(12),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 176,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Valid for: ${_formatDate(visitor['visit_date'] ?? '')}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textMid),
            ),
            const SizedBox(height: 4),
            Text(
              qrData,
              style: const TextStyle(fontSize: 10, color: AppTheme.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showAddVisitorDialog(BuildContext context) {
    final nameController    = TextEditingController();
    final phoneController   = TextEditingController();
    final purposeController = TextEditingController();
    DateTime selectedDate   = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Pre-Register Visitor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                const SizedBox(height: 20),
                _buildTextField('Visitor Name *', nameController, Icons.person_outlined),
                const SizedBox(height: 14),
                _buildTextField('Phone Number', phoneController, Icons.phone_outlined, type: TextInputType.phone),
                const SizedBox(height: 14),
                _buildTextField('Purpose of Visit', purposeController, Icons.info_outlined),
                const SizedBox(height: 14),

                // Date picker
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      setModalState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(12),
                      color: AppTheme.bgLight,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppTheme.textMid, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Visit Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Register Visitor',
                  onTap: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter visitor name')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    final visitDate =
                        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2,'0')}-${selectedDate.day.toString().padLeft(2,'0')}';
                    await _addVisitor(
                      nameController.text.trim(),
                      phoneController.text.trim(),
                      purposeController.text.trim(),
                      visitDate,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, IconData icon, {TextInputType? type}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textMid, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary)),
        filled: true,
        fillColor: AppTheme.bgLight,
      ),
    );
  }
}