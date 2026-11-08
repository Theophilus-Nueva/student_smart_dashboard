import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../services/app_services.dart';
import '../theme/app_colors.dart';
import 'common.dart';

/// Week 6 Current Location card with coordinates and an Open Map button.
/// Shows "Live" for GPS readings and "Campus" with the reason otherwise.
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.brand,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Current Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.circle, size: 8, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      fix.live ? 'Live' : 'Campus',
                      style: TextStyle(fontSize: 12, color: statusColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(fix.address, style: const TextStyle(fontSize: 13)),
                if (fix.problem != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${fix.problem} · showing the campus location',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.pending,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InfoField(
                        label: 'Latitude',
                        value: fix.latitude.toStringAsFixed(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InfoField(
                        label: 'Longitude',
                        value: fix.longitude.toStringAsFixed(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InfoField(
                        label: 'Accuracy',
                        value: '±${fix.accuracyMeters.round()} m',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InfoField(
                        label: 'Speed',
                        value: '${fix.speedKmh.round()} km/h',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InfoField(
                        label: 'Altitude',
                        value: '${fix.altitudeMeters.round()} m',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.map),
                  icon: const Icon(Icons.map),
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
