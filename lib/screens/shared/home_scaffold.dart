import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/app_services.dart';
import '../../widgets/home_app_bar.dart';
import 'recent_activity_view.dart';

/// Home frame shared by both roles: header, Dashboard / Recent Activity tabs.
/// Each role passes its own dashboard content.
class HomeScaffold extends StatelessWidget {
  const HomeScaffold({super.key, required this.dashboard});

  final Widget dashboard;

  @override
  Widget build(BuildContext context) {
    final activity = AppScope.of(context).activity;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: ListenableBuilder(
            listenable: activity,
            builder: (context, _) => HomeAppBar(
              unread: activity.unreadCount,
              onNotifications: () =>
                  Navigator.of(context).pushNamed(AppRoutes.notifications),
            ),
          ),
        ),
        body: Column(
          children: [
            const Material(
              color: Colors.white,
              child: TabBar(
                tabs: [
                  Tab(text: 'Dashboard'),
                  Tab(text: 'Recent Activity'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [dashboard, const RecentActivityView()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
