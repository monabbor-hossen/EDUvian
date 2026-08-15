import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userOnlineProvider = StreamProvider.family<bool, String>((ref, userId) {
  if (userId.isEmpty) return Stream.value(false);
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return false;
    final data = snapshot.data();
    if (data == null) return false;
    
    final isOnline = data['isOnline'] as bool? ?? false;
    if (!isOnline) return false;
    
    final lastActive = data['lastActive'] as Timestamp?;
    if (lastActive != null) {
       final diff = DateTime.now().difference(lastActive.toDate());
       // If last active was more than 3 minutes ago, consider offline even if isOnline is true.
       if (diff.inMinutes >= 3) {
           return false;
       }
    }
    return true;
  });
});
