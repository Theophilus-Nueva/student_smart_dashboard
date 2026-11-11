import 'package:flutter/material.dart';

import 'notification_badge.dart';
import '../theme/app_assets.dart';
import '../config/lab_week.dart';

/// Red header used on the tab roots: LPU logo, app name, notification bell.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({
    super.key,
    this.title,
    this.unread = 0,
    this.onNotifications,
  });

  /// Defaults to the current lab week's app name.
  final String? title;
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
              child: Image.asset(AppAssets.logo, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title ?? LabWeek.appName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
