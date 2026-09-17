// lib/services/admin_account_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';

class AdminAccountService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Creates a Firebase Auth user on a *secondary* Firebase App so the
  /// admin's current session is never touched, then writes the matching
  /// Firestore doc with status = pending.
  ///
  /// The student cannot log in yet — the login page blocks `pending`
  /// accounts. Call [releaseAccount] to flip them to `active`.
  Future<String> createPendingAccount({
    required String fullName,
    required String email,
    required String studentId,
    required String course,
    required String tempPassword,
  }) async {
    final cleanEmail = email.trim();
    final cleanPassword = tempPassword.trim();

    if (cleanEmail.isEmpty) {
      throw Exception('Email is required.');
    }
    if (cleanPassword.length < 6) {
      throw Exception('Temporary password must be at least 6 characters.');
    }

    User? authUser;

    // ---- 1. Create the Auth user on a throwaway secondary app ----
    const secondaryAppName = 'admin_account_creator';

    FirebaseApp? secondaryApp;
    try {
      // Reuse the secondary app if it was already initialized, otherwise
      // initialize it from the primary app's options.
      try {
        secondaryApp = Firebase.app(secondaryAppName);
      } catch (_) {
        secondaryApp = await Firebase.initializeApp(
          name: secondaryAppName,
          options: Firebase.app().options,
        );
      }

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );
      authUser = cred.user;

      // Sign the secondary session out so no stale session lingers.
      await secondaryAuth.signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('An account with this email already exists.');
      }
      if (e.code == 'weak-password') {
        throw Exception('Password is too weak. Use at least 6 characters.');
      }
      if (e.code == 'invalid-email') {
        throw Exception('Invalid email address format.');
      }
      throw Exception('Failed to create account: ${e.message}');
    }

    if (authUser == null) {
      throw Exception('Account creation failed. Please try again.');
    }

    // ---- 2. Write the Firestore profile doc ----
    final docRef = _db.collection('users').doc(authUser.uid);

    final user = AppUser(
      uid: authUser.uid,
      email: cleanEmail,
      displayName: fullName.trim(),
      username: fullName.trim(),
      studentId: studentId.trim(),
      course: course.trim(),
      role: UserRole.user,
      accountStatus: AccountStatus.pending,
      tempPassword: cleanPassword,
      createdAt: DateTime.now(),
      isActive: true,
      points: 0,
      credits: 0.0,
      preferences: {
        'notifications': true,
        'theme': 'light',
      },
    );

    await docRef.set(user.toMap());
    return docRef.id;
  }

  /// Marks the account active and removes the temp password so the student
  /// can sign in with the credentials that were handed to them.
  ///
  /// Assumes the Firebase Auth user was already created by
  /// [createPendingAccount].
  Future<void> releaseAccount(String uid) async {
    final userRef = _db.collection('users').doc(uid);
    final snap = await userRef.get();
    if (!snap.exists) {
      throw Exception('Account not found.');
    }

    await userRef.update({
      'accountStatus': AccountStatus.active.name,
      'tempPassword': FieldValue.delete(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Adds credits (1 credit = ₱1) after the admin receives the cash.
  /// Also records a transaction in `credit_transactions` for the audit log.
  Future<void> addCredits({
    required String uid,
    required double amountInPesos,
    String? note,
  }) async {
    if (amountInPesos <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }

    final userRef = _db.collection('users').doc(uid);
    final txRef = _db.collection('credit_transactions').doc();

    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(userRef);
      if (!snapshot.exists) throw Exception('User not found');

      final current = (snapshot.data()?['credits'] as num?)?.toDouble() ?? 0.0;
      final newBalance = current + amountInPesos;

      tx.update(userRef, {
        'credits': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(txRef, {
        'uid': uid,
        'type': 'credit',
        'amount': amountInPesos,
        'balanceAfter': newBalance,
        'note': note ?? 'Cash payment',
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Deduct credits (used when the student places an order).
  Future<void> deductCredits({
    required String uid,
    required double amountInPesos,
    String? note,
  }) async {
    if (amountInPesos <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }

    final userRef = _db.collection('users').doc(uid);
    final txRef = _db.collection('credit_transactions').doc();

    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(userRef);
      if (!snapshot.exists) throw Exception('User not found');

      final current = (snapshot.data()?['credits'] as num?)?.toDouble() ?? 0.0;
      if (current < amountInPesos) {
        throw Exception('Insufficient credits.');
      }
      final newBalance = current - amountInPesos;

      tx.update(userRef, {
        'credits': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(txRef, {
        'uid': uid,
        'type': 'debit',
        'amount': amountInPesos,
        'balanceAfter': newBalance,
        'note': note ?? 'Order payment',
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Live list of every student account (for the admin directory page).
  /// Sorted client-side so no composite Firestore index is required.
  Stream<List<AppUser>> studentsStream() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'user')
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => AppUser.fromFirestore(d)).toList();
          list.sort((a, b) {
            final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime); // newest first
          });
          return list;
        });
  }
}