import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Tento e-mail už používa iný účet.';
      case 'invalid-email':
        return 'Zadaj platný e-mail.';
      case 'weak-password':
        return 'Heslo musí mať aspoň 6 znakov.';
      case 'user-not-found':
        return 'Účet s týmto e-mailom neexistuje.';
      case 'wrong-password':
        return 'Nesprávne heslo.';
      case 'invalid-credential':
        return 'Nesprávny e-mail alebo heslo.';
      case 'too-many-requests':
        return 'Príliš veľa pokusov. Skús to o chvíľu.';
      case 'operation-not-allowed':
        return 'Prihlásenie e-mailom nie je v Firebase povolené.';
      default:
        return e.message ?? 'Autentifikácia zlyhala (${e.code}).';
    }
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
