import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/app_services.dart';
import '../../services/location_service.dart';
import '../../widgets/app_bottom_nav.dart';
import '../faculty/faculty_tabs.dart';
import '../student/student_tabs.dart';

/// Bottom-nav shell. Both roles get the same four tabs; the content of each
/// tab comes from the role's own tab list (student/ or faculty/).
class RoleShell extends StatefulWidget {
  const RoleShell({super.key, required this.user});

  final AppUser user;

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  int _index = 0;
  late final List<Widget> _tabs = widget.user.isFaculty
      ? facultyTabs()
      : studentTabs();

  LocationTracker? _tracker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // GPS updates for the Current Location card and the map while signed in.
    _tracker ??= AppScope.of(context).tracker..start();
  }

  @override
  void dispose() {
    _tracker?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
