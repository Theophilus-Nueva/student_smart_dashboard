import 'package:flutter/material.dart';

import '../../models/tour.dart';
import '../../routes/app_routes.dart';
import '../../services/app_services.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/sync_status_banner.dart';
import '../../widgets/tour_progress_card.dart';

enum _TourFilter { all, visited, notVisited, bookmarked }

/// Shared / Campus Tour (Week 7): status, search, filters, progress,
/// six locations and visit history.
class CampusTourScreen extends StatefulWidget {
  const CampusTourScreen({super.key});

  @override
  State<CampusTourScreen> createState() => _CampusTourScreenState();
}

class _CampusTourScreenState extends State<CampusTourScreen> {
  final _search = TextEditingController();
  _TourFilter _filter = _TourFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final tour = services.tour;
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Tour')),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([tour, _search]),
          builder: (context, _) {
            final q = _search.text.trim().toLowerCase();
            final locations = tour.locations.where((l) {
              final matches =
                  q.isEmpty ||
                  l.title.toLowerCase().contains(q) ||
                  l.subtitle.toLowerCase().contains(q);
              final passes = switch (_filter) {
                _TourFilter.all => true,
                _TourFilter.visited => tour.isVisited(l.id),
                _TourFilter.notVisited => !tour.isVisited(l.id),
                _TourFilter.bookmarked => tour.isBookmarked(l.id),
              };
              return matches && passes;
            }).toList();
            final history = tour.visits.take(10).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SyncStatusBanner(sync: services.sync),
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Search locations',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (f, label) in const [
                      (_TourFilter.all, 'All'),
                      (_TourFilter.visited, 'Visited'),
                      (_TourFilter.notVisited, 'Not visited'),
                      (_TourFilter.bookmarked, 'Bookmarks'),
                    ])
                      PillChip(
                        label: label,
                        selected: _filter == f,
                        onTap: () => setState(() => _filter = f),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TourProgressCard(tour: tour),
                const SectionHeader('Campus Locations'),
                OutlinedButton.icon(
                  key: const Key('tour.addLocation'),
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.addLocation),
                  icon: const Icon(Icons.add_location_alt),
                  label: const Text('Add Location'),
                ),
                const SizedBox(height: 10),
                if (locations.isEmpty)
                  const StateMessage(
                    icon: Icons.location_off,
                    title: 'No locations match',
                  ),
                for (final l in locations) ...[
                  _LocationRow(location: l),
                  const SizedBox(height: 8),
                ],
                const SectionHeader('Visit History'),
                if (history.isEmpty)
                  const Text(
                    'No visits yet. Open a location and tap Record Visit.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                for (final v in history)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          v.synced ? Icons.cloud_done : Icons.cloud_upload,
                          size: 18,
                          color: v.synced
                              ? AppColors.online
                              : AppColors.pending,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${tour.byId(v.locationId)?.title ?? v.locationId}'
                            ' · ${formatWhen(v.time)}',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.location});

  final TourLocation location;

  @override
  Widget build(BuildContext context) {
    final tour = AppScope.of(context).tour;
    final visited = tour.isVisited(location.id);
    final bookmarked = tour.isBookmarked(location.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            Navigator.of(context)
                .pushNamed(AppRoutes.locationDetail, arguments: location.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
          child: Row(
            children: [
              Icon(
                visited ? Icons.check_circle : Icons.circle_outlined,
                color: visited ? AppColors.online : AppColors.muted,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      location.addedByUser
                          ? '${location.subtitle} · '
                                '${location.synced ? 'Added' : 'Pending upload'}'
                          : '${location.subtitle} · '
                                '${location.distanceMeters} m',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: bookmarked
                    ? 'Remove bookmark for ${location.title}'
                    : 'Bookmark ${location.title}',
                onPressed: () => tour.toggleBookmark(location.id),
                icon: Icon(
                  bookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: bookmarked ? AppColors.brand : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
