import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'firestore_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> initialize() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
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

        final eligDoc =
            await db.collection('eligibility').doc(donorId).get();
        if (eligDoc.exists) {
          final data = eligDoc.data()!;
          if (data['isPermanentlyIneligible'] == true) continue;
          final nextDate =
              (data['nextEligibleDate'] as Timestamp?)?.toDate();
          if (nextDate != null && nextDate.isAfter(DateTime.now())) continue;
        }

        final fcmToken = donorDoc.data()['fcmToken'] as String?;
        if (fcmToken == null) continue;

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

  Future<void> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    const cloudFunctionUrl =
        'https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/sendNotification';
    try {
      await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'title': title,
          'body': body,
          'data': data,
        }),
      );
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
