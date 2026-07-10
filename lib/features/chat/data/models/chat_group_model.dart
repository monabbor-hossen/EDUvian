import 'package:cloud_firestore/cloud_firestore.dart';

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
    return ChatGroupModel(
      id: doc.id,
      name: data['name'] as String? ?? data['sectionId'] as String? ?? 'Unknown Group',
      type: data['type'] as String? ?? 'section',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      lastMessage: data['lastMessage'] as String? ?? '',
      lastSenderName: data['lastSenderName'] as String? ?? '',
      lastTimestamp: (data['lastTimestamp'] as Timestamp?)?.toDate(),
      mutedBy: List<String>.from(data['mutedBy'] ?? []),
    );
  }
}
