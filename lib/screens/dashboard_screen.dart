import 'package:flutter/material.dart';
import '../widgets/profile_card.dart';
import '../widgets/dashboard_tile.dart';
import 'activity_feed.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          spacing: 8,
          children: [
            Text("Smart Dashboard"),
            ProfileCard(),
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
          Expanded(
            flex: 1,
            child: ActivityFeed(),
          ),
        ],
      ),
    );
  }
}