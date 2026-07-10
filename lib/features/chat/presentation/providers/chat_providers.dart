import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_group.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSourceImpl();
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final remoteDataSource = ref.watch(chatRemoteDataSourceProvider);
  return ChatRepositoryImpl(remoteDataSource: remoteDataSource);
});

// For legacy code compatibility
final chatServiceProvider = Provider<ChatRepository>((ref) {
  return ref.watch(chatRepositoryProvider);
});

/// Loads the section ID from SharedPreferences.
final sectionIdProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('academic_info') ?? '';
  return raw.isEmpty ? null : raw.trim().toUpperCase();
});

/// Streams messages for a given section, ordered oldest → newest.
final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, sectionId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.streamMessages(sectionId);
});

/// Streams the member list for a given section doc.
final chatMembersProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>(
        (ref, sectionId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.streamMembers(sectionId);
});

/// Streams all custom and section chats that the current user is a member of.
final userChatsProvider = StreamProvider<List<ChatGroup>>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.streamUserChats();
});
