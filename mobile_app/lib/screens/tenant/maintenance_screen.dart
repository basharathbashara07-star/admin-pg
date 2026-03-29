import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tenant/tenant_common_widgets.dart';
import '../../config/api_config.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {

 String _token = '';

  List<Map<String, dynamic>> _activeTickets = [];
  List<Map<String, dynamic>> _resolvedTickets = [];
  Map<String, dynamic> _summary = {'total': 0, 'active': 0, 'resolved': 0};
  bool _loading = true;

  @override
  void initState() {
  super.initState();
  _loadToken();
}

  Future<void> _loadToken() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() => _token = prefs.getString('tenant_token') ?? '');
  _fetchComplaints();
}

  Future<void> _fetchComplaints() async {
    try {
      setState(() => _loading = true);
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/maintenance'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        setState(() {
          _activeTickets   = List<Map<String, dynamic>>.from(data['active']);
          _resolvedTickets = List<Map<String, dynamic>>.from(data['resolved']);
          _summary         = Map<String, dynamic>.from(data['summary']);
          _loading         = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('fetchComplaints error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Maintenance'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTicketDialog(context),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchComplaints,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── STATS ──
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Open',
                            '${_activeTickets.where((t) => t['status'] == 'open').length}',
                            AppTheme.orange, Icons.report_problem_outlined)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('In Progress',
                            '${_activeTickets.where((t) => t['status'] == 'in_progress').length}',
                            AppTheme.primary, Icons.autorenew)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Resolved',
                            '${_summary['resolved']}',
                            AppTheme.success, Icons.check_circle_outline)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── ACTIVE TICKETS ──
                    if (_activeTickets.isNotEmpty) ...[
                      Row(
                        children: [
                          Container(width: 10, height: 10,
                              decoration: BoxDecoration(color: AppTheme.orange, borderRadius: BorderRadius.circular(5))),
                          const SizedBox(width: 8),
                          Text('Active (${_activeTickets.length})',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.orange)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._activeTickets.map((ticket) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTicketCard(context, ticket),
                      )),
                    ],

                    // ── RESOLVED — compact ──
                    if (_resolvedTickets.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(width: 10, height: 10,
                              decoration: BoxDecoration(color: AppTheme.success, borderRadius: BorderRadius.circular(5))),
                          const SizedBox(width: 8),
                          Text('Resolved (${_resolvedTickets.length})',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.success)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
                        child: Column(
                          children: _resolvedTickets.asMap().entries.map((entry) {
                            final i = entry.key;
                            final t = entry.value;
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 34, height: 34,
                                        decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                        child: Icon(_categoryIcon(t['category'] ?? ''), color: AppTheme.success, size: 16),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(t['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark)),
                                            Text(t['category'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.check_circle, color: AppTheme.success, size: 18),
                                    ],
                                  ),
                                ),
                                if (i < _resolvedTickets.length - 1) const Divider(height: 1, indent: 14, endIndent: 14),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    // ── EMPTY STATE ──
                    if (_activeTickets.isEmpty && _resolvedTickets.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(Icons.build_outlined, size: 48, color: AppTheme.textLight),
                              SizedBox(height: 12),
                              Text('No maintenance requests', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textMid)),
                              SizedBox(height: 4),
                              Text('Tap + New Request to report an issue', style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMid), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, Map<String, dynamic> ticket) {
    return AppCard(
      onTap: () => _showTicketDetail(context, ticket),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: _categoryColor(ticket['category'] ?? '').withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_categoryIcon(ticket['category'] ?? ''), color: _categoryColor(ticket['category'] ?? ''), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(ticket['title'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark))),
                        Text('#${ticket['id']}', style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
                      ],
                    ),
                    Text(ticket['description'] ?? '',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMid),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.border)),
                child: Text(ticket['category'] ?? 'General', style: const TextStyle(fontSize: 11, color: AppTheme.textMid, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 8),
              _priorityBadge(ticket['priority'] ?? 'low'),
              const Spacer(),
              StatusBadge(status: ticket['status'] ?? 'open'),
            ],
          ),
          const SizedBox(height: 12),
          _buildTimeline(ticket['status'] ?? 'open'),

          // Admin response
          if (ticket['admin_response'] != null && ticket['admin_response'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings, color: AppTheme.success, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(ticket['admin_response'], style: const TextStyle(fontSize: 12, color: AppTheme.textDark))),
                ],
              ),
            ),
          ],

          

          // Cancel button only if open
          if (ticket['status'] == 'open') ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _deleteTicket(context, ticket['id']),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(border: Border.all(color: AppTheme.danger.withOpacity(0.4)), borderRadius: BorderRadius.circular(8)),
                child: const Center(
                  child: Text('Cancel Request', style: TextStyle(color: AppTheme.danger, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _priorityBadge(String priority) {
    Color color;
    switch (priority) {
      case 'high': color = AppTheme.danger; break;
      case 'medium': color = AppTheme.orange; break;
      default: color = AppTheme.textMid;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(priority.toUpperCase(), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildTimeline(String status) {
    final steps = [
      {'label': 'Submitted', 'done': true},
      {'label': 'Assigned',   'done': status == 'in_progress' || status == 'resolved'},
      {'label': 'In Progress','done': status == 'in_progress' || status == 'resolved'},
      {'label': 'Resolved',   'done': status == 'resolved'},
    ];

    return Row(
      children: List.generate(steps.length, (index) {
        final done = steps[index]['done'] as bool;
        final isLast = index == steps.length - 1;
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(color: done ? AppTheme.success : AppTheme.border, shape: BoxShape.circle),
                    child: done ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
                  ),
                  const SizedBox(height: 4),
                  Text(steps[index]['label'] as String,
                      style: TextStyle(fontSize: 9, color: done ? AppTheme.success : AppTheme.textLight, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center),
                ],
              ),
              if (!isLast)
                Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 18), color: done ? AppTheme.success : AppTheme.border)),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _deleteTicket(BuildContext context, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Request?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to cancel this request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/maintenance/$id'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request cancelled.'), backgroundColor: AppTheme.success),
        );
        _fetchComplaints();
      } else {
        final msg = jsonDecode(res.body)['message'] ?? 'Failed.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error.'), backgroundColor: Colors.red));
    }
  }

  void _showCreateTicketDialog(BuildContext context) {
    String selectedCategory = 'Electrical';
    String selectedPriority = 'low';
    final titleController = TextEditingController();
    final descController  = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                const Text('New Maintenance Request', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                const SizedBox(height: 20),

                // Category
                const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: ['Electrical', 'Plumbing', 'Furniture', 'Cleaning', 'AC/Fan', 'Other'].map((cat) => GestureDetector(
                    onTap: () => setS(() => selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selectedCategory == cat ? AppTheme.primary : AppTheme.bgLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selectedCategory == cat ? AppTheme.primary : AppTheme.border),
                      ),
                      child: Text(cat, style: TextStyle(color: selectedCategory == cat ? Colors.white : AppTheme.textMid, fontWeight: FontWeight.w500, fontSize: 13)),
                    ),
                  )).toList(),
                ),

                const SizedBox(height: 16),

                // Priority
                const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark)),
                const SizedBox(height: 8),
                Row(
                  children: ['low', 'medium', 'high'].map((p) {
                    Color c = p == 'high' ? AppTheme.danger : p == 'medium' ? AppTheme.orange : AppTheme.textMid;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setS(() => selectedPriority = p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selectedPriority == p ? c.withOpacity(0.1) : AppTheme.bgLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: selectedPriority == p ? c : AppTheme.border),
                          ),
                          child: Text(p.toUpperCase(), style: TextStyle(color: selectedPriority == p ? c : AppTheme.textMid, fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                const Text('Title', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark)),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Brief title of the issue',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary)),
                    filled: true, fillColor: AppTheme.bgLight,
                  ),
                ),

                const SizedBox(height: 16),
                const Text('Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark)),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe the issue in detail...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary)),
                    filled: true, fillColor: AppTheme.bgLight,
                  ),
                ),

                const SizedBox(height: 16),
                // Upload photo button (UI only — no actual upload for now)
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, color: AppTheme.textMid),
                          SizedBox(width: 8),
                          Text('Upload Photo (Optional)', style: TextStyle(color: AppTheme.textMid, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () async {
                    if (titleController.text.isEmpty || descController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill title and description')),
                      );
                      return;
                    }
                    try {
                      final res = await http.post(
                        Uri.parse('${ApiConfig.baseUrl}/maintenance'),
                        headers: {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'title': titleController.text,
                          'description': descController.text,
                          'category': selectedCategory,
                          'priority': selectedPriority,
                        }),
                      );
                      if (res.statusCode == 201) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Request submitted!'), backgroundColor: AppTheme.success),
                        );
                        _fetchComplaints();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to submit. Try again.'), backgroundColor: Colors.red),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Network error.'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF3B82F6)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('Submit Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTicketDetail(BuildContext context, Map<String, dynamic> ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(ticket['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark))),
                StatusBadge(status: ticket['status'] ?? 'open'),
              ],
            ),
            const SizedBox(height: 8),
            Text(ticket['description'] ?? '', style: const TextStyle(fontSize: 14, color: AppTheme.textMid)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildDetailItem('Ticket ID', '#${ticket['id']}'),
                const SizedBox(width: 24),
                _buildDetailItem('Category', ticket['category'] ?? ''),
                const SizedBox(width: 24),
                _buildDetailItem('Priority', ticket['priority'] ?? 'low'),
              ],
            ),
            if (ticket['admin_response'] != null && ticket['admin_response'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Admin Response', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textDark)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.success.withOpacity(0.3))),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings, color: AppTheme.success, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(ticket['admin_response'], style: const TextStyle(fontSize: 13, color: AppTheme.textDark))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
      ],
    );
  }
  Color _categoryColor(String category) {
    switch (category) {
      case 'Plumbing': return Colors.blue;
      case 'Electrical': return Colors.orange;
      case 'Furniture': return Colors.brown;
      case 'Cleaning': return Colors.teal;
      case 'AC/Fan': return Colors.cyan;
      default: return AppTheme.primary;
    }
  }
  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Plumbing': return Icons.plumbing;
      case 'Electrical': return Icons.bolt;
      case 'Furniture': return Icons.chair;
      case 'Cleaning': return Icons.cleaning_services;
      case 'AC/Fan': return Icons.ac_unit;
      default: return Icons.build;
    }
  }
}