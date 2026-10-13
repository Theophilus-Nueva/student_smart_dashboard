import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ActivityFeed extends StatefulWidget {
  const ActivityFeed({super.key});

  @override
  State<ActivityFeed> createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initTimeZones();
  }

  void _initTimeZones() {
    tz.initializeTimeZones();
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final manilaLoc = tz.getLocation('Asia/Manila');
    final tokyoLoc = tz.getLocation('Asia/Tokyo');
    final newYorkLoc = tz.getLocation('America/New_York');

    final manilaTime = tz.TZDateTime.now(manilaLoc);
    final tokyoTime = tz.TZDateTime.now(tokyoLoc);
    final newYorkTime = tz.TZDateTime.now(newYorkLoc);

    final timeFormat = DateFormat('hh:mm a');
    final dateFormat = DateFormat('dd MMM yyyy');

    final cities = [
      {
        'city': 'Manila',
        'time': timeFormat.format(manilaTime),
        'date': dateFormat.format(manilaTime),
      },
      {
        'city': 'Tokyo',
        'time': timeFormat.format(tokyoTime),
        'date': dateFormat.format(tokyoTime),
      },
      {
        'city': 'New York',
        'time': timeFormat.format(newYorkTime),
        'date': dateFormat.format(newYorkTime),
      },
    ];

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Expanded(
              child: Row(
                children: cities.map((cityData) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              cityData['city']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cityData['time']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cityData['date']!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
