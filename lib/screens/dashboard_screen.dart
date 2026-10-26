import 'package:flutter/material.dart';
import '../widgets/notification_badge.dart';
import 'dashboard_body.dart';
import 'registration_form_screen.dart';
import 'summary_page_screen.dart';
import 'file_storage_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    DashboardBody(),
    RegistrationFormBody(),
    SummaryPageBody(),
    FileStorageBody(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        title: Column(
          spacing: 8,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/images/images.png',
                  fit: BoxFit.contain,
                  width: 48.0,
                  height: 48.0,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Student Information App",
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const NotificationBadge(count: 8),
              ],
            ),
          ],
        ),
        toolbarHeight: 64,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.red[900],
        unselectedItemColor: Colors.white,
        selectedItemColor: Colors.amber[300],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.app_registration),
            label: 'Registration Form',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.summarize),
            label: 'Summary Page',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'File Storage Confirmation',
          ),
        ],
      ),
    );
  }
}
