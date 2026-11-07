import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Figma "Stat Card": small label, large value, optional note.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.note,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? note;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.text,
                ),
              ),
            ),
            if (note != null)
              Text(
                note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
          ],
        ),
      ),
    );
  }
}

/// Lays stat cards out two per row without fixed heights.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final perRow = MediaQuery.sizeOf(context).width > 600 ? 4 : 2;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += perRow) {
      final slice = children.sublist(i, (i + perRow).clamp(0, children.length));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < perRow; j++) ...[
                if (j > 0) const SizedBox(width: 10),
                Expanded(child: j < slice.length ? slice[j] : const SizedBox()),
              ],
            ],
          ),
        ),
      );
      if (i + perRow < children.length) rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }
}
