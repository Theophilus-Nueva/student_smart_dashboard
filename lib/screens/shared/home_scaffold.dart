import 'package:flutter/material.dart';

import '../../config/feature_flags.dart';

import '../../routes/app_routes.dart';
import '../../services/app_services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/home_app_bar.dart';
import 'recent_activity_view.dart';
import '../../config/lab_week.dart';

/// Home frame shared by both roles: header, Dashboard / Recent Activity tabs.
/// Each role passes its own dashboard content.
class HomeScaffold extends StatelessWidget {
  const HomeScaffold({super.key, required this.dashboard});

  final Widget dashboard;

  /// AR Guide button: the user's switch and Week 7 must both allow it.
  static bool get showsArButton =>
      FeatureFlags.showArGuideButton && Feature.arGuide.on;

  @override
  Widget build(BuildContext context) {
    final activity = AppScope.of(context).activity;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        // Week 7 "Launch AR Guide" shortcut.
        // Hidden for now; see FeatureFlags.showArGuideButton.
        floatingActionButton: !showsArButton
            ? null
            : FloatingActionButton.extended(
                heroTag: 'ar-guide',
                tooltip: 'Launch AR Guide',
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.arGuide),
                icon: const Icon(Icons.view_in_ar),
                label: const Text('AR Guide'),
              ),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: ListenableBuilder(
            listenable: activity,
            builder: (context, _) => HomeAppBar(
              unread: activity.unreadCount,
              // The badge is Week 1; the Notifications screen is Week 6.
              onNotifications: Feature.notifications.on
                  ? () =>
                        Navigator.of(context).pushNamed(AppRoutes.notifications)
                  : null,
              onAbout: Feature.aboutLpu.on
                  ? () => Navigator.of(context).pushNamed(AppRoutes.about)
                  : null,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: Column(
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
      ),
    );
  }
}
