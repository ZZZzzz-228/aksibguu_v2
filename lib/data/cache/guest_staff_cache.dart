import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

/// Кэш списка сотрудников для гостевой страницы контактов (работа без сети после первой успешной загрузки).
class GuestStaffCache {
  GuestStaffCache._();

  static const _key = 'guest_staff_list_v1';

  static Future<List<StaffMemberItem>?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) return null;
    try {
      return decoded
          .whereType<Map>()
          .map((e) => StaffMemberItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(List<StaffMemberItem> staff) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(staff.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
