import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/app_services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/grade_pill.dart';
import 'faculty_actions.dart';

/// Faculty / Student Details: record fields with Edit, Export, Delete.
class StudentDetailsScreen extends StatelessWidget {
  const StudentDetailsScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).students;
    return Scaffold(
      appBar: AppBar(title: const Text('Student Details')),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          final s = repo.byId(studentId);
          if (s == null) {
            return const StateMessage(
              icon: Icons.person_off,
              title: 'Student not found',
              message: 'This record may have been deleted.',
            );
          }
          final top = repo.topPerformer?.id == s.id;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const FacultyOnlyTag(),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 32),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${s.id} · ${s.program} · ${s.yearLevel}',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      GradePill(grade: s.grade),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final (label, value) in [
                ('Email Address', s.email),
                ('Program', s.program),
                ('Year Level', s.yearLevel),
                (
                  'Grade',
                  '${s.grade.toStringAsFixed(1)}${top ? ' · Top performer' : ''}',
                ),
                ('Contact Number', s.contact.isEmpty ? '—' : s.contact),
                ('Address', s.address.isEmpty ? '—' : s.address),
                ('Sync', s.synced ? 'Synced' : 'Pending upload'),
              ]) ...[
                InfoField(label: label, value: value),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context)
                        .pushNamed(AppRoutes.studentForm, arguments: s.id),
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => exportStudentRecord(context, s),
                icon: const Icon(Icons.download),
                label: const Text('Export'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brand,
                  side: const BorderSide(color: AppColors.brand),
                ),
                onPressed: () async {
                  final deleted = await confirmDeleteStudent(context, s);
                  if (deleted && context.mounted) Navigator.of(context).pop();
                },
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
              ),
            ],
          );
        },
      ),
    );
  }
}
