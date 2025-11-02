import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart'; // <-- important pour TimeOfDay

class StorageService {
  static const String _pdfPathKey = 'pdf_path';
  static const String _pdfNameKey = 'pdf_name';
  static const String _totalPagesKey = 'total_pages';
  static const String _numberOfDaysKey = 'number_of_days';
  static const String _completedDaysKey = 'completed_days';
  static const String _planningConfirmedKey = 'planning_confirmed';

  // Sauvegarder le document PDF
  Future<void> savePdfDocument({
    required String path,
    required String name,
    required int totalPages,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pdfPathKey, path);
    await prefs.setString(_pdfNameKey, name);
    await prefs.setInt(_totalPagesKey, totalPages);
  }

  // Charger le document PDF
  Future<Map<String, dynamic>?> loadPdfDocument() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_pdfPathKey);
    final name = prefs.getString(_pdfNameKey);
    final totalPages = prefs.getInt(_totalPagesKey);

    if (path == null || name == null || totalPages == null) {
      return null;
    }

    return {
      'path': path,
      'name': name,
      'totalPages': totalPages,
    };
  }

  // Sauvegarder le nombre de jours
  Future<void> saveNumberOfDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_numberOfDaysKey, days);
  }

  // Charger le nombre de jours
  Future<int> loadNumberOfDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_numberOfDaysKey) ?? 7;
  }

  // Sauvegarder les jours complétés
  Future<void> saveCompletedDays(Set<int> days) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(days.toList());
    await prefs.setString(_completedDaysKey, jsonString);
  }

  // Charger les jours complétés
  Future<Set<int>> loadCompletedDays() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_completedDaysKey);
    
    if (jsonString == null) return {};
    
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((e) => e as int).toSet();
  }

  // Sauvegarder l'heure de notification
  Future<void> saveNotificationTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_hour', time.hour);
    await prefs.setInt('notification_minute', time.minute);
  }

  // Charger l'heure de notification
  Future<TimeOfDay> loadNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('notification_hour') ?? 9;
    final minute = prefs.getInt('notification_minute') ?? 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

  // Sauvegarder l'état de confirmation du planning
  Future<void> savePlanningConfirmed(bool confirmed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_planningConfirmedKey, confirmed);
  }

  // Charger l'état de confirmation du planning
  Future<bool> loadPlanningConfirmed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_planningConfirmedKey) ?? false;
  }

  // Effacer toutes les données
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pdfPathKey);
    await prefs.remove(_pdfNameKey);
    await prefs.remove(_totalPagesKey);
    await prefs.remove(_numberOfDaysKey);
    await prefs.remove(_completedDaysKey);
    await prefs.remove('notification_hour');
    await prefs.remove('notification_minute');
    await prefs.remove(_planningConfirmedKey);
  }
}

// Objet de stockage interne
class StoredTimeOfDay {
  final int hour;
  final int minute;

  StoredTimeOfDay({required this.hour, required this.minute});

  factory StoredTimeOfDay.fromTimeOfDay(TimeOfDay time) {
    return StoredTimeOfDay(hour: time.hour, minute: time.minute);
  }

  TimeOfDay toTimeOfDay() {
    return TimeOfDay(hour: hour, minute: minute);
  }
}
