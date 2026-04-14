import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

/// Кэш контента для гостевой страницы "Абитуриенту":
/// специальности и программы обучения.
class GuestApplicantContentCache {
  GuestApplicantContentCache._();

  static const _specialtiesKey = 'guest_applicant_specialties_v1';
  static const _educationKey = 'guest_applicant_education_v1';

  static Future<List<SpecialtyItem>?> readSpecialties() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_specialtiesKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) return null;
    try {
      return decoded
          .whereType<Map>()
          .map((e) => SpecialtyItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveSpecialties(List<SpecialtyItem> rows) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(rows.map((e) => e.toJson()).toList());
    await prefs.setString(_specialtiesKey, raw);
  }

  static Future<List<EducationProgramItem>?> readEducationPrograms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_educationKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) return null;
    try {
      return decoded
          .whereType<Map>()
          .map((e) => EducationProgramItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveEducationPrograms(List<EducationProgramItem> rows) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(rows.map((e) => e.toJson()).toList());
    await prefs.setString(_educationKey, raw);
  }
}
