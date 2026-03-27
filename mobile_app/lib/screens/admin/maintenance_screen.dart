import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';
import '../../widgets/maintenance_card.dart';
import '../../widgets/maintenance_detail_sheet.dart';
import '../../services/api_service.dart';
import 'dart:async';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {

  String _selectedFilter = 'All';
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  String? _token;
  late Timer _timer;

  final List<String> _filters = [
    'All', 'Pending', 'In Progress', 'Overdue', 'Resolved'
  ];

  List<MaintenanceRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_token != null) _fetchComplaints();
    });
  }

  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    await _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    if (_requests.isEmpty) setState(() => _isLoading = true);
    try {
      final data = await ApiService.fetchComplaints(_token!);
      setState(() {
        _requests = data.map((c) {
          final name = (c['tenant_name'] ?? 'Unknown') as String;
          final initials = name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
          final colors = [0xFF2196F3, 0xFF4CAF50, 0xFF9C27B0, 0xFFFF9800, 0xFFF44336, 0xFF009688];
          final colorIndex = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;

          String status = c['status'] ?? 'open';
          if (status == 'open') status = 'Pending';
          else if (status == 'in_progress') status = 'In Progress';
          else if (status == 'resolved') status = 'Resolved';
          else if (status == 'overdue') status = 'Overdue';

          String priority = c['priority'] ?? 'medium';
          priority = priority[0].toUpperCase() + priority.substring(1).toLowerCase();

          return MaintenanceRequest(
            id: c['id'].toString(),
            tenantId: (c['tenant_id'] ?? '').toString(),
            tenantName: name,
            tenantInitials: initials,
            tenantAvatarColor: colors[colorIndex],
            roomNumber: c['room_no'] ?? 'N/A',
            issueTitle: c['title'] ?? '',
            description: c['description'] ?? '',
            category: c['category'] ?? 'General',
            priority: priority,
            status: status,
            dateRaised: DateTime.tryParse(c['created_at'] ?? '') ?? DateTime.now(),
            adminResponse: c['admin_response'],
            imageUrl: c['image_url'],
            resolvedAt: c['resolved_at'] != null ? DateTime.tryParse(c['resolved_at'].toString()) : null,
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
                 
   Future<void> _deleteComplaint(String id) async {
    try {
      await ApiService.deleteComplaint(_token!, id);
      await _fetchComplaints();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint deleted!'),
            backgroundColor: Color(0xFFF44336),
          ),
        );
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _updateStatus(String id, String newStatus, {String? adminResponse, DateTime? dueDate}) async {
    String dbStatus = newStatus;
    if (newStatus == 'Pending') dbStatus = 'open';
    else if (newStatus == 'In Progress') dbStatus = 'in_progress';
    else if (newStatus == 'Resolved') dbStatus = 'resolved';

    await ApiService.updateComplaintStatus(_token!, id, dbStatus, adminResponse: adminResponse, dueDate: dueDate);
    await _fetchComplaints();
  }

  List<MaintenanceRequest> get _filtered {
    return _requests.where((r) {
      final matchFilter = _selectedFilter == 'All' || r.status == _selectedFilter;
      final matchSearch = _searchQuery.isEmpty ||
          r.tenantName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.issueTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.roomNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchFilter && matchSearch;
    }).toList();
  }

  int get _openCount => _requests.where((r) => r.status == 'Pending').length;
  int get _inProgressCount => _requests.where((r) => r.status == 'In Progress').length;
  int get _overdueCount => _requests.where((r) => r.status == 'Overdue').length;
  int get _resolvedCount => _requests.where((r) => r.status == 'Resolved').length;

  List<MaintenanceRequest> _group(String status) =>
      _filtered.where((r) => r.status == status).toList();

  void _viewDetails(MaintenanceRequest request) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => MaintenanceDetailSheet(
          request: request,
          onDelete: (id) => _deleteComplaint(id),
          onStatusUpdate: (updated) async {
            await _updateStatus(updated.id, updated.status, adminResponse: updated.adminResponse, dueDate: updated.dueDate );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${updated.tenantName}\'s complaint updated to ${updated.status}!'),
                  backgroundColor: const Color(0xFF4CAF50),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchComplaints,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text('Maintenance',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                  const Text('All complaints & requests',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                  const SizedBox(height: 16),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 2.6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _statChip('Open Tickets', '$_openCount', const Color(0xFF2196F3), const Color(0xFFE3F2FD), '🎫'),
                      _statChip('In Progress', '$_inProgressCount', const Color(0xFF00BCD4), const Color(0xFFE0F7FA), '⚙'),
                      _statChip('Overdue', '$_overdueCount', const Color(0xFFF44336), const Color(0xFFFFEBEE), '⚠'),
                      _statChip('Resolved', '$_resolvedCount', const Color(0xFF4CAF50), const Color(0xFFE8F5E9), '✅'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_overdueCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFDE7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFD54F), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Text('🔔', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Reminder: ',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF9800)),
                                  ),
                                  TextSpan(
                                    text: '$_overdueCount tickets are overdue and require urgent attention.',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF1A1A2E)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: const InputDecoration(
                        hintText: 'Search tickets...',
                        hintStyle: TextStyle(color: Color(0xFFBDBDBD), fontSize: 12),
                        prefixIcon: Icon(Icons.search, color: Color(0xFFBDBDBD), size: 18),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((f) {
                        final isActive = _selectedFilter == f;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFilter = f),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFF2196F3) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                            ),
                            child: Text(f,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? Colors.white : const Color(0xFF9E9E9E))),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_group('Pending').isNotEmpty) ...[
                    _groupHeader('🟡  Pending', _group('Pending').length, const Color(0xFFFF9800), const Color(0xFFFFF3E0)),
                    const SizedBox(height: 8),
                    ..._group('Pending').map((r) => MaintenanceCard(request: r, onView: () => _viewDetails(r))),
                    const SizedBox(height: 8),
                  ],
                  if (_group('In Progress').isNotEmpty) ...[
                    _groupHeader('🔵  In Progress', _group('In Progress').length, const Color(0xFF00BCD4), const Color(0xFFE0F7FA)),
                    const SizedBox(height: 8),
                    ..._group('In Progress').map((r) => MaintenanceCard(request: r, onView: () => _viewDetails(r))),
                    const SizedBox(height: 8),
                  ],
                  if (_group('Overdue').isNotEmpty) ...[
                    _groupHeader('🔴  Overdue', _group('Overdue').length, const Color(0xFFF44336), const Color(0xFFFFEBEE)),
                    const SizedBox(height: 8),
                    ..._group('Overdue').map((r) => MaintenanceCard(request: r, onView: () => _viewDetails(r))),
                    const SizedBox(height: 8),
                  ],
                  if (_group('Resolved').isNotEmpty) ...[
                    _groupHeader('✅  Resolved', _group('Resolved').length, const Color(0xFF4CAF50), const Color(0xFFE8F5E9)),
                    const SizedBox(height: 8),
                    ..._group('Resolved').map((r) => MaintenanceCard(request: r, onView: () => _viewDetails(r))),
                    const SizedBox(height: 8),
                  ],

                  if (_filtered.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No complaints found', style: TextStyle(color: Color(0xFF9E9E9E))),
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
  }

  Widget _statChip(String label, String value, Color color, Color bgColor, String icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF9E9E9E))),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _groupHeader(String title, int count, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}