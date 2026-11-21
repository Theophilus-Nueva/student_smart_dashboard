import 'package:flutter/cupertino.dart';
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
                  const StudyReminderRow(),
                  ToggleRow(
                    title: 'Assignment Reminders',
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

/// Study Reminders: on/off plus the time it arrives every day (Philippine
/// time). Changing either reschedules the phone's daily reminder.
class StudyReminderRow extends StatelessWidget {
  const StudyReminderRow({super.key});

  Future<void> _pickTime(BuildContext context) async {
    final services = AppScope.of(context);
    final (hour, minute) = services.settings.studyReminderTime;
    final picked = await pickTimeOfDay(
      context,
      initial: TimeOfDay(hour: hour, minute: minute),
      title: 'Study reminder time',
    );
    if (picked == null || !context.mounted) return;
    await services.settings.setStudyReminderTime(picked.hour, picked.minute);
    await services.syncStudyReminder(ask: true);
    if (context.mounted) {
      showAppSnack(
        context,
        'Study reminder set for ${picked.format(context)} every day.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    // Listens itself: as a const child it isn't rebuilt with its parent.
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final services = AppScope.of(context);
    final settings = services.settings;
    final on = settings.get(AppSettings.studyReminders);
    final (hour, minute) = settings.studyReminderTime;
    final time = TimeOfDay(hour: hour, minute: minute).format(context);
    return Column(
      children: [
        ToggleRow(
          title: 'Study Reminders',
          subtitle: on ? 'Daily at $time' : 'Off',
          value: on,
          onChanged: (v) async {
            await settings.set(AppSettings.studyReminders, v);
            await services.syncStudyReminder(ask: v);
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 4),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Reminder time (Philippine time)',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ),
              OutlinedButton.icon(
                key: const Key('settings.studyTime'),
                // The theme makes outlined buttons full width.
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                onPressed: on ? () => _pickTime(context) : null,
                icon: const Icon(Icons.schedule, size: 18),
                label: Text(time),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The phone's own style of time picker: the iOS wheel on iPhone (in a
/// bottom panel with Cancel / Done), the Material clock on Android.
Future<TimeOfDay?> pickTimeOfDay(
  BuildContext context, {
  required TimeOfDay initial,
  required String title,
}) {
  final platform = Theme.of(context).platform;
  if (platform != TargetPlatform.iOS && platform != TargetPlatform.macOS) {
    return showTimePicker(
      context: context,
      initialTime: initial,
      helpText: title,
    );
  }
  var chosen = initial;
  return showCupertinoModalPopup<TimeOfDay>(
    context: context,
    builder: (popup) => ColoredBox(
      color: CupertinoColors.systemBackground.resolveFrom(popup),
      // The popup sits outside the Material page, so text needs the iOS
      // style given explicitly (otherwise Flutter's big red fallback).
      child: DefaultTextStyle(
        style: CupertinoTheme.of(popup).textTheme.textStyle,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 260,
            child: Column(
              children: [
                // iOS toolbar: Cancel, title, Done.
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        onPressed: () => Navigator.pop(popup),
                        child: const Text('Cancel'),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      CupertinoButton(
                        key: const Key('timePicker.done'),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        onPressed: () => Navigator.pop(popup, chosen),
                        child: const Text(
                          'Done',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: DateTime(
                      2000,
                      1,
                      1,
                      initial.hour,
                      initial.minute,
                    ),
                    onDateTimeChanged: (t) =>
                        chosen = TimeOfDay(hour: t.hour, minute: t.minute),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
