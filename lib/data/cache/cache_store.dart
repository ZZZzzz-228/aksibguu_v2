import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CacheStore {
  CacheStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<CacheStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return CacheStore(prefs);
  }

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  Future<void> setJson(String key, Object value) => setString(key, jsonEncode(value));

  Map<String, dynamic>? getJsonMap(String key) {
    final raw = getString(key);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  List<dynamic>? getJsonList(String key) {
    final raw = getString(key);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    return decoded is List ? decoded : null;
  }
}

