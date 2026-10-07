// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/user_model.dart';
import 'login_lookup_service.dart';
import 'login_lookup_sync.dart';

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

    final strictEmailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    final looksLikeEmail = strictEmailRegex.hasMatch(identifier);

    try {
      String? email;
      try {
        final lookup = LoginLookupService();
        final record = await lookup.lookup(identifier);
        if (record != null && record.email.isNotEmpty) {
          email = record.email.toLowerCase();
        }
      } catch (_) {
        // fall through
      }

      if (email == null && !looksLikeEmail) {
        try {
          final snap = await _firestore
              .collection('users')
              .where('username', isEqualTo: identifier)
              .limit(1)
              .get();

          QuerySnapshot? result = snap;

          if (result.docs.isEmpty) {
            result = await _firestore
                .collection('users')
                .where('displayName', isEqualTo: identifier)
                .limit(1)
                .get();
          }

          if (result.docs.isEmpty) {
            // Try studentId (students logging in by ID)
            result = await _firestore
                .collection('users')
                .where('studentId', isEqualTo: identifier)
                .limit(1)
                .get();
          }

          if (result.docs.isNotEmpty) {
            final data = result.docs.first.data() as Map<String, dynamic>;
            final foundEmail = (data['email'] ?? '').toString();
            if (foundEmail.isNotEmpty) {
              email = foundEmail.toLowerCase();
            }
          }
        } catch (_) {
        }
      }

      if (email == null && looksLikeEmail) {
        email = identifier.toLowerCase();
      }

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

      final userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      final data = userDoc.data() ?? {};
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

      await _ensureLookupForCurrentUser();
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

  Future<void> _ensureLookupForCurrentUser() async {
    final authUser = _auth.currentUser;
    if (authUser == null) return;

    try {
      final userDoc =
          await _firestore.collection('users').doc(authUser.uid).get();
      if (!userDoc.exists) return;

      final appUser = AppUser.fromFirestore(userDoc);
      if (appUser.email.isEmpty) return;

      // Check whether the primary (email) lookup doc exists.
      final existing = await _firestore
          .collection('login_lookup')
          .doc(appUser.email.toLowerCase())
          .get();

      if (existing.exists) return;

      // Missing → sync all identifiers now.
      await LoginLookupSync.upsert(appUser);
      debugPrint('[AuthService] Self-healed login_lookup for ${appUser.email}');
    } catch (e) {
      // Non-fatal — user is already signed in.
      debugPrint('[AuthService] _ensureLookupForCurrentUser failed: $e');
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
        await _ensureLookupForCurrentUser();
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
      // Check username availability via the public lookup doc.
      final usernameKey = username.trim().toLowerCase();
      final usernameDoc = await _firestore
          .collection('login_lookup')
          .doc(usernameKey)
          .get();

      if (usernameDoc.exists) {
        throw Exception('Username already taken. Please choose another.');
      }

      // Also check email availability (in case someone else already
      // registered with this email but never synced a lookup doc).
      final emailKey = email.trim().toLowerCase();
      final emailDoc = await _firestore
          .collection('login_lookup')
          .doc(emailKey)
          .get();

      if (emailDoc.exists) {
        throw Exception(
            'This email is already registered. Please sign in instead.');
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

        await LoginLookupSync.upsert(appUser);
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
    await _ensureLookupForCurrentUser();
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
    await LoginLookupSync.upsert(appUser);
    return appUser;
  }

  /// Uses set+merge so it never throws if the user doc is missing.
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).set(
        {
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isActive': true,
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Non-fatal.
    }
  }

  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        try {
          await _firestore.collection('users').doc(user.uid).set(
            {'isActive': false},
            SetOptions(merge: true),
          );
        } catch (_) {}
      }
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
      final doc = await _firestore
          .collection('login_lookup')
          .doc(username.trim().toLowerCase())
          .get();
      return !doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final u = AppUser.fromFirestore(doc);
        await LoginLookupSync.remove(
          email: u.email,
          username: u.username,
          studentId: u.studentId,
        );
      }
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    } catch (e) {
      rethrow;
    }
  }
}