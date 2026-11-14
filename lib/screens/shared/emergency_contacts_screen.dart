import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/activity_item.dart';
import '../../services/app_services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/list_row.dart';
import '../../config/lab_week.dart';

/// Shared / Emergency Contacts (Week 6): tel:, sms: and mailto: links via
/// `url_launcher`. Sample numbers from the Figma prototype.
class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  static const securityNumber = '+639123456789';
  static const adviserNumber = '+639123456790';
  static const supportEmail = 'support@lpu.example';

  Future<void> _open(BuildContext context, String title, Uri uri) async {
    final services = AppScope.of(context);
    var opened = false;
    try {
      opened = await launchUrl(uri);
    } on PlatformException {
      opened = false;
    }
    if (opened) {
      await services.activity.add(ActivityKind.device, title, uri.path);
      return;
    }
    if (!context.mounted) return;
    // No app can handle the link (e.g. an emulator without a dialer).
    final value = uri.path;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SelectableText(value, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            const Text(
              'No app on this device can open this contact.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: value));
                if (sheetContext.mounted) Navigator.pop(sheetContext);
                if (context.mounted) showAppSnack(context, 'Copied $value');
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sos(BuildContext context) async {
    final fix = await AppScope.of(context).location.current();
    if (!context.mounted) return;
    final body =
        'SOS from ${LabWeek.appName}. I need help. My location: '
        '${fix.latitude.toStringAsFixed(5)}, ${fix.longitude.toStringAsFixed(5)}'
        ' https://maps.google.com/?q=${fix.latitude},${fix.longitude}';
    await _open(
      context,
      'Send SOS SMS',
      Uri(scheme: 'sms', path: securityNumber, queryParameters: {'body': body}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Tapping a contact opens your phone's dialer, SMS or email app.",
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            ListRow(
              icon: Icons.call,
              title: 'Call Security',
              subtitle: 'Campus security office · +63 912 345 6789',
              onTap: () => _open(
                context,
                'Call Security',
                Uri(scheme: 'tel', path: securityNumber),
              ),
            ),
            const SizedBox(height: 10),
            ListRow(
              icon: Icons.call,
              title: 'Call Adviser',
              subtitle: 'Your class adviser · +63 912 345 6790',
              onTap: () => _open(
                context,
                'Call Adviser',
                Uri(scheme: 'tel', path: adviserNumber),
              ),
            ),
            const SizedBox(height: 10),
            ListRow(
              icon: Icons.email,
              title: 'Email Support',
              subtitle: supportEmail,
              onTap: () => _open(
                context,
                'Email Support',
                Uri(
                  scheme: 'mailto',
                  path: supportEmail,
                  query: 'subject=Smart%20Campus%20Tour%20Guide%20support',
                ),
              ),
            ),
            const SizedBox(height: 10),
            ListRow(
              icon: Icons.sms,
              iconColor: AppColors.brand,
              title: 'Send SOS SMS',
              subtitle: 'Texts your location to campus security',
              onTap: () => _sos(context),
            ),
          ],
        ),
      ),
    );
  }
}
