import 'package:flutter/material.dart';

/// Grade badge from Student Records: green ≥ 90, blue ≥ 80, amber below.
class GradePill extends StatelessWidget {
  const GradePill({super.key, required this.grade});

  final double grade;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = grade >= 90
        ? (const Color(0xFFE6F4EA), const Color(0xFF1E7B34))
        : grade >= 80
        ? (const Color(0xFFE8EAF6), const Color(0xFF303F9F))
        : (const Color(0xFFFFF3E0), const Color(0xFFB26A00));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        grade.toStringAsFixed(1),
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}
