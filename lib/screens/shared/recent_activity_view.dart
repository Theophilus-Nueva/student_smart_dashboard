import 'package:flutter/material.dart';

import '../../models/activity_item.dart';
import '../../services/app_services.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

/// Shared / Recent Activity (empty and with data), the second Home tab.
class RecentActivityView extends StatefulWidget {
  const RecentActivityView({super.key});

  @override
  State<RecentActivityView> createState() => _RecentActivityViewState();
}

class _RecentActivityViewState extends State<RecentActivityView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).activity.markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final activity = AppScope.of(context).activity;
    return ListenableBuilder(
      listenable: activity,
      builder: (context, _) {
        final items = activity.items;
        if (items.isEmpty) {
          return const StateMessage(
            icon: Icons.history,
            title: 'No Recent Activity Available',
            message:
                'Sign-ins, exports, campus visits and syncs will show up here.',
          );
        }
        final children = <Widget>[];
        String? heading;
        for (final item in items) {
          final h = formatDayHeading(item.time);
          if (h != heading) {
            heading = h;
            children.add(SectionHeader(h));
          }
          children.add(_ActivityRow(item: item));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: children,
        );
      },
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.kind.icon, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.description.isNotEmpty)
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            formatTime(item.time),
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
