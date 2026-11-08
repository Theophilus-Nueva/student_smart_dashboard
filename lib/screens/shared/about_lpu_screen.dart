import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_assets.dart';

/// Shared / About LPU (Week 3). Mission, vision and core values are
/// placeholders in the Figma file too; replace them with LPU's official text.
class AboutLpuScreen extends StatelessWidget {
  const AboutLpuScreen({super.key});

  static const sections = [
    ('Mission', "Add LPU's official mission here."),
    ('Vision', "Add LPU's official vision here."),
    ('Core Values', "Add LPU's official core values here."),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About LPU')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Image.asset(AppAssets.logo, height: 96),
          const SizedBox(height: 12),
          const Text(
            'Lyceum of the Philippines University – Cavite',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Governor’s Drive, Manggahan, General Trias, Cavite',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          for (final (title, body) in sections) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brand,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(body),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
