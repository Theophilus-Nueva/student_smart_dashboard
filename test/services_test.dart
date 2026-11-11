import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:smart_dashboard/models/student.dart';
import 'package:smart_dashboard/services/file_export_service.dart';
import 'package:smart_dashboard/services/task_service.dart';
import 'package:smart_dashboard/widgets/id_card.dart';
import 'package:smart_dashboard/widgets/network_status.dart';

import 'test_helpers.dart';

void main() {
  test('ID card name puts the last name in capitals', () {
    expect(idCardName('Nueva, Theophilus T.'), 'NUEVA, Theophilus T.');
    expect(idCardName('Dela Cruz, Juan'), 'DELA CRUZ, Juan');
    expect(idCardName('Madonna'), 'Madonna');
  });

  taskRemoteTests();

  test('Export writes student_info.txt in the Week 3 format', () async {
    final dir = await Directory.systemTemp.createTemp('export');
    final service = FileExportService(documentsDirectory: () async => dir);
    final result = await service.exportStudent(sampleStudents[3]);

    expect(result.fileName, 'student_info.txt');
    final text = await File(result.path).readAsString();
    expect(
      text,
      startsWith('STUDENT INFORMATION\n\nName: Nueva, Theophilus T.'),
    );
    expect(text, contains('Program: BSIT'));
    await dir.delete(recursive: true);
  });

  test('Students persist as JSON under "students"', () async {
    final services = await makeServices();
    await services.students.add(
      const Student(
        id: '2026-1-00001',
        name: 'Test, Student',
        email: 'test@lpu.example',
        program: 'BSLIS',
        yearLevel: '1st Year',
        grade: 80,
      ),
    );
    expect(services.prefs.getString('students'), contains('2026-1-00001'));

    final reloaded = await makeServices(
      prefs: {'students': services.prefs.getString('students')!},
    );
    expect(reloaded.students.byId('2026-1-00001')?.name, 'Test, Student');
  });

  test(
    'Offline changes queue as pending, then sync when back online',
    () async {
      final services = await makeServices(online: false);
      await services.sync.checkConnection();
      await services.tour.recordVisit('library');

      expect(services.sync.state, NetworkState.offline);
      expect(services.sync.pendingCount, 1);
      expect(await services.sync.syncNow(), isFalse);

      await services.sync.setOnline(true);
      await Future<void>.delayed(Duration.zero);
      expect(services.sync.pendingCount, 0);
      expect(services.sync.state, NetworkState.online);
      expect(services.sync.completedSyncs, 1);
      expect(services.sync.log.first.status, 'ONLINE');
    },
  );

  test('With auto-sync off, changes stay pending until Sync Now', () async {
    final services = await makeServices();
    await services.sync.setAutoSync(false);
    await services.students.delete('2024-1-00123');
    expect(services.sync.state, NetworkState.online); // delete leaves no record
    await services.tour.recordVisit('library');
    expect(services.sync.state, NetworkState.pending);
    expect(await services.sync.syncNow(), isTrue);
    expect(services.sync.pendingCount, 0);
  });
}

class _FakeRemote implements TaskRemote {
  final controller = StreamController<List<CloudTask>>();
  final saved = <String, CloudTask>{};
  final deleted = <String>[];

  @override
  Stream<List<CloudTask>> watch() => controller.stream;

  @override
  Future<void> upsert(CloudTask task) async => saved[task.id] = task;

  @override
  Future<void> delete(String id) async => deleted.add(id);
}

void taskRemoteTests() {
  test(
    'Tasks push to the cloud on sync and merge live cloud changes',
    () async {
      final services = await makeServices();
      final remote = _FakeRemote();
      services.tasks.attachRemote(remote);

      await services.tasks.add('Review Assignment 3');
      await Future<void>.delayed(Duration.zero); // auto-sync runs
      expect(remote.saved.values.single.title, 'Review Assignment 3');
      expect(services.tasks.pendingCount, 0);

      // Another device adds a task in Firestore.
      remote.controller.add([
        ...remote.saved.values.map((t) => t.copyWith(synced: true)),
        CloudTask(
          id: 'x1',
          title: 'Study for Midterms',
          updatedAt: DateTime(2026),
        ),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(services.tasks.totalCount, 2);

      final id = services.tasks.tasks.firstWhere((t) => t.id != 'x1').id;
      await services.tasks.delete(id);
      expect(remote.deleted, [id]);
      await remote.controller.close();
    },
  );
}
