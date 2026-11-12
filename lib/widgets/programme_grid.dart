import 'package:flutter/material.dart';

import 'stat_card.dart';

/// Week 2 Challenges 2–3: CCS programme cards in a 2-column statistics grid.
/// The enrolment numbers are the lab's sample values.
class ProgrammeGrid extends StatelessWidget {
  const ProgrammeGrid({super.key});

  static const programmes = [
    ('BSIT-NS', 'Network and Security', 120),
    ('BSIT-WM', 'Web and Mobile', 150),
    ('BSCS-DS', 'Data Science', 100),
    ('BSCS-SE', 'Software Engineering', 90),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final cellWidth = (constraints.maxWidth - spacing) / 2;
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          // Fixed card height, whatever the screen width.
          childAspectRatio: cellWidth / 96,
          children: [
            for (final (code, name, students) in programmes)
              StatCard(label: code, value: '$students', note: name),
          ],
        );
      },
    );
  }
}
