import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Bottom nav from the Figma component set (Active=Home/Analytics/Device/Settings).
/// Icons are always white; a translucent pill behind the icon marks the
/// selected tab, and its label is bold.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const items = <(IconData, String)>[
    (Icons.home, 'Home'),
    (Icons.insert_chart, 'Analytics'),
    (Icons.smartphone, 'Device'),
    (Icons.settings, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brand,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: items[i].$1,
                    label: items[i].$2,
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 30,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.28)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
