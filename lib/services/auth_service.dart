// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (kIsWeb || _googleInitialized) return;
    await _googleSignIn.initialize();
    _googleInitialized = true;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<AppUser?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) return AppUser.fromFirestore(doc);
      return await _createUserDocument(user);
    } catch (e) {
      return null;
    }
  }

  /// Resolves an identifier (email / username / displayName / studentId)
  /// to an email address by querying the `users` collection directly.
  /// Returns `null` if no match is found.
  Future<String?> _resolveIdentifierToEmail(String identifier) async {
    // If it looks like an email, use it as-is.
    final strictEmailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (strictEmailRegex.hasMatch(identifier)) {
      return identifier.toLowerCase();
    }

    // Try username, then displayName, then studentId.
    final fieldsToTry = ['username', 'displayName', 'studentId'];
    for (final field in fieldsToTry) {
      try {
        final snap = await _firestore
            .collection('users')
            .where(field, isEqualTo: identifier)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          final data = snap.docs.first.data();
          final email = (data['email'] ?? '').toString();
          if (email.isNotEmpty) return email.toLowerCase();
        }
      } catch (_) {
        // try next field
      }
    }

    return null;
  }

  Future<AppUser?> signInWithUser(
    String userIdentifier,
    String password,
  ) async {
    final identifier = userIdentifier.trim();
    if (identifier.isEmpty || password.isEmpty) {
      throw Exception('Invalid credentials. Please check and try again.');
    }

    const genericFailure =
        'Invalid credentials. Please check and try again.';

    try {
      final email = await _resolveIdentifierToEmail(identifier);

      if (email == null) {
        await Future.delayed(const Duration(milliseconds: 400));
        throw Exception(genericFailure);
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception(genericFailure);

      // Read the user doc to check account status.
      final userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      final data = userDoc.data() ?? {};

      // Admin bypass — admins are never gated by accountStatus.
      final isAdminDoc = data['role'] == 'admin';
      if (!isAdminDoc) {
        final status = (data['accountStatus'] ?? 'active').toString();
        if (status == 'pending') {
          await _auth.signOut();
          throw Exception(
              'Your account is pending release. Please inquire at the canteen counter.');
        }
        if (status == 'suspended') {
          await _auth.signOut();
          throw Exception(
              'Your account has been suspended. Please contact the canteen admin.');
        }
      }

      await _updateLastLogin(user.uid);
      return await getCurrentUserData();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        throw Exception(
            'Too many failed attempts. Please wait a few minutes and try again.');
      }
      throw Exception(genericFailure);
    }
  }

  // Sign in with email and password (kept for direct calls)
  Future<AppUser?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        await _updateLastLogin(user.uid);
        return await getCurrentUserData();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // REGISTER
  // ─────────────────────────────────────────────────────────────────
  Future<AppUser?> registerWithEmail(
    String email,
    String password,
    String username,
    UserRole role,
  ) async {
    try {
      // Check username availability directly against the users collection.
      final usernameSnap = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get();

      if (usernameSnap.docs.isNotEmpty) {
        throw Exception('Username already taken. Please choose another.');
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(username);
        await user.reload();

        final appUser = AppUser(
          uid: user.uid,
          email: email,
          displayName: username,
          username: username,
          role: role,
          accountStatus: AccountStatus.active,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isActive: true,
          points: 0,
          preferences: {
            'notifications': true,
            'theme': 'light',
          },
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(appUser.toMap());

        return appUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Google sign-in — unchanged
  Future<AppUser?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        final userCredential = await _auth.signInWithPopup(googleProvider);
        final user = userCredential.user;
        if (user == null) return null;
        return await _handleGoogleUser(user);
      }

      await _ensureGoogleInitialized();

      final account = await _googleSignIn.authenticate();
      googleUser = account;

      final authorization =
          await googleUser.authorizationClient.authorizationForScopes(
        ['email', 'profile'],
      ) ??
              await googleUser.authorizationClient.authorizeScopes(
                ['email', 'profile'],
              );

      final idToken = googleUser.authentication.idToken;

      final credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
        idToken: idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return null;
      return await _handleGoogleUser(user);
    } on GoogleSignInException catch (e) {
      debugPrint('GoogleSignInException: ${e.code} ${e.description}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      throw Exception('Google sign-in failed: ${e.description ?? e.code}');
    } catch (e) {
      rethrow;
    }
  }

  Future<AppUser?> _handleGoogleUser(User user) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      await _createUserDocument(user);
    } else {
      await _updateLastLogin(user.uid);
    }
    return await getCurrentUserData();
  }

  Future<AppUser> _createUserDocument(User user) async {
    final username = user.displayName ?? user.email?.split('@').first ?? 'User';
    final appUser = AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: username,
      username: username,
      role: UserRole.user,
      accountStatus: AccountStatus.active,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isActive: true,
      points: 0,
      preferences: {
        'notifications': true,
        'theme': 'light',
      },
    );
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(appUser.toMap(), SetOptions(merge: true));
    return appUser;
  }

  /// Writes only `lastLoginAt`. Does NOT touch `isActive` — toggling that
  /// field races with the next login and can be rejected by Firestore
  /// rules when `credits`/`points` are missing on the doc.
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).set(
        {
          'lastLoginAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Non-fatal.
    }
  }

  /// Signs out the Firebase user and the Google session. Does NOT write
  /// to Firestore — avoids racing with the next login's user-doc read.
  Future<void> signOut() async {
    try {
      if (!kIsWeb && _googleInitialized) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  Future<void> updateUserProfile({
    String? username,
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? preferences,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      final Map<String, dynamic> updates = {};
      if (username != null) updates['username'] = username;
      if (displayName != null) updates['displayName'] = displayName;
      if (photoURL != null) updates['photoURL'] = photoURL;
      if (preferences != null) updates['preferences'] = preferences;

      if (updates.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(updates, SetOptions(merge: true));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<AppUser?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) return AppUser.fromFirestore(doc);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final snap = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get();
      return snap.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    } catch (e) {
      rethrow;
    }
  }
}