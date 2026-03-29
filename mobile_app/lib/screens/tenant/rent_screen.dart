import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tenant/tenant_common_widgets.dart';
import '../../config/api_config.dart';

class RentScreen extends StatefulWidget {
  const RentScreen({super.key});
  @override
  State<RentScreen> createState() => _RentScreenState();
}

class _RentScreenState extends State<RentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;


String _token = '';

  // Rent
  Map<String, dynamic>? _currentRent;
  bool _loadingRent = true;

  // Payment history
  List<Map<String, dynamic>> _paymentHistory = [];
  bool _loadingHistory = true;

  // Expenses
  List<Map<String, dynamic>> _pendingExpenses = [];
  List<Map<String, dynamic>> _settledExpenses = [];
  List<Map<String, dynamic>> _roommates = [];
  bool _loadingExpenses = true;
  String _myPending = '0';

  @override
  void initState() {
  super.initState();
  _tabController = TabController(length: 2, vsync: this);
  _loadToken();
  }

  Future<void> _loadToken() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() => _token = prefs.getString('tenant_token') ?? '');
  _fetchCurrentRent();
  _fetchPaymentHistory();
  _fetchRoommates();
  _fetchExpenses();
 }

  Future<void> _fetchCurrentRent() async {
    try {
      setState(() => _loadingRent = true);
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/rent/current'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        setState(() {
          _currentRent = jsonDecode(res.body)['data'];
          _loadingRent = false;
        });
      } else {
        setState(() => _loadingRent = false);
      }
    } catch (e) {
      debugPrint('fetchCurrentRent error: $e');
      setState(() => _loadingRent = false);
    }
  }

  Future<void> _fetchPaymentHistory() async {
    try {
      setState(() => _loadingHistory = true);
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/rent/history'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        setState(() {
          _paymentHistory = List<Map<String, dynamic>>.from(
              jsonDecode(res.body)['data']['history']);
          _loadingHistory = false;
        });
      } else {
        setState(() => _loadingHistory = false);
      }
    } catch (e) {
      debugPrint('fetchPaymentHistory error: $e');
      setState(() => _loadingHistory = false);
    }
  }

  Future<void> _fetchRoommates() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/expenses/roommates'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        setState(() {
          _roommates = List<Map<String, dynamic>>.from(data['roommates']);
        });
      }
    } catch (e) {
      debugPrint('fetchRoommates error: $e');
    }
  }

  Future<void> _fetchExpenses() async {
    try {
      setState(() => _loadingExpenses = true);
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/expenses'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        setState(() {
          _pendingExpenses = List<Map<String, dynamic>>.from(data['pending']);
          _settledExpenses = List<Map<String, dynamic>>.from(data['settled']);
          _myPending = data['summary']['my_pending'].toString();
          _loadingExpenses = false;
        });
      } else {
        setState(() => _loadingExpenses = false);
      }
    } catch (e) {
      debugPrint('fetchExpenses error: $e');
      setState(() => _loadingExpenses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Rent & Payments'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMid,
          indicatorColor: AppTheme.primary,
          tabs: const [Tab(text: 'Rent'), Tab(text: 'Payments')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRentTab(context),
          _buildPaymentsTab(context),
        ],
      ),
    );
  }

  Widget _buildRentTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── RENT CARD ──
          _loadingRent
              ? Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                )
              : _currentRent == null
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('No rent data found', style: TextStyle(color: Colors.white)),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${_currentRent!['month_display'] ?? _currentRent!['month']} Rent',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _currentRent!['status'] == 'paid'
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.orange.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _currentRent!['status'].toString().toUpperCase(),
                                  style: TextStyle(
                                    color: _currentRent!['status'] == 'paid' ? Colors.greenAccent : Colors.orange,
                                    fontSize: 12, fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Rs.${_currentRent!['amount']}',
                              style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text('Due: ${_formatDueDate(_currentRent!['due_date'])}',
                              style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 20),
                          if (_currentRent!['status'] != 'paid')
                            GestureDetector(
                              onTap: () => _showPaymentDialog(context),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.payment, color: AppTheme.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Pay Rs.${_currentRent!['amount']} Now  >',
                                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 16)),
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text('Rent Paid ✓', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

          const SizedBox(height: 24),

          // ── SHARED EXPENSES HEADER ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Shared Expenses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
              GestureDetector(
                onTap: () => _showAddExpenseDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── ROOMMATES ROW ──
          if (_roommates.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Text('Room:', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary, fontSize: 13)),
                  const SizedBox(width: 10),
                  _roommateAvatar('You', AppTheme.primary),
                  ..._roommates.map((r) => _roommateAvatar(r['name'], AppTheme.secondary)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── PENDING TOTAL ──
          if (_myPending != '0' && _myPending != '0.00')
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppTheme.orange, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Your total pending', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark))),
                  Text('Rs.$_myPending', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.orange)),
                ],
              ),
            ),

          const SizedBox(height: 16),

          if (_loadingExpenses)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else ...[
            if (_pendingExpenses.isNotEmpty) ...[
              Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: AppTheme.orange, borderRadius: BorderRadius.circular(5))),
                const SizedBox(width: 8),
                Text('Pending (${_pendingExpenses.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.orange)),
              ]),
              const SizedBox(height: 10),
              ..._pendingExpenses.map((exp) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildExpenseCard(context, exp, isPending: true),
              )),
            ],
            if (_settledExpenses.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: AppTheme.success, borderRadius: BorderRadius.circular(5))),
                const SizedBox(width: 8),
                Text('Settled (${_settledExpenses.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.success)),
              ]),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
                child: Column(
                  children: _settledExpenses.asMap().entries.map((entry) {
                    final i = entry.key;
                    final exp = entry.value;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 34, height: 34,
                                decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: Icon(_expenseIcon(exp['title']), color: AppTheme.success, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(exp['title'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark))),
                              Text('Rs.${exp['my_share']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark)),
                              const SizedBox(width: 8),
                              const Icon(Icons.check_circle, color: AppTheme.success, size: 18),
                            ],
                          ),
                        ),
                        if (i < _settledExpenses.length - 1) const Divider(height: 1, indent: 14, endIndent: 14),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
            if (_pendingExpenses.isEmpty && _settledExpenses.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Center(
                  child: Column(children: [
                    Icon(Icons.receipt_long_outlined, size: 40, color: AppTheme.textLight),
                    SizedBox(height: 8),
                    Text('No shared expenses yet', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textMid)),
                    SizedBox(height: 4),
                    Text('Tap + Add to split a bill with roommates', style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
                  ]),
                ),
              ),
          ],

          const SizedBox(height: 24),

          // ── AI INSIGHTS ──
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── PAYMENTS TAB — real data from backend ──
  Widget _buildPaymentsTab(BuildContext context) {
    if (_loadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    final history = _paymentHistory.where((p) => p != null).toList();
    if (history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textLight),
            SizedBox(height: 12),
            Text('No payment history yet', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textMid)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final p = history[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            child: ListTile(
              leading: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: _statusColor(p['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_statusIcon(p['status']), color: _statusColor(p['status']), size: 20),
              ),
              title: Text(_formatMonth(p['month'] ?? ''), style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark)),
              subtitle: Text(p['payment_date'] ?? p['due_date'] ?? '',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Rs.${p['amount']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textDark)),
                  StatusBadge(status: p['status']),
                ],
              ),
              onTap: p['status'] == 'paid' ? () => _showReceiptDialog(context, p) : null,
            ),
          ),
        );
      },
    );
  }

  Widget _roommateAvatar(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          AvatarWidget(name: name, size: 34, backgroundColor: color),
          const SizedBox(height: 4),
          Text(name.split(' ')[0], style: const TextStyle(fontSize: 10, color: AppTheme.textMid)),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, Map<String, dynamic> expense, {required bool isPending}) {
    final splits = expense['splits'] as List? ?? [];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: _expenseColor(expense['title']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_expenseIcon(expense['title']), color: _expenseColor(expense['title']), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense['title'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textDark)),
                    Text('Total: Rs.${expense['total_amount']}  •  ${expense['expense_date']?.toString().split('T')[0] ?? ''}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Your share', style: TextStyle(fontSize: 11, color: AppTheme.textMid)),
                  Text('Rs.${expense['my_share']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textDark)),
                ],
              ),
            ],
          ),
          if (splits.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            const Text('Split Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMid)),
            const SizedBox(height: 8),
            ...splits.map((split) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  AvatarWidget(name: split['tenant_name'] ?? 'User', size: 28, backgroundColor: AppTheme.secondary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(split['tenant_name'] ?? 'User', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textDark))),
                  Text('Rs.${split['amount']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textDark)),
                  const SizedBox(width: 8),
                  StatusBadge(status: split['status']),
                ],
              ),
            )),
          ],
          const SizedBox(height: 12),
          if (isPending)
            GestureDetector(
              onTap: () => _payMyShare(context, expense),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF3B82F6)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('Pay My Share Rs.${expense['my_share']}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _payMyShare(BuildContext context, Map<String, dynamic> expense) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Pay ${expense['title']} Share', style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Confirm payment of'),
            const SizedBox(height: 8),
            Text('Rs.${expense['my_share']}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.primary)),
            const SizedBox(height: 8),
            Text('for ${expense['title']}', style: const TextStyle(color: AppTheme.textMid)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final res = await http.post(
                  Uri.parse('${ApiConfig.baseUrl}/expenses/pay/${expense['id']}'),
                  headers: {'Authorization': 'Bearer $_token'},
                );
                if (res.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Paid Rs.${expense['my_share']} for ${expense['title']}!'), backgroundColor: AppTheme.success),
                  );
                  _fetchExpenses();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment failed. Try again.'), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Network error.'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Confirm Pay', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final amountController = TextEditingController();
    String selectedTitle = 'Electricity';
    Map<int, bool> selectedRoommates = {
      for (var r in _roommates) (r['id'] as int): true
    };

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
                const Text('Add Shared Expense', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                const SizedBox(height: 6),
                const Text('Choose who to split with', style: TextStyle(fontSize: 13, color: AppTheme.textMid)),
                const SizedBox(height: 20),
                const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: ['Electricity', 'Wi-Fi', 'Groceries', 'Water', 'Gas', 'Other'].map((cat) => GestureDetector(
                    onTap: () => setS(() => selectedTitle = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selectedTitle == cat ? AppTheme.primary : AppTheme.bgLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selectedTitle == cat ? AppTheme.primary : AppTheme.border),
                      ),
                      child: Text(cat, style: TextStyle(color: selectedTitle == cat ? Colors.white : AppTheme.textMid, fontWeight: FontWeight.w500, fontSize: 13)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark)),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setS(() {}),
                  decoration: InputDecoration(
                    hintText: 'e.g. 1200',
                    prefixText: 'Rs. ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary)),
                    filled: true, fillColor: AppTheme.bgLight,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Split with', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primary)),
                      const SizedBox(height: 10),
                      const Row(children: [
                        AvatarWidget(name: 'You', size: 30, backgroundColor: AppTheme.primary),
                        SizedBox(width: 10),
                        Expanded(child: Text('You', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                        Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
                      ]),
                      if (_roommates.isNotEmpty) const Divider(height: 16),
                      ..._roommates.map((r) {
                        final id = r['id'] as int;
                        final isSelected = selectedRoommates[id] ?? true;
                        final amount = double.tryParse(amountController.text) ?? 0;
                        final count = selectedRoommates.values.where((v) => v).length + 1;
                        final perPerson = count > 0 ? (amount / count) : 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              AvatarWidget(name: r['name'], size: 30, backgroundColor: isSelected ? AppTheme.secondary : AppTheme.border),
                              const SizedBox(width: 10),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r['name'], style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isSelected ? AppTheme.textDark : AppTheme.textLight)),
                                  if (amount > 0 && isSelected)
                                    Text('Rs.${perPerson.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w500)),
                                ],
                              )),
                              Switch(value: isSelected, activeThumbColor: AppTheme.primary, onChanged: (val) => setS(() => selectedRoommates[id] = val)),
                            ],
                          ),
                        );
                      }),
                      if (amountController.text.isNotEmpty) ...[
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Each person pays', style: TextStyle(fontSize: 12, color: AppTheme.textMid)),
                            Text(() {
                              final amount = double.tryParse(amountController.text) ?? 0;
                              final count = selectedRoommates.values.where((v) => v).length + 1;
                              return 'Rs.${(amount / count).toStringAsFixed(0)}';
                            }(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.primary)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () async {
                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
                      return;
                    }
                    final selectedIds = _roommates
                        .where((r) => selectedRoommates[r['id'] as int] == true)
                        .map((r) => r['id']).toList();
                    try {
                      final res = await http.post(
                        Uri.parse('${ApiConfig.baseUrl}/expenses'),
                        headers: {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'title': selectedTitle,
                          'total_amount': amount,
                          'expense_date': DateTime.now().toIso8601String().split('T')[0],
                          'selected_ids': selectedIds,
                        }),
                      );
                      if (res.statusCode == 201) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$selectedTitle added and split!'), backgroundColor: AppTheme.success),
                        );
                        _fetchExpenses();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to add expense.'), backgroundColor: Colors.red),
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
                    child: const Center(child: Text('Add & Split', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textMid))),
      ]),
    );
  }

  Color _expenseColor(String title) {
    switch (title.toLowerCase()) {
      case 'electricity': return Colors.orange;
      case 'wi-fi': return AppTheme.primary;
      case 'groceries': return AppTheme.success;
      case 'water': return Colors.blue;
      case 'gas': return Colors.red;
      default: return AppTheme.secondary;
    }
  }

  IconData _expenseIcon(String title) {
    switch (title.toLowerCase()) {
      case 'electricity': return Icons.bolt;
      case 'wi-fi': return Icons.wifi;
      case 'groceries': return Icons.shopping_basket;
      case 'water': return Icons.water_drop;
      case 'gas': return Icons.local_fire_department;
      default: return Icons.receipt;
    }
  }
  String _formatDueDate(dynamic dateStr) {
  if (dateStr == null) return 'N/A';
  try {
    final date = DateTime.parse(dateStr.toString());
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  } catch (_) {
    return dateStr.toString();
  }
}

  String _formatMonth(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid': return AppTheme.success;
      case 'pending': return AppTheme.orange;
      case 'overdue': return AppTheme.danger;
      default: return AppTheme.textMid;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'paid': return Icons.check_circle;
      case 'pending': return Icons.schedule;
      case 'overdue': return Icons.warning;
      default: return Icons.info;
    }
  }

  void _showPaymentDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _paymentOption(Icons.account_balance, 'UPI / Net Banking', context),
            _paymentOption(Icons.credit_card, 'Credit / Debit Card', context),
            _paymentOption(Icons.account_balance_wallet, 'Wallet', context),
          ],
        ),
      ),
    );
  }

  Widget _paymentOption(IconData icon, String label, BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppTheme.primary),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMid),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Processing via $label...'), backgroundColor: AppTheme.success),
        );
      },
    );
  }

  void _showReceiptDialog(BuildContext context, Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Digital Receipt', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ReceiptRow(label: 'Month', value: payment['month'] ?? ''),
              _ReceiptRow(label: 'Amount', value: 'Rs.${payment['amount']}'),
              _ReceiptRow(label: 'Status', value: payment['status'] ?? ''),
              _ReceiptRow(label: 'Paid On', value: payment['payment_date'] ?? 'N/A'),
              _ReceiptRow(label: 'Method', value: payment['payment_method'] ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Download PDF', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReceiptRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
        ],
      ),
    );
  }
}