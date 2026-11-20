import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/device_service.dart';
import '../theme/app_colors.dart';
import 'device_sheet.dart';

/// Line colours for the X, Y and Z axes.
const accelAxisColors = [
  AppColors.brand,
  AppColors.tabActive,
  AppColors.online,
];

/// Slides up the accelerometer from the Device tab: live X/Y/Z with their
/// highest values, and the movement history as a graph.
Future<void> showAccelerometerSheet(
  BuildContext context,
  DeviceService device,
) {
  return showDeviceSheet(
    context,
    listenable: device,
    builder: (context) => DeviceSheetBody(
      children: [
        const DeviceSheetTitle('Accelerometer'),
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
                      child: _AxisTile(
                        axis: 'XYZ'[i],
                        color: accelAxisColors[i],
                        value: device.accel.values[i],
                        max: device.accelMax.values[i],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Movement history',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                'Last ${DeviceService.accelHistoryLength} seconds',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: device.accelHistory.length < 2
                    ? const Center(
                        child: Text(
                          'Waiting for readings…',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      )
                    : AccelGraph(
                        key: const Key('accel.graph'),
                        history: device.accelHistory,
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
                        color: accelAxisColors[i],
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
    ),
  );
}

class _AxisTile extends StatelessWidget {
  const _AxisTile({
    required this.axis,
    required this.color,
    required this.value,
    required this.max,
  });

  final String axis;
  final Color color;
  final double value;
  final double max;

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
            key: Key('accel.value.$axis'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          Text(
            'max ${max.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Line graph of accelerometer readings (newest first in [history]): one
/// line per axis, newest on the right, centred on 0. Touch a point to read
/// its value.
class AccelGraph extends StatelessWidget {
  const AccelGraph({super.key, required this.history});

  final List<Vec3> history;

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
    final last = (DeviceService.accelHistoryLength - 1).toDouble();

    return LineChart(
      duration: const Duration(milliseconds: 250),
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
              color: accelAxisColors[axis],
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
                    color: accelAxisColors[s.barIndex],
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
