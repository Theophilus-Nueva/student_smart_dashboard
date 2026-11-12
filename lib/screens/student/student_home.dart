import 'package:flutter/material.dart';

import '../../config/feature_flags.dart';

import '../../routes/app_routes.dart';
import '../../services/app_services.dart';
import '../../widgets/action_tile.dart';
import '../../widgets/common.dart';
import '../../widgets/current_location_card.dart';
import '../../widgets/id_card.dart';
import '../../widgets/info_cards.dart';
import '../../widgets/kpi_grid.dart';
import '../../widgets/programme_grid.dart';
import '../../widgets/tour_progress_card.dart';
import '../../widgets/welcome_banner.dart';
import '../../widgets/world_clock.dart';
import '../shared/dashboard_tiles.dart';
import '../shared/home_scaffold.dart';
import '../../config/lab_week.dart';

/// Student / Home.
class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final user = services.session.user!;
    void open(String route) => Navigator.of(context).pushNamed(route);
    final hasActions = const [
      Feature.dashboardTiles,
      Feature.myRecord,
      Feature.campusTour,
      Feature.cloudTasks,
      Feature.emergencyContacts,
      Feature.facultyDirectory,
    ].any((f) => f.on);

    return HomeScaffold(
      dashboard: ListView(
        key: const Key('home.dashboard'),
        // Extra bottom space so the AR Guide button never covers content.
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          HomeScaffold.showsArButton ? 88 : 16,
        ),
        children: [
          // ID card first, then the location card with Open Map.
          IdCard(user: user),
          if (Feature.campusWelcome.on) ...[
            const SizedBox(height: 16),
            WelcomeBanner(user: user),
          ],
          if (Feature.location.on) ...[
            const SizedBox(height: 16),
            const CurrentLocationCard(),
          ],
          if (Feature.kpiCards.on) ...[
            const SectionHeader('Status'),
            const KpiGrid(),
          ],
          if (Feature.infoCards.on) ...[
            const SectionHeader('Overview'),
            const InfoCards(),
          ],
          if (Feature.programmeCards.on) ...[
            const SectionHeader('CCS Programmes'),
            const ProgrammeGrid(),
          ],
          if (hasActions) ...[
            const SectionHeader('Quick Actions'),
            ActionGrid(
              children: [
                if (Feature.dashboardTiles.on) ...dashboardTiles(context),
                if (Feature.myRecord.on)
                  ActionTile(
                    icon: Icons.person,
                    label: 'My Record',
                    onTap: () => open(AppRoutes.myRecord),
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
                    icon: Icons.people,
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
      ),
    );
  }
}
