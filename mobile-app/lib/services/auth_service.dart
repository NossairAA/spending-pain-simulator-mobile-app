import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile.dart';

/// Authentication service — mirrors web app's auth-context.tsx
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _sessionStartedAtKey = 'mindspend_session_started_at';
  static const _rememberPasswordKey = 'mindspend_remember_password';
  static const _savedEmailKey = 'mindspend_saved_email';
  static const _legacySavedPasswordKey = 'mindspend_saved_password';
  static const _secureSavedPasswordKey = 'mindspend_saved_password_secure';
  static const _biometricEmailKey = 'mindspend_biometric_email';
  static const _biometricPasswordKey = 'mindspend_biometric_password';
  static const _sessionTtl = Duration(minutes: 30);
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges =>
      _auth.authStateChanges().asyncMap((user) async {
        final prefs = await SharedPreferences.getInstance();

        if (user == null) {
          await prefs.remove(_sessionStartedAtKey);
          return null;
        }

        final startedAt = prefs.getInt(_sessionStartedAtKey);
        final now = DateTime.now().millisecondsSinceEpoch;
        if (startedAt != null && now - startedAt > _sessionTtl.inMilliseconds) {
          await signOut();
          return null;
        }

        if (startedAt == null) {
          await prefs.setInt(_sessionStartedAtKey, now);
        }

        return user;
      });

  // ─── Sign In with Google ───
  Future<UserCredential> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();
    final googleUser = await googleSignIn.authenticate();

    final googleAuth = googleUser.authentication;

    // In GoogleSignIn 7.x, accessToken requires separate authorization.
    // Firebase Auth works with just the idToken.
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    await _startSession();
    return userCredential;
  }

  // ─── Sign In with Email/Password ───
  Future<UserCredential> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _startSession();
    return credential;
  }

  // ─── Sign Up with Email/Password ───
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Send verification email
    await credential.user?.sendEmailVerification();

    await _startSession();

    return credential;
  }

  // ─── Resend Verification Email ───
  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // ─── Sign Out ───
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // GoogleSignIn may not be initialized
    }
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionStartedAtKey);
  }

  Future<void> _startSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _sessionStartedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<bool> hasActiveUnexpiredSession() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final startedAt = prefs.getInt(_sessionStartedAtKey);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (startedAt == null) {
      await prefs.setInt(_sessionStartedAtKey, now);
      return true;
    }

    return now - startedAt <= _sessionTtl.inMilliseconds;
  }

  Future<AuthCredentialsPrefs> loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacySavedPassword(prefs);

    return AuthCredentialsPrefs(
      rememberPassword: prefs.getBool(_rememberPasswordKey) ?? false,
      email: prefs.getString(_savedEmailKey) ?? '',
      password: await _secureStorage.read(key: _secureSavedPasswordKey) ?? '',
    );
  }

  Future<void> saveCredentialsPreference({
    required String email,
    required String password,
    required bool rememberPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedEmailKey, email);
    await prefs.setBool(_rememberPasswordKey, rememberPassword);

    if (rememberPassword) {
      await _secureStorage.write(key: _secureSavedPasswordKey, value: password);
    } else {
      await _secureStorage.delete(key: _secureSavedPasswordKey);
      await prefs.remove(_legacySavedPasswordKey);
    }
  }

  Future<void> saveBiometricCredentials({
    required String email,
    required String password,
  }) async {
    await _secureStorage.write(key: _biometricEmailKey, value: email);
    await _secureStorage.write(key: _biometricPasswordKey, value: password);
  }

  Future<void> _migrateLegacySavedPassword(SharedPreferences prefs) async {
    final legacyPassword = prefs.getString(_legacySavedPasswordKey);
    if (legacyPassword == null || legacyPassword.isEmpty) return;

    final securePassword = await _secureStorage.read(key: _secureSavedPasswordKey);
    if (securePassword == null || securePassword.isEmpty) {
      await _secureStorage.write(
        key: _secureSavedPasswordKey,
        value: legacyPassword,
      );
    }

    final biometricPassword = await _secureStorage.read(key: _biometricPasswordKey);
    if (biometricPassword == null || biometricPassword.isEmpty) {
      await _secureStorage.write(
        key: _biometricPasswordKey,
        value: legacyPassword,
      );
      final email = prefs.getString(_savedEmailKey) ?? '';
      if (email.isNotEmpty) {
        await _secureStorage.write(key: _biometricEmailKey, value: email);
      }
    }

    await prefs.remove(_legacySavedPasswordKey);
  }

  Future<bool> signInWithBiometricCredentials() async {
    final email = await _secureStorage.read(key: _biometricEmailKey) ?? '';
    final password = await _secureStorage.read(key: _biometricPasswordKey) ?? '';

    if (email.isEmpty || password.isEmpty) {
      return false;
    }

    try {
      await signInWithEmail(email, password);
      return true;
    } on FirebaseAuthException {
      return false;
    } catch (_) {
      return false;
    }
  }

  // ─── Delete Account ───
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Delete user data from Firestore
    await _db.collection('users').doc(user.uid).delete();

    // Delete Firebase Auth user
    await user.delete();
  }

  // ─── Profile Management ───
  Future<UserProfile?> loadProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data.containsKey('profile')) {
        return UserProfile.fromMap(data['profile'] as Map<String, dynamic>);
      }
    }
    return null;
  }

  Future<void> saveProfile(String uid, UserProfile profile) async {
    final doc = _db.collection('users').doc(uid);
    final nextProfile = profile.toMap();

    final snapshot = await doc.get();
    final existingRaw = snapshot.data()?['profile'];
    final existingProfile = existingRaw is Map
        ? Map<String, dynamic>.from(existingRaw)
        : <String, dynamic>{};

    await doc.set({'profile': nextProfile}, SetOptions(merge: true));

    final fieldsToDelete = <String, dynamic>{};
    for (final key in existingProfile.keys) {
      if (!nextProfile.containsKey(key)) {
        fieldsToDelete['profile.$key'] = FieldValue.delete();
      }
    }

    if (fieldsToDelete.isNotEmpty) {
      await doc.update(fieldsToDelete);
    }
  }

  // ─── Guest Profile (SharedPreferences) ───
  static const _guestProfileKey = 'mindspend_guest_profile';

  Future<UserProfile?> loadGuestProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_guestProfileKey);
    if (json != null) {
      return UserProfile.fromMap(jsonDecode(json) as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> saveGuestProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_guestProfileKey, jsonEncode(profile.toMap()));
  }

  Future<void> clearGuestData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestProfileKey);
    await prefs.remove('mindspend_purchase_history');
    await prefs.remove('mindspend_last_ethical_check');
  }

  /// Map Firebase error codes to user-friendly messages
  static String friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in instead.';
      case 'weak-password':
        return 'Password should be at least 6 characters';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password';
      case 'requires-recent-login':
        return 'For security, please sign out and sign in again before deleting your account.';
      case 'sign-in-cancelled':
        return 'Sign-in was cancelled';
      default:
        return e.message ?? 'An error occurred';
    }
  }
}

class AuthCredentialsPrefs {
  final bool rememberPassword;
  final String email;
  final String password;

  const AuthCredentialsPrefs({
    required this.rememberPassword,
    required this.email,
    required this.password,
  });
}
