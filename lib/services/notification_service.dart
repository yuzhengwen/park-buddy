import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:park_buddy/screens/parking_session_detail_screen.dart';
import 'package:park_buddy/services/parking_service.dart';
import 'package:timezone/data/latest_10y.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:park_buddy/models/parking_session.dart';

/// Service class for handling local notifications.
class NotifService extends ChangeNotifier {
  static const iconPath = 'ic_stat_directions_car';

  final _plugin = FlutterLocalNotificationsPlugin();
  final _navigatorKey = GlobalKey<NavigatorState>();

  List<RateNotification> _notifs = const [];

  /// Pending rate alerts registered in the system.
  List<RateNotification> get pendingRateAlerts => _notifs;

  /// Global key for navigating to session details screen from notification
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  /// Initialise notification service. Call this at the start of the app.
  Future<void> initialize() async {
    // Initialise time zone info
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Singapore'));

    // Initialise the notification plugin
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(iconPath),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) _onTapNotif(response.payload!);

        _updatePendingRateAlerts();
        notifyListeners();
      },
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    // Get data from the notification that launched the app
    final details = await _plugin.getNotificationAppLaunchDetails();
    final payload = details?.notificationResponse?.payload;

    if (payload != null) _onTapNotif(payload);

    _updatePendingRateAlerts();
    notifyListeners();
  }

  Future<void> _onTapNotif(String payload) async {
    // Parse parking session from notification data
    final sessionFromNotif = RateNotification.fromJson(payload).session;

    // Get corresponding parking session from database
    final sessionFromDb = await ParkingService()
        .fetchSessionById(sessionFromNotif.sessionId);

    final session = sessionFromDb ?? sessionFromNotif.toMap();

    // Navigate to parking session details screen
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) {
          return ParkingSessionDetailScreen(session: session);
        },
      ),
    );
  }

  /// Schedule a parking rate alert notification.
  Future<RateNotification> scheduleRateAlert({
    required ParkingSession session,
    required tz.TZDateTime scheduledTime,
  }) async {

    final notif = RateNotification(
      session: session,
      scheduledTime: scheduledTime,
    );

    await _plugin.zonedSchedule(
      id: notif.notifId,
      title: notif.notifTitle,
      body: notif.notifBody,
      scheduledDate: notif.scheduledTime,
      notificationDetails: RateNotification.notifDetails,
      androidScheduleMode: .exactAllowWhileIdle,
      payload: notif.toJson(),
    );

    await _updatePendingRateAlerts();
    notifyListeners();

    return notif;
  }

  /// Cancel the rate alert notification.
  Future<void> cancelRateAlert(RateNotification notif) async {
    await _plugin.cancel(id: notif.notifId);
    await _updatePendingRateAlerts();
    notifyListeners();
  }

  /// Get all the rate alerts scheduled on the system.
  Future<void> _updatePendingRateAlerts() async {
    final alerts = await _plugin.pendingNotificationRequests();
    _notifs = alerts
        .map((notif) => notif.payload)
        .whereType<String>()
        .map(RateNotification.fromJson)
        .toList();
  }
}

/// Stores persistent data for a scheduled rate notification.
class RateNotification {
  static const notifDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'rate_alert',
      'Parking Rate Alerts',
      channelDescription: 'Used for user-specified parking rate alerts once the parking fees exceed a certain threshold.',
      priority: .high,
      importance: .high,
    ),
  );

  late final ParkingSession session;
  late final tz.TZDateTime scheduledTime;

  int get notifId => session.sessionId.hashCode;
  String get notifTitle => session.sessionName ?? '(unnamed session)';
  String get notifBody => session.rateThreshold != null
      ? 'Parking session exceeded \$${session.rateThreshold!.toStringAsFixed(2)}'
      : 'Invalid notification content';

  RateNotification({required this.session, required this.scheduledTime});

  RateNotification.fromJson(String json) {
    final Map<String, dynamic> map = jsonDecode(json);
    scheduledTime = tz.TZDateTime.parse(
      tz.local,
      map['scheduledTime'] as String,
    );
    session = ParkingSession.fromMap(map['session'] as Map<String, dynamic>);
  }

  String toJson() => jsonEncode({
    'scheduledTime': scheduledTime.toIso8601String(),
    'session': session.toMap(),
  });
}
