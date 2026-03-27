import 'package:flutter/material.dart';
import '../models/models.dart';

class TenantActionSheet extends StatelessWidget {
  final Tenant tenant;
  final VoidCallback onViewDetails;
  final VoidCallback onRecordPayment;
  final VoidCallback onVacateTenant;
  final VoidCallback onDeleteTenant;

  const TenantActionSheet({
    super.key,
    required this.tenant,
    required this.onViewDetails,
    required this.onRecordPayment,
    required this.onVacateTenant,
    required this.onDeleteTenant,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Tenant Info Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
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
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${tenant.roomNumber}  ·  ${tenant.status}  ·  ₹${tenant.rent.toInt()}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 8),

          // ── Actions ──
          _buildAction(
            context,
            icon: Icons.visibility_outlined,
            iconBg: const Color(0xFFE3F2FD),
            iconColor: const Color(0xFF2196F3),
            label: 'View Details',
            onTap: () {
              Navigator.pop(context);
              onViewDetails();
            },
          ),
          _buildAction(
            context,
            icon: Icons.currency_rupee_rounded,
            iconBg: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF4CAF50),
            label: 'Record Payment',
            onTap: () {
              Navigator.pop(context);
              onRecordPayment();
            },
          ),

          _buildAction(
            context,
            icon: Icons.logout_rounded,
            iconBg: const Color(0xFFFFF3E0),
            iconColor: const Color(0xFFFF9800),
            label: 'Vacate Tenant',
            onTap: () {
              Navigator.pop(context);
              onVacateTenant();
            },
          ),
          _buildAction(
            context,
            icon: Icons.delete_outline_rounded,
            iconBg: const Color(0xFFFFEBEE),
            iconColor: const Color(0xFFF44336),
            label: 'Delete Tenant',
            isDestructive: true,
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context);
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAction(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isDestructive
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isDestructive
                      ? const Color(0xFFF44336)
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDestructive
                  ? const Color(0xFFF44336)
                  : const Color(0xFF9E9E9E),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Theme.of(context).cardColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFF44336),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Remove Tenant?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to remove ${tenant.name} from ${tenant.roomNumber}? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9E9E9E),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE0E0E0),
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        onDeleteTenant();
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF44336),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFFF44336).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Remove',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}