import 'package:flutter/material.dart';

import '../widgets/dashboard_tile.dart';

class DashboardBody extends StatelessWidget {
  const DashboardBody({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Expanded(
          flex: width > 600 ? 3 : 2,
          child: GridView.count(
            crossAxisCount: width > 600 ? 4 : 2,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            children: const [
              DashboardTile(
                title: "Students",
                icon: Icons.people,
                description: "Total: 10 000",
              ),
              DashboardTile(
                title: "Programs",
                icon: Icons.school,
                description: "Active: 50",
              ),
              DashboardTile(
                title: "Campus",
                icon: Icons.location_city,
                description: "1st Semester",
              ),
            ],
          ),
        ),
      ],
    );
  }
}
