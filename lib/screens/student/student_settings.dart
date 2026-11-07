import 'package:flutter/material.dart';

import '../../services/app_services.dart';
import '../../widgets/common.dart';
import '../../widgets/settings_sections.dart';

/// Student / Settings: security center, device, notifications, auto-sync.
/// Students have no Sync Now, refresh or reset (faculty only).
class StudentSettings extends StatelessWidget {
  const StudentSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final sync = services.sync;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AccountHeaderCard(user: services.session.user!),
          const SecurityCenterSection(),
          const NotificationTogglesSection(),
          const SectionHeader('Sync'),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: ListenableBuilder(
                listenable: sync,
                builder: (context, _) => ToggleRow(
                  title: 'Auto-sync when online',
                  subtitle: 'Visits and tasks upload automatically',
                  value: sync.autoSync,
                  onChanged: sync.setAutoSync,
                ),
              ),
            ),
          ),
          const SettingsFooter(),
        ],
      ),
    );
  }
}
