import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// BACKGROUND MESSAGE HANDLER
// ---------------------------------------------------------------------------
// This must be a top-level function annotated with @pragma('vm:entry-point')
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to access Firebase services here, call await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

// ---------------------------------------------------------------------------
// NOTIFICATION SERVICE
// ---------------------------------------------------------------------------
class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // ⚠️ FCM AUTHORIZATION ⚠️
  // If using the Legacy HTTP API, provide your Server Key like: 'key=AIzaSyYOUR_SERVER_KEY...'
  // If using the HTTP v1 API, you must dynamically generate an OAuth2 Bearer Token.
  // Note: Storing server keys on client devices is a security risk. For production apps, 
  // Google recommends using a backend server or Cloud Functions to send notifications.
  final String _authHeader = 'key=YOUR_FCM_SERVER_KEY_OR_BEARER_TOKEN_HERE';

  /// Initializes the service, requests permissions, and sets up local notification channels.
  Future<void> initialize() async {
    // 1. Request notification permissions (required for iOS & Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('User declined or has not accepted push notification permissions.');
      return;
    }

    // 2. Initialize Flutter Local Notifications for foreground display
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    
    await _localNotifications.initialize(initSettings);

    // 3. Register the top-level background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Listen for incoming messages while the app is in the FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
  }

  /// Displays a local notification banner when a message is received in the foreground.
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'eduvian_high_importance_channel', // High priority channel ID
        'EDUvian Notifications',             // Channel name
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
        notification.hashCode,
        notification.title,
        notification.body,
        platformDetails,
      );
    }
  }

  /// Generates a clean FCM topic string from the raw batch format.
  /// Example: '7DCSE.2' -> 'batch_7_CSE_2'
  String? _generateTopicFromBatch(String raw) {
    final upper = raw.trim().toUpperCase();

    // Regex Explanation:
    // ^(\d+)    -> Group 1: Matches semester numbers (e.g. 7)
    // [A-Z]     -> Ignores the single placeholder letter (e.g. 'D')
    // ([A-Z]+)  -> Group 2: Matches the department (e.g. CSE)
    // (?:\.(\d+))?$ -> Group 3: Optional section number after a dot (e.g. 2)
    final pattern = RegExp(r'^(\d+)[A-Z]([A-Z]+)(?:\.(\d+))?$');
    final match = pattern.firstMatch(upper);
    
    if (match == null) {
      debugPrint("Invalid batch string format: $raw");
      return null;
    }

    final semester = match.group(1)!;
    final department = match.group(2)!;
    final section = match.group(3);

    String topic = 'batch_${semester}_$department';
    if (section != null) {
      topic += '_$section';
    }

    return topic;
  }

  /// Parses the user's batch string and subscribes them to the generated topic.
  Future<void> subscribeToBatchTopic(String batchString) async {
    final topic = _generateTopicFromBatch(batchString);
    if (topic != null) {
      try {
        await _fcm.subscribeToTopic(topic);
        debugPrint("Successfully subscribed to topic: $topic");
      } catch (e) {
        debugPrint("Error subscribing to topic: $e");
      }
    }
  }
  
  /// Unsubscribes from a batch topic (e.g. when changing settings or logging out).
  Future<void> unsubscribeFromBatchTopic(String batchString) async {
    final topic = _generateTopicFromBatch(batchString);
    if (topic != null) {
      try {
        await _fcm.unsubscribeFromTopic(topic);
        debugPrint("Successfully unsubscribed from topic: $topic");
      } catch (e) {
        debugPrint("Error unsubscribing from topic: $e");
      }
    }
  }

  /// Sends a Push Notification directly to the FCM REST API from the app.
  /// Targets users subscribed to the specific [topic].
  Future<void> sendNotificationToTopic({
    required String title,
    required String body,
    required String topic,
  }) async {
    // For Legacy HTTP API. 
    // If using HTTP v1 API, use: 'https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send'
    const String endpoint = 'https://fcm.googleapis.com/fcm/send';

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _authHeader, 
        },
        body: jsonEncode({
          'to': '/topics/$topic', // The topic to send to
          'notification': {
            'title': title,
            'body': body,
            // 'sound': 'default' 
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'type': 'batch_update',
            'topic': topic,
          }
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Notification sent successfully to $topic');
      } else {
        debugPrint('Failed to send notification. Code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }
}
