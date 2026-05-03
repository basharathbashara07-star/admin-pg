import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class TenantCard extends StatefulWidget {
  final Tenant tenant;
  final VoidCallback onActionTap;

  const TenantCard({
    super.key,
    required this.tenant,
    required this.onActionTap,
  });

  @override
  State<TenantCard> createState() => _TenantCardState();
}

class _TenantCardState extends State<TenantCard> {
  int? _willPayLate;
  double? _riskPercentage;
  bool _loadingPrediction = true;

  @override
  void initState() {
    super.initState();
    _fetchPrediction();
  }

  Future<void> _fetchPrediction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final data = await ApiService.predictRentPayment(token, widget.tenant.id);
      print('PREDICTION for ${widget.tenant.name}: $data'); 
      if (data['success'] == true) {
        setState(() {
          _willPayLate = data['prediction']['will_pay_late'];
          _riskPercentage = double.tryParse(
              data['prediction']['risk_percentage'].toString());
          _loadingPrediction = false;
        });
      } else {
        setState(() => _loadingPrediction = false);
      }
    } catch (e) {
      setState(() => _loadingPrediction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onActionTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Color(widget.tenant.avatarColor),
              child: Text(
                widget.tenant.avatarInitials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.tenant.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.tenant.roomNumber} · ${widget.tenant.floor}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '₹${widget.tenant.rent.toInt()}/mo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // ── PREDICTION ROW ──
                  _loadingPrediction
                      ? const SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        )
                      : _willPayLate == null
                          ? const SizedBox()
                          : Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _willPayLate == 1
                                        ? const Color(0xFFF44336)
                                        : const Color(0xFF4CAF50),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _willPayLate == 1
                                      ? 'Likely to Pay Late • ${_riskPercentage?.toStringAsFixed(0)}%'
                                      : 'Likely to Pay on Time • ${_riskPercentage?.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _willPayLate == 1
                                        ? const Color(0xFFF44336)
                                        : const Color(0xFF4CAF50),
                                  ),
                                ),
                              ],
                            ),
                ],
              ),
            ),
            // Status badge
            _buildStatusBadge(widget.tenant.status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Paid':
        bgColor = const Color(0xFF4CAF50);
        textColor = Colors.white;
        break;
      case 'Due':
        bgColor = const Color(0xFFFF9800);
        textColor = Colors.white;
        break;
      case 'Overdue':
        bgColor = const Color(0xFFF44336);
        textColor = Colors.white;
        break;
      case 'Partially Paid':
        bgColor = const Color(0xFFFF9800);
        textColor = Colors.white;
        break;
      case 'Vacated':
        bgColor = const Color(0xFF00BCD4);
        textColor = Colors.white;
        break;
      default:
        bgColor = const Color(0xFF9E9E9E);
        textColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}