import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_assets.dart';

/// Shared / About LPU (Week 3): LPU's official vision, mission and core
/// values.
class AboutLpuScreen extends StatelessWidget {
  const AboutLpuScreen({super.key});

  static const sections = [
    (
      'Vision',
      'An internationally accredited university by 2030, dedicated to '
          'innovation and excellence in the service of God and country.',
    ),
    (
      'Mission',
      'The Lyceum of the Philippines University, espousing the ideals of '
          'Jose P. Laurel, is committed to the following missions:\n\n'
          '1. Provide industry-based knowledge and skills – INSTRUCTION\n'
          '2. Undertake multi-disciplinary research – RESEARCH\n'
          '3. Support community engagement and social responsibility – '
          'COMMUNITY ENGAGEMENT\n'
          '4. Establish local and international linkages – INSTITUTIONAL '
          'DEVELOPMENT\n'
          '5. Produce sustainability advocates for global action – '
          'SUSTAINABILITY',
    ),
    (
      'Core Values',
      'L – Love of God\n'
          'P – Probity\n'
          'U – Unity\n'
          'N – Nationalism\n'
          'J – Justice\n'
          'P – Pro-Environment\n'
          'L – Leadership',
    ),
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
                    Text(body, style: const TextStyle(height: 1.4)),
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
