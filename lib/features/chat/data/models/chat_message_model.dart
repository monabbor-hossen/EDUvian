import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.senderId,
    required super.senderName,
    required super.senderEmail,
    required super.text,
    required super.timestamp,
    super.edited = false,
    super.isEncrypted = false,
    super.encryptedKeys,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatMessageModel(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Unknown',
      senderEmail: data['senderEmail'] as String? ?? '',
      text: data['text'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      edited: data['edited'] as bool? ?? false,
      isEncrypted: data['isEncrypted'] as bool? ?? false,
      encryptedKeys: data['encryptedKeys'] != null 
          ? Map<String, String>.from(data['encryptedKeys'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderName': senderName,
        'senderEmail': senderEmail,
        'text': text,
        'timestamp': Timestamp.fromDate(timestamp),
        'edited': edited,
        'isEncrypted': isEncrypted,
        if (encryptedKeys != null) 'encryptedKeys': encryptedKeys,
      };
}

