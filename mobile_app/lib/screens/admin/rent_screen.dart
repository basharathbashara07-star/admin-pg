import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/rent_card.dart';
import '../../widgets/rent_calendar.dart';
import '../../widgets/record_payment_sheet.dart';
import '../../widgets/set_rent_dialog.dart';

class RentScreen extends StatefulWidget {
  const RentScreen({super.key});

  @override
  State<RentScreen> createState() => _RentScreenState();
}

class _RentScreenState extends State<RentScreen> {
  bool _isCalendarView = true;
  DateTime? _selectedDate;
  List<RentRecord> _filteredRecords = [];

  bool _isLoading = true;
  bool _showAllPayments = false;
  double _totalCollected = 0;
  double _totalPending = 0;
  double _totalOverdue = 0;
  double _totalExpected = 0;
  int _paidCount = 0;
  int _dueCount = 0;
  int _overdueCount = 0;
  List<dynamic> _monthlyChart = [];
  List<dynamic> _tenantsList = [];
  List<RentRecord> _records = [];
  Map<String, List<String>> _overdueMonthsMap = {};
  Map<String, double> _overdueAmountMap = {};

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final data = await ApiService.fetchRentSummary(token);
      if (data['success'] == true) {
        setState(() {
          _totalCollected = double.tryParse(data['collected'].toString()) ?? 0;
          _totalPending = double.tryParse(data['pending'].toString()) ?? 0;
          _totalOverdue = double.tryParse(data['overdue'].toString()) ?? 0;
          _totalExpected = double.tryParse(data['expected'].toString()) ?? 0;
          _paidCount = data['rent_status']['paid'] ?? 0;
          _dueCount = data['rent_status']['due'] ?? 0;
          _overdueCount = data['rent_status']['overdue'] ?? 0;
          _monthlyChart = data['monthly_chart'] ?? [];
          _isLoading = false;
        });
      }
      final statusData = await ApiService.fetchTenantsStatus(token);
    
