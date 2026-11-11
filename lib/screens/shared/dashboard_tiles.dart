import 'package:flutter/material.dart';

import '../../services/app_services.dart';
import '../../widgets/action_tile.dart';
import '../../widgets/common.dart';
import '../shell/role_shell.dart';

/// Week 1 action tiles from the lab's expected final layout: Device,
/// Network, Reports and Settings. Device, Reports and Settings open the
/// matching bottom-nav tab; Network checks the connection.
List<Widget> dashboardTiles(BuildContext context) {
  void tab(int index) => RoleShell.selectTab(context, index);

  Future<void> checkNetwork() async {
    final online = await AppScope.of(context).sync.checkConnection();
    if (!context.mounted) return;
    showAppSnack(
      context,
      online ? 'You are online.' : 'You are offline.',
      error: !online,
      duration: const Duration(seconds: 2),
    );
  }

  return [
    ActionTile(
      icon: Icons.smartphone,
      label: 'Device',
      onTap: () => tab(RoleShell.deviceTab),
    ),
    ActionTile(icon: Icons.wifi, label: 'Network', onTap: checkNetwork),
    ActionTile(
      icon: Icons.bar_chart,
      label: 'Reports',
      onTap: () => tab(RoleShell.analyticsTab),
    ),
    ActionTile(
      icon: Icons.settings,
      label: 'Settings',
      onTap: () => tab(RoleShell.settingsTab),
    ),
  ];
}
