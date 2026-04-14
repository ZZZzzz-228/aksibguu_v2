import 'package:flutter/material.dart';

class FavoriteSpecialtyStore {
  FavoriteSpecialtyStore._();
  static final FavoriteSpecialtyStore instance = FavoriteSpecialtyStore._();
  final ValueNotifier<Set<String>> favorites = ValueNotifier(<String>{});
  bool isFavorite(String id) => favorites.value.contains(id);
  void toggle(String id) {
    final next = Set<String>.from(favorites.value);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    favorites.value = next;
  }
}

class Specialty {
  final String id;
  final String title;
  final String shortTitle;
  final String code;
  final String description;
  final String duration;
  final String form;
  final IconData icon;
  final Color color;
  final String qualification;
  final String career;
  final String skills;
  final String salary;
  final String imagePath;
  const Specialty({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.code,
    required this.description,
    required this.duration,
    required this.form,
    required this.icon,
    required this.color,
    required this.qualification,
    required this.career,
    required this.skills,
    required this.salary,
    required this.imagePath,
  });
}

enum EducationFilter { additional, courses }

enum EducationType { additional, courses }

class EducationProgram {
  final EducationType type;
  final String title;
  final String description;
  final String duration;
  final String details;
  final IconData icon;
  final Color color;
  final String targetAudience;
  final String outcome;
  final String format;
  final String imagePath;
  const EducationProgram({
    required this.type,
    required this.title,
    required this.description,
    required this.duration,
    required this.details,
    required this.icon,
    required this.color,
    required this.targetAudience,
    required this.outcome,
    required this.format,
    required this.imagePath,
  });
}

String educationProgramTypeLabel(EducationType t) {
  switch (t) {
    case EducationType.additional:
      return 'Доп. образование';
    case EducationType.courses:
      return 'Курсы';
  }
}

class StoryData {
  final String title;
  final String content;
  final Color color;
  final String imagePath;
  final String date;
  final String time;
  final String location;
  final String schedule;
  StoryData({
    required this.title,
    required this.content,
    required this.color,
    required this.imagePath,
    required this.date,
    required this.time,
    required this.location,
    required this.schedule,
  });
}

class Partner {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String url;
  final String imagePath;
  const Partner({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.url,
    required this.imagePath,
  });
}
