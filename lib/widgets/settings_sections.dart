import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../routes/app_routes.dart';
import '../services/app_services.dart';
import '../services/app_settings.dart';
import '../services/biometric_service.dart';
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
                    const BiometricLoginToggle(),
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

/// Security Center toggle for signing in with the phone's own biometric.
/// It asks the phone what it has (Face ID, Touch ID, fingerprint, face
/// unlock) and is named after it; greyed out if nothing is set up. Turning
/// it on asks for that biometric once, so the user knows it works.
class BiometricLoginToggle extends StatefulWidget {
  const BiometricLoginToggle({super.key});

  @override
  State<BiometricLoginToggle> createState() => _BiometricLoginToggleState();
}

class _BiometricLoginToggleState extends State<BiometricLoginToggle> {
  Future<BiometricKind>? _kind;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _kind ??= AppScope.of(context).biometric.detect();
  }

  Future<void> _change(BiometricKind kind, bool on) async {
    final services = AppScope.of(context);
    if (!on) {
      await services.settings.set(AppSettings.biometricLogin, false);
      return;
    }
    setState(() => _busy = true);
    final error = await services.session.confirmBiometric(kind);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      showAppSnack(context, error, error: true);
      return;
    }
    await services.settings.set(AppSettings.biometricLogin, true);
    if (mounted) {
      showAppSnack(context, '${kind.label} sign-in is on.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    return FutureBuilder<BiometricKind>(
      future: _kind,
      builder: (context, snapshot) {
        final kind = snapshot.data;
        if (kind == null) {
          return const ToggleRow(
            title: 'Biometric Login',
            subtitle: 'Checking this phone…',
            value: false,
            onChanged: null,
          );
        }
        if (!kind.available) {
          return const ToggleRow(
            key: Key('settings.biometric'),
            title: 'Biometric Login',
            subtitle:
                'No Face ID or fingerprint is set up on this phone. Set one '
                'up in your phone’s settings first.',
            value: false,
            onChanged: null,
          );
        }
        return ToggleRow(
          key: const Key('settings.biometric'),
          title: 'Sign in with ${kind.label}',
          subtitle: 'Use ${kind.label} instead of your password',
          value: settings.get(AppSettings.biometricLogin),
          onChanged: _busy ? null : (on) => _change(kind, on),
        );
      },
    );
  }
}
