class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.text,
    required this.timestamp,
  });

  /// Returns two-letter initials from the sender's name or email.
  String get initials {
    final parts = senderName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (senderName.isNotEmpty) return senderName[0].toUpperCase();
    if (senderEmail.isNotEmpty) return senderEmail[0].toUpperCase();
    return '?';
  }
}
