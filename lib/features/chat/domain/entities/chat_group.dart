class ChatGroup {
  final String id;
  final String name;
  final String type; // 'section', 'direct', or 'custom'
  final List<String> memberIds;
  final String lastMessage;
  final String lastSenderName;
  final String lastSenderId;
  final DateTime? lastTimestamp;
  final List<String> mutedBy;

  const ChatGroup({
    required this.id,
    required this.name,
    required this.type,
    required this.memberIds,
    required this.lastMessage,
    required this.lastSenderName,
    this.lastSenderId = '',
    this.lastTimestamp,
    this.mutedBy = const [],
  });
}
