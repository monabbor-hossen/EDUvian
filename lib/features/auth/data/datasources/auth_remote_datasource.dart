import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class AuthRemoteDataSource {
  User? get currentUser;
  Stream<User?> get authStateChanges;
  Future<UserCredential> signInWithEmail(String email, String password);
  Future<UserCredential> signUpWithEmail(String email, String password);
  Future<UserCredential?> signInWithGoogle();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSourceImpl({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<UserCredential> signInWithEmail(String email, String password) {
    final trimmedEmail = email.trim();
    if (!trimmedEmail.toLowerCase().endsWith('@eastdelta.edu.bd')) {
      throw Exception('Only @eastdelta.edu.bd emails are allowed.');
    }
    return _auth.signInWithEmailAndPassword(
      email: trimmedEmail,
      password: password,
    );
  }

  @override
  Future<UserCredential> signUpWithEmail(String email, String password) {
    final trimmedEmail = email.trim();
    if (!trimmedEmail.toLowerCase().endsWith('@eastdelta.edu.bd')) {
      throw Exception('Only @eastdelta.edu.bd emails are allowed.');
    }
    return _auth.createUserWithEmailAndPassword(
      email: trimmedEmail,
      password: password,
    );
  }

  @override
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    if (!googleUser.email.toLowerCase().endsWith('@eastdelta.edu.bd')) {
      await _googleSignIn.signOut();
      throw Exception('Only @eastdelta.edu.bd emails are allowed.');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
