import 'package:flutter/material.dart';
import '../models/models.dart';

class MaintenanceCard extends StatelessWidget {
  final MaintenanceRequest request;
  final VoidCallback onView;

  const MaintenanceCard({
    super.key,
    required this.request,
    required this.onView,
  });

  Color get _priorityColor {
    switch (request.priority) {
      case 'High':   return const Color(0xFFF44336);
      case 'Medium': return const Color(0xFFFF9800);
      case 'Low':    return const Color(0xFF4CAF50);
      default:       return const Color(0xFF9E9E9E);
    }
  }

  Color get _priorityBgColor {
    switch (request.priority) {
      case 'High':   return const Color(0xFFFFEBEE);
      case 'Medium': return const Color(0xFFFFF3E0);
      case 'Low':    return const Color(0xFFE8F5E9);
      default:       return const Color(0xFFEEEEEE);
    }
  }

  Color get _statusColor {
    switch (request.status) {
      case 'Pending':     return const Color(0xFFFF9800);
      case 'In Progress': return const Color(0xFF00BCD4);
      case 'Overdue':     return const Color(0xFFF44336);
      case 'Resolved':    return const Color(0xFF4CAF50);
      default:            return const Color(0xFF9E9E9E);
    }
  }

  Color get _statusBgColor {
    switch (request.status) {
      case 'Pending':     return const Color(0xFFFFF3E0);
      case 'In Progress': return const Color(0xFFE0F7FA);
      case 'Overdue':     return const Color(0xFFFFEBEE);
      case 'Resolved':    return const Color(0xFFE8F5E9);
      default:            return const Color(0xFFEEEEEE);
    }
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: onView,
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
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
              // ── Priority color bar ──
              Container(width: 4, color: _priorityColor),

              // ── Content ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Row 1: Avatar + Name + Room + Priority ──
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                Color(request.tenantAvatarColor),
                            child: Text(
                              request.tenantInitials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.tenantName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                Text(
                                  request.roomNumber,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF9E9E9E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Priority badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _priorityBgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              request.priority,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: _priorityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ── Row 2: Issue title ──
                      Text(
                        request.issueTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // ── Row 3: Category tag + Date ──
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              request.category,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF2196F3),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '· ${_formatDate(request.dateRaised)}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFF5F6FA)),
                      const SizedBox(height: 8),

                      // ── Row 4: Status + Actions ──
                      Row(
                        children: [
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusBgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  request.status,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: _statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),

                          // View button
                          _actionBtn(Icons.visibility_outlined,
                              const Color(0xFFE3F2FD),
                              const Color(0xFF2196F3), onView),
                          const SizedBox(width: 6),
                      
                        ],
                      ),
                    ],
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

  Widget _actionBtn(
      IconData icon, Color bg, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: iconColor),
      ),
    );
  }
}