import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile.dart';

/// Authentication service — mirrors web app's auth-context.tsx
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

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

    return await _auth.signInWithCredential(credential);
  }

  // ─── Sign In with Email/Password ───
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ─── Sign Up with Email/Password ───
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Send verification email
    await credential.user?.sendEmailVerification();

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
    await _db.collection('users').doc(uid).set({
      'profile': profile.toMap(),
    }, SetOptions(merge: true));
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
