import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_group_model.dart';
import '../models/chat_message_model.dart';

abstract class ChatRemoteDataSource {
  String? get currentUid;
  String get currentDisplayName;

  Future<void> sendMessage(String sectionId, String text);
  Future<void> registerMember(String sectionId);
  Future<List<Map<String, dynamic>>> searchUsers(String query);
  Future<String> createCustomGroup(String name, List<Map<String, dynamic>> selectedUsers);

  Stream<List<ChatMessageModel>> streamMessages(String sectionId);
  Stream<List<Map<String, dynamic>>> streamMembers(String sectionId);
  Stream<List<ChatGroupModel>> streamUserChats();
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  ChatRemoteDataSourceImpl({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  User? get _user => _auth.currentUser;

  @override
  String? get currentUid => _user?.uid;

  @override
  String get currentDisplayName {
    final user = _user;
    if (user == null) return 'Unknown';
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    final email = user.email ?? '';
    final localPart = email.split('@').first;
    return localPart
        .replaceAll(RegExp(r'[._]'), ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Future<void> sendMessage(String sectionId, String text) async {
    final user = _user;
    if (user == null) return;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final msgRef = _db
        .collection('chats')
        .doc(sectionId)
        .collection('messages')
        .doc();

    await msgRef.set({
      'senderId': user.uid,
      'senderName': currentDisplayName,
      'senderEmail': user.email ?? '',
      'text': trimmed,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _db.collection('chats').doc(sectionId).set({
      'lastMessage': trimmed,
      'lastSenderName': currentDisplayName,
      'lastSenderId': user.uid,
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> registerMember(String sectionId) async {
    final user = _user;
    if (user == null) return;

    await _db
        .collection('chats')
        .doc(sectionId)
        .collection('members')
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'name': currentDisplayName,
      'email': user.email ?? '',
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection('chats').doc(sectionId).set({
      'sectionId': sectionId,
      'type': 'section',
      'memberIds': FieldValue.arrayUnion([user.uid]),
    }, SetOptions(merge: true));
  }

  @override
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return [];

    final snap = await _db.collection('users').get();
    return snap.docs
        .map((d) => d.data())
        .where((user) {
          final name = (user['name'] as String? ?? '').toLowerCase();
          final email = (user['email'] as String? ?? '').toLowerCase();
          return name.contains(trimmed) || email.contains(trimmed);
        })
        .toList();
  }

  @override
  Future<String> createCustomGroup(String name, List<Map<String, dynamic>> selectedUsers) async {
    final user = _user;
    if (user == null) throw Exception('Not logged in');

    final memberIds = selectedUsers.map((u) => u['uid'] as String).toList();
    if (!memberIds.contains(user.uid)) {
      memberIds.add(user.uid);
      selectedUsers.add({
        'uid': user.uid,
        'name': currentDisplayName,
        'email': user.email ?? '',
      });
    }

    final docRef = await _db.collection('chats').add({
      'name': name.trim(),
      'type': 'custom',
      'memberIds': memberIds,
      'lastMessage': 'Group created',
      'lastSenderName': 'System',
      'lastTimestamp': FieldValue.serverTimestamp(),
    });

    final batch = _db.batch();
    for (final member in selectedUsers) {
      final memRef = docRef.collection('members').doc(member['uid']);
      batch.set(memRef, {
        'uid': member['uid'],
        'name': member['name'],
        'email': member['email'],
        'joinedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    return docRef.id;
  }

  @override
  Stream<List<ChatMessageModel>> streamMessages(String sectionId) {
    return _db
        .collection('chats')
        .doc(sectionId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessageModel.fromFirestore).toList());
  }

  @override
  Stream<List<Map<String, dynamic>>> streamMembers(String sectionId) {
    return _db
        .collection('chats')
        .doc(sectionId)
        .collection('members')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  @override
  Stream<List<ChatGroupModel>> streamUserChats() {
    final user = _user;
    if (user == null) return Stream.value([]);
    
    return _db
        .collection('chats')
        .where('memberIds', arrayContains: user.uid)
        .orderBy('lastTimestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ChatGroupModel.fromFirestore).toList());
  }
}
