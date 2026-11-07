import 'package:flutter/material.dart';

import '../../models/activity_item.dart';
import '../../models/student.dart';
import '../../routes/app_routes.dart';
import '../../services/app_services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

/// Faculty-only record actions shared by Student Records and Student Details.

Future<bool> confirmDeleteStudent(BuildContext context, Student student) async {
  final services = AppScope.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete student?'),
      content: Text(
        '${student.name} (${student.id}) will be removed from Student Records.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.brand),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  await services.students.delete(student.id);
  await services.activity.add(
    ActivityKind.record,
    'Student deleted',
    '${student.name} · ${student.id}',
  );
  if (context.mounted) showAppSnack(context, '${student.name} deleted');
  return true;
}

Future<void> exportStudentRecord(BuildContext context, Student student) async {
  final services = AppScope.of(context);
  try {
    final result = await services.files.exportStudent(student);
    await services.activity.add(
      ActivityKind.export,
      'Record exported',
      '${student.name} · ${result.fileName}',
    );
    if (context.mounted) {
      await Navigator.of(context)
          .pushNamed(AppRoutes.fileSaved, arguments: result);
    }
  } on Exception catch (e) {
    if (context.mounted) {
      showAppSnack(context, 'Could not save the file: $e', error: true);
    }
  }
}

/// Sync Now (Weeks 4 and 7) with result feedback.
Future<void> runSyncNow(BuildContext context) async {
  final sync = AppScope.of(context).sync;
  await sync.checkConnection();
  final ok = await sync.syncNow();
  if (!context.mounted) return;
  showAppSnack(
    context,
    ok ? 'Sync successful' : 'Sync failed · you are offline',
    error: !ok,
  );
}
