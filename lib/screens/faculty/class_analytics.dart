import 'package:flutter/material.dart';

import '../../models/activity_item.dart';
import '../../models/student.dart';
import '../../services/app_services.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/connectivity_log_list.dart';
import '../../widgets/stat_card.dart';
import '../../config/lab_week.dart';

/// Faculty / Class Analytics: student stats, students by programme, API
/// summary, sync and connectivity log, app activity (Weeks 2, 4, 6, 7).
class ClassAnalytics extends StatelessWidget {
  const ClassAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Analytics'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([
            services.students,
            services.directory,
            services.sync,
            services.activity,
          ]),
          builder: (context, _) {
            final students = services.students;
            final directory = services.directory;
            final sync = services.sync;
            final byProgram = students.countByProgram;
            final top = students.topPerformer;
            int countOf(ActivityKind kind) =>
                services.activity.items.where((i) => i.kind == kind).length;

            // Week 1 allows a placeholder Analytics tab.
            if (!Feature.classStats.on &&
                !Feature.apiSummary.on &&
                !Feature.appActivity.on) {
              return const StateMessage(
                icon: Icons.insert_chart,
                title: 'Class Analytics',
                message: 'Class stats will appear here in a later lab week.',
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (Feature.classStats.on) ...[
                  StatGrid(
                    children: [
                      StatCard(
                        label: 'Total Students',
                        value: '${students.total}',
                      ),
                      StatCard(
                        label: 'Average Grade',
                        value: students.averageGrade.toStringAsFixed(1),
                      ),
                      StatCard(
                        label: 'Highest Grade',
                        value: top?.grade.toStringAsFixed(1) ?? '—',
                        note: top?.name,
                      ),
                      StatCard(
                        label: 'Online Users',
                        value: '${directory.users.length}',
                      ),
                    ],
                  ),
                  const SectionHeader('Students by program'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          for (final p in Student.programs)
                            _ProgramBar(
                              label: p,
                              count: byProgram[p] ?? 0,
                              total: students.total,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (Feature.apiSummary.on) ...[
                  const SectionHeader('API summary'),
                  StatGrid(
                    children: [
                      StatCard(
                        label: 'Total Users',
                        value: '${directory.users.length}',
                      ),
                      StatCard(
                        label: 'Total Companies',
                        value: '${directory.totalCompanies}',
                      ),
                      StatCard(
                        label: 'Total Emails',
                        value: '${directory.totalEmails}',
                      ),
                      StatCard(
                        label: 'Contact Numbers',
                        value: '${directory.totalPhones}',
                      ),
                    ],
                  ),
                ],
                if (Feature.offlineSync.on) ...[
                  const SectionHeader('Sync'),
                  StatGrid(
                    children: [
                      StatCard(
                        label: 'Pending records',
                        value: '${sync.pendingCount}',
                      ),
                      StatCard(
                        label: 'Completed syncs',
                        value: '${sync.completedSyncs}',
                      ),
                      StatCard(
                        label: 'Total records',
                        value: '${sync.totalCount}',
                      ),
                      StatCard(
                        label: 'Last sync',
                        value: formatLastSync(sync.lastSync),
                      ),
                    ],
                  ),
                ],
                if (Feature.connectivityLog.on) ...[
                  const SectionHeader('Connectivity log'),
                  ConnectivityLogList(sync: sync),
                ],
                if (Feature.appActivity.on) ...[
                  const SectionHeader('App activity'),
                  StatGrid(
                    children: [
                      StatCard(
                        label: 'Sign-ins',
                        value: '${countOf(ActivityKind.signIn)}',
                      ),
                      if (Feature.studentRecords.on)
                        StatCard(
                          label: 'Record changes',
                          value: '${countOf(ActivityKind.record)}',
                        ),
                      if (Feature.fileExport.on)
                        StatCard(
                          label: 'Exports',
                          value: '${countOf(ActivityKind.export)}',
                        ),
                      if (Feature.campusTour.on)
                        StatCard(
                          label: 'Campus visits',
                          value: '${countOf(ActivityKind.visit)}',
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProgramBar extends StatelessWidget {
  const _ProgramBar({
    required this.label,
    required this.count,
    required this.total,
  });

  final String label;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : count / total,
                minHeight: 10,
                color: AppColors.brand,
                backgroundColor: AppColors.border,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text('$count', textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
