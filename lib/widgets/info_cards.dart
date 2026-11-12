import 'package:flutter/material.dart';

import '../models/student.dart';
import '../services/app_services.dart';

/// Semester for [date], assuming the usual Philippine calendar: 1st
/// Semester August–December, 2nd Semester January–May, Summer June–July.
({String term, String schoolYear}) semesterFor(DateTime date) {
  final m = date.month;
  final startYear = m >= 8 ? date.year : date.year - 1;
  final term = m >= 8
      ? '1st Semester'
      : m <= 5
      ? '2nd Semester'
      : 'Summer';
  return (term: term, schoolYear: 'AY $startYear–${startYear + 1}');
}

/// Week 3 dashboard cards: Students, Programs, Campus, showing Total
/// Students, Active Programs and Current Semester. A Column on phones, a
/// Row on tablets (over 600 px wide).
class InfoCards extends StatelessWidget {
  const InfoCards({super.key, this.now});

  /// For tests; defaults to today.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final students = AppScope.of(context).students;
    final wide = MediaQuery.sizeOf(context).width > 600;
    return ListenableBuilder(
      listenable: students,
      builder: (context, _) {
        final sem = semesterFor(now ?? DateTime.now());
        final cards = [
          _InfoCard(
            icon: Icons.people,
            title: 'Students',
            label: 'Total Students',
            value: '${students.total}',
          ),
          _InfoCard(
            icon: Icons.school,
            title: 'Programs',
            label: 'Active Programs',
            value: '${Student.programs.length}',
          ),
          _InfoCard(
            icon: Icons.location_city,
            title: 'Campus',
            label: 'Current Semester',
            value: sem.term,
            note: sem.schoolYear,
          ),
        ];
        return wide
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: cards[i]),
                    ],
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    cards[i],
                  ],
                ],
              );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.label,
    required this.value,
    this.note,
  });

  final IconData icon;
  final String title;
  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(note == null ? label : '$label · $note'),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
