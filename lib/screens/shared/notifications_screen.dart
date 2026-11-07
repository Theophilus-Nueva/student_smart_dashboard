import 'package:flutter/material.dart';

import '../../models/activity_item.dart';
import '../../services/app_services.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/settings_sections.dart';

/// Shared / Notifications (Week 6): test notification and the three
/// reminder categories. System notifications need
/// `flutter_local_notifications`; until then the test shows in the app.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).activity.markAllRead();
    });
  }

  Future<void> _test() async {
    final activity = AppScope.of(context).activity;
    await activity.add(
      ActivityKind.notification,
      'Dashboard Reminder',
      'You have pending tasks',
    );
    await activity.markAllRead();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        leading: const Icon(Icons.notifications, color: AppColors.brand),
        content: const Text('Dashboard Reminder\nYou have pending tasks'),
        actions: [
          TextButton(
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  @override
  void deactivate() {
    ScaffoldMessenger.maybeOf(context)?.clearMaterialBanners();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final activity = AppScope.of(context).activity;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            onPressed: _test,
            icon: const Icon(Icons.notifications_active),
            label: const Text('Send Test Notification'),
          ),
          const SizedBox(height: 6),
          const Text(
            'Shows in the app for now. Phone notifications are added with '
            'the notifications package.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const NotificationTogglesSection(),
          const SectionHeader('Recent'),
          ListenableBuilder(
            listenable: activity,
            builder: (context, _) {
              final items = activity.items.take(10).toList();
              if (items.isEmpty) {
                return const Text(
                  'Nothing yet.',
                  style: TextStyle(color: AppColors.muted),
                );
              }
              return Card(
                child: Column(
                  children: [
                    for (final i in items)
                      ListTile(
                        leading: Icon(i.kind.icon),
                        title: Text(i.title),
                        subtitle: i.description.isEmpty
                            ? null
                            : Text(i.description),
                        trailing: Text(
                          formatTime(i.time),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
