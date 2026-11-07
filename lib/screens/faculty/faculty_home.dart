import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/app_services.dart';
import '../../services/location_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/action_tile.dart';
import '../../widgets/common.dart';
import '../../widgets/current_location_card.dart';
import '../../widgets/id_card.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/sync_status_banner.dart';
import '../../widgets/tour_progress_card.dart';
import '../../widgets/world_clock.dart';
import '../shared/home_scaffold.dart';
import 'faculty_actions.dart';

/// Faculty / Home: sync status with Sync Now, class stats, management
/// shortcuts, plus the shared location / ID / tour / clock sections.
class FacultyHome extends StatefulWidget {
  const FacultyHome({super.key});

  @override
  State<FacultyHome> createState() => _FacultyHomeState();
}

class _FacultyHomeState extends State<FacultyHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final directory = AppScope.of(context).directory;
      if (directory.lastUpdated == null) directory.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final user = services.session.user!;
    void open(String route) => Navigator.of(context).pushNamed(route);

    return HomeScaffold(
      dashboard: ListView(
        key: const Key('home.dashboard'),
        padding: const EdgeInsets.all(16),
        children: [
          SyncStatusBanner(sync: services.sync),
          const SizedBox(height: 12),
          const _SyncStatusCard(),
          const SizedBox(height: 12),
          const CurrentLocationCard(fix: LocationService.campus),
          const SizedBox(height: 16),
          IdCard(user: user),
          const SectionHeader('Class Overview'),
          ListenableBuilder(
            listenable: Listenable.merge([
              services.students,
              services.directory,
            ]),
            builder: (context, _) {
              final students = services.students;
              final top = students.topPerformer;
              return StatGrid(
                children: [
                  StatCard(label: 'Total Students', value: '${students.total}'),
                  StatCard(
                    label: 'Average Grade',
                    value: students.averageGrade.toStringAsFixed(1),
                  ),
                  StatCard(
                    label: 'Top Performer',
                    value: top?.grade.toStringAsFixed(1) ?? '—',
                    note: top?.name,
                  ),
                  StatCard(
                    label: 'Online Users',
                    value: '${services.directory.users.length}',
                    note: 'from the API',
                  ),
                ],
              );
            },
          ),
          const SectionHeader('Quick Actions'),
          ActionGrid(
            children: [
              ActionTile(
                icon: Icons.people,
                label: 'Student Records',
                onTap: () => open(AppRoutes.studentRecords),
              ),
              ActionTile(
                icon: Icons.cloud_done,
                label: 'Online Directory',
                onTap: () => open(AppRoutes.onlineDirectory),
              ),
              ActionTile(
                icon: Icons.flag,
                label: 'Campus Tour',
                onTap: () => open(AppRoutes.campusTour),
              ),
              ActionTile(
                icon: Icons.assignment,
                label: 'Cloud Tasks',
                onTap: () => open(AppRoutes.cloudTasks),
              ),
              ActionTile(
                icon: Icons.call,
                label: 'Emergency Contacts',
                onTap: () => open(AppRoutes.emergencyContacts),
              ),
              ActionTile(
                icon: Icons.school,
                label: 'Faculty Directory',
                onTap: () => open(AppRoutes.facultyDirectory),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TourProgressCard(tour: services.tour),
          const SectionHeader('World Clock'),
          const WorldClock(),
        ],
      ),
    );
  }
}

/// Week 4 Sync Status card + Week 7 queue counts, with SYNC NOW.
class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard();

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final sync = services.sync;
    return ListenableBuilder(
      listenable: Listenable.merge([sync, services.directory]),
      builder: (context, _) {
        final updated = services.directory.lastUpdated;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sync, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Sync Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'Faculty only',
                      style: TextStyle(fontSize: 12, color: AppColors.brand),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                DetailLine(
                  label: 'Last updated',
                  value: updated == null ? '—' : formatTime(updated),
                ),
                DetailLine(
                  label: 'Users retrieved (API)',
                  value: '${services.directory.users.length}',
                ),
                DetailLine(
                  label: 'Pending records',
                  value: '${sync.pendingCount}',
                ),
                DetailLine(
                  label: 'Completed syncs',
                  value: '${sync.completedSyncs}',
                ),
                DetailLine(label: 'Total records', value: '${sync.totalCount}'),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: sync.syncing ? null : () => runSyncNow(context),
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync Now'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
