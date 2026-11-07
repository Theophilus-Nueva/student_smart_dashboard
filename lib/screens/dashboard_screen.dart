import 'package:flutter/material.dart';

import '../widgets/app_bottom_nav.dart';
import '../widgets/home_app_bar.dart';
import 'dashboard_body.dart';

/// Interim shell (Step 1): new header and bottom nav around the existing
/// dashboard. Replaced by the role-aware shell in Step 2.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final label = AppBottomNav.items[_selectedIndex].$2;
    return Scaffold(
      appBar: const HomeAppBar(unread: 8),
      body: _selectedIndex == 0
          ? const DashboardBody()
          : Center(child: Text('$label (coming soon)')),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}
