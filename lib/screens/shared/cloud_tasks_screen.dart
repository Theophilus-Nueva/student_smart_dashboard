import 'package:flutter/material.dart';

import '../../models/activity_item.dart';
import '../../services/app_services.dart';
import '../../services/task_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/sync_status_banner.dart';

/// Shared / Cloud Tasks (Week 6): add, edit, delete, complete.
class CloudTasksScreen extends StatefulWidget {
  const CloudTasksScreen({super.key});

  @override
  State<CloudTasksScreen> createState() => _CloudTasksScreenState();
}

class _CloudTasksScreenState extends State<CloudTasksScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final title = _input.text.trim();
    if (title.isEmpty) return;
    final services = AppScope.of(context);
    await services.tasks.add(title);
    await services.activity.add(ActivityKind.task, 'Task added', title);
    _input.clear();
  }

  Future<void> _edit(CloudTask task) async {
    final controller = TextEditingController(text: task.title);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit task'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.trim().isEmpty || !mounted) return;
    await AppScope.of(context).tasks.rename(task.id, title);
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final tasks = services.tasks;
    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Tasks')),
      body: ListenableBuilder(
        listenable: tasks,
        builder: (context, _) {
          final items = tasks.tasks;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SyncStatusBanner(sync: services.sync),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('tasks.input'),
                      controller: _input,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _add(),
                      decoration: const InputDecoration(
                        hintText: 'Add a task…',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Add task',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.brand,
                    ),
                    onPressed: _add,
                    icon: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const StateMessage(
                  icon: Icons.assignment,
                  title: 'No tasks yet',
                  message: 'Add your first task above.',
                ),
              for (final t in items) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Checkbox(
                          value: t.done,
                          activeColor: AppColors.brand,
                          onChanged: (_) => tasks.toggleDone(t.id),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  decoration: t.done
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              Text(
                                '${t.done
                                    ? 'Completed'
                                    : t.synced
                                    ? 'Synced'
                                    : 'Pending upload'}'
                                ' · ${formatWhen(t.updatedAt)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit task',
                          onPressed: () => _edit(t),
                          icon: const Icon(Icons.edit, color: AppColors.muted),
                        ),
                        IconButton(
                          tooltip: 'Delete task',
                          onPressed: () => tasks.delete(t.id),
                          icon: const Icon(
                            Icons.delete,
                            color: AppColors.brand,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              const Text(
                'Tasks are saved on this phone and are still here after you '
                'restart the app. Live Firebase sync is added with the '
                'Firestore step.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          );
        },
      ),
    );
  }
}
