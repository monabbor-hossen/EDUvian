import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/chat_group.dart';

class ChatGroupModel extends ChatGroup {
  const ChatGroupModel({
    required super.id,
    required super.name,
    required super.type,
    required super.memberIds,
    required super.lastMessage,
    required super.lastSenderName,
    super.lastTimestamp,
    super.mutedBy = const [],
  });

  factory ChatGroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    String type = data['type'] as String? ?? 'section';
    final memberIds = List<String>.from(data['memberIds'] ?? data['participants'] ?? []);
    
    String resolvedName = data['name'] as String? ?? data['sectionId'] as String? ?? 'Unknown Group';

    // Fallback for older direct chats that might not have the 'type' field set correctly
    if (type != 'direct' && resolvedName.contains(' & ') && memberIds.length <= 2) {
      type = 'direct';
    }
    if (type == 'section' && resolvedName.startsWith('E')) {
      if (resolvedName.length > 1 && RegExp(r'^\d').hasMatch(resolvedName.substring(1))) {
        resolvedName = resolvedName.substring(1);
      }
    }
    if (type == 'direct') {
      final names = data['names'] as Map<String, dynamic>?;
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final otherUid = memberIds.firstWhere((id) => id != currentUid, orElse: () => '');
      if (names != null && otherUid.isNotEmpty) {
        resolvedName = names[otherUid] as String? ?? resolvedName;
      } else if (resolvedName.contains(' & ')) {
        final parts = resolvedName.split(' & ');
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final email = user.email ?? '';
          final localPart = email.split('@').first;
          final currentDisplayName = user.displayName?.isNotEmpty == true 
              ? user.displayName! 
              : localPart.replaceAll(RegExp(r'[._]'), ' ')
                  .split(' ')
                  .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
                  .join(' ');
          
          final cleanParts = parts.map((p) => p.trim()).toList();
          final cleanCurrentName = currentDisplayName.trim();
          
          if (cleanParts.contains(cleanCurrentName)) {
            cleanParts.remove(cleanCurrentName);
            resolvedName = cleanParts.join(' & ');
          } else {
            // Fallback robust replacement if exact match fails
            String temp = resolvedName.replaceAll(currentDisplayName, '').replaceAll('&', '').trim();
            if (temp.isNotEmpty) {
              resolvedName = temp;
            }
          }
        }
      }
    }

    return ChatGroupModel(
      id: doc.id,
      name: resolvedName,
      type: type,
      memberIds: memberIds,
      lastMessage: data['lastMessage'] as String? ?? '',
      lastSenderName: data['lastSenderName'] as String? ?? '',
      lastTimestamp: (data['lastTimestamp'] as Timestamp? ?? data['lastMessageTime'] as Timestamp?)?.toDate(),
      mutedBy: List<String>.from(data['mutedBy'] ?? []),
    );
  }
}
