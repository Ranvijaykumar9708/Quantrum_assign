import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize timezone data
    tz.initializeTimeZones();
    
    // Get the device's current timezone
    final deviceTimeZone = DateTime.now().timeZoneName;
    print('Device timezone: $deviceTimeZone');
    
    // Set the local timezone to the device's timezone
    tz.setLocalLocation(tz.getLocation(deviceTimeZone));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification clicked: ${response.payload}');
      },
    );

    await createNotificationChannel();
  }

  Future<void> createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'task_reminder_channel',
      'Task Reminders',
      description: 'Notifications for task reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> scheduleTaskNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final now = DateTime.now();
    final local = tz.local;
    
    // Convert scheduled date to local timezone
    final scheduledTZ = tz.TZDateTime.from(scheduledDate, local);
    final nowTZ = tz.TZDateTime.from(now, local);

    print('\n=== Notification Scheduling Debug ===');
    print('Task ID: $id');
    print('Title: $title');
    print('Body: $body');
    print('Device Timezone: ${local.name}');
    print('Scheduled Date (UTC): ${scheduledDate.toUtc()}');
    print('Scheduled Date (Local): $scheduledDate');
    print('Scheduled TZ: $scheduledTZ');
    print('Current Time (UTC): ${now.toUtc()}');
    print('Current Time (Local): $now');
    print('Current TZ: $nowTZ');
    print('Time Difference: ${scheduledTZ.difference(nowTZ).inMinutes} minutes');

    // For testing: If the scheduled time is in the future, schedule it for 1 minute from now
    if (scheduledTZ.isAfter(nowTZ.add(const Duration(days: 1)))) {
      print('Warning: Scheduled time is more than 1 day in the future');
      print('For testing purposes, scheduling for 1 minute from now');
      final testTime = nowTZ.add(const Duration(minutes: 1));
      await _scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledTZ: testTime,
      );
      return;
    }

    if (scheduledTZ.isBefore(nowTZ)) {
      print('Error: Cannot schedule notification in the past');
      return;
    }

    await _scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledTZ: scheduledTZ,
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTZ,
  }) async {
    try {
      await cancelNotification(id);
      
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZ,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminder_channel',
            'Task Reminders',
            channelDescription: 'Notifications for task reminders',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            enableLights: true,
            playSound: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.reminder,
            ongoing: false,
            autoCancel: true,
            showWhen: true,
            color: Colors.blue,
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            actions: [
              const AndroidNotificationAction('view', 'View Task'),
              const AndroidNotificationAction('dismiss', 'Dismiss'),
            ],
            styleInformation: BigTextStyleInformation(body),
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
        uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
      );

      final pendingNotifications = await flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      
      print('\nPending notifications:');
      for (var notification in pendingNotifications) {
        print('ID: ${notification.id}, Title: ${notification.title}');
      }
      
      print('\nNotification scheduled successfully!');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}