import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Initialiser les notifications
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialiser les timezones
    tz.initializeTimeZones();

    // Configuration Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configuration iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Gérer le clic sur la notification
        debugPrint('Notification cliquée: ${details.payload}');
      },
    );

    _initialized = true;
  }

  // Demander les permissions (Android 13+)
  Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final iOS = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (iOS != null) {
      final granted = await iOS.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  // Programmer une notification quotidienne
  Future<void> scheduleDailyNotification({
    required int hour,
    required int minute,
    required int dayNumber,
    required int startPage,
    required int endPage,
  }) async {
    await initialize();

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Si l'heure est déjà passée aujourd'hui, programmer pour demain
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'daily_reading_channel',
      'Rappels de lecture',
      channelDescription: 'Notifications quotidiennes pour votre planning de lecture',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      dayNumber, // ID unique par jour
      '📚 Lecture du jour $dayNumber',
      'Il est temps de lire les pages $startPage à $endPage',
      tzScheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // uiLocalNotificationDateInterpretation:
      //     UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time, // Répéter quotidiennement
    );
  }

  // Programmer toutes les notifications pour le planning
  Future<void> scheduleAllNotifications({
    required int hour,
    required int minute,
    required List<Map<String, int>> dayPlans,
  }) async {
    // Annuler les anciennes notifications
    await cancelAllNotifications();

    // Programmer une notification pour chaque jour
    for (var plan in dayPlans) {
      await scheduleDailyNotification(
        hour: hour,
        minute: minute,
        dayNumber: plan['day']!,
        startPage: plan['startPage']!,
        endPage: plan['endPage']!,
      );
    }
  }

  // Annuler toutes les notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Annuler une notification spécifique
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Afficher une notification immédiate (pour test)
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'instant_channel',
      'Notifications instantanées',
      channelDescription: 'Notifications immédiates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      title,
      body,
      details,
    );
  }

  // Vérifier les notifications en attente
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}