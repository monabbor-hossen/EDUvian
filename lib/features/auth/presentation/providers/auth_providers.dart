import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource: remoteDataSource);
});

final authStateProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

// Alias provider to match legacy usage in other files
final authServiceProvider = Provider<AuthRepository>((ref) {
  return ref.watch(authRepositoryProvider);
});

/// Streams the display name from Firestore so it updates everywhere
/// immediately after saving — even without a new Firebase Auth event.
final userNameProvider = StreamProvider<String>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final uid = authAsync.asData?.value?.uid;
  if (uid == null) return Stream.value('');

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) {
    final name = snap.data()?['name'] as String? ?? '';
    return name.isNotEmpty ? name : (FirebaseAuth.instance.currentUser?.displayName ?? '');
  });
});

