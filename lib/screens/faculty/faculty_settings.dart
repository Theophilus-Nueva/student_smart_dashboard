import 'package:flutter/material.dart';

import '../../models/activity_item.dart';
import '../../services/app_services.dart';
import '../../services/app_settings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/list_row.dart';
import '../../widgets/pull_to_sync.dart';
import '../../widgets/settings_sections.dart';
import 'faculty_actions.dart';

/// Faculty / Settings: security center, Data Management (refresh, sync,
/// auto-refresh, reset database), notifications, log out.
class FacultySettings extends StatelessWidget {
  const FacultySettings({super.key});

  Future<void> _refresh(BuildContext context) async {
    final ok = await AppScope.of(context).directory.refresh();
    if (context.mounted) {
      showAppSnack(
        context,
        ok ? 'Dashboard refreshed' : 'Refresh failed · API Error',
        error: !ok,
      );
    }
  }

  Future<void> _reset(BuildContext context) async {
    final services = AppScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset database?'),
        content: const Text(
          'Student Records go back to the sample list. Records you added or '
          'edited on this phone will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.brand),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await services.students.reset();
    await services.activity.add(
      ActivityKind.record,
      'Database reset',
      'Student Records restored to the sample list',
    );
    if (context.mounted) showAppSnack(context, 'Database reset');
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final settings = services.settings;
    final sync = services.sync;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: PullToSync(
        onRefresh: () => refreshAndSync(context),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AccountHeaderCard(user: services.session.user!),
            const SecurityCenterSection(),
            const SectionHeader('Data Management'),
            ListRow(
              icon: Icons.refresh,
              title: 'Refresh Dashboard',
              subtitle: 'Reload API users and recalculate stats',
              onTap: () => _refresh(context),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: ListenableBuilder(
                  listenable: Listenable.merge([settings, sync]),
                  builder: (context, _) => Column(
                    children: [
                      ToggleRow(
                        title: 'Auto-refresh',
                        subtitle:
                            'Reload the Online Directory every 15 seconds',
                        value: settings.get(AppSettings.autoRefresh),
                        onChanged: (v) =>
                            settings.set(AppSettings.autoRefresh, v),
                      ),
                      ToggleRow(
                        title: 'Auto-sync when online',
                        subtitle: 'Upload changes as soon as they are made',
                        value: sync.autoSync,
                        onChanged: sync.setAutoSync,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListRow(
              icon: Icons.delete_forever,
              iconColor: AppColors.brand,
              title: 'Reset Database',
              subtitle: 'Restore Student Records to the sample list',
              onTap: () => _reset(context),
            ),
            const NotificationTogglesSection(),
            const SettingsFooter(),
          ],
        ),
      ),
    );
  }
}
