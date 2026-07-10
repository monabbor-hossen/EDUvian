import '../../domain/entities/chat_group.dart';
import '../../domain/entities/chat_message.dart';

abstract class ChatRepository {
  String? get currentUid;
  String get currentDisplayName;

  Future<void> sendMessage(String sectionId, String text);
  Future<void> registerMember(String sectionId);
  Future<List<Map<String, dynamic>>> searchUsers(String query);
  Future<String> createCustomGroup(String name, List<Map<String, dynamic>> selectedUsers);

  Stream<List<ChatMessage>> streamMessages(String sectionId);
  Stream<List<Map<String, dynamic>>> streamMembers(String sectionId);
  Stream<List<ChatGroup>> streamUserChats();

  Future<void> muteGroup(String groupId, bool mute);
  Future<void> leaveGroup(String groupId);
  Future<void> deleteGroup(String groupId);
}
