import '../../domain/entities/chat_group.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl({required ChatRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  String? get currentUid => _remoteDataSource.currentUid;

  @override
  String get currentDisplayName => _remoteDataSource.currentDisplayName;

  @override
  Future<void> sendMessage(String sectionId, String text) {
    return _remoteDataSource.sendMessage(sectionId, text);
  }

  @override
  Future<void> registerMember(String sectionId) {
    return _remoteDataSource.registerMember(sectionId);
  }

  @override
  Future<List<Map<String, dynamic>>> searchUsers(String query) {
    return _remoteDataSource.searchUsers(query);
  }

  @override
  Future<String> createCustomGroup(String name, List<Map<String, dynamic>> selectedUsers) {
    return _remoteDataSource.createCustomGroup(name, selectedUsers);
  }

  @override
  Stream<List<ChatMessage>> streamMessages(String sectionId) {
    return _remoteDataSource.streamMessages(sectionId).map((list) => list.cast<ChatMessage>());
  }

  @override
  Stream<List<Map<String, dynamic>>> streamMembers(String sectionId) {
    return _remoteDataSource.streamMembers(sectionId);
  }

  @override
  Stream<List<ChatGroup>> streamUserChats() {
    return _remoteDataSource.streamUserChats().map((list) => list.cast<ChatGroup>());
  }
}
