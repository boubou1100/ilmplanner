import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ilmplanner/models/models.dart';
import 'package:ilmplanner/services/notification_service.dart';
import 'package:ilmplanner/services/storage_service.dart';

final storageServiceProvider = Provider((ref) => StorageService());
final notificationServiceProvider = Provider((ref) => NotificationService());

// Provider pour charger automatiquement les données sauvegardées
final autoLoadProvider = FutureProvider<void>((ref) async {
  final storage = ref.read(storageServiceProvider);

  // Charger le document PDF
  final pdfData = await storage.loadPdfDocument();
  if (pdfData != null) {
    ref.read(pdfDocumentProvider.notifier).state = PdfDocument(
      path: pdfData['path'],
      name: pdfData['name'],
      totalPages: pdfData['totalPages'],
    );
  }

  // Charger le nombre de jours
  final days = await storage.loadNumberOfDays();
  ref.read(numberOfDaysProvider.notifier).state = days;

  // Charger les jours complétés
  final completedDays = await storage.loadCompletedDays();
  ref.read(completedDaysProvider.notifier).state = completedDays;

  // Charger l'heure de notification
  final storedTime = await storage.loadNotificationTime();
  ref.read(notificationTimeProvider.notifier).state =
      TimeOfDay(hour: storedTime.hour, minute: storedTime.minute);
});

final pdfDocumentProvider = StateProvider<PdfDocument?>((ref) => null);
final numberOfDaysProvider = StateProvider<int>((ref) => 7);
final completedDaysProvider = StateProvider<Set<int>>((ref) => {});

// ✅ Le provider utilise TimeOfDay (Flutter)
final notificationTimeProvider = StateProvider<TimeOfDay>((ref) =>
  const TimeOfDay(hour: 9, minute: 0),
);

// ✅ Génération du plan
final readingPlanProvider = StateProvider<ReadingPlan?>((ref) {
  final document = ref.watch(pdfDocumentProvider);
  final numberOfDays = ref.watch(numberOfDaysProvider);

  if (document == null) return null;

  final pagesPerDay = (document.totalPages / numberOfDays).ceil();
  final dayPlans = <DayPlan>[];

  for (int i = 0; i < numberOfDays; i++) {
    final startPage = (i * pagesPerDay) + 1;
    final endPage = ((i + 1) * pagesPerDay).clamp(1, document.totalPages);

    if (startPage <= document.totalPages) {
      dayPlans.add(DayPlan(
        day: i + 1,
        startPage: startPage,
        endPage: endPage,
      ));
    }
  }

  return ReadingPlan(
    document: document,
    numberOfDays: numberOfDays,
    dayPlans: dayPlans,
  );
});
