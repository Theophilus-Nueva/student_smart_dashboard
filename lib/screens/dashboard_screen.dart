import 'package:flutter/material.dart';
import '../widgets/profile_card.dart';
import '../widgets/dashboard_tile.dart';
import '../widgets/notification_badge.dart';
import 'activity_feed.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        title: Column(
          spacing: 8,
          children: [
            Row(
              children: [
                Image.asset(
                    'assets/images/images.png',
                    fit: BoxFit.contain,
                    width: 48.0,
                    height: 48.0,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "LPU Smart Campus Dashboard",
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const NotificationBadge(count: 8),
              ],
            ),
            const ProfileCard(),
          ],
        ),
        toolbarHeight: 128,
      ),
      body: Column(
        children: [
          Expanded(
            flex: width > 600 ? 3 : 2,
            child: GridView.count(
              crossAxisCount: width > 600 ? 4 : 2,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              children: const [
                DashboardTile(title: "DEVICE", icon: Icons.devices_rounded),
                DashboardTile(title: "GPS", icon: Icons.gps_fixed_rounded),
                DashboardTile(title: "API", icon: Icons.api_rounded),
                DashboardTile(title: "STORAGE", icon: Icons.storage_rounded),
              ],
            ),
          ),
          const Expanded(
            flex: 1,
            child: ActivityFeed(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.red[900],
        unselectedItemColor: Colors.white,
        selectedItemColor: Colors.amber[300],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.amber),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: 'Device',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}