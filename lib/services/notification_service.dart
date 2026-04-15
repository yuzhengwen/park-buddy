import 'dart:convert';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:park_buddy/models/parking_session.dart';

const iconPath = 'ic_stat_directions_car';
const channelId = 'rate_alert';
const channelName = 'Parking Rate Alerts';
const channelDesc = 'Used for user-specified parking rate alerts once the parking fees exceed a certain threshold.';

const notifDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    channelId, channelName,
    channelDescription: channelDesc,
    priority: .high,
    importance: .high,
  ),
);

final _plugin = FlutterLocalNotificationsPlugin();

/// Initialises notification services. Call this at the start of the app.
/// [onTapNotif] is the callback invoked when the notification is tapped by the
/// user.
Future<void> startService({
  void Function(String payload)? onTapNotif,
}) async {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Singapore'));

  // Initialise the notification plugin
  await _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings(iconPath),
    ),
    onDidReceiveNotificationResponse: (response) {
      if (response.payload != null) {
        onTapNotif?.call(response.payload!);
      }
    },
  );

  // Get data from the notification that launched the app
  final details = await _plugin.getNotificationAppLaunchDetails();
  final payload = details?.notificationResponse?.payload;

  if (payload != null) onTapNotif?.call(payload);
}

Future<void> scheduleRateAlert(ParkingSession session, tz.TZDateTime time) async {
  final name = session.sessionName;
  final threshold = session.rateThreshold?.toStringAsFixed(2);

  final titleText = name ?? 'Error';
  final bodyText = threshold != null
      ? 'Parking session exceeded \$$threshold'
      : 'Invalid notification content';

  await _plugin.zonedSchedule(
    id: 0,
    title: titleText,
    body: bodyText,
    scheduledDate: time,
    notificationDetails: notifDetails,
    androidScheduleMode: .exactAllowWhileIdle,
    payload: jsonEncode(session.toMap()),
  );
}
