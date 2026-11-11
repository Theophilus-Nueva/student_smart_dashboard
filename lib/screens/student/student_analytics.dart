import 'package:flutter/material.dart';

import '../../services/app_services.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/connectivity_log_list.dart';
import '../../widgets/network_status.dart';
import '../../widgets/stat_card.dart';
import '../../config/lab_week.dart';

/// Student / Analytics: personal stats only (Weeks 6–7).
class StudentAnalytics extends StatelessWidget {
  const StudentAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final user = services.session.user!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        automaticallyImplyLeading: false,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          services.sync,
          services.tour,
          services.students,
          services.activity,
        ]),
        builder: (context, _) {
          final sync = services.sync;
          final tour = services.tour;
          final me = services.students.byId(user.idNumber);
          final pct = (tour.progress * 100).round();
          final logins = services.activity.items
              .where((i) => i.title == 'Signed in')
              .length;
          final cloudStatus = switch (sync.state) {
            NetworkState.online => 'Up to date',
            NetworkState.pending => '${sync.pendingCount} pending',
            NetworkState.offline => 'Offline',
          };
          final cards = [
            if (Feature.tourProgress.on)
              StatCard(
                label: 'Tour Progress',
                value:
                    '${tour.visitedCount} / ${tour.locations.length} · $pct%',
              ),
            if (Feature.grades.on)
              StatCard(
                label: 'Current Grade',
                value: me == null ? '—' : me.grade.toStringAsFixed(1),
                note: me?.program,
              ),
            if (Feature.offlineSync.on) ...[
              StatCard(
                label: 'Last sync',
                value: formatLastSync(sync.lastSync),
              ),
              StatCard(label: 'Pending records', value: '${sync.pendingCount}'),
              StatCard(label: 'Total records', value: '${sync.totalCount}'),
              StatCard(
                label: 'Cloud sync status',
                value: cloudStatus,
                valueColor: sync.state.color,
              ),
            ],
            if (Feature.campusTour.on)
              StatCard(
                label: 'Bookmarked places',
                value:
                    '${tour.locations.where((l) => tour.isBookmarked(l.id)).length}',
              ),
            if (Feature.appActivity.on)
              StatCard(label: 'Sign-ins logged', value: '$logins'),
          ];
          // Week 1 allows a placeholder Analytics tab; stats arrive with
          // later weeks.
          if (cards.isEmpty) {
            return const StateMessage(
              icon: Icons.insert_chart,
              title: 'Analytics',
              message: 'Your stats will appear here in a later lab week.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'These are your personal stats. Class analytics are '
                'available to faculty.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              StatGrid(children: cards),
              if (Feature.connectivityLog.on) ...[
                const SectionHeader('Connectivity log'),
                ConnectivityLogList(sync: sync),
              ],
            ],
          );
        },
      ),
    );
  }
}
