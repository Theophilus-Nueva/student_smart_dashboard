import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../routes/app_routes.dart';
import '../services/app_services.dart';
import '../services/app_settings.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';
import 'common.dart';
import 'list_row.dart';
import '../config/lab_week.dart';

/// Account row at the top of Settings with the role pill.
class AccountHeaderCard extends StatelessWidget {
  const AccountHeaderCard({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.field,
              foregroundImage: user.photoAsset == null
                  ? null
                  : AssetImage(user.photoAsset!),
              child: const Icon(Icons.person, size: 28, color: AppColors.muted),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    user.isFaculty ? user.subtitle : user.idNumber,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Security Center (Week 6): biometric toggles, last login, access status,
/// and the logged-in device row.
class SecurityCenterSection extends StatelessWidget {
  const SecurityCenterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final settings = services.settings;
    final session = services.session;
    final user = session.user!;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final signedIn = session.signedInAt;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader('Security Center'),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Column(
                  children: [
                    ToggleRow(
                      title: 'Fingerprint Login',
                      subtitle: 'Required when you open the app',
                      value: settings.get(AppSettings.fingerprintLogin),
                      onChanged: (v) =>
                          settings.set(AppSettings.fingerprintLogin, v),
                    ),
                    ToggleRow(
                      title: 'Face Authentication',
                      subtitle: 'Use face unlock instead of fingerprint',
                      value: settings.get(AppSettings.faceAuth),
                      onChanged: (v) => settings.set(AppSettings.faceAuth, v),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        children: [
                          DetailLine(
                            label: 'Last login',
                            value: signedIn == null
                                ? '—'
                                : formatWhen(signedIn).replaceFirst(' ·', ','),
                          ),
                          DetailLine(
                            label: 'Access status',
                            value: 'Granted · ${user.role.label}',
                            valueColor: AppColors.online,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            ListRow(
              icon: Icons.smartphone,
              title: sampleDeviceName,
              subtitle: sampleDeviceDetail,
              onTap: () => showAppSnack(
                context,
                'This is the only device signed in to your account.',
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Week 6 notification categories.
class NotificationTogglesSection extends StatelessWidget {
  const NotificationTogglesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Notifications'),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Column(
                children: [
                  ToggleRow(
                    title: 'Study Reminders',
                    subtitle: 'Daily at 7:00 PM',
                    value: settings.get(AppSettings.studyReminders),
                    onChanged: (v) =>
                        settings.set(AppSettings.studyReminders, v),
                  ),
                  ToggleRow(
                    title: 'Assignment Reminders',
                    subtitle: 'Day before each due date',
                    value: settings.get(AppSettings.assignmentReminders),
                    onChanged: (v) =>
                        settings.set(AppSettings.assignmentReminders, v),
                  ),
                  ToggleRow(
                    title: 'Daily Check-In',
                    subtitle: 'Remind me to record a campus visit',
                    value: settings.get(AppSettings.dailyCheckIn),
                    onChanged: (v) => settings.set(AppSettings.dailyCheckIn, v),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// About LPU row and the Log out button.
class SettingsFooter extends StatelessWidget {
  const SettingsFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).session;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (Feature.aboutLpu.on) ...[
          const SizedBox(height: 12),
          ListRow(
            icon: Icons.info,
            title: 'About LPU',
            subtitle: 'Mission, vision and core values',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.about),
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.brand,
            side: const BorderSide(color: AppColors.brand),
          ),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            session.signOut();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
