import 'package:flutter/material.dart';

/// One entry in Recent Activity (sign-ins, exports, visits, syncs…).
class ActivityItem {
  const ActivityItem({
    required this.kind,
    required this.title,
    required this.description,
    required this.time,
  });

  final ActivityKind kind;
  final String title;
  final String description;
  final DateTime time;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'title': title,
    'description': description,
    'time': time.toIso8601String(),
  };

  factory ActivityItem.fromJson(Map<String, dynamic> json) => ActivityItem(
    kind: ActivityKind.values.asNameMap()[json['kind']] ?? ActivityKind.info,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    time: DateTime.parse(json['time'] as String),
  );
}

enum ActivityKind {
  signIn(Icons.login),
  record(Icons.person),
  export(Icons.description),
  visit(Icons.flag),
  sync(Icons.sync),
  network(Icons.wifi),
  task(Icons.assignment),
  notification(Icons.notifications),
  device(Icons.smartphone),
  info(Icons.info);

  const ActivityKind(this.icon);
  final IconData icon;
}
