import 'package:flutter/material.dart';

/// Figma "Action Tile": black icon (no tinted badge) above a label.
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 22),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-column grid of [ActionTile]s (four columns on tablets and in
/// landscape, Week 1). Tiles keep a fixed height so two-line labels fit
/// however wide the columns are.
class ActionGrid extends StatelessWidget {
  const ActionGrid({super.key, required this.children});

  final List<Widget> children;

  static const tileHeight = 100.0;
  static const spacing = 10.0;

  @override
  Widget build(BuildContext context) {
    final columns = MediaQuery.sizeOf(context).width > 600 ? 4 : 2;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: cell / tileHeight,
          children: children,
        );
      },
    );
  }
}
