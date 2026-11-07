import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class NotificationBadge extends StatelessWidget {
  final int count;

  const NotificationBadge({super.key, this.count = 8});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications, size: 28, color: Colors.white),
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: AppColors.badge,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
