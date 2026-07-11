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

  Stream<List<ChatMessageModel>> streamMessages(String sectionId);
  Stream<List<Map<String, dynamic>>> streamMembers(String sectionId);
  Stream<List<ChatGroupModel>> streamUserChats();

  Future<void> muteGroup(String groupId, bool mute);
  Future<void> leaveGroup(String groupId);
  Future<void> deleteGroup(String groupId);
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
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> registerMember(String sectionId) async {
    final user = _user;
    if (user == null) return;

    // Check if it's a section chat ID format.
    // Section chat ID format: e.g. "7DCSE.2" or "E7DCSE.2" or "E_7CSE_2"
    final isSectionChat = RegExp(r'^[Ee]?_?\d+[A-Za-z]').hasMatch(sectionId);
    if (!isSectionChat) {
      // For private DMs or custom chats, just write their member details if they are in the group.
      final doc = await _db.collection('chats').doc(sectionId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final participants = List<String>.from(data['participants'] ?? []);
        if (!participants.contains(user.uid)) {
          return; // They are not in the participants list, so deny registration
        }
      } else {
        return;
      }
    } else {
      // 1. Create/Update the parent chat document first.
      await _db.collection('chats').doc(sectionId).set({
        'sectionId': sectionId,
        'type': 'section',
        'memberIds': FieldValue.arrayUnion([user.uid]),
        'participants': FieldValue.arrayUnion([user.uid]),
      }, SetOptions(merge: true));
    }

    // 2. Add the user to the members subcollection
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
  Future<List<Map<String, dynamic>>> fetchClassmates({
    required int semester,
    required String department,
    int? section,
    required String shift,
  }) async {
    final currentUid = _user?.uid;

    Query<Map<String, dynamic>> query = _db.collection('users')
        .where('semester',   isEqualTo: semester)
        .where('department', isEqualTo: department)
        .where('shift',      isEqualTo: shift);

    if (section != null) {
      query = query.where('section', isEqualTo: section);
    }

    final snap = await query.get();
    return snap.docs
        .map((d) => d.data())
        .where((u) => (u['uid'] as String?) != currentUid)
        .toList()
        ..sort((a, b) => (a['name'] as String? ?? '')
            .toLowerCase()
            .compareTo((b['name'] as String? ?? '').toLowerCase()));
  }

  @override
  Future<String> getOrCreateDirectChat({
    required String otherUserUid,
    required String otherUserName,
    required String otherUserEmail,
  }) async {
    final user = _user;
    if (user == null) throw Exception('Not logged in');

    // Query chats of type 'direct' where participants array contains the current user
    final query = await _db.collection('chats')
        .where('type', isEqualTo: 'direct')
        .where('participants', arrayContains: user.uid)
        .get();

    for (final doc in query.docs) {
      final p = List<String>.from(doc.data()['participants'] ?? doc.data()['memberIds'] ?? []);
      if (p.length == 2 && p.contains(otherUserUid)) {
        return doc.id;
      }
    }

    // No existing direct chat found, create a new one
    final memberIds = [user.uid, otherUserUid];
    final docRef = await _db.collection('chats').add({
      'name': '$otherUserName & $currentDisplayName',
      'type': 'direct',
      'creatorId': user.uid,
      'memberIds': memberIds,
      'participants': memberIds,
      'names': {
        user.uid: currentDisplayName,
        otherUserUid: otherUserName,
      },
      'lastMessage': 'Chat started',
      'lastSenderName': 'System',
      'lastTimestamp': FieldValue.serverTimestamp(),
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    final batch = _db.batch();
    batch.set(docRef.collection('members').doc(user.uid), {
      'uid': user.uid,
      'name': currentDisplayName,
      'email': user.email ?? '',
      'joinedAt': FieldValue.serverTimestamp(),
    });
    batch.set(docRef.collection('members').doc(otherUserUid), {
      'uid': otherUserUid,
      'name': otherUserName,
      'email': otherUserEmail,
      'joinedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    return docRef.id;
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
      'creatorId': user.uid,
      'memberIds': memberIds,
      'participants': memberIds,
      'lastMessage': 'Group created',
      'lastSenderName': 'System',
      'lastTimestamp': FieldValue.serverTimestamp(),
      'lastMessageTime': FieldValue.serverTimestamp(),
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
  Future<void> muteGroup(String groupId, bool mute) async {
    final user = _user;
    if (user == null) return;

    await _db.collection('chats').doc(groupId).update({
      'mutedBy': mute
          ? FieldValue.arrayUnion([user.uid])
          : FieldValue.arrayRemove([user.uid]),
    });
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    final user = _user;
    if (user == null) return;

    await _db.collection('chats').doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([user.uid]),
      'participants': FieldValue.arrayRemove([user.uid]),
    });

    await _db.collection('chats').doc(groupId).collection('members').doc(user.uid).delete();
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await _db.collection('chats').doc(groupId).delete();
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
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(ChatGroupModel.fromFirestore).toList();
          list.sort((a, b) {
            final t1 = a.lastTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
            final t2 = b.lastTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
            return t2.compareTo(t1);
          });
          return list;
        });
  }
}
