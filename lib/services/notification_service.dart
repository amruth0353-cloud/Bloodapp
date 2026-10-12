import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import '../models/models.dart';
import 'firestore_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  AutoRefreshingAuthClient? _authClient;

  Future<void> initialize() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'blood_requests_channel',
      'Blood Donation Requests',
      description: 'Emergency blood donation alerts and notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: initializationSettingsAndroid),
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    final notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'blood_requests_channel',
            'Blood Donation Requests',
            channelDescription:
                'Emergency blood donation alerts and notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  }

  Future<AutoRefreshingAuthClient?> _getAuthClient() async {
    if (_authClient != null) {
      return _authClient;
    }
    try {
      final jsonStr = await rootBundle.loadString('assets/service_account.json');
      final accountCredentials =
          ServiceAccountCredentials.fromJson(jsonDecode(jsonStr));
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      _authClient = await clientViaServiceAccount(accountCredentials, scopes);
      return _authClient;
    } catch (e) {
      debugPrint('Error getting FCM v1 auth client: $e');
      return null;
    }
  }

  Future<void> sendBloodRequestToEligibleDonors({
    required String bloodType,
    required String requestId,
    required String urgencyLevel,
    required String hospitalName,
    required String adminId,
  }) async {
    final db = FirebaseFirestore.instance;
    final compatible = _getCompatibleBloodTypes(bloodType);

    for (final bt in compatible) {
      final donorsSnap = await db
          .collection('users')
          .where('role', isEqualTo: 'donor')
          .where('bloodType', isEqualTo: bt)
          .get();

      for (final donorDoc in donorsSnap.docs) {
        final donorId = donorDoc.id;
        final donor = UserModel.fromFirestore(donorDoc);
        
        if (!donor.isTimeEligible) continue;

        final fcmToken = donor.fcmToken;

        await _firestoreService.saveNotification(
          donorId,
          AppNotification(
            id: '',
            title: urgencyLevel == 'critical'
                ? 'Critical Blood Request!'
                : 'Blood Donation Needed',
            body:
                '$bloodType blood needed at $hospitalName. Can you help?',
            type: 'blood_request',
            data: {
              'requestId': requestId,
              'bloodType': bloodType,
              'urgencyLevel': urgencyLevel,
            },
            isRead: false,
            createdAt: DateTime.now(),
          ),
        );

        if (fcmToken != null && fcmToken.isNotEmpty) {
          await _sendFCMNotification(
            token: fcmToken,
            title: urgencyLevel == 'critical'
                ? 'Critical: $bloodType Blood Needed!'
                : 'Blood Donation Request',
            body: '$bloodType blood urgently needed at $hospitalName',
            data: {
              'type': 'blood_request',
              'requestId': requestId,
              'bloodType': bloodType,
              'urgencyLevel': urgencyLevel,
            },
          );
        }
      }
    }
  }

  Future<void> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    try {
      final client = await _getAuthClient();
      if (client == null) {
        debugPrint('FCM client is null, could not send notification');
        return;
      }

      final jsonStr = await rootBundle.loadString('assets/service_account.json');
      final decoded = jsonDecode(jsonStr);
      final projectId = decoded['project_id'] ?? 'bloodconnect-e0c1a';

      final url = Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

      final payload = {
        'message': {
          'token': token,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data,
          'android': {
            'priority': 'HIGH',
            'notification': {
              'channel_id': 'blood_requests_channel',
              'priority': 'HIGH',
              'default_sound': true,
              'default_vibrate_timings': true,
              'notification_priority': 'PRIORITY_MAX',
            },
          },
        },
      };

      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint('FCM v1 response: ${response.statusCode} - ${response.body}');
    } catch (e) {
      debugPrint('FCM send error: $e');
    }
  }

  List<String> _getCompatibleBloodTypes(String requestedType) {
    const donors = {
      'A+': ['A+', 'A-', 'O+', 'O-'],
      'A-': ['A-', 'O-'],
      'B+': ['B+', 'B-', 'O+', 'O-'],
      'B-': ['B-', 'O-'],
      'AB+': ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
      'AB-': ['A-', 'B-', 'AB-', 'O-'],
      'O+': ['O+', 'O-'],
      'O-': ['O-'],
    };
    return donors[requestedType] ?? [requestedType];
  }

  Future<String?> getToken() => _fcm.getToken();
}
