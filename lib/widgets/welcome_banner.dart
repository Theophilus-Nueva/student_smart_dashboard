import 'package:flutter/material.dart';

import '../config/lab_week.dart';
import '../models/app_user.dart';
import '../routes/app_routes.dart';
import '../screens/shared/placeholder_screen.dart';
import '../theme/app_colors.dart';

/// "Nueva, Theophilus T." → "Theophilus"; names without a comma give their
/// first word.
String firstName(String displayName) {
  final comma = displayName.indexOf(',');
  final given = (comma == -1 ? displayName : displayName.substring(comma + 1))
      .trim();
  return given.split(' ').first;
}

/// Week 1 Challenge 1: welcome banner with the user's name, programme (or
/// department for faculty) and LPU Cavite.
class WelcomeBanner extends StatelessWidget {
  const WelcomeBanner({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${firstName(user.displayName)}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          if (user.subtitle.isNotEmpty)
            Text(
              user.subtitle,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          const Text(
            'Lyceum of the Philippines University Cavite',
            style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Week 1 Challenge 1 campus icons: Academics, Student Services, Campus
/// Announcements, Facilities. Facilities opens the campus map; the others
/// are placeholder pages until a later week fills them in.
class CampusIcons extends StatelessWidget {
  const CampusIcons({super.key});

  @override
  Widget build(BuildContext context) {
    void placeholder(String title) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaceholderScreen(
          title: title,
          message: 'Campus information will be added here.',
        ),
      ),
    );
    final items = [
      (Icons.menu_book, 'Academics', () => placeholder('Academics')),
      (
        Icons.support_agent,
        'Student Services',
        () => placeholder('Student Services'),
      ),
      (
        Icons.campaign,
        'Campus Announcements',
        () => Feature.notifications.on
            ? Navigator.of(context).pushNamed(AppRoutes.notifications)
            : placeholder('Campus Announcements'),
      ),
      (
        Icons.apartment,
        'Facilities',
        () => Navigator.of(context).pushNamed(AppRoutes.map),
      ),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (icon, label, onTap) in items)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Icon(icon, size: 28, color: Colors.black),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
