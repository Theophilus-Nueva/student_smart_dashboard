import 'package:flutter/material.dart';

import '../../models/activity_item.dart';
import '../../routes/app_routes.dart';
import '../../services/app_services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

/// Student / My Record: the signed-in student's own record, read-only,
/// with export to `student_info.txt` (Weeks 3–4).
class MyRecordScreen extends StatefulWidget {
  const MyRecordScreen({super.key});

  @override
  State<MyRecordScreen> createState() => _MyRecordScreenState();
}

class _MyRecordScreenState extends State<MyRecordScreen> {
  bool _exporting = false;

  Future<void> _export() async {
    final services = AppScope.of(context);
    final student = services.students.byId(services.session.user!.idNumber);
    if (student == null) return;
    setState(() => _exporting = true);
    try {
      final result = await services.files.exportStudent(student);
      await services.activity.add(
        ActivityKind.export,
        'Record exported',
        result.fileName,
      );
      if (!mounted) return;
      await Navigator.of(context)
          .pushNamed(AppRoutes.fileSaved, arguments: result);
    } on Exception catch (e) {
      if (mounted) {
        showAppSnack(context, 'Could not save the file: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final id = services.session.user!.idNumber;
    return Scaffold(
      appBar: AppBar(title: const Text('My Record')),
      body: ListenableBuilder(
        listenable: services.students,
        builder: (context, _) {
          final s = services.students.byId(id);
          if (s == null) {
            return const StateMessage(
              icon: Icons.person_off,
              title: 'No record found',
              message:
                  'Your student record is not on this device yet. '
                  'Ask your adviser to add it.',
            );
          }
          final fields = [
            ('Student Name', s.name),
            ('Student ID', s.id),
            ('Email Address', s.email),
            ('Program', s.program),
            ('Year Level', s.yearLevel),
            ('Current Grade', s.grade.toStringAsFixed(1)),
            ('Contact Number', s.contact.isEmpty ? '—' : s.contact),
            ('Address', s.address.isEmpty ? '—' : s.address),
          ];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.field,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, size: 18, color: AppColors.muted),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your record is read-only. Ask your adviser to update '
                        'any details.',
                        style: TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final (label, value) in fields) ...[
                InfoField(label: label, value: value),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _exporting ? null : _export,
                icon: const Icon(Icons.download),
                label: const Text('Export to student_info.txt'),
              ),
            ],
          );
        },
      ),
    );
  }
}
