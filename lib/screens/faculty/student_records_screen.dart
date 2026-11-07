import 'package:flutter/material.dart';

import '../../models/student.dart';
import '../../routes/app_routes.dart';
import '../../services/app_services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/grade_pill.dart';
import 'faculty_actions.dart';

/// Faculty / Student Records: search, programme filter, edit and delete (W4).
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
    return Scaffold(
      appBar: AppBar(title: const Text('Student Records')),
      body: ListenableBuilder(
        listenable: Listenable.merge([repo, _search]),
        builder: (context, _) {
          final results = repo.search(_search.text, program: _program);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const FacultyOnlyTag(),
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  hintText: 'Search by student ID or name',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
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
              const SizedBox(height: 12),
              Text(
                '${results.length} ${results.length == 1 ? 'student' : 'students'}'
                ' · sorted by name',
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
                _StudentCard(student: s),
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
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final s = student;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            Navigator.of(context)
                .pushNamed(AppRoutes.studentDetails, arguments: s.id),
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
                          '${s.id} · ${s.program} · ${s.yearLevel}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GradePill(grade: s.grade),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit ${s.name}',
                    icon: const Icon(Icons.edit, color: AppColors.muted),
                    onPressed: () =>
                        Navigator.of(context)
                            .pushNamed(AppRoutes.studentForm, arguments: s.id),
                  ),
                  IconButton(
                    tooltip: 'Delete ${s.name}',
                    icon: const Icon(Icons.delete, color: AppColors.brand),
                    onPressed: () => confirmDeleteStudent(context, s),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
