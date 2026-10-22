// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';
import '../sync/sync_engine.dart';

class SyncProvider extends ChangeNotifier {
  final SyncEngine _engine;

  SyncProvider({required SyncEngine engine}) : _engine = engine {
    _engine.addListener(_onEngineChanged);
  }

  SyncState get state => _engine.state;
  int get pendingCount => _engine.pendingCount;
  bool get isSyncing => _engine.isSyncing;
  String? get errorMessage => _engine.errorMessage;

  Future<void> syncNow(String accountId) => _engine.processQueue(accountId);

  Future<void> fullSync(String accountId, {String? familyId}) =>
      _engine.fullSync(accountId, familyId: familyId);

  void _onEngineChanged() => notifyListeners();

  @override
  void dispose() {
    _engine.removeListener(_onEngineChanged);
    super.dispose();
  }
}
