import 'package:flutter/material.dart';

import '../services/app_services.dart';
import '../utils/format.dart';
import 'stat_card.dart';

/// Week 1 KPI cards: Network, API and Storage status, read from the app's
/// own services. GPS status is the Current Location card above.
class KpiGrid extends StatefulWidget {
  const KpiGrid({super.key});

  @override
  State<KpiGrid> createState() => _KpiGridState();
}

class _KpiGridState extends State<KpiGrid> {
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checked) return;
    _checked = true;
    final services = AppScope.of(context);
    // Check the API once each time the dashboard opens (refresh() ignores
    // the call if a check is already running).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) services.directory.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([services.sync, services.directory]),
      builder: (context, _) {
        final online = services.sync.online;
        final api = services.directory;
        final updated = api.lastUpdated;
        final (apiValue, apiNote) = api.loading
            ? ('Checking', 'JSONPlaceholder')
            : api.error != null
            ? ('Error', 'Could not reach the API')
            : updated != null
            ? ('Online', 'Updated ${formatTime(updated)}')
            : ('Not checked', 'JSONPlaceholder');
        return StatGrid(
          columns: 3,
          children: [
            StatCard(
              label: 'Network',
              value: online ? 'Online' : 'Offline',
              note: online ? 'Connected' : 'No connection',
            ),
            StatCard(label: 'API', value: apiValue, note: apiNote),
            const StatCard(
              label: 'Storage',
              value: 'Ready',
              note: 'Saved on this phone',
            ),
          ],
        );
      },
    );
  }
}
