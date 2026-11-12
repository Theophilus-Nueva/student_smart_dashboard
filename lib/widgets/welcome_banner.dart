import 'package:flutter/material.dart';

import '../models/app_user.dart';
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
