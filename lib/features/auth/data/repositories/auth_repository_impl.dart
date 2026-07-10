import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    FirebaseFirestore? firestore,
  })  : _remoteDataSource = remoteDataSource,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  User? get currentUser => _remoteDataSource.currentUser;

  @override
  Stream<User?> get authStateChanges => _remoteDataSource.authStateChanges;

  Future<void> _saveUserToFirestore(User? user) async {
    if (user == null) return;
    
    // Generate a fallback display name from email if needed
    String displayName = user.displayName ?? '';
    if (displayName.isEmpty && user.email != null) {
      final localPart = user.email!.split('@').first;
      displayName = localPart
          .replaceAll(RegExp(r'[._]'), ' ')
          .split(' ')
          .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
    }

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email ?? '',
      'name': displayName,
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    final cred = await _remoteDataSource.signInWithEmail(email, password);
    await _saveUserToFirestore(cred.user);
    return cred;
  }

  @override
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    final cred = await _remoteDataSource.signUpWithEmail(email, password);
    await _saveUserToFirestore(cred.user);
    return cred;
  }

  @override
  Future<UserCredential?> signInWithGoogle() async {
    final cred = await _remoteDataSource.signInWithGoogle();
    if (cred != null) {
      await _saveUserToFirestore(cred.user);
    }
    return cred;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _remoteDataSource.sendPasswordResetEmail(email);
  }

  @override
  Future<void> signOut() {
    return _remoteDataSource.signOut();
  }
}
