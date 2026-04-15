import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_10y.dart' as tz;

/// Singleton service that manages scheduled parking-fee threshold notifications.
///
/// Usage:
///   1. Call [initialize] once at app startup (e.g. in main()).
///   2. Call [scheduleThresholdAlert] when a session with a threshold starts or
///      the threshold is changed.
///   3. Call [cancelThresholdAlert] when the session ends.
class ParkingAlertService {
  // ── Singleton ─────────────────────────────────────────────────────────────
  static final ParkingAlertService _instance = ParkingAlertService._internal();
  factory ParkingAlertService() => _instance;
  ParkingAlertService._internal();

  // ── Internals ─────────────────────────────────────────────────────────────
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const _channelId = 'parking_threshold_channel';
  static const _channelName = 'Parking Threshold Alerts';
  static const _channelDesc =
      'Alerts when your parking fee reaches the threshold you set.';

  // ── Public API ────────────────────────────────────────────────────────────

  /// Initialise the notification plugin and timezone database.
  /// Safe to call multiple times – subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // asked separately on first alert
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Create the Android notification channel up-front so it is ready before
    // the first notification fires.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
          ),
        );

    _initialized = true;
  }

  /// Schedule a notification that fires at [alertTime].
  ///
  /// If [alertTime] is already in the past the notification is shown
  /// immediately instead, so a threshold that was set on an already-expensive
  /// session still alerts the user without delay.
  ///
  /// Calling this again for the same [sessionId] automatically cancels the
  /// previous pending notification before scheduling the new one.
  Future<void> scheduleThresholdAlert({
    required String sessionId,
    required String? carparkName,
    required double threshold,
    required DateTime alertTime,
  }) async {
    await initialize();
    await _requestPermissionsIfNeeded();

    final id = _notificationId(sessionId);
    await _plugin.cancel(id); // replace any existing alert for this session

    final locationLabel = carparkName ?? 'Your parking session';
    const title = 'Parking Fee Threshold Reached';
    final body =
        '$locationLabel has reached your \$${threshold.toStringAsFixed(2)} fee threshold.';

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Parking fee alert',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    if (alertTime.isBefore(DateTime.now())) {
      // Threshold already exceeded — fire immediately.
      await _plugin.show(id, title, body, notificationDetails);
    } else {
      // Schedule for the exact moment the threshold will be exceeded.
      final scheduledTime = tz.TZDateTime.from(alertTime, tz.local);
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Cancel any pending threshold alert for [sessionId].
  Future<void> cancelThresholdAlert(String sessionId) async {
    if (!_initialized) return;
    await _plugin.cancel(_notificationId(sessionId));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Derive a stable non-negative 32-bit notification ID from a session UUID.
  int _notificationId(String sessionId) => sessionId.hashCode & 0x7FFFFFFF;

  Future<void> _requestPermissionsIfNeeded() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }
}
