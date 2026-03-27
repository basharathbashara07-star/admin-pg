import 'package:flutter/material.dart';
import '../models/models.dart';

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = [
      ActivityItem(
        icon: Icons.receipt_rounded,
        iconBg: const Color(0xFFFFC107),
        title: 'John Doe paid the rent',
        time: '10 min',
      ),
      ActivityItem(
        icon: Icons.warning_rounded,
        iconBg: const Color(0xFFF44336),
        title: 'New maintenance request added',
        time: '2 hours',
      ),
      ActivityItem(
        icon: Icons.person_add_rounded,
        iconBg: const Color(0xFF2196F3),
        title: 'Visitor added by you',
        time: '1 day',
      ),
      ActivityItem(
        icon: Icons.campaign_rounded,
        iconBg: const Color(0xFF2196F3),
        title: 'New notice posted',
        time: '3 days',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2196F3),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...activities.map((a) => _buildActivityRow(context, a)),
        ],
      ),
    );
  }

  Widget _buildActivityRow(BuildContext context, ActivityItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            item.time,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }
}