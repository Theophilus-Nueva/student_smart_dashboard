import 'package:flutter/material.dart';

import '../../models/activity_item.dart';
import '../../services/app_services.dart';
import '../../services/app_settings.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/settings_sections.dart';

/// Shared / Notifications (Week 6): test notification and the three
/// reminder categories, sent as phone notifications.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static const _samples = {
    ReminderCategory.study: (
      'Study Reminder',
      'Time to review today’s lessons.',
      AppSettings.studyReminders,
    ),
    ReminderCategory.assignment: (
      'Assignment Reminder',
      'An assignment is due tomorrow.',
      AppSettings.assignmentReminders,
    ),
    ReminderCategory.dailyCheckIn: (
      'Daily Check-In',
      'Record a campus visit today.',
      AppSettings.dailyCheckIn,
    ),
  };

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  ScaffoldMessengerState? _messenger;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).activity.markAllRead();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
  }

  Future<void> _send(
    ReminderCategory category,
    String title,
    String body,
  ) async {
    final services = AppScope.of(context);
    final allowed = await services.notifications.requestPermission();
    if (allowed) {
      await services.notifications.show(category, title, body);
    }
    await services.activity.add(ActivityKind.notification, title, body);
    await services.activity.markAllRead();
    if (!mounted) return;
    if (!allowed) {
      showAppSnack(
        context,
        'Notifications are turned off for this app in your phone settings.',
        error: true,
      );
      return;
    }
    // Also show it in the app, in case the phone is in Do Not Disturb.
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        leading: const Icon(Icons.notifications, color: AppColors.brand),
        content: Text('$title\n$body'),
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
  void dispose() {
    _messenger?.clearMaterialBanners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final activity = services.activity;
    final settings = services.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            onPressed: () => _send(
              ReminderCategory.dashboard,
              'Dashboard Reminder',
              'You have pending tasks',
            ),
            icon: const Icon(Icons.notifications_active),
            label: const Text('Send Test Notification'),
          ),
          const NotificationTogglesSection(),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: settings,
            builder: (context, _) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final MapEntry(key: category, value: sample)
                    in NotificationsScreen._samples.entries)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: settings.get(sample.$3)
                        ? () => _send(category, sample.$1, sample.$2)
                        : null,
                    child: Text('Send ${category.label.split(' ').first}'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Turn a category off above to stop its reminders.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
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
