import 'package:flutter/material.dart';

import '../../services/file_export_service.dart';
import '../../theme/app_colors.dart';

/// Shared / File Saved: confirmation and preview of `student_info.txt`.
class FileSavedScreen extends StatelessWidget {
  const FileSavedScreen({super.key, required this.result});

  final ExportResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Saved')),
      body: ListView(
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
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
