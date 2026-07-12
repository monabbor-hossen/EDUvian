import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:shared_preferences/shared_preferences.dart';

import 'academic_info_service.dart';

// ---------------------------------------------------------------------------
// BACKGROUND MESSAGE HANDLER
// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

// ---------------------------------------------------------------------------
// NOTIFICATION SERVICE (FCM HTTP v1 API)
// ---------------------------------------------------------------------------
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // The path to your service account JSON file in the assets folder.
  // ⚠️ SECURITY WARNING: Shipping a Service Account JSON in a client app is a massive security risk. 
  // Anyone extracting the APK can get admin access to your Firebase project. 
  // For production, this token generation should happen on a secure backend.
  final String _serviceAccountJsonPath = 'assets/eduvian-9c08e-firebase-adminsdk-fbsvc-a70028ce91.json';
  
  // Your Firebase Project ID
  final String _projectId = 'eduvian-9c08e';

  /// Initializes the service, requests permissions, and sets up local notification channels.
  Future<void> initialize() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('User declined or has not accepted push notification permissions.');
      return;
    }

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    
    await _localNotifications.initialize(settings: initSettings);

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission(); // Request permissions on Android 13+

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'eduvian_high_importance_channel', // id
        'EDUvian Notifications', // name
        description: 'Used for important class and assignment updates.', // description
        importance: Importance.max,
      );
      await androidImplementation.createNotificationChannel(channel);
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Auto-subscribe to the topic on app startup if enabled
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notifications_enabled') ?? true;
      final info = await AcademicInfoService.getRawAcademicInfo() ?? '';
      if (enabled && info.isNotEmpty) {
        await subscribeToBatchTopic(info);
      }
      
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await subscribeToUserTopic(uid);
      }
    } catch (e) {
      debugPrint('Error on notification initialization auto-subscribe: $e');
    }
  }
  
  /// Subscribes to a unique user topic for direct messages
  Future<void> subscribeToUserTopic(String uid) async {
    try {
      await _fcm.subscribeToTopic('user_$uid').timeout(const Duration(seconds: 5));
      debugPrint("Subscribed to user topic: user_$uid");
    } catch (e) {
      debugPrint("Error subscribing to user topic user_$uid: $e");
    }
  }

  /// Generates a valid OAuth2 Access Token using the local Service Account JSON.
  Future<String?> _getAccessToken() async {
    try {
      final jsonString = await rootBundle.loadString(_serviceAccountJsonPath);
      final credentials = auth.ServiceAccountCredentials.fromJson(jsonString);
      
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      
      final client = await auth.clientViaServiceAccount(credentials, scopes);
      final token = client.credentials.accessToken.data;
      client.close();
      return token;
    } catch (e) {
      debugPrint('Error generating OAuth2 token: $e');
      return null;
    }
  }

  /// Displays a local notification banner when a message is received in the foreground.
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'eduvian_high_importance_channel', 
        'EDUvian Notifications',             
        channelDescription: 'Used for important class and assignment updates.',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      
      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      );

      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: platformDetails,
      );
    }
  }

  /// Generates a clean FCM topic string from the raw batch format.
  String? _generateTopicFromBatch(String raw, String shift) {
    final upper = raw.trim().toUpperCase();
    final pattern = RegExp(r'^(\d+)[A-Z]([A-Z]+)(?:\.(\d+))?$');
    final match = pattern.firstMatch(upper);
    
    if (match == null) return null;

    final semester = match.group(1)!;
    final department = match.group(2)!;
    final section = match.group(3);

    final prefix = shift == 'Evening' ? 'E_' : '';
    String topic = 'batch_$prefix${semester}_$department';
    if (section != null) topic += '_$section';

    return topic;
  }

  Future<void> subscribeToBatchTopic(String batchString, {String shift = 'Regular'}) async {
    final topic = _generateTopicFromBatch(batchString, shift);
    if (topic != null) {
      try {
        await _fcm.subscribeToTopic(topic).timeout(const Duration(seconds: 5));
        debugPrint("Successfully subscribed to FCM topic: $topic");
      } catch (e) {
        debugPrint("Error subscribing to FCM topic $topic: $e");
      }
    }
  }
  
  Future<void> unsubscribeFromBatchTopic(String batchString, {String shift = 'Regular'}) async {
    final topic = _generateTopicFromBatch(batchString, shift);
    if (topic != null) {
      try {
        await _fcm.unsubscribeFromTopic(topic).timeout(const Duration(seconds: 5));
        debugPrint("Successfully unsubscribed from FCM topic: $topic");
      } catch (e) {
        debugPrint("Error unsubscribing from FCM topic $topic: $e");
      }
    }
  }

  /// Builds and subscribes to the Official Class Group chat FCM topic.
  /// Topic format: `chat_official_{semester}_{department}_{section}_{shift}`
  /// e.g.: `chat_official_7_CSE_2_Evening`
  Future<void> subscribeToOfficialChatTopic({
    required int semester,
    required String department,
    int? section,
    required String shift,
  }) async {
    String topic = 'chat_official_${semester}_${department.toUpperCase()}';
    if (section != null) topic += '_$section';
    topic += '_${shift.replaceAll(' ', '_')}';
    try {
      await _fcm.subscribeToTopic(topic).timeout(const Duration(seconds: 5));
      debugPrint("Subscribed to official chat topic: $topic");
    } catch (e) {
      debugPrint("Error subscribing to official chat topic $topic: $e");
    }
  }

  /// Unsubscribes from the Official Class Group chat FCM topic.
  Future<void> unsubscribeFromOfficialChatTopic({
    required int semester,
    required String department,
    int? section,
    required String shift,
  }) async {
    String topic = 'chat_official_${semester}_${department.toUpperCase()}';
    if (section != null) topic += '_$section';
    topic += '_${shift.replaceAll(' ', '_')}';
    try {
      await _fcm.unsubscribeFromTopic(topic).timeout(const Duration(seconds: 5));
      debugPrint("Unsubscribed from official chat topic: $topic");
    } catch (e) {
      debugPrint("Error unsubscribing from official chat topic $topic: $e");
    }
  }

  /// Sends a Push Notification via the FCM HTTP v1 API.
  Future<void> sendNotificationToTopic({
    required String title,
    required String body,
    required String topicName,
  }) async {
    final token = await _getAccessToken();
    if (token == null) {
      debugPrint('Could not retrieve access token. Aborting push notification.');
      return;
    }

    final String endpoint = 'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', 
        },
        body: jsonEncode({
          'message': {
            'topic': topicName, 
            'notification': {
              'title': title,
              'body': body,
            },
            'android': {
              'notification': {
                'channel_id': 'eduvian_high_importance_channel',
              }
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound': 'default',
                }
              }
            },
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'type': 'batch_update',
              'topic': topicName,
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Notification sent successfully to $topicName');
      } else {
        debugPrint('Failed to send notification. Code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }
}
