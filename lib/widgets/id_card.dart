import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../theme/app_colors.dart';
import '../theme/app_assets.dart';

/// "Nueva, Theophilus T." → "NUEVA, Theophilus T." (last name in caps,
/// as printed on LPU IDs). Names without a comma are left as they are.
String idCardName(String displayName) {
  final comma = displayName.indexOf(',');
  if (comma == -1) return displayName;
  return displayName.substring(0, comma).toUpperCase() +
      displayName.substring(comma);
}

/// LPU ID card from the Home frames: logo, portrait and ID number over the
/// campus photo, then the role band and name band.
class IdCard extends StatelessWidget {
  const IdCard({super.key, required this.user});

  final AppUser user;

  /// Size relative to the original 150 px Figma card.
  static const scale = 1.4;
  static const width = 150 * scale;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8 * scale),
          // No outline: a border would inset the photo and leave white
          // strips down the sides. The shadow marks the card's edge.
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header, portrait and ID number sit on the campus photo, which
            // fades up into white behind the logo.
            Stack(
              alignment: Alignment.topCenter,
              children: [
                // Spans the full card width so the photo reaches both edges.
                const SizedBox(width: double.infinity),
                Positioned.fill(
                  child: Image.asset(
                    AppAssets.campusPhoto,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, 0.2),
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white,
                          Colors.white,
                          Color(0xCCFFFFFF),
                          Color(0x00FFFFFF),
                        ],
                        stops: [0, 0.42, 0.56, 0.86],
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        6 * scale,
                        6 * scale,
                        6 * scale,
                        4 * scale,
                      ),
                      child: Image.asset(
                        AppAssets.idHeader,
                        height: 56 * scale,
                        fit: BoxFit.contain,
                        semanticLabel: 'Lyceum of the Philippines University',
                      ),
                    ),
                    Container(
                      width: 64 * scale,
                      height: 76 * scale,
                      color: const Color(0xFFB0BEC5),
                      child: user.photoAsset == null
                          ? const Icon(
                              Icons.person,
                              size: 52 * scale,
                              color: Colors.white,
                            )
                          : Image.asset(
                              user.photoAsset!,
                              fit: BoxFit.cover,
                              semanticLabel: 'Photo of ${user.displayName}',
                            ),
                    ),
                    if (user.idNumber.isEmpty)
                      const SizedBox(height: 6 * scale)
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4 * scale,
                        ),
                        child: Text(
                          user.idNumber,
                          style: const TextStyle(
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Container(
              width: double.infinity,
              color: const Color(0xFFD9CCF0),
              padding: const EdgeInsets.symmetric(vertical: 3 * scale),
              child: Text(
                user.role.label.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(height: 3 * scale, color: AppColors.badge),
            Container(
              width: double.infinity,
              color: AppColors.brand,
              padding: const EdgeInsets.symmetric(
                vertical: 4 * scale,
                horizontal: 4 * scale,
              ),
              child: Text(
                idCardName(user.displayName),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12 * scale,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
