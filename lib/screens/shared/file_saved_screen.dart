import 'package:flutter/material.dart';

import '../../services/app_services.dart';
import '../../services/file_export_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

/// Shared / File Saved: confirmation and preview of `student_info.txt`.
class FileSavedScreen extends StatelessWidget {
  const FileSavedScreen({
    super.key,
    required this.result,
    this.alsoSaved = const [],
  });

  final ExportResult result;

  /// Other files written in the same step (e.g. student_record.txt).
  final List<String> alsoSaved;

  Future<void> _share(BuildContext context) async {
    final services = AppScope.of(context);
    try {
      final shared = await services.files.share(
        result,
        origin: shareOrigin(context),
      );
      if (shared && context.mounted) {
        showAppSnack(context, '${result.fileName} shared');
      }
    } on Exception catch (e) {
      if (context.mounted) {
        showAppSnack(context, 'Could not share the file: $e', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Saved')),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 12),
            const Icon(Icons.check_circle, size: 64, color: AppColors.online),
            const SizedBox(height: 12),
            Text(
              '${result.fileName} saved',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              "Saved to the app's Documents folder on this device.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          result.fileName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    SelectableText(
                      result.content,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            SelectableText(
              result.path,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            if (alsoSaved.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Also saved: ${alsoSaved.join(', ')}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
            const SizedBox(height: 20),
            Builder(
              builder: (context) => OutlinedButton.icon(
                onPressed: () => _share(context),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
