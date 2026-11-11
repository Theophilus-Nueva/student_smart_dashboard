import 'package:flutter/material.dart';

import '../../config/feature_flags.dart';
import '../../config/lab_week.dart';

import '../../routes/app_routes.dart';
import '../../services/app_services.dart';
import '../../utils/format.dart';
import '../../widgets/action_tile.dart';
import '../../widgets/common.dart';
import '../../widgets/current_location_card.dart';
import '../../widgets/id_card.dart';
import '../../widgets/kpi_grid.dart';
import '../../widgets/pull_to_sync.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/tour_progress_card.dart';
import '../../widgets/world_clock.dart';
import '../shared/dashboard_tiles.dart';
import '../shared/home_scaffold.dart';
import 'faculty_actions.dart';

/// Faculty / Home: sync status (pull down to sync), class stats, management
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

    final hasActions = const [
      Feature.dashboardTiles,
      Feature.studentRecords,
      Feature.registrationForm,
      Feature.apiDirectory,
      Feature.campusTour,
      Feature.cloudTasks,
      Feature.emergencyContacts,
      Feature.facultyDirectory,
    ].any((f) => f.on);

    final list = ListView(
      key: const Key('home.dashboard'),
      // Extra bottom space so the AR Guide button never covers content.
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        HomeScaffold.showsArButton ? 88 : 16,
      ),
      children: [
        if (Feature.syncStatus.on) ...[
          const _SyncStatusCard(),
          const SizedBox(height: 12),
        ],
        if (Feature.location.on) ...[
          const CurrentLocationCard(),
          const SizedBox(height: 16),
        ],
        IdCard(user: user),
        if (Feature.kpiCards.on) ...[
          const SectionHeader('Status'),
          const KpiGrid(),
        ],
        if (Feature.classStats.on) ...[
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
        ],
        if (hasActions) ...[
          const SectionHeader('Quick Actions'),
          ActionGrid(
            children: [
              if (Feature.dashboardTiles.on) ...dashboardTiles(context),
              if (Feature.studentRecords.on)
                ActionTile(
                  icon: Icons.people,
                  label: 'Student Records',
                  onTap: () => open(AppRoutes.studentRecords),
                ),
              // Week 3 only: open the registration form directly (Week 4
              // reaches it through Student Records instead).
              if (Feature.registrationForm.on && !Feature.studentRecords.on)
                ActionTile(
                  icon: Icons.person_add,
                  label: 'Add Student',
                  onTap: () => open(AppRoutes.studentForm),
                ),
              if (Feature.apiDirectory.on)
                ActionTile(
                  icon: Icons.cloud_done,
                  label: 'Online Directory',
                  onTap: () => open(AppRoutes.onlineDirectory),
                ),
              if (Feature.campusTour.on)
                ActionTile(
                  icon: Icons.flag,
                  label: 'Campus Tour',
                  onTap: () => open(AppRoutes.campusTour),
                ),
              if (Feature.cloudTasks.on)
                ActionTile(
                  icon: Icons.assignment,
                  label: 'Cloud Tasks',
                  onTap: () => open(AppRoutes.cloudTasks),
                ),
              if (Feature.emergencyContacts.on)
                ActionTile(
                  icon: Icons.call,
                  label: 'Emergency Contacts',
                  onTap: () => open(AppRoutes.emergencyContacts),
                ),
              if (Feature.facultyDirectory.on)
                ActionTile(
                  icon: Icons.school,
                  label: 'Faculty Directory',
                  onTap: () => open(AppRoutes.facultyDirectory),
                ),
            ],
          ),
        ],
        // Hidden for now; see FeatureFlags.showHomeTourProgress.
        if (FeatureFlags.showHomeTourProgress && Feature.tourProgress.on) ...[
          const SizedBox(height: 12),
          TourProgressCard(tour: services.tour),
        ],
        const SectionHeader('World Clock'),
        const WorldClock(),
      ],
    );

    return HomeScaffold(
      // Pull down to refresh and sync (Week 4).
      dashboard: Feature.syncStatus.on
          ? PullToSync(onRefresh: () => refreshAndSync(context), child: list)
          : list,
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
                if (Feature.offlineSync.on) ...[
                  DetailLine(
                    label: 'Pending records',
                    value: '${sync.pendingCount}',
                  ),
                  DetailLine(
                    label: 'Completed syncs',
                    value: '${sync.completedSyncs}',
                  ),
                  DetailLine(
                    label: 'Total records',
                    value: '${sync.totalCount}',
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
