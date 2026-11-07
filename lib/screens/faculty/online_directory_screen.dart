import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/app_services.dart';
import '../../services/app_settings.dart';
import '../../services/directory_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/stat_card.dart';
import 'faculty_actions.dart';

/// Faculty / Online Directory (+ Loading, Error, empty states). API users
/// with a 15-second auto-refresh (Week 4) and a sync button.
class OnlineDirectoryScreen extends StatefulWidget {
  const OnlineDirectoryScreen({super.key});

  static const refreshEvery = Duration(seconds: 15);

  @override
  State<OnlineDirectoryScreen> createState() => _OnlineDirectoryScreenState();
}

class _OnlineDirectoryScreenState extends State<OnlineDirectoryScreen> {
  final _search = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final services = AppScope.of(context);
      services.directory.refresh();
      if (services.settings.get(AppSettings.autoRefresh)) {
        _timer = Timer.periodic(
          OnlineDirectoryScreen.refreshEvery,
          (_) => services.directory.refresh(),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _syncNow() async {
    final directory = AppScope.of(context).directory;
    final ok = await directory.refresh();
    if (!mounted) return;
    if (ok) {
      await runSyncNow(context);
    } else {
      showAppSnack(context, 'Sync failed · API Error', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final directory = services.directory;
    return Scaffold(
      appBar: AppBar(title: const Text('Online Directory')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Sync now',
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        onPressed: _syncNow,
        child: const Icon(Icons.sync),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([directory, services.sync, _search]),
        builder: (context, _) {
          final header = <Widget>[
            const FacultyOnlyTag(),
            StatGrid(
              children: [
                StatCard(
                  label: 'Last updated',
                  value: directory.lastUpdated == null
                      ? '—'
                      : formatTime(directory.lastUpdated!),
                ),
                StatCard(
                  label: 'Users retrieved',
                  value: '${directory.users.length}',
                ),
              ],
            ),
            const SizedBox(height: 12),
          ];

          // Loading with nothing cached yet.
          if (directory.loading && !directory.hasData) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...header,
                const SizedBox(height: 60),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
                const Text('Loading users…', textAlign: TextAlign.center),
              ],
            );
          }

          // Error with nothing cached.
          if (directory.error != null && !directory.hasData) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...header,
                StateMessage(
                  icon: Icons.cloud_off,
                  title: 'API Error',
                  message:
                      "Couldn't load users from jsonplaceholder.typicode.com. "
                      'Check your connection and try again.',
                  action: ElevatedButton(
                    onPressed: directory.refresh,
                    child: const Text('Try again'),
                  ),
                ),
              ],
            );
          }

          final users = directory.search(_search.text);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              ...header,
              if (directory.error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.offlineBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'API Error · Your last saved list is still available '
                    'offline.',
                    style: TextStyle(color: AppColors.offline),
                  ),
                ),
              if (directory.loading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: LinearProgressIndicator(),
                ),
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  hintText: 'Search users',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              if (users.isEmpty)
                StateMessage(
                  icon: Icons.person_search,
                  title: directory.hasData ? 'No matches' : 'No users yet',
                  message: directory.hasData
                      ? 'Try another name, email or company.'
                      : 'Pull the latest list with the sync button.',
                ),
              for (final u in users) ...[
                _UserCard(user: u),
                const SizedBox(height: 10),
              ],
              const Text(
                'Source: jsonplaceholder.typicode.com/users',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final DirectoryUser user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.cloud_done, size: 18, color: AppColors.online),
              ],
            ),
            const SizedBox(height: 6),
            DetailLine(label: 'Email', value: user.email),
            DetailLine(label: 'Phone', value: user.phone),
            DetailLine(label: 'Company', value: user.company),
          ],
        ),
      ),
    );
  }
}
