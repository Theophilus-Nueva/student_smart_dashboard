import 'package:flutter/material.dart';

import '../../widgets/common.dart';

/// Shared / Faculty Directory (Week 2 challenge, static mock data).
class FacultyDirectoryScreen extends StatefulWidget {
  const FacultyDirectoryScreen({super.key});

  static const faculty = [
    (
      'Prof. Maria Santos',
      'Information Technology',
      'maria.santos@lpu.example',
      '+63 912 345 6720',
    ),
    (
      'Prof. Jose Reyes',
      'Computer Science',
      'jose.reyes@lpu.example',
      '+63 912 345 6721',
    ),
    (
      'Prof. Ana Villanueva',
      'Library and Information Science',
      'ana.villanueva@lpu.example',
      '+63 912 345 6722',
    ),
    (
      'Engr. Mark Bautista',
      'Information Technology',
      'mark.bautista@lpu.example',
      '+63 912 345 6723',
    ),
  ];

  @override
  State<FacultyDirectoryScreen> createState() => _FacultyDirectoryScreenState();
}

class _FacultyDirectoryScreenState extends State<FacultyDirectoryScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Faculty Directory')),
      body: ListenableBuilder(
        listenable: _search,
        builder: (context, _) {
          final q = _search.text.trim().toLowerCase();
          final results = FacultyDirectoryScreen.faculty
              .where(
                (f) =>
                    q.isEmpty ||
                    f.$1.toLowerCase().contains(q) ||
                    f.$2.toLowerCase().contains(q),
              )
              .toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  hintText: 'Search faculty',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              if (results.isEmpty)
                const StateMessage(
                  icon: Icons.person_search,
                  title: 'No matches',
                  message: 'Try another name or department.',
                ),
              for (final (name, dept, email, phone) in results) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.school),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(dept),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        DetailLine(label: 'Email', value: email),
                        DetailLine(label: 'Contact', value: phone),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}
