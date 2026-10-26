import 'package:flutter/material.dart';

class DashboardTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const DashboardTile({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
        child: SizedBox(
        height: 100,
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,size:40),
          Text(title),
          Text(description)
        ],
      ),
     ),
    );
  }
}
