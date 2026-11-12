import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../services/app_services.dart';
import '../theme/app_colors.dart';

/// Week 6 Current Location card, kept short on Home: the place name, the
/// Live / Campus status and Open Map. Coordinates, accuracy, speed and
/// altitude are on the Map screen.
class CurrentLocationCard extends StatelessWidget {
  const CurrentLocationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tracker = AppScope.of(context).tracker;
    return ListenableBuilder(
      listenable: tracker,
      builder: (context, _) {
        final fix = tracker.fix;
        final statusColor = fix.live ? AppColors.online : AppColors.muted;
        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.brand),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fix.placeName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            fix.live ? 'Live' : 'Campus',
                            style: TextStyle(fontSize: 12, color: statusColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.map),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  iconAlignment: IconAlignment.end,
                  label: const Text('Open Map'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
