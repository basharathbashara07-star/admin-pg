import 'package:flutter/material.dart';
import '../models/models.dart';

class RentCard extends StatelessWidget {
  final RentRecord record;
  final VoidCallback onMarkPaid;
  final List<String> overdueMonths;
  final double overdueAmount;

  const RentCard({
    super.key,
    required this.record,
    required this.onMarkPaid,
    this.overdueMonths = const [],
    this.overdueAmount = 0,
  });

  Color get _statusColor {
    switch (record.status) {
      case 'Paid':           return const Color(0xFF4CAF50);
      case 'Due':            return const Color(0xFFFF9800);
      case 'Overdue':        return const Color(0xFFF44336);
      case 'Partially Paid': return const Color(0xFF9C27B0);
      default:               return const Color(0xFF9E9E9E);
    }
  }

  Color get _statusBgColor {
    switch (record.status) {
      case 'Paid':           return const Color(0xFFE8F5E9);
      case 'Due':            return const Color(0xFFFFF3E0);
      case 'Overdue':        return const Color(0xFFFFEBEE);
      case 'Partially Paid': return const Color(0xFFF3E5F5);
      default:               return const Color(0xFFEEEEEE);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = record.status == 'Paid';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, color: _statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(record.tenantAvatarColor),
                            child: Text(
                              record.tenantInitials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.tenantName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  record.roomNumber,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF9E9E9E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${record.totalRent.toInt()}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _statusBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  record.status,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: _statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (!isPaid) ...[
  const SizedBox(height: 8),
  Row(
    children: [
      Icon(
        record.status == 'Overdue' ? Icons.warning_amber_rounded : Icons.access_time,
        color: _statusColor,
        size: 13,
      ),
      const SizedBox(width: 4),
      Text(
        record.status == 'Overdue'
            ? 'Overdue since ${_formatDate(record.dueDate)}'
            : 'Due on ${_formatDate(record.dueDate)}',
        style: TextStyle(
          fontSize: 10,
          color: _statusColor,
        ),
      ),
    ],
  ),
  if (overdueMonths.isNotEmpty) ...[
    const SizedBox(height: 6),
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.history, color: Color(0xFFF44336), size: 12),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Unpaid: ${overdueMonths.join(', ')}',
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFFF44336),
            ),
          ),
        ),
      ],
    ),
    const SizedBox(height: 4),
    Row(
      children: [
        const Icon(Icons.currency_rupee, color: Color(0xFFF44336), size: 12),
        const SizedBox(width: 2),
        Text(
          'Total Overdue: ₹${overdueAmount.toInt()}',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF44336),
          ),
        ),
      ],
    ),
  ],

                      ]
                      else ...[
  const SizedBox(height: 8),
  Row(
    children: [
      const Icon(Icons.check_circle,
          color: Color(0xFF4CAF50), size: 13),
      const SizedBox(width: 4),
      Text(
        'Paid via ${record.paymentMode} · '
        '${_formatDate(record.paymentDate)}',
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF4CAF50),
        ),
      ),
    ],
  ),
  if (overdueMonths.isNotEmpty) ...[
    const SizedBox(height: 6),
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.warning_amber_rounded,
            color: Color(0xFFFF9800), size: 12),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Unpaid: ${overdueMonths.join(', ')}',
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFFFF9800),
            ),
          ),
        ),
      ],
    ),
    const SizedBox(height: 4),
    Row(
      children: [
        const Icon(Icons.currency_rupee,
            color: Color(0xFFFF9800), size: 12),
        const SizedBox(width: 2),
        Text(
          'Total Overdue: ₹${overdueAmount.toInt()}',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF9800),
          ),
        ),
      ],
    ),
  ],
],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}