import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/app_services.dart';
import '../../services/app_settings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/action_tile.dart';
import '../../widgets/common.dart';
import '../../widgets/current_location_card.dart';
import '../../widgets/id_card.dart';
import '../../widgets/tour_progress_card.dart';
import '../../widgets/world_clock.dart';
import '../shared/home_scaffold.dart';

/// Student / Home.
class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

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
          const CurrentLocationCard(),
          const SizedBox(height: 16),
          IdCard(user: user),
          const SizedBox(height: 8),
          Text(
            '${user.subtitle} · $sampleDeviceName',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SectionHeader('Quick Actions'),
          ActionGrid(
            children: [
              ActionTile(
                icon: Icons.person,
                label: 'My Record',
                onTap: () => open(AppRoutes.myRecord),
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
                icon: Icons.people,
                label: 'Faculty Directory',
                onTap: () => open(AppRoutes.facultyDirectory),
              ),
              ActionTile(
                icon: Icons.info,
                label: 'About LPU',
                onTap: () => open(AppRoutes.about),
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
