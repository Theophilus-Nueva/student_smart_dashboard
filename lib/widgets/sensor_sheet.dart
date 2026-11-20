import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/device_service.dart';
import '../theme/app_colors.dart';
import 'device_sheet.dart';

/// Line colours for the X, Y and Z axes.
const sensorAxisColors = [
  AppColors.brand,
  AppColors.tabActive,
  AppColors.online,
];

/// Slides up a motion sensor from the Device tab (accelerometer,
/// gyroscope): live X/Y/Z with notes under each value, and the history as
/// a graph. [keyPrefix] names the widgets for tests (`<prefix>.graph`,
/// `<prefix>.value.X`).
Future<void> showSensorSheet(
  BuildContext context, {
  required DeviceService device,
  required String title,
  required String historyTitle,
  required String keyPrefix,
  required Vec3 Function() current,
  required List<String> Function(int axis) notes,
  required List<Vec3> Function() history,
  required int historyLength,
  required Duration interval,
}) {
  final seconds = (historyLength * interval.inMilliseconds / 1000).round();
  return showDeviceSheet(
    context,
    listenable: device,
    builder: (context) {
      final readings = history();
      return DeviceSheetBody(
        children: [
          DeviceSheetTitle(title),
          const SizedBox(height: 16),
          // Kept readable in landscape instead of stretching edge to edge.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _SensorAxisTile(
                          axis: 'XYZ'[i],
                          color: sensorAxisColors[i],
                          value: current().values[i],
                          notes: notes(i),
                          keyPrefix: keyPrefix,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  historyTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Last $seconds seconds',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: readings.length < 2
                      ? const Center(
                          child: Text(
                            'Waiting for readings…',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        )
                      : SensorGraph(
                          key: Key('$keyPrefix.graph'),
                          history: readings,
                          length: historyLength,
                          // Never longer than the gap between readings.
                          duration: interval < const Duration(milliseconds: 250)
                              ? interval * 0.75
                              : const Duration(milliseconds: 250),
                        ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 20),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: sensorAxisColors[i],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('XYZ'[i]),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _SensorAxisTile extends StatelessWidget {
  const _SensorAxisTile({
    required this.axis,
    required this.color,
    required this.value,
    required this.notes,
    required this.keyPrefix,
  });

  final String axis;
  final Color color;
  final double value;

  /// Small lines under the value, e.g. "max 1.20".
  final List<String> notes;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            axis,
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            value.toStringAsFixed(2),
            key: Key('$keyPrefix.value.$axis'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          for (final note in notes)
            Text(
              note,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}

class SensorGraph extends StatelessWidget {
  const SensorGraph({
    super.key,
    required this.history,
    required this.length,
    this.duration = const Duration(milliseconds: 250),
  });

  /// Readings, newest first.
  final List<Vec3> history;

  /// Slots across the graph (the most readings kept).
  final int length;

  /// How long each update slides the lines.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    // Symmetric scale around 0 that fits the biggest reading (at least ±1).
    var peak = 1.0;
    for (final v in history) {
      for (final a in v.values) {
        peak = math.max(peak, a.abs());
      }
    }
    final scale = peak * 1.1;
    // Newest reading on the right edge (x = last slot); older ones step
    // left one slot per second, so the graph scrolls as readings come in.
    final last = (length - 1).toDouble();

    return LineChart(
      duration: duration,
      LineChartData(
        minX: 0,
        maxX: last,
        minY: -scale,
        maxY: scale,
        lineBarsData: [
          for (var axis = 0; axis < 3; axis++)
            LineChartBarData(
              spots: [
                for (var i = 0; i < history.length; i++)
                  FlSpot(last - i, history[i].values[axis]),
              ],
              color: sensorAxisColors[axis],
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
        ],
        // Grid and labels at −scale, 0 and +scale.
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: scale,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: scale,
              getTitlesWidget: (value, meta) => Text(
                value.abs() < 1e-9 ? '0' : value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
            ),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: const AxisTitles(),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.white,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${'XYZ'[s.barIndex]}  ${s.y.toStringAsFixed(2)}',
                  TextStyle(
                    color: sensorAxisColors[s.barIndex],
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
