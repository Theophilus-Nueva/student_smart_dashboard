import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'task_service.dart';

/// Starts Firebase with the project from `flutterfire configure`
/// (smart-campus-tour-guide). Returns false if it can't start (for example
/// on a platform that isn't configured), and the app keeps working with
/// on-phone storage only.
Future<bool> initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } on Object catch (e) {
    debugPrint('Firebase not configured: $e');
    return false;
  }
}

/// Week 6 Cloud Task Manager storage: the `dashboard` collection with
/// `task` and `timestamp` fields (plus `done`).
class FirestoreTaskRemote implements TaskRemote {
  FirestoreTaskRemote([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _db.collection('dashboard');

  @override
  Stream<List<CloudTask>> watch() => _tasks.snapshots().map(
    (snapshot) => [
      for (final doc in snapshot.docs)
        CloudTask(
          id: doc.id,
          title: doc.data()['task'] as String? ?? '',
          updatedAt:
              (doc.data()['timestamp'] as Timestamp?)?.toDate() ??
              DateTime.now(),
          done: doc.data()['done'] as bool? ?? false,
          synced: true,
        ),
    ],
  );

  @override
  Future<void> upsert(CloudTask task) => _tasks.doc(task.id).set({
    'task': task.title,
    'timestamp': Timestamp.fromDate(task.updatedAt),
    'done': task.done,
  });

  @override
  Future<void> delete(String id) => _tasks.doc(id).delete();

  /// Week 6 Security Center: login timestamps stored in Firebase.
  Future<void> logLogin(String username, String role, String method) =>
      _db.collection('logins').add({
        'user': username,
        'role': role,
        'method': method,
        'timestamp': FieldValue.serverTimestamp(),
      });
}
