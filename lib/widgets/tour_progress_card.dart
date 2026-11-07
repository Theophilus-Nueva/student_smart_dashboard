import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../services/tour_service.dart';
import '../theme/app_colors.dart';

/// Campus Tour progress card (Week 7 "Locations Visited" + next stop).
class TourProgressCard extends StatelessWidget {
  const TourProgressCard({super.key, required this.tour});

  final TourService tour;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: tour,
      builder: (context, _) {
        final next = tour.nextStop;
        final total = tour.locations.length;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.campusTour),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flag, color: AppColors.brand, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Campus Tour',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${tour.visitedCount} / $total visited',
                        style: const TextStyle(color: AppColors.brand),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: tour.progress,
                      minHeight: 8,
                      color: AppColors.brand,
                      backgroundColor: AppColors.border,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    next == null
                        ? 'Tour complete · all $total locations visited'
                        : 'Next stop: ${next.title} · ${next.distanceMeters} m · '
                              'about ${next.walkMinutes} min walk',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
