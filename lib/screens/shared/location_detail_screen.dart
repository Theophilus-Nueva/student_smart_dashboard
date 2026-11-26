import 'package:flutter/material.dart';

import '../../models/activity_item.dart';
import '../../routes/app_routes.dart';
import '../../services/app_services.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/location_photo.dart';

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

  Future<void> _confirmDelete(BuildContext context, String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete location?'),
        content: Text('$title and its visits will be removed from the tour.'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.brand,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final tour = AppScope.of(context).tour;
    Navigator.of(context).pop();
    await tour.deleteLocation(locationId);
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
                LocationPhoto(
                  location: location,
                  height: 180,
                  width: double.infinity,
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
                        if (location.hours.isNotEmpty)
                          DetailLine(label: 'Hours', value: location.hours),
                        if (location.hasDistance)
                          DetailLine(
                            label: 'Distance',
                            value:
                                '${location.distanceMeters} m from you · about '
                                '${location.walkMinutes} min walk',
                          ),
                        if (location.addedByUser)
                          DetailLine(
                            label: 'Upload',
                            value: location.synced
                                ? 'Synced'
                                : 'Pending upload',
                            valueColor: location.synced
                                ? AppColors.online
                                : AppColors.pending,
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
                if (location.addedByUser) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brand,
                    ),
                    onPressed: () => _confirmDelete(context, location.title),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete Location'),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
