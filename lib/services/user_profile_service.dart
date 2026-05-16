import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfile {
  const UserProfile({
    required this.avatarId,
    required this.email,
  });

  final String avatarId;
  final String? email;

  factory UserProfile.defaults(String? email) => UserProfile(
        avatarId: 'user',
        email: email,
      );
}

class UserProfileService {
  UserProfileService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  Stream<UserProfile> watchProfile() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(UserProfile.defaults(null));
    }

    return _doc(user.uid).snapshots().map((snap) {
      final data = snap.data();
      return UserProfile(
        avatarId: data?['avatarId'] as String? ?? 'user',
        email: user.email,
      );
    });
  }

  Future<void> setAvatarId(String avatarId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw ProfileException('Nie si prihlásený.');
    }

    await _doc(uid).set(
      {
        'avatarId': avatarId,
        'email': _auth.currentUser?.email,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw ProfileException('Nie si prihlásený.');
    }
    if (newPassword.length < 6) {
      throw ProfileException('Nové heslo musí mať aspoň 6 znakov.');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    try {
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw ProfileException(_passwordError(e));
    }
  }

  String _passwordError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Súčasné heslo nie je správne.';
      case 'weak-password':
        return 'Nové heslo je príliš slabé.';
      default:
        return e.message ?? 'Zmena hesla zlyhala (${e.code}).';
    }
  }
}

class ProfileException implements Exception {
  ProfileException(this.message);
  final String message;

  @override
  String toString() => message;
}
