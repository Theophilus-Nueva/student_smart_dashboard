import 'package:flutter/material.dart';

import '../../config/feature_flags.dart';
import '../../config/lab_week.dart';
import '../../models/student.dart';
import '../../routes/app_routes.dart';
import '../../services/app_services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/pull_to_sync.dart';
import '../../widgets/grade_pill.dart';
import 'faculty_actions.dart';

/// Faculty / Student Records: search, programme filter, edit and delete (W4).
/// In Week 3 it is the Student Directory: the saved students and Add Student.
class StudentRecordsScreen extends StatefulWidget {
  const StudentRecordsScreen({super.key});

  @override
  State<StudentRecordsScreen> createState() => _StudentRecordsScreenState();
}

class _StudentRecordsScreenState extends State<StudentRecordsScreen> {
  final _search = TextEditingController();
  String? _program;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).students;
    // Week 4 adds search, filter, edit, delete, details and grades.
    final full = Feature.studentRecords.on;
    return Scaffold(
      appBar: AppBar(
        title: Text(full ? 'Student Records' : 'Student Directory'),
      ),
      body: PullToSync(
        enabled: Feature.syncStatus.on,
        onRefresh: () => refreshAndSync(context),
        child: ListenableBuilder(
          listenable: Listenable.merge([repo, _search]),
          builder: (context, _) {
            final results = repo.search(_search.text, program: _program);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (full)
                  TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      hintText: 'Search by student ID or name',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                // Hidden for now; see FeatureFlags.showRecordsProgramFilter.
                if (full && FeatureFlags.showRecordsProgramFilter) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PillChip(
                        label: 'All Students',
                        selected: _program == null,
                        onTap: () => setState(() => _program = null),
                      ),
                      for (final p in Student.programs)
                        PillChip(
                          label: p,
                          selected: _program == p,
                          onTap: () => setState(() => _program = p),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  '${results.length} ${results.length == 1 ? 'student' : 'students'}'
                  '${full ? ' · sorted by name' : ''}',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                if (results.isEmpty)
                  StateMessage(
                    icon: Icons.person_search,
                    title: repo.total == 0 ? 'No students yet' : 'No matches',
                    message: repo.total == 0
                        ? 'Add a student to get started.'
                        : 'Try another name, ID or programme.',
                  ),
                for (final s in results) ...[
                  _StudentCard(student: s, full: full),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 4),
                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.studentForm),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Student'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student, required this.full});

  final Student student;

  /// Week 4: tap for details, edit, delete and the grade pill.
  final bool full;

  @override
  Widget build(BuildContext context) {
    final s = student;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: full
            ? () =>
                  Navigator.of(context)
                      .pushNamed(AppRoutes.studentDetails, arguments: s.id)
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.person),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          [
                            s.id,
                            s.program,
                            // Hidden for now; see FeatureFlags.showRecordsYearLevel.
                            if (FeatureFlags.showRecordsYearLevel) s.yearLevel,
                          ].join(' · '),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (Feature.grades.on)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GradePill(grade: s.grade),
                    ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    // Hidden for now; see FeatureFlags.showRecordsEmail.
                    child: FeatureFlags.showRecordsEmail
                        ? Text(
                            s.email,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (full) ...[
                    IconButton(
                      tooltip: 'Edit ${s.name}',
                      icon: const Icon(Icons.edit, color: AppColors.muted),
                      onPressed: () => Navigator.of(context)
                          .pushNamed(AppRoutes.studentForm, arguments: s.id),
                    ),
                    IconButton(
                      tooltip: 'Delete ${s.name}',
                      icon: const Icon(Icons.delete, color: AppColors.brand),
                      onPressed: () => confirmDeleteStudent(context, s),
                    ),
                  ] else
                    const SizedBox(height: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
