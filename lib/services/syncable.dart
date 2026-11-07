import 'package:flutter/foundation.dart';

/// A local store whose records carry a `synced` flag (Week 7 offline queue).
abstract class Syncable implements Listenable {
  int get pendingCount;
  int get totalCount;
  Future<void> markAllSynced();
}
