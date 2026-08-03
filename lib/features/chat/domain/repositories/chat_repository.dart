import '../../domain/entities/chat_group.dart';
import '../../domain/entities/chat_message.dart';

abstract class ChatRepository {
  String? get currentUid;
  String get currentDisplayName;

  Future<void> sendMessage(String sectionId, String text);
  Future<void> registerMember(String sectionId);
  Future<List<Map<String, dynamic>>> searchUsers(String query);
  Future<List<Map<String, dynamic>>> fetchClassmates({
    required int semester,
    required String department,
    int? section,
    required String shift,
  });
  Future<String> getOrCreateDirectChat({
    required String otherUserUid,
    required String otherUserName,
    required String otherUserEmail,
  });
  Future<String> createCustomGroup(String name, List<Map<String, dynamic>> selectedUsers);

  Stream<List<ChatMessage>> streamMessages(String sectionId, {int limit = 50});
  Stream<List<Map<String, dynamic>>> streamMembers(String sectionId);
  Stream<List<ChatGroup>> streamUserChats();

  Future<void> muteGroup(String groupId, bool mute);
  Future<void> leaveGroup(String groupId);
  Future<void> deleteGroup(String groupId);

  Future<void> deleteMessage(String sectionId, String messageId);
  Future<void> editMessage(String sectionId, String messageId, String newText);
}
