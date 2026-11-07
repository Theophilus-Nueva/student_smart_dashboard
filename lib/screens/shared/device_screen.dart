import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

/// Shared / Device tab (Week 5): camera, gallery, accelerometer, gyroscope,
/// compass and sensor status. The layout is in place; readings and photos
/// need `image_picker` and `sensors_plus`, which are added in a later step.
class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.pendingBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Camera and sensors are not connected yet. They need the '
              'image_picker and sensors_plus packages.',
              style: TextStyle(color: AppColors.pending),
            ),
          ),
          const SectionHeader('Camera'),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.field,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 48, color: AppColors.muted),
                SizedBox(height: 6),
                Text('No photo yet', style: TextStyle(color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.image),
                  label: const Text('Select Photo'),
                ),
              ),
            ],
          ),
          const SectionHeader('Accelerometer'),
          const _AxisCard(),
          const SectionHeader('Gyroscope'),
          const _AxisCard(),
          const SectionHeader('Compass'),
          const Card(
            child: ListTile(
              leading: Icon(Icons.explore),
              title: Text('Heading —'),
              subtitle: Text('Direction history appears once the sensor runs'),
            ),
          ),
          const SectionHeader('Sensor Status'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  for (final s in const [
                    'Camera',
                    'Accelerometer',
                    'Gyroscope',
                    'Compass',
                  ])
                    DetailLine(
                      label: s,
                      value: 'Not connected',
                      valueColor: AppColors.muted,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AxisCard extends StatelessWidget {
  const _AxisCard();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final axis in const ['X', 'Y', 'Z']) ...[
          if (axis != 'X') const SizedBox(width: 8),
          Expanded(
            child: InfoField(label: axis, value: '—'),
          ),
        ],
      ],
    );
  }
}
