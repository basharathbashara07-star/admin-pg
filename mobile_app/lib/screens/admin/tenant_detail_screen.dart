import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/edit_tenant_dialog.dart';

class TenantDetailScreen extends StatefulWidget {
  final Tenant tenant;
  final List<RoomOption> vacantRooms;

  const TenantDetailScreen({
    super.key,
    required this.tenant,
    required this.vacantRooms,
  });

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  late Tenant _tenant;
  bool _isLoading = false;
  List<Map<String, dynamic>> _paymentHistory = [];

  @override
  void initState() {
    super.initState();
    _tenant = widget.tenant;
    WidgetsBinding.instance.addPostFrameCallback((_){
      _refreshTenant();
    });
  }

  Future<void> _refreshTenant() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final data = await ApiService.fetchTenant(token, _tenant.id);

      if (data['success'] == true) {
        final t = data['tenant'];
        final name = t['name'] ?? '';
        setState(() {
          _tenant = Tenant(
            id: t['id'].toString(),
            name: name,
            email: t['email'] ?? '',
            phone: t['phone'] ?? '',
            gender: t['gender'],
            fatherName: t['father_name'],
            fatherPhone: t['father_phone'],
            motherName: t['mother_name'],
            motherPhone: t['mother_phone'],
            roomNumber: t['room_no'] ?? 'Not Assigned',
            floor: t['floor'] ?? '',
            bed: t['bed'] ?? '',
            rent: double.tryParse(t['rent_amount'].toString()) ?? 0,
            status: t['payment_status'] == 'paid'
                ? 'Paid'
                : t['payment_status'] == 'overdue'
                    ? 'Overdue'
                    : 'Due',
            avatarInitials: name
                .split(' ')
                .map((e) => e.isNotEmpty ? e[0] : '')
                .take(2)
                .join(),
            avatarColor: 0xFF2196F3,
            dueDay: t['due_day'] != null ? int.tryParse(t['due_day'].toString()) : null,
          );
        });
      }
      final paymentData = await ApiService.fetchTenantPayments(token, _tenant.id);
      if (paymentData['success'] == true) {
        setState(() {
          _paymentHistory = List<Map<String, dynamic>>.from(paymentData['payments']);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Gradient Header ──
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF7B1FA2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 16,
                                      color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('Tenant Profile',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              const Spacer(),
                              // Edit Button
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => EditTenantDialog(
                                      tenant: _tenant,
                                      vacantRooms: widget.vacantRooms,
                                      onUpdated: () {
                                        _refreshTenant();
                                      },
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.3)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.edit_rounded,
                                          color: Colors.white, size: 14),
                                      SizedBox(width: 6),
                                      Text('Edit',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _statusBadge(_tenant.status),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.4),
                                      width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    _tenant.avatarInitials,
                                    style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_tenant.name,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_tenant.roomNumber} · ${_tenant.floor} · ${_tenant.bed}',
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.white70),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '₹${_tenant.rent.toInt()}/month',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Body ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Personal Information
                        _sectionCard(
                          context,
                          icon: Icons.person_rounded,
                          iconColor: const Color(0xFF2196F3),
                          iconBg: const Color(0xFFE3F2FD),
                          borderColor: const Color(0xFF2196F3),
                          title: 'Personal Information',
                          child: Column(
                            children: [
                              _infoRow(context, Icons.badge_outlined,
                                  'Full Name', _tenant.name),
                              _infoRow(context, Icons.person_outline_rounded,
                                  'Gender', _tenant.gender ?? 'N/A'),
                              _infoRow(context, Icons.phone_outlined, 'Phone',
                                  _tenant.phone),
                              _infoRow(context, Icons.email_outlined, 'Email',
                                  _tenant.email,
                                  isLast: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Emergency Contacts
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: const Border(
                                left: BorderSide(
                                    color: Color(0xFFFF6F00), width: 4)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.emergency_rounded,
                                        color: Color(0xFFFF6F00), size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text('Emergency Contacts',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFF6F00))),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F2FD),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: const [
                                              Icon(Icons.man_rounded,
                                                  color: Color(0xFF1565C0),
                                                  size: 18),
                                              SizedBox(width: 6),
                                              Text('Father',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Color(0xFF1565C0))),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _tenant.fatherName ?? 'N/A',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.phone_rounded,
                                                  size: 12,
                                                  color: Color(0xFF1565C0)),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  _tenant.fatherPhone ?? 'N/A',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Color(0xFF1565C0)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFCE4EC),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: const [
                                              Icon(Icons.woman_rounded,
                                                  color: Color(0xFF880E4F),
                                                  size: 18),
                                              SizedBox(width: 6),
                                              Text('Mother',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Color(0xFF880E4F))),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _tenant.motherName ?? 'N/A',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.phone_rounded,
                                                  size: 12,
                                                  color: Color(0xFF880E4F)),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  _tenant.motherPhone ?? 'N/A',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Color(0xFF880E4F)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),


                        // Room Information
                        _sectionCard(
                          context,
                          icon: Icons.meeting_room_rounded,
                          iconColor: const Color(0xFF00897B),
                          iconBg: const Color(0xFFE0F2F1),
                          borderColor: const Color(0xFF00897B),
                          title: 'Room Information',
                          child: Column(
                            children: [
                              _infoRow(context, Icons.door_front_door_outlined,
                                  'Room Number', _tenant.roomNumber),
                              _infoRow(context, Icons.layers_outlined, 'Floor',
                                  _tenant.floor),
                              _infoRow(context, Icons.bed_outlined, 'Bed Type',
                                  _tenant.bed),
                              _infoRow(
                                  context,
                                  Icons.currency_rupee_rounded,
                                  'Monthly Rent',
                                  '₹${_tenant.rent.toInt()}/month',
                                  isLast: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Payment Status
                        _sectionCard(
                          context,
                          icon: Icons.payment_rounded,
                          iconColor: const Color(0xFF7B1FA2),
                          iconBg: const Color(0xFFF3E5F5),
                          borderColor: const Color(0xFF7B1FA2),
                          title: 'Payment Status',
                          child: Column(
                            children: [
                              _infoRow(context, Icons.calendar_month_outlined,
                                  'Current Month', _currentMonth()),
                              _paymentStatusRow(context),
                              _infoRow(context, Icons.event_rounded, 'Due Date', _dueDateText(), isLast: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
// Payment History
_sectionCard(
  context,
  icon: Icons.history_rounded,
  iconColor: const Color(0xFF7B1FA2),
  iconBg: const Color(0xFFF3E5F5),
  borderColor: const Color(0xFF7B1FA2),
  title: 'Payment History',
  child: _paymentHistory.isEmpty
      ? const Text('No payment records found',
          style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)))
      : Column(
          children: _paymentHistory.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            final isPaid = p['status'] == 'paid';
            final isLast = i == _paymentHistory.length - 1;
            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isPaid
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isPaid
                            ? Icons.check_circle_rounded
                            : Icons.warning_amber_rounded,
                        color: isPaid
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFF44336),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['month'] ?? '',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                          if (isPaid)
                            Text(
                              'Paid ₹${double.tryParse(p['amount'].toString())?.toInt()} via ${p['payment_mode']}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF4CAF50)),
                            )
                          else
                            Text(
                              'Overdue ₹${double.tryParse(p['amount'].toString())?.toInt()}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFF44336)),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isPaid ? 'Paid' : 'Overdue',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPaid
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFF44336),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isLast)
                  const Divider(height: 16, thickness: 0.5),
              ],
            );
          }).toList(),
        ),
),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color borderColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(
      BuildContext context, IconData icon, String label, String value,
      {bool isLast = false}) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF9E9E9E)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF9E9E9E))),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface)),
                ],
              ),
            ),
          ],
        ),
        if (!isLast)
          Divider(
            height: 20,
            color:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
          ),
      ],
    );
  }

  Widget _paymentStatusRow(BuildContext context) {
    Color color;
    Color bg;
    IconData icon;
    switch (_tenant.status) {
      case 'Paid':
        color = const Color(0xFF4CAF50);
        bg = const Color(0xFFE8F5E9);
        icon = Icons.check_circle_rounded;
        break;
      case 'Overdue':
        color = const Color(0xFFF44336);
        bg = const Color(0xFFFFEBEE);
        icon = Icons.cancel_rounded;
        break;
      case 'Due':
        color = const Color(0xFFFF9800);
        bg = const Color(0xFFFFF3E0);
        icon = Icons.access_time_rounded;
        break;
      default:
        color = const Color(0xFF9E9E9E);
        bg = const Color(0xFFF5F6FA);
        icon = Icons.help_outline_rounded;
    }
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.payment_outlined,
              size: 16, color: Color(0xFF9E9E9E)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Payment Status',
                  style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
              const SizedBox(height: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 14),
                    const SizedBox(width: 4),
                    Text(_tenant.status,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    Color bg;
    switch (status) {
      case 'Paid':
        color = Colors.white;
        bg = const Color(0xFF4CAF50).withOpacity(0.8);
        break;
      case 'Due':
        color = Colors.white;
        bg = const Color(0xFFFF9800).withOpacity(0.8);
        break;
      case 'Overdue':
        color = Colors.white;
        bg = const Color(0xFFF44336).withOpacity(0.8);
        break;
      default:
        color = Colors.white;
        bg = Colors.white.withOpacity(0.2);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(status,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  String _dueDateText() {
  final now = DateTime.now();
  final dueDay = _tenant.dueDay ?? 5;
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  if (_tenant.status == 'Paid') {
    // Show next month's due date
    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    final nextYear = now.month == 12 ? now.year + 1 : now.year;
    return 'Next Due: ${months[nextMonth - 1]} $dueDay, $nextYear';
  } else {
    // Show current month's due date
    return 'Due: ${months[now.month - 1]} $dueDay, ${now.year}';
  }
}

  String _currentMonth() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }
}