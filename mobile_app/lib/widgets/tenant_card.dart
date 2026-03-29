import 'package:flutter/material.dart';
import '../models/models.dart';

class TenantCard extends StatelessWidget {
  final Tenant tenant;
  final VoidCallback onActionTap;

  const TenantCard({
    super.key,
    required this.tenant,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onActionTap,
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
              backgroundColor: Color(tenant.avatarColor),
              child: Text(
                tenant.avatarInitials,
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
                    tenant.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${tenant.roomNumber} · ${tenant.floor}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '₹${tenant.rent.toInt()}/mo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            // Status badge
            _buildStatusBadge(tenant.status),
          
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