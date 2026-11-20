import 'package:flutter/material.dart';

import '../services/device_service.dart';
import 'sensor_sheet.dart';

/// Slides up the accelerometer from the Device tab: live X/Y/Z with their
/// highest values, and the movement history as a graph.
Future<void> showAccelerometerSheet(
  BuildContext context,
  DeviceService device,
) {
  return showSensorSheet(
    context,
    device: device,
    title: 'Accelerometer',
    historyTitle: 'Movement history',
    keyPrefix: 'accel',
    current: () => device.accel,
    notes: (axis) => ['max ${device.accelMax.values[axis].toStringAsFixed(2)}'],
    history: () => device.accelHistory,
    historyLength: DeviceService.accelHistoryLength,
    interval: DeviceService.accelInterval,
  );
}
