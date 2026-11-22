import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:uuid/uuid.dart';

import '../l10n/l10n.dart';
import '../models/lab_record.dart';
import '../services/lab_cloud_service.dart';
import '../services/lab_storage_service.dart';

class LabRecordsProvider extends ChangeNotifier {
  LabRecordsProvider({
    LabStorageService? storage,
    this.cloud,
    Connectivity? connectivity,
  }) : _storage = storage ?? LabStorageService() {
    _activeLoad = _loadForAccount(null);
    unawaited(_activeLoad);
    if (cloud != null) {
      _connectivitySubscription = (connectivity ?? Connectivity())
          .onConnectivityChanged
          .listen((results) {
            if (results.any((result) => result != ConnectivityResult.none)) {
              unawaited(_syncIfAvailable());
            }
          });
    }
  }

  final LabStorageService _storage;
  final LabCloudService? cloud;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  List<LabRecord> _allRecords = [];
  bool _loading = true;
  bool _syncing = false;
  bool _accountInitialized = false;
  String? _accountId;
  String? _syncError;
  int _loadGeneration = 0;
  late Future<void> _activeLoad;
  Future<void> _syncQueue = Future<void>.value();

  List<LabRecord> get records => List.unmodifiable(
    _allRecords.where((record) => record.deletedAt == null),
  );
  bool get loading => _loading;
  bool get syncing => _syncing;
  String? get syncError => _syncError;
  String? get accountId => _accountId;

  LabRecord? get latest => records.isEmpty ? null : records.last;

  void setAccount(String? userId) {
    if (_accountInitialized && userId == _accountId) return;
    _accountInitialized = true;
    _accountId = userId;
    _syncing = false;
    _syncError = null;
    _activeLoad = _loadForAccount(userId);
    unawaited(_activeLoad);
  }

  void clearSyncError() {
    _syncError = null;
    notifyListeners();
  }

  Future<void> _loadForAccount(String? userId) async {
    final generation = ++_loadGeneration;
    _loading = true;
    notifyListeners();
    final loaded = await _storage.loadAll(userId: userId);
    if (generation != _loadGeneration) return;
    _allRecords = loaded;
    _loading = false;
    notifyListeners();
    if (userId != null) await _syncIfAvailable();
  }

  Future<void> addRecord(LabRecord record) async {
    _allRecords.removeWhere((existing) => existing.id == record.id);
    _allRecords.add(record);
    _allRecords.sort((a, b) => a.date.compareTo(b.date));
    await _storage.saveAll(_allRecords, userId: _accountId);
    notifyListeners();
    await _syncIfAvailable();
  }

  Future<int> guestRecordCount() async {
    final guestRecords = await _storage.loadAll();
    return guestRecords.where((record) => record.deletedAt == null).length;
  }

  Future<int> importGuestRecordsToAccount() async {
    final userId = _accountId;
    if (userId == null) {
      throw StateError('Sign in before importing local results.'.tr);
    }
    await _activeLoad;
    final guestRecords = await _storage.loadAll();
    final accountRecords = await _storage.loadAll(userId: userId);
    if (_accountId != userId) return 0;

    final existingIds = accountRecords.map((record) => record.id).toSet();
    const uuid = Uuid();
    final imported = <LabRecord>[];
    for (final record in guestRecords) {
      if (record.deletedAt != null) continue;
      final id = uuid.v5(Namespace.url.value, 'shifai:$userId:${record.id}');
      if (existingIds.contains(id)) continue;
      imported.add(
        LabRecord(
          id: id,
          date: record.date,
          fastingGlucoseMgdl: record.fastingGlucoseMgdl,
          fastingInsulinUiuml: record.fastingInsulinUiuml,
          hba1cPercent: record.hba1cPercent,
          triglyceridesMgdl: record.triglyceridesMgdl,
          hdlMgdl: record.hdlMgdl,
          notes: record.notes,
          otherMarkers: record.otherMarkers,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }
    if (imported.isEmpty) return 0;

    accountRecords.addAll(imported);
    accountRecords.sort((a, b) => a.date.compareTo(b.date));
    _allRecords = accountRecords;
    await _storage.saveAll(accountRecords, userId: userId);
    notifyListeners();
    await _syncIfAvailable();
    return imported.length;
  }

  Future<void> deleteRecord(String id) async {
    final index = _allRecords.indexWhere(
      (record) => record.id == id && record.deletedAt == null,
    );
    if (index == -1) return;
    final record = _allRecords[index];
    final now = DateTime.now();
    _allRecords[index] = LabRecord(
      id: record.id,
      date: record.date,
      fastingGlucoseMgdl: record.fastingGlucoseMgdl,
      fastingInsulinUiuml: record.fastingInsulinUiuml,
      hba1cPercent: record.hba1cPercent,
      triglyceridesMgdl: record.triglyceridesMgdl,
      hdlMgdl: record.hdlMgdl,
      notes: record.notes,
      otherMarkers: record.otherMarkers,
      updatedAt: now,
      deletedAt: now,
    );
    await _storage.saveAll(_allRecords, userId: _accountId);
    notifyListeners();
    await _syncIfAvailable();
  }

  Future<void> _syncIfAvailable() {
    final userId = _accountId;
    final cloud = this.cloud;
    if (userId == null || cloud == null) return Future<void>.value();
    final previous = _syncQueue;
    final completed = Completer<void>();
    _syncQueue = completed.future;
    return _runQueuedSync(previous, userId, cloud, completed);
  }

  Future<void> _runQueuedSync(
    Future<void> previous,
    String userId,
    LabCloudService cloud,
    Completer<void> completed,
  ) async {
    try {
      await previous;
      await _sync(userId, cloud);
    } finally {
      completed.complete();
    }
  }

  Future<void> _sync(String userId, LabCloudService cloud) async {
    _syncing = true;
    _syncError = null;
    notifyListeners();
    try {
      final merged = await cloud.syncRecords(userId, List.of(_allRecords));
      if (_accountId != userId) return;
      _allRecords = LabSyncPlan.resolve(
        local: List.of(_allRecords),
        remote: merged,
      ).merged;
      await _storage.saveAll(_allRecords, userId: userId);
    } on CloudSyncException catch (error) {
      if (_accountId == userId) _syncError = error.message;
    } on ClientException {
      if (_accountId == userId) {
        _syncError = 'Offline. Changes are saved on this device and will sync when reconnected.'
            .tr;
      }
    } on TimeoutException {
      if (_accountId == userId) {
        _syncError = 'Cloud sync timed out. Changes are saved on this device and will retry.'
            .tr;
      }
    } on PostgrestException catch (error) {
      if (_accountId == userId) {
        _syncError = 'Cloud sync failed: {message}'.trf({
          'message': error.message,
        });
      }
    } finally {
      if (_accountId == userId) {
        _syncing = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
