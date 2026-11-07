import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/list_row.dart';

/// Shared / Emergency Contacts (Week 6). Opening the dialer, SMS or email
/// app needs `url_launcher`; until it is added each contact shows its
/// details with a copy button.
class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  static const contacts = [
    (
      Icons.call,
      'Call Security',
      'Campus security office · +63 912 345 6789',
      'tel:+639123456789',
    ),
    (
      Icons.call,
      'Call Adviser',
      'Your class adviser · +63 912 345 6790',
      'tel:+639123456790',
    ),
    (
      Icons.email,
      'Email Support',
      'support@lpu.example',
      'mailto:support@lpu.example',
    ),
    (
      Icons.sms,
      'Send SOS SMS',
      'Texts your location to your emergency contacts',
      'sms:+639123456789',
    ),
  ];

  void _show(BuildContext context, String title, String uri) {
    final value = uri.substring(uri.indexOf(':') + 1);
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
              'Opening the dialer, SMS or email app is added with the '
              'url_launcher package.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Tapping a contact opens your phone's dialer, SMS or email app.",
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          for (final (icon, title, subtitle, uri) in contacts) ...[
            ListRow(
              icon: icon,
              iconColor: title == 'Send SOS SMS' ? AppColors.brand : null,
              title: title,
              subtitle: subtitle,
              onTap: () => _show(context, title, uri),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