      if (statusData['success'] == true) {
      setState(() {
      _tenantsList = statusData['tenants'];
      final converted = _convertToRentRecords(statusData['tenants']);
      _records
      ..clear()
      ..addAll(converted);
      });
      }
        final overdueData = await ApiService.fetchOverdueMonths(token);
        if (overdueData['success'] == true) {
         final Map<String, List<String>> map = {};
final Map<String, double> amountMap = {};
for (var item in overdueData['overdue_months']) {
  final key = item['tenant_id'].toString();
  if (!map.containsKey(key)) {
    map[key] = [];
    amountMap[key] = 0;
  }
  map[key]!.add(item['month'].toString());
  amountMap[key] = (amountMap[key] ?? 0) + 
    (double.tryParse(item['amount'].toString()) ?? 0);
}
setState(() {
  _overdueMonthsMap = map;
  _overdueAmountMap = amountMap;
});
}
    } catch (e) {
      print('FETCH ERROR: $e');
      setState(() => _isLoading = false);
    }
  }



  void _onDateSelected(DateTime date, List<RentRecord> records) {
    setState(() {
      _selectedDate = date;
      _filteredRecords = records;
    });
  }

  void _showPaymentSheet(RentRecord record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RecordPaymentSheet(
        record: record,
        onConfirm: (updated) {
          setState(() {
            final idx = _records.indexWhere((r) => r.id == updated.id);
            if (idx != -1) _records[idx] = updated;
            if (_selectedDate != null) {
              _filteredRecords = _filteredRecords
                  .map((r) => r.id == updated.id ? updated : r)
                  .toList();
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${updated.tenantName} marked as ${updated.status}!'),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
          _fetchSummary();
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }


   List<RentRecord> _convertToRentRecords(List<dynamic> tenants) {
  return tenants.map((t) {
    final name = t['name']?.toString() ?? '';
    final initials = name.trim().split(' ').take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();
    final colors = [0xFF2196F3, 0xFF4CAF50, 0xFFFF9800, 0xFF9C27B0, 0xFFF44336];
    final colorIndex = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;

    final dueDay = t['due_day'] ?? 5;
    final now = DateTime.now();
    final dueDate = DateTime(now.year, now.month, dueDay);

    DateTime paymentDate;
    if (t['payment_date'] != null) {
      final dateStr = t['payment_date'].toString().split('T')[0];
      final parts = dateStr.split('-');
      paymentDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

      
    } else {
      paymentDate = DateTime(2000, 1, 1);
    }

    return RentRecord(
      id: t['id']?.toString() ?? '',
      tenantId: t['id']?.toString() ?? '',
      tenantName: name,
      tenantInitials: initials,
      tenantAvatarColor: colors[colorIndex],
      roomNumber: t['room_number']?.toString() ?? '',
      amount: double.tryParse(t['paid_amount']?.toString() ?? '0') ?? 0,
      totalRent: double.tryParse(t['rent_amount']?.toString() ?? '0') ?? 0,
      paymentMode: t['payment_mode']?.toString() ?? 'Cash',
      paymentDate: paymentDate,
      dueDate: dueDate,
      status: t['rent_status']?.toString() ?? 'Due',
    );
  }).toList();
}

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
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
                    'Rent',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                 '${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => SetRentDialog(
                          onSave: (rents) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Rent updated successfully!'),
                                backgroundColor: Color(0xFF4CAF50),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.edit, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Set Rent',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1432),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _toggleBtn('📅 Cal', _isCalendarView, () {
                          setState(() => _isCalendarView = true);
                        }),
                        _toggleBtn('☰ List', !_isCalendarView, () {
                          setState(() => _isCalendarView = false);
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.6,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _statChip('Collected',
                  '₹${_totalCollected.toStringAsFixed(0)}',
                  const Color(0xFF4CAF50), const Color(0xFFE8F5E9),
                  '↑ this month'),
                  _statChip('Pending',
                 '₹${_totalPending.toStringAsFixed(0)}',
                  const Color(0xFFFF9800), const Color(0xFFFFF3E0),
                 'This month'),
                 _statChip('Overdue',
                 '₹${_totalOverdue.toStringAsFixed(0)}',
                  const Color(0xFFF44336), const Color(0xFFFFEBEE),
                 'All months'),
                  _statChip('Expected',
                  '₹${_totalExpected.toStringAsFixed(0)}',
                  const Color(0xFF2196F3), const Color(0xFFE3F2FD),
                  'This month'),
            ],
          ),
          const SizedBox(height: 20),

          _sectionHeader('Monthly Collection', 'Last 6 months'),
          const SizedBox(height: 10),
          _barChart(),
          const SizedBox(height: 20),

          _sectionHeader('Rent Status', '${_getMonthName(DateTime.now().month)} ${DateTime.now().year}'),
          const SizedBox(height: 10),
          _donutCard(),
          const SizedBox(height: 20),

          _sectionHeader('Payment Calendar', 'Tap date to filter'),
          const SizedBox(height: 10),

          if (_isCalendarView) ...[
            RentCalendar(
              records: _records,
              onDateSelected: _onDateSelected,
            ),
            const SizedBox(height: 16),
            if (_selectedDate != null) ...[
              _calendarResultHeader(),
              const SizedBox(height: 10),
              if (_filteredRecords.isEmpty)
                _emptyState()
              else
                ..._filteredRecords.map((r) => RentCard(
                      record: r,
                      onMarkPaid: () => _showPaymentSheet(r),
                      overdueMonths: _overdueMonthsMap[r.tenantId] ?? [],
                      overdueAmount: _overdueAmountMap[r.tenantId] ?? 0,
                    )),
            ] else ...[
              _tapHint(),
            ],
          ] else ...[
            _groupHeader('🔴  Overdue', _records.where((r) => _overdueMonthsMap.containsKey(r.tenantId)).length,
                const Color(0xFFF44336), const Color(0xFFFFEBEE)),
            const SizedBox(height: 8),
            ..._records.where((r) => _overdueMonthsMap.containsKey(r.tenantId)).map((r) => RentCard(
                  record: r,
                  onMarkPaid: () => _showPaymentSheet(r),
                  overdueMonths: _overdueMonthsMap[r.tenantId] ?? [],
                  overdueAmount: _overdueAmountMap[r.tenantId] ?? 0,
                )),
            const SizedBox(height: 8),
            _groupHeader('🟡  Due This Month', _records.where((r) => r.status == 'Due' && !_overdueMonthsMap.containsKey(r.tenantId)).length,
                const Color(0xFFFF9800), const Color(0xFFFFF3E0)),
            const SizedBox(height: 8),
            ..._records.where((r) => r.status == 'Due' && !_overdueMonthsMap.containsKey(r.tenantId)).map((r) => RentCard(
                  record: r,
                  onMarkPaid: () => _showPaymentSheet(r),
                  overdueMonths: _overdueMonthsMap[r.tenantId] ?? [],
                  overdueAmount: _overdueAmountMap[r.tenantId] ?? 0,
                )),
            const SizedBox(height: 8),
            _groupHeader('✅  Paid', _records.where((r) => r.status == 'Paid' && !_overdueMonthsMap.containsKey(r.tenantId)).length,
                const Color(0xFF4CAF50), const Color(0xFFE8F5E9)),
            const SizedBox(height: 8),
            ...(_records.where((r) => r.status == 'Paid' && !_overdueMonthsMap.containsKey(r.tenantId)).toList()
              ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate))).map((r) => RentCard(
                  record: r,
                  onMarkPaid: () => _showPaymentSheet(r),
                  overdueMonths: _overdueMonthsMap[r.tenantId] ?? [],
                  overdueAmount: _overdueAmountMap[r.tenantId] ?? 0,
                )),
          ],

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionHeader('Recent Activity', null),
             GestureDetector(
  onTap: () {
    setState(() {
      _showAllPayments = !_showAllPayments;
    });
  },
  child: Text(
    _showAllPayments ? 'Show less ↑' : 'See all →',
    style: const TextStyle(
      fontSize: 11,
      color: Color(0xFF2196F3),
      fontWeight: FontWeight.bold,
    ),
  ),
),
            ],
          ),
          const SizedBox(height: 4),
          Text(
           'Today · ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
           style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E)),
          ),
          const SizedBox(height: 10),
          ...(_records.where((r) => r.status == 'Paid').toList()
          ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate)))
          .take(_showAllPayments ? 999 : 5)
          .map((r) => _activityTile(r)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2196F3) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : const Color(0xFF8090C8),
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label, String value, Color color,
      Color bgColor, String sub) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
              const Spacer(),
              Text(sub, style: TextStyle(fontSize: 8, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String? subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface)),
        if (subtitle != null)
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
      ],
    );
  }

  Widget _barChart() {
  final List<String> months = _monthlyChart.isNotEmpty
      ? _monthlyChart.map((e) => e['month'].toString()).toList()
      : ['Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb'];
  final List<double> data = _monthlyChart.isNotEmpty
      ? _monthlyChart.map((e) => double.tryParse(e['total'].toString()) ?? 0).toList()
      : [0, 0, 0, 0, 0, 0];
  final maxVal = data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b);
  final lastIndex = data.length - 1;

  return Container(
    height: 180,
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(data.length, (i) {
        final isLast = i == lastIndex;
        final barH = maxVal == 0 ? 0.0 : (data[i] / maxVal) * 100;
        final barColor = isLast ? const Color(0xFF2196F3) : const Color(0xFFB3D9F9);
        final amountColor = isLast ? const Color(0xFF2196F3) : const Color(0xFFB3D9F9);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '₹${data[i].toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Container(
                  height: barH,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  months[i],
                  style: const TextStyle(fontSize: 9, color: Color(0xFF9E9E9E)),
                ),
              ],
            ),
          ),
        );
      }),
    ),
  );
}

  Widget _donutCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _DonutPainter(
                values: [
                  _paidCount.toDouble(),
                  _dueCount.toDouble(),
                  _overdueCount.toDouble(),
                ],
                colors: const [
                  Color(0xFF4CAF50),
                  Color(0xFFFF9800),
                  Color(0xFFF44336),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_paidCount + _dueCount + _overdueCount}',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const Text('Tenants', style: TextStyle(fontSize: 9, color: Color(0xFF9E9E9E))),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                _legendRow('Paid', _paidCount, const Color(0xFF4CAF50)),
                _legendRow('Due', _dueCount, const Color(0xFFFF9800)),
                _legendRow('Overdue', _overdueCount, const Color(0xFFF44336)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
          ),
          Text('$count tenants',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
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
          Text(title,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Text('$count',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _calendarResultHeader() {
    final isPast = _selectedDate!.isBefore(DateTime.now()) ||
        (_selectedDate!.year == DateTime.now().year &&
            _selectedDate!.month == DateTime.now().month &&
            _selectedDate!.day == DateTime.now().day);
    final color = isPast ? const Color(0xFF4CAF50) : const Color(0xFFFF9800);
    final bgColor = isPast ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
    final icon = isPast ? '✅' : '📅';
    final label = isPast ? 'Payments on' : 'Due on';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            '$label  ${_formatDate(_selectedDate!)}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
          const Spacer(),
          Text('${_filteredRecords.length} records',
              style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 40, color: Color(0xFFE0E0E0)),
            SizedBox(height: 8),
            Text('No payments on this date',
                style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
          ],
        ),
      ),
    );
  }

  Widget _tapHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.touch_app_rounded, color: Color(0xFF2196F3), size: 18),
          SizedBox(width: 8),
          Text('Tap a date to see payments',
              style: TextStyle(fontSize: 12, color: Color(0xFF2196F3))),
        ],
      ),
    );
  }

  Widget _activityTile(RentRecord r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Color(r.tenantAvatarColor),
            child: Text(r.tenantInitials,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.tenantName,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface)),
                Text('Room ${r.roomNumber} · ${r.paymentMode}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
                Text('${r.paymentDate.day} ${_getMonthName(r.paymentDate.month)} ${r.paymentDate.year}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
              ],
            ),
          ),
          Text('₹${r.amount.toInt()}',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _DonutPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (a, b) => a + b);
    if (total == 0) return;
    final rect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    double startAngle = -3.14 / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}