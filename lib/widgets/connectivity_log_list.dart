import 'package:flutter/material.dart';

import '../services/sync_service.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';

/// Five most recent connectivity events (Week 7 ConnectivityLog).
class ConnectivityLogList extends StatelessWidget {
  const ConnectivityLogList({super.key, required this.sync});

  final SyncService sync;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final entries = sync.log.take(5).toList();
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: entries.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'No connectivity changes recorded yet.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : Column(
                    children: [
                      for (final e in entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                e.online ? Icons.wifi : Icons.wifi_off,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(formatWhen(e.time))),
                              Text(
                                e.status,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: e.online
                                      ? AppColors.online
                                      : AppColors.offline,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
