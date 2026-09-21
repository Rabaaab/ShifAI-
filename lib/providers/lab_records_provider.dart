import 'package:flutter/foundation.dart';
import '../models/lab_record.dart';
import '../services/lab_storage_service.dart';

class LabRecordsProvider extends ChangeNotifier {
  final LabStorageService _storage = LabStorageService();

  List<LabRecord> _records = [];
  bool _loading = true;

  List<LabRecord> get records => List.unmodifiable(_records);
  bool get loading => _loading;

  LabRecord? get latest => _records.isEmpty ? null : _records.last;

  LabRecordsProvider() {
    _load();
  }

  Future<void> _load() async {
    _records = await _storage.loadAll();
    _loading = false;
    notifyListeners();
  }

  Future<void> addRecord(LabRecord record) async {
    await _storage.add(record);
    _records = await _storage.loadAll();
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    await _storage.delete(id);
    _records = await _storage.loadAll();
    notifyListeners();
  }
}
