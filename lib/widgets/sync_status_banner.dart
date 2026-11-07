import 'package:flutter/material.dart';

import '../services/sync_service.dart';
import '../utils/format.dart';
import 'network_status.dart';

/// Network status bound to the sync service.
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key, required this.sync});

  final SyncService sync;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final last = formatLastSync(sync.lastSync);
        final pending = sync.pendingCount;
        final detail = switch (sync.state) {
          NetworkState.online =>
            '${sync.autoSync ? 'Auto-sync on' : 'Auto-sync off'} · last sync $last',
          NetworkState.pending => '$pending pending · last sync $last',
          NetworkState.offline => 'Saved on this phone · $pending pending',
        };
        return NetworkStatusBanner(state: sync.state, detail: detail);
      },
    );
  }
}
