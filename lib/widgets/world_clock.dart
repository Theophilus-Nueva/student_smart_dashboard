import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../theme/app_colors.dart';

/// World clock (Week 1 challenge): Manila, Tokyo and New York with the date
/// and the offset from Manila. Refreshes every 30 seconds.
class WorldClock extends StatefulWidget {
  const WorldClock({super.key});

  static const cities = [
    ('Manila', 'Asia/Manila'),
    ('Tokyo', 'Asia/Tokyo'),
    ('New York', 'America/New_York'),
  ];

  @override
  State<WorldClock> createState() => _WorldClockState();
}

class _WorldClockState extends State<WorldClock> {
  static bool _tzReady = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!_tzReady) {
      tzdata.initializeTimeZones();
      _tzReady = true;
    }
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static String _offset(Duration d) {
    final hours = d.inMinutes / 60;
    final whole = hours == hours.roundToDouble();
    final n = whole
        ? hours.round().abs().toString()
        : hours.abs().toStringAsFixed(1);
    final sign = hours < 0 ? '-' : '+';
    return '$sign$n ${n == '1' ? 'HR' : 'HRS'}';
  }

  @override
  Widget build(BuildContext context) {
    final manila = tz.TZDateTime.now(tz.getLocation('Asia/Manila'));
    final dateFormat = DateFormat('EEE, dd MMM yyyy');
    final timeFormat = DateFormat('h:mm a');
    return Column(
      children: [
        for (final (city, zone) in WorldClock.cities)
          Builder(
            builder: (context) {
              final now = tz.TZDateTime.now(tz.getLocation(zone));
              final offset = now.timeZoneOffset - manila.timeZoneOffset;
              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 4,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${dateFormat.format(now)} · ${_offset(offset)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                          Text(city, style: const TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                    Text(
                      timeFormat.format(now),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
