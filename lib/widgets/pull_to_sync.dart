import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Pull down from the top of [child] to refresh and sync (replaces the old
/// Sync buttons). A loading spinner follows the finger and runs [onRefresh]
/// when released; it stays until the sync finishes.
class PullToSync extends StatelessWidget {
  const PullToSync({super.key, required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.brand,
      backgroundColor: Colors.white,
      // Lets short pages be pulled too, not just ones that overflow.
      notificationPredicate: (n) => n.depth == 0,
      child: ScrollConfiguration(behavior: const _AlwaysPull(), child: child),
    );
  }
}

class _AlwaysPull extends MaterialScrollBehavior {
  const _AlwaysPull();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
}
