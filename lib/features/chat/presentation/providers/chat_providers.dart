import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/models/academic_info.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_group.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../../routine/presentation/providers/routine_providers.dart';

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
  final prefs = await ref.watch(userAcademicPrefsProvider.future);
  final raw = prefs.info;
  if (raw.isEmpty) return null;
  
  final upper = raw.trim().toUpperCase();
  if (prefs.shift == 'Evening' && !upper.startsWith('E')) {
    return 'E$upper';
  }
  return upper;
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

/// Fetches and **caches** the list of classmates who are in the same
/// semester, department, section, and shift as the current user.
///
/// This uses a structured Firestore compound query instead of fetching all
/// users — minimising read costs. Riverpod caches the result until the
/// provider is invalidated (e.g. when the user updates their academic info).
final classmatesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('academic_info') ?? '';
  if (raw.isEmpty) return [];

  final info = parseAcademicInfo(raw);
  if (info == null) return [];

  // Determine shift from the current user's email
  final email = FirebaseAuth.instance.currentUser?.email ?? '';
  final localPart = email.split('@').first.toLowerCase();
  final shift = localPart.endsWith('e') ? 'Evening' : 'Regular';

  final repository = ref.read(chatRepositoryProvider);
  return repository.fetchClassmates(
    semester:   info.semester,
    department: shift == 'Evening' ? 'EBSC in CSE' : 'BSC in CSE',
    section:    info.section,
    shift:      shift,
  );
});
