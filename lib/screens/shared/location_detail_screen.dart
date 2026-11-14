import 'package:flutter/material.dart';

import '../../models/activity_item.dart';
import '../../routes/app_routes.dart';
import '../../services/app_services.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

/// Shared / Location Detail (Week 7): hours, distance, Record Visit,
/// bookmark, open in map, visits.
class LocationDetailScreen extends StatelessWidget {
  const LocationDetailScreen({super.key, required this.locationId});

  final String locationId;

  Future<void> _recordVisit(BuildContext context) async {
    final services = AppScope.of(context);
    final location = services.tour.byId(locationId)!;
    await services.tour.recordVisit(locationId);
    await services.activity.add(
      ActivityKind.visit,
      'Visited ${location.title}',
      services.sync.online
          ? 'Campus tour · ${services.tour.visitedCount} / '
                '${services.tour.locations.length}'
          : 'Saved offline · uploads when you are back online',
    );
    if (context.mounted) showAppSnack(context, 'Visit recorded');
  }

  @override
  Widget build(BuildContext context) {
    final tour = AppScope.of(context).tour;
    final location = tour.byId(locationId);
    if (location == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Location')),
        body: SafeArea(
          top: false,
          bottom: false,
          child: const StateMessage(
            icon: Icons.location_off,
            title: 'Location not found',
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(location.title)),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListenableBuilder(
          listenable: tour,
          builder: (context, _) {
            final visits = tour.visitsFor(locationId);
            final bookmarked = tour.isBookmarked(locationId);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.field,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.apartment,
                    size: 64,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  location.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  location.subtitle,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                Text(location.description),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        DetailLine(label: 'Hours', value: location.hours),
                        DetailLine(
                          label: 'Distance',
                          value:
                              '${location.distanceMeters} m from you · about '
                              '${location.walkMinutes} min walk',
                        ),
                        DetailLine(
                          label: 'Status',
                          value: visits.isEmpty
                              ? 'Not visited yet'
                              : 'Visited ${formatWhen(visits.first.time).toLowerCase()}',
                          valueColor: visits.isEmpty ? null : AppColors.online,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => _recordVisit(context),
                  icon: const Icon(Icons.flag),
                  label: const Text('Record Visit'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => tour.toggleBookmark(locationId),
                        icon: Icon(
                          bookmarked ? Icons.bookmark : Icons.bookmark_border,
                        ),
                        label: Text(bookmarked ? 'Bookmarked' : 'Bookmark'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.of(context).pushNamed(AppRoutes.map),
                        icon: const Icon(Icons.map),
                        label: const Text('Open in Map'),
                      ),
                    ),
                  ],
                ),
                const SectionHeader('Visits'),
                if (visits.isEmpty)
                  const Text(
                    'No visits recorded here yet.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                for (final v in visits)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text(formatWhen(v.time))),
                        Text(
                          v.synced ? 'Synced' : 'Pending upload',
                          style: TextStyle(
                            fontSize: 12,
                            color: v.synced
                                ? AppColors.online
                                : AppColors.pending,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Visits are saved on your phone first and upload '
                  'automatically when you are back online.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
