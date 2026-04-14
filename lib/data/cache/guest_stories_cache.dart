import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

/// Кэш историй/мероприятий для гостевой страницы.
class GuestStoriesCache {
  GuestStoriesCache._();

  static const _key = 'guest_stories_list_v1';

  static Future<List<StoryItem>?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) return null;
    try {
      return decoded
          .whereType<Map>()
          .map((e) => StoryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(List<StoryItem> stories) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(stories.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
