// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// GoogleSignIn.instance is a singleton in v7 — no constructor.
  /// On web we still use signInWithPopup through Firebase, so we
  /// only need this on mobile.
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _googleInitialized = false;

  /// Initialize GoogleSignIn once, only on mobile.
  /// Calling initialize() on web without a clientId will hang.
  Future<void> _ensureGoogleInitialized() async {
    if (kIsWeb || _googleInitialized) return;
    await _googleSignIn.initialize();
    _googleInitialized = true;
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user data from Firestore
  Future<AppUser?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return await _createUserDocument(user);
    } catch (e) {
      return null;
    }
  }

  // Sign in with username OR email
  Future<AppUser?> signInWithUser(
      String userIdentifier, String password) async {
    final identifier = userIdentifier.trim();
    if (identifier.isEmpty) {
      throw Exception('Please enter your email, username, or student ID.');
    }

    try {
      // ── Step 1: Figure out the account email ──
      String email;

      final bool looksLikeEmail =
          identifier.contains('@') && identifier.contains('.');

      if (looksLikeEmail) {
        // Normalize to lowercase so "Juan@x.com" also matches "juan@x.com".
        email = identifier.toLowerCase();
      } else {
        // Search by username OR studentId. Firestore can't OR across fields
        // in a single query, so we run both and take the first hit.
        final byUsername = await _firestore
            .collection('users')
            .where('username', isEqualTo: identifier)
            .limit(1)
            .get();

        if (byUsername.docs.isNotEmpty) {
          email = (byUsername.docs.first.data()['email'] ?? '').toString();
        } else {
          // Try studentId
          final byStudentId = await _firestore
              .collection('users')
              .where('studentId', isEqualTo: identifier)
              .limit(1)
              .get();

          if (byStudentId.docs.isEmpty) {
            throw Exception(
                'No account found with "$identifier". Check your email, username, or student ID.');
          }
          email = (byStudentId.docs.first.data()['email'] ?? '').toString();
        }
      }

      if (email.isEmpty) {
        throw Exception(
            'This account has no email on file. Please contact the canteen admin.');
      }

      // ── Step 2: Authenticate with the resolved email ──
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return null;

      // ── Step 3: Check account status before letting them through ──
      // Pending accounts created by the admin are not yet allowed in.
      final userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      final data = userDoc.data() ?? {};
      final status = (data['accountStatus'] ?? 'active').toString();

      if (status == 'pending') {
        // Sign them out so they don't hold a half-authenticated session.
        await _auth.signOut();
        throw Exception(
            'Your account is pending release. Please inquire at the canteen counter.');
      }
      if (status == 'suspended') {
        await _auth.signOut();
        throw Exception(
            'Your account has been suspended. Please contact the canteen admin.');
      }

      // ── Step 4: Update the login timestamp and return the profile ──
      await _updateLastLogin(user.uid);
      return await getCurrentUserData();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        throw Exception('Invalid email/username/student ID or password.');
      }
      if (e.code == 'invalid-email') {
        throw Exception('That email address looks invalid.');
      }
      if (e.code == 'too-many-requests') {
        throw Exception(
            'Too many failed attempts. Please wait a few minutes and try again.');
      }
      throw Exception('Login failed: ${e.message}');
    }
  }

  // Sign in with email and password
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

  // Register with email and password
  Future<AppUser?> registerWithEmail(
    String email,
    String password,
    String username,
    UserRole role,
  ) async {
    try {
      final existingUser = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
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
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isActive: true,
          points: 125,
          preferences: {
            'notifications': true,
            'theme': 'light',
          },
        );

        await _firestore.collection('users').doc(user.uid).set(appUser.toMap());
        return appUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
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

      // ── Mobile flow ──
      await _ensureGoogleInitialized();

      // 1. Authenticate (replaces signIn() in v7)
      final account = await _googleSignIn.authenticate();
      googleUser = account;

      // 2. Authorize to get an access token (v7 no longer returns it
      //    from authentication)
      final authorization =
          await googleUser.authorizationClient.authorizationForScopes(
        ['email', 'profile'],
      ) ??
              await googleUser.authorizationClient.authorizeScopes(
                ['email', 'profile'],
              );

      // 3. Get the ID token from the authentication object
      final idToken = googleUser.authentication.idToken;

      // 4. Build the Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
        idToken: idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return null;
      return await _handleGoogleUser(user);
    } on GoogleSignInException catch (e) {
      // User cancelled or other Google-specific error
      debugPrint('GoogleSignInException: ${e.code} ${e.description}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      throw Exception('Google sign-in failed: ${e.description ?? e.code}');
    } catch (e) {
      rethrow;
    }
  }

  // Shared post-sign-in handling for both web & mobile
  Future<AppUser?> _handleGoogleUser(User user) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      await _createUserDocument(user);
    } else {
      await _updateLastLogin(user.uid);
    }
    return await getCurrentUserData();
  }

  // Create user document
  Future<AppUser> _createUserDocument(User user) async {
    final username = user.displayName ?? user.email?.split('@').first ?? 'User';
    final appUser = AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: username,
      username: username,
      role: UserRole.user,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isActive: true,
      points: 125,
      preferences: {
        'notifications': true,
        'theme': 'light',
      },
    );
    await _firestore.collection('users').doc(user.uid).set(appUser.toMap());
    return appUser;
  }

  // Update last login time
  Future<void> _updateLastLogin(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'isActive': false,
        });
      }
      if (!kIsWeb && _googleInitialized) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Handle auth exceptions
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

  // Update user profile
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
        await _firestore.collection('users').doc(user.uid).update(updates);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get user by ID
  Future<AppUser?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      return query.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }

  // Delete user account
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