import 'package:flutter/material.dart';

import '../services/device_service.dart';
import 'sensor_sheet.dart';

/// Slides up the gyroscope from the Device tab: live X/Y/Z (rad/s) with the
/// previous and highest values, and the rotation history as a graph.
Future<void> showGyroscopeSheet(BuildContext context, DeviceService device) {
  return showSensorSheet(
    context,
    device: device,
    title: 'Gyroscope',
    historyTitle: 'Rotation history',
    keyPrefix: 'gyro',
    current: () => device.gyro,
    notes: (axis) => [
      'prev ${device.gyroPrevious.values[axis].toStringAsFixed(2)}',
      'max ${device.gyroMax.values[axis].toStringAsFixed(2)}',
    ],
    history: () => device.gyroHistory,
    historyLength: DeviceService.gyroHistoryLength,
    interval: DeviceService.gyroInterval,
  );
}
