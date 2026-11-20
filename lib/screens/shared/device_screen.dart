import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/activity_item.dart';
import '../../services/app_services.dart';
import '../../services/device_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

/// Shared / Device tab (Week 5): camera, gallery, accelerometer, gyroscope,
/// compass and sensor status. Sensors run only while this tab is open
/// (the role shell starts and stops them).
class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key});

  Future<void> _pick(BuildContext context, {required bool fromCamera}) async {
    final services = AppScope.of(context);
    try {
      final photo = await services.device.pickPhoto(fromCamera: fromCamera);
      if (photo == null) return;
      await services.activity.add(
        ActivityKind.device,
        fromCamera ? 'Photo taken' : 'Photo selected',
        '${photo.name} · ${photo.sizeLabel}',
      );
    } on PlatformException catch (e) {
      if (context.mounted) {
        showAppSnack(
          context,
          e.code.contains('denied')
              ? 'Camera or photo access is turned off in your phone settings.'
              : 'Could not get the photo (${e.code}).',
          error: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = AppScope.of(context).device;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListenableBuilder(
          listenable: device,
          builder: (context, _) {
            final latest = device.latestPhoto;
            final heading = device.heading;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SectionHeader('Camera'),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 180,
                    color: AppColors.field,
                    child: latest == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image,
                                size: 48,
                                color: AppColors.muted,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'No photo yet',
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ],
                          )
                        : Image.file(
                            File(latest.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                  ),
                ),
                if (latest != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${latest.name} · ${latest.sizeLabel} · '
                    '${latest.fromCamera ? 'Captured' : 'Selected'} '
                    '${formatWhen(latest.time).toLowerCase()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pick(context, fromCamera: true),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pick(context, fromCamera: false),
                        icon: const Icon(Icons.image),
                        label: const Text('Select Photo'),
                      ),
                    ),
                  ],
                ),
                if (device.photos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Last 3 images',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: i < device.photos.length
                              ? _Thumb(photo: device.photos[i])
                              : const SizedBox(),
                        ),
                      ],
                    ],
                  ),
                ],
                _sensorHeader('Accelerometer', device.status['Accelerometer']!),
                _AxisRow(
                  values: device.accel,
                  notes: [
                    for (final m in device.accelMax.values)
                      'max ${m.toStringAsFixed(2)}',
                  ],
                ),
                if (device.accelHistory.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Movement (X): '
                      '${device.accelHistory.take(5).map((v) => v.x.toStringAsFixed(1)).join(' → ')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                _sensorHeader('Gyroscope', device.status['Gyroscope']!),
                _AxisRow(
                  values: device.gyro,
                  notes: [
                    for (final p in device.gyroPrevious.values)
                      'prev ${p.toStringAsFixed(2)}',
                  ],
                ),
                _sensorHeader('Compass', device.status['Compass']!),
                Card(
                  child: ListTile(
                    leading: Transform.rotate(
                      angle: -(heading ?? 0) * math.pi / 180,
                      child: const Icon(
                        Icons.navigation,
                        color: AppColors.brand,
                      ),
                    ),
                    title: Text(
                      heading == null
                          ? 'Heading —'
                          : '${device.direction} · ${heading.round()}°',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      device.directionHistory.isEmpty
                          ? 'Hold the phone flat for a steady reading'
                          : 'Recent: ${device.directionHistory.map((d) => '${d.$1} ${formatTime(d.$2)}').join(' · ')}',
                    ),
                  ),
                ),
                const SectionHeader('Sensor Status'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        for (final MapEntry(key: name, value: s)
                            in device.status.entries)
                          DetailLine(
                            label: name,
                            value: _statusLabel(s),
                            valueColor: _statusColor(s),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Widget _sensorHeader(String title, SensorStatus status) =>
      SectionHeader(
        title,
        action: Text(
          _statusLabel(status),
          style: TextStyle(fontSize: 12, color: _statusColor(status)),
        ),
      );

  static String _statusLabel(SensorStatus s) => switch (s) {
    SensorStatus.active => 'Active',
    SensorStatus.waiting => 'Starting…',
    SensorStatus.off => 'Paused',
    SensorStatus.unavailable => 'Not available',
  };

  static Color _statusColor(SensorStatus s) => switch (s) {
    SensorStatus.active => AppColors.online,
    SensorStatus.unavailable => AppColors.offline,
    _ => AppColors.muted,
  };
}

class _AxisRow extends StatelessWidget {
  const _AxisRow({required this.values, required this.notes});

  final Vec3 values;
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    const axes = ['X', 'Y', 'Z'];
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoField(
                  label: axes[i],
                  value: values.values[i].toStringAsFixed(2),
                ),
                const SizedBox(height: 2),
                Text(
                  notes[i],
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.photo});

  final DevicePhoto photo;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(File(photo.path), fit: BoxFit.cover),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => AppScope.of(context).device.removePhoto(photo),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white,
                    semanticLabel: 'Remove ${photo.name}',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
