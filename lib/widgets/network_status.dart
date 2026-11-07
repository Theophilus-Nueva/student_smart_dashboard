import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Week 7 sync states: online (green), sync pending (amber), offline (red).
enum NetworkState { online, pending, offline }

extension NetworkStateStyle on NetworkState {
  String get label => switch (this) {
    NetworkState.online => 'ONLINE',
    NetworkState.pending => 'SYNC PENDING',
    NetworkState.offline => 'OFFLINE',
  };

  Color get color => switch (this) {
    NetworkState.online => AppColors.online,
    NetworkState.pending => AppColors.pending,
    NetworkState.offline => AppColors.offline,
  };

  Color get background => switch (this) {
    NetworkState.online => AppColors.onlineBg,
    NetworkState.pending => AppColors.pendingBg,
    NetworkState.offline => AppColors.offlineBg,
  };
}

class NetworkStatusBanner extends StatelessWidget {
  const NetworkStatusBanner({super.key, required this.state, this.detail});

  final NetworkState state;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: state.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: state.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: state.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            state.label,
            style: TextStyle(
              color: state.color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                detail!,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
