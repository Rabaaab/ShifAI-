import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' show ClientException;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';

class CoachingProvider extends ChangeNotifier {
  CoachingProvider({this.client, Connectivity? connectivity}) {
    unawaited(_loadForAccount(null));
    if (client != null) {
      _connectivitySubscription = (connectivity ?? Connectivity())
          .onConnectivityChanged
          .listen((results) {
            if (results.any((result) => result != ConnectivityResult.none)) {
              unawaited(_syncIfAvailable());
            }
          });
    }
  }

  final SupabaseClient? client;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Map<String, _CompletionEntry> _entries = {};
  String? _accountId;
  String? _syncError;
  bool _accountInitialized = false;
  bool _syncing = false;
  bool _syncAgain = false;
  int _loadGeneration = 0;

  String? get syncError => _syncError;

  bool isCompleted(String tipId) {
    final key = _entryKey(_today, tipId);
    return _entries[key]?.completed ?? false;
  }

  void setAccount(String? userId) {
    if (_accountInitialized && userId == _accountId) return;
    _accountInitialized = true;
    _accountId = userId;
    unawaited(_loadForAccount(userId));
  }

  Future<void> toggle(String tipId) async {
    final key = _entryKey(_today, tipId);
    final current = _entries[key]?.completed ?? false;
    _entries[key] = _CompletionEntry(
      date: _today,
      tipId: tipId,
      completed: !current,
      updatedAt: DateTime.now().toUtc(),
    );
    await _saveLocal();
    notifyListeners();
    await _syncIfAvailable();
  }

  void clearSyncError() {
    _syncError = null;
    notifyListeners();
  }

  Future<void> _loadForAccount(String? userId) async {
    final generation = ++_loadGeneration;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey(userId));
    final decoded = raw == null ? <String, dynamic>{} : jsonDecode(raw);
    if (generation != _loadGeneration) return;
    _entries = {
      for (final entry in (decoded as Map<String, dynamic>).entries)
        entry.key: _CompletionEntry.fromJson(
          entry.value as Map<String, dynamic>,
        ),
    };
    notifyListeners();
    if (userId != null) await _syncIfAvailable();
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey(_accountId),
      jsonEncode({
        for (final entry in _entries.entries) entry.key: entry.value.toJson(),
      }),
    );
  }

  Future<void> _syncIfAvailable() async {
    final syncClient = client;
    if (_accountId == null || syncClient == null) return;
    if (_syncing) {
      _syncAgain = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _syncAgain = false;
        final userId = _accountId;
        if (userId == null) return;
        await _syncOnce(userId, syncClient);
      } while (_syncAgain && _accountId != null);
    } finally {
      _syncing = false;
    }
  }

  Future<void> _syncOnce(String userId, SupabaseClient client) async {
    _syncError = null;
    notifyListeners();
    try {
      final response = await client
          .from('coaching_completions')
          .select()
          .eq('user_id', userId);
      final remote = (response as List<dynamic>)
          .map(
            (row) =>
                _CompletionEntry.fromCloudJson(row as Map<String, dynamic>),
          )
          .toList();
      final remoteById = {for (final entry in remote) entry.key: entry};
      final merged = <String, _CompletionEntry>{};
      final uploads = <_CompletionEntry>[];

      for (final local in _entries.values) {
        final cloud = remoteById[local.key];
        if (cloud == null || local.updatedAt.isAfter(cloud.updatedAt)) {
          merged[local.key] = local;
          uploads.add(local);
        } else {
          merged[local.key] = cloud;
        }
      }
      for (final cloud in remote) {
        if (!_entries.containsKey(cloud.key)) merged[cloud.key] = cloud;
      }
      if (_accountId != userId) return;
      if (uploads.isNotEmpty) {
        await client
            .from('coaching_completions')
            .upsert(
              uploads.map((entry) => entry.toCloudJson(userId)).toList(),
              onConflict: 'user_id,completion_date,tip_id',
            );
      }
      _entries = merged;
      await _saveLocal();
    } on PostgrestException catch (error) {
      if (_accountId == userId) {
        _syncError = 'Coaching sync failed: {message}'.trf({
          'message': error.message,
        });
      }
    } on ClientException {
      if (_accountId == userId) {
        _syncError = 'Offline. Coaching updates are saved on this device.'.tr;
      }
    } on TimeoutException {
      if (_accountId == userId) {
        _syncError =
            'Coaching sync timed out. Updates will retry when online.'.tr;
      }
    } finally {
      if (_accountId == userId) notifyListeners();
    }
  }

  String get _today => DateTime.now().toIso8601String().substring(0, 10);

  String _storageKey(String? userId) =>
      'shifai_coaching_state_${userId ?? 'guest'}';

  String _entryKey(String date, String tipId) => '$date|$tipId';

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

class _CompletionEntry {
  const _CompletionEntry({
    required this.date,
    required this.tipId,
    required this.completed,
    required this.updatedAt,
  });

  final String date;
  final String tipId;
  final bool completed;
  final DateTime updatedAt;

  String get key => '$date|$tipId';

  Map<String, dynamic> toJson() => {
    'date': date,
    'tipId': tipId,
    'completed': completed,
    'updatedAt': updatedAt.toIso8601String(),
  };

  Map<String, dynamic> toCloudJson(String userId) => {
    'user_id': userId,
    'completion_date': date,
    'tip_id': tipId,
    'completed': completed,
    'updated_at': updatedAt.toIso8601String(),
  };

  factory _CompletionEntry.fromJson(Map<String, dynamic> json) =>
      _CompletionEntry(
        date: json['date'] as String,
        tipId: json['tipId'] as String,
        completed: json['completed'] as bool,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  factory _CompletionEntry.fromCloudJson(Map<String, dynamic> json) =>
      _CompletionEntry(
        date: json['completion_date'] as String,
        tipId: json['tip_id'] as String,
        completed: json['completed'] as bool,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
