import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';
import '../../widgets/tenant_card.dart';
import '../../widgets/add_tenant_dialog.dart';
import '../../widgets/tenant_action_sheet.dart';
import '../../services/api_service.dart';
import 'tenant_detail_screen.dart';
import 'dart:async';
import '../../widgets/record_payment_sheet.dart';
import '../../widgets/edit_tenant_dialog.dart';

class TenantScreen extends StatefulWidget {
  const TenantScreen({super.key});

  @override
  State<TenantScreen> createState() => _TenantScreenState();
}

class _TenantScreenState extends State<TenantScreen> {
  String _searchQuery = '';
  bool _isLoading = true;

  final List<Tenant> _tenants = [];
  final List<RoomOption> _vacantRooms = [];
  int _totalCount = 0;
  int _activeCount = 0;
  int _vacatedCount = 0;
  int _pendingCount = 0;
  late Timer _timer;


  @override
  void initState() {
    super.initState();
    _fetchTenants();
    _fetchRooms();
    _fetchCounts();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
    _fetchTenants();
    _fetchCounts();
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
      
      final data = await ApiService.fetchTenants(token);

      if (data["success"] == true) {
        final List tenantList = data["tenants"];
        setState(() {
          _tenants.clear();
          for (var t in tenantList) {
            final name = t["name"] ?? "";
            _tenants.add(Tenant(
              id: t["id"].toString(),
              name: name,
              email: t["email"] ?? "",
              phone: t["phone"] ?? "",
              roomNumber: t["room_no"] ?? "Not Assigned",
              floor: t["floor"] ?? "",
              bed: t["bed"] ?? "",
              rent: double.tryParse(t["rent_amount"].toString()) ?? 0,
              status: t["payment_status"] == "paid" ? "Paid" :t["payment_status"] == "overdue" ? "Overdue" : "Due", 

              avatarInitials: name
                  .split(' ')
                  .map((e) => e.isNotEmpty ? e[0] : '')
                  .take(2)
                  .join(),
              avatarColor: 0xFF2196F3,
              gender: t["gender"],
              fatherName: t["father_name"],
              fatherPhone: t["father_phone"],
              motherName: t["mother_name"],
              motherPhone: t["mother_phone"],
              dueDay: t["due_day"] != null ? int.tryParse(t["due_day"].toString()) : null,
            ));
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showError(data["message"] ?? "Failed to load tenants");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Server error: $e");
    }
  }                                
  
  //Counts
  Future<void> _fetchCounts() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final data = await ApiService.fetchTenantCounts(token);
    setState(() {
      _totalCount = data['total'] ?? 0;
      _activeCount = data['active'] ?? 0;
      _vacatedCount = data['vacated'] ?? 0;
      _pendingCount = data['pending'] ?? 0;
    });
  } catch (e) {
    print("COUNTS ERROR: $e"); // CHANGE THIS
  }
}


  Future<void> _fetchRooms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final data = await ApiService.fetchRooms(token);

      if (data["success"] == true) {
        final List roomList = data["rooms"];
        setState(() {
          _vacantRooms.clear();
          for (var r in roomList) {
            _vacantRooms.add(RoomOption(
              id: r["id"],
              room_no: r["room_no"],
              floor: r["floor"],
              bed: r["bed"],
              capacity: r["capacity"],
              current_occupancy: r["current_occupancy"],
              status: r["status"],
              availableBeds: r["availableBeds"],
            ));
          }
        });
      }
    } catch (e) {
      _showError("Failed to load rooms: $e");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFF44336),
      ),
    );
  }

  List<Tenant> get _filteredTenants {
    if (_searchQuery.isEmpty) return _tenants;
    return _tenants
        .where((t) =>
            t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.roomNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.status.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

 

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return _buildBody();
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tenants',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '$_totalCount total residents',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showAddTenantDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2196F3).withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Add Tenant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip('$_totalCount', 'Total',
                  const Color(0xFF2196F3), const Color(0xFFE3F2FD)),
              const SizedBox(width: 8),
              _buildStatChip('$_activeCount', 'Active',
                  const Color(0xFF4CAF50), const Color(0xFFE8F5E9)),
              const SizedBox(width: 8),
              _buildStatChip('$_vacatedCount', 'Vacated',
                  const Color(0xFF9C27B0), const Color(0xFFF3E5F5)),
              const SizedBox(width: 8),
              _buildStatChip('$_pendingCount', 'Pending',
                  const Color(0xFFFF9800), const Color(0xFFFFF3E0)),
            ],
          ),
          const SizedBox(height: 14),
          if (_pendingCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFFFC107), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded,
                      color: Color(0xFFFFC107), size: 18),
                  const SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Reminder: ',
                          style: TextStyle(
                            color: Color(0xFFFFC107),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        TextSpan(
                          text:
                              '$_pendingCount tenants have pending rent this month.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: const InputDecoration(
                hintText: 'Search tenants...',
                hintStyle:
                    TextStyle(color: Color(0xFFBDBDBD), fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Color(0xFF9E9E9E), size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Tenants',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '${_filteredTenants.length} found',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _filteredTenants.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Icon(Icons.search_off_rounded,
                            size: 48, color: Color(0xFFE0E0E0)),
                        const SizedBox(height: 12),
                        Text(
                          'No tenants found',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredTenants.length,
                  itemBuilder: (context, index) {
                    final tenant = _filteredTenants[index];
                    return TenantCard(
                      tenant: tenant,
                      onActionTap: () => _showActionSheet(tenant),
                    );
                  },
                ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatChip(
      String num, String label, Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration:
                  BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(num,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 9, color: Color(0xFF9E9E9E))),
          ],
        ),
      ),
    );
  }

  void _showAddTenantDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddTenantDialog(
        vacantRooms: _vacantRooms,
        onAdd: (name, email, phone, room, gender, fatherName, fatherPhone, motherName, motherPhone, rent, dueDay) {
          setState(() {
            _tenants.add(Tenant(
              id: DateTime.now().toString(),
              name: name,
              email: email,
              phone: phone,
              roomNumber: room.room_no,
              floor: room.floor,
              bed: room.bed,
              rent: 0,
              status: 'Due',
              avatarInitials:
                  name.split(' ').map((e) => e[0]).take(2).join(),
              avatarColor: 0xFF2196F3,
              gender: gender,
              fatherName: fatherName,
              fatherPhone: fatherPhone,
              motherName: motherName,
              motherPhone: motherPhone,
              dueDay: dueDay,
            ));
            _vacantRooms.remove(room);
          });
        },
      ),
    );
  }

  void _showActionSheet(Tenant tenant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => TenantActionSheet(
        tenant: tenant,
        onViewDetails: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TenantDetailScreen(tenant: tenant,
              vacantRooms: _vacantRooms,
              ),
            ),
          );
        },
        onRecordPayment: () {
          if (tenant.status == 'Paid'){
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This tenant has already paid this month!'),
                backgroundColor: Color(0xFF4CAF50),
      ),
            );
            return;
          }
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => RecordPaymentSheet(
              record: RentRecord(
                id: tenant.id,
                tenantId: tenant.id,
                tenantName: tenant.name,
                tenantInitials: tenant.avatarInitials,
                tenantAvatarColor: tenant.avatarColor,
                roomNumber: tenant.roomNumber,
                amount: tenant.rent,
                totalRent: tenant.rent,
                paymentMode: '',
                paymentDate: DateTime.now(),
                dueDate: DateTime.now(),
                status: tenant.status,
              ),
  onConfirm: (updated) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final now = DateTime.now();
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    final month = '${months[now.month - 1]} ${now.year}';
    final dueDayNum = tenant.dueDay ?? 5;
    final dueDate = '${now.year}-${now.month.toString().padLeft(2,'0')}-${dueDayNum.toString().padLeft(2,'0')}';

    final paymentDate = '${updated.paymentDate.year}-${updated.paymentDate.month.toString().padLeft(2, '0')}-${updated.paymentDate.day.toString().padLeft(2, '0')}';

    final result = await ApiService.recordPayment(
      token,
      int.parse(tenant.id),
      updated.amount,
      tenant.rent,
      updated.paymentMode,
      month,
      dueDate,
      paymentDate,
    );

    if (result['success'] == true) {
      _fetchTenants();
      _fetchCounts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment recorded for ${tenant.name}!'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to record payment'),
          backgroundColor: const Color(0xFFF44336),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: const Color(0xFFF44336),
      ),
    );
  }
},
            ),
          );
        },
       
  onVacateTenant: () async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  final data = await ApiService.vacateTenant(token, tenant.id);

  if (data['success'] == true) {
    _fetchTenants();
    _fetchCounts();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${tenant.name} vacated successfully'),
        backgroundColor: const Color(0xFFFF9800),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(data['message'] ?? 'Failed to vacate tenant'),
        backgroundColor: const Color(0xFFF44336),
      ),
    );
  }
},


 //delete tenant
                                               onDeleteTenant: () async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  final data = await ApiService.deleteTenant(token, tenant.id);

  if (data['success'] == true) {
    _fetchTenants();
    _fetchCounts();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${tenant.name} deleted successfully'),
        backgroundColor: const Color(0xFFF44336),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(data['message'] ?? 'Failed to delete tenant'),
        backgroundColor: const Color(0xFFF44336),
      ),
    );
  }
},      
      ),
    );
  }
}