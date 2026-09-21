import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lab_record.dart';

/// On-device persistence for lab records. No data leaves the phone.
class LabStorageService {
  static const _key = 'shifai_lab_records';

  Future<List<LabRecord>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    final records = list
        .map((e) => LabRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    records.sort((a, b) => a.date.compareTo(b.date));
    return records;
  }

  Future<void> saveAll(List<LabRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  Future<void> add(LabRecord record) async {
    final records = await loadAll();
    records.add(record);
    await saveAll(records);
  }

  Future<void> delete(String id) async {
    final records = await loadAll();
    records.removeWhere((r) => r.id == id);
    await saveAll(records);
  }
}
