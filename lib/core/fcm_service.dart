import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/routine.dart';
import 'auth_service.dart';

/// Request notification permissions and log the FCM token.
Future<void> setupFCM() async {
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
}

/// A provider that automatically manages the user's FCM topic subscription
/// based on their current academic info and authentication state.
final fcmSubscriptionProvider = Provider<void>((ref) {
  // We need to know if the user is logged in.
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value;
  
  // We need to know their current academic info (which drives the batch ID).
  final academicInfoAsync = ref.watch(academicInfoProvider);
  
  // Clean up function to run when the state changes
  ref.onDispose(() {
    // We don't unsubscribe on dispose because this provider lives as long as the app.
    // Unsubscribing is handled explicitly below when the batch ID changes.
  });

  if (user == null) {
    // If logged out, we should probably unsubscribe from the last known batch.
    _unsubscribeFromLastBatch();
    return;
  }

  academicInfoAsync.whenData((rawInfo) async {
    final batchId = batchIdFromRaw(rawInfo);
    if (batchId != null && batchId.isNotEmpty) {
      await _unsubscribeFromLastBatch();
      
      final topic = 'routine_$batchId';
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      
      // Save this as the last known batch so we can unsubscribe later
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_fcm_topic', topic);
    } else {
      await _unsubscribeFromLastBatch();
    }
  });
});

Future<void> _unsubscribeFromLastBatch() async {
  final prefs = await SharedPreferences.getInstance();
  final lastTopic = prefs.getString('last_fcm_topic');
  if (lastTopic != null && lastTopic.isNotEmpty) {
    await FirebaseMessaging.instance.unsubscribeFromTopic(lastTopic);
    await prefs.remove('last_fcm_topic');
  }
}
