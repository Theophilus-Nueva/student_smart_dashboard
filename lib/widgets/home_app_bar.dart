import 'package:flutter/material.dart';

import 'notification_badge.dart';

/// Red header used on the tab roots: LPU logo, app name, notification bell.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({
    super.key,
    this.title = 'Smart Campus Tour Guide',
    this.unread = 0,
    this.onNotifications,
  });

  final String title;
  final int unread;
  final VoidCallback? onNotifications;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/images/images.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: onNotifications,
          icon: NotificationBadge(count: unread),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
