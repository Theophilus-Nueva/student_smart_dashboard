import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../theme/app_colors.dart';

/// LPU ID card from the Home frames: logo, photo, ID number, role band,
/// name band. The photo is a placeholder until the camera step.
class IdCard extends StatelessWidget {
  const IdCard({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 150,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/images.png',
                    width: 36,
                    height: 30,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'LPU',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 96,
              width: double.infinity,
              color: const Color(0xFFDCE3D9),
              alignment: Alignment.center,
              child: Container(
                width: 64,
                height: 76,
                color: const Color(0xFFB0BEC5),
                child: const Icon(Icons.person, size: 52, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                user.idNumber,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: const Color(0xFFD9CCF0),
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                user.role.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(height: 3, color: AppColors.badge),
            Container(
              width: double.infinity,
              color: AppColors.brand,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Text(
                user.displayName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
