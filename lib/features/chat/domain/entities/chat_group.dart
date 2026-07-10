class ChatGroup {
  final String id;
  final String name;
  final String type; // 'section' or 'custom'
  final List<String> memberIds;
  final String lastMessage;
  final String lastSenderName;
  final DateTime? lastTimestamp;

  const ChatGroup({
    required this.id,
    required this.name,
    required this.type,
    required this.memberIds,
    required this.lastMessage,
    required this.lastSenderName,
    this.lastTimestamp,
  });
}
