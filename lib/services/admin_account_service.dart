import 'dart:math';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:emailjs/emailjs.dart' as emailjs;
import '../models/user_model.dart';

class TopupOtpResult {
  final String requestId;
  final String otp;
  final bool sentViaEmail;
  final String? message;

  const TopupOtpResult({
    required this.requestId,
    required this.otp,
    required this.sentViaEmail,
    this.message,
  });
}

class AdminAccountService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // EmailJS config
  static const String _emailJsServiceId  = 'service_i0vdj6i';
  static const String _emailJsTemplateId = 'template_8f6ccje';
  static const String _emailJsPublicKey  = 'flqF82GLAuasaws5l';

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

  /// ⚠️ DEPRECATED — kept for compatibility only.
  /// The Admin Accounts UI now calls [requestCreditOtp] and
  /// [confirmCreditTopup] below so every top-up requires the OTP.
  @Deprecated('Use requestCreditOtp + confirmCreditTopup instead')
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

  Future<TopupOtpResult> requestCreditOtp({
    required String uid,
    required String studentEmail,
    required double amountInPesos,
    String? note,
  }) async {
    if (amountInPesos <= 0) {
      throw Exception('Amount must be greater than zero.');
    }
    if (studentEmail.trim().isEmpty) {
      throw Exception('Student has no email on file.');
    }

    final expiresAt = DateTime.now().add(const Duration(minutes: 10));
    final randomOtp = (100000 + Random().nextInt(900000)).toString();

    // 1. Persist the request + OTP (this is what confirmCreditTopup reads).
    final reqRef = await _db.collection('credit_topup_requests').add({
      'uid': uid,
      'studentEmail': studentEmail.trim(),
      'amount': amountInPesos,
      'note': note ?? 'Counter top-up',
      'otp': randomOtp,
      'status': 'pending', // pending | confirmed | expired | cancelled
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'requestedBy': FirebaseAuth.instance.currentUser?.uid,
    });

    // 2. Send the OTP email via EmailJS.
    bool sentViaEmail = false;
    String? emailMessage;

    try {
      await emailjs.send(
        _emailJsServiceId,
        _emailJsTemplateId,
        {
          'to_email': studentEmail.trim(),
          'otp': randomOtp,
          'amount': amountInPesos.toStringAsFixed(2),
          'expires_minutes': '10',
        },
        const emailjs.Options(
          publicKey: _emailJsPublicKey,
          privateKey: 'nyIGsznvJtPS4Ysn3QzmA', 
        ),
      );
      sentViaEmail = true;
      emailMessage = 'OTP emailed to ${studentEmail.trim()}.';
    } catch (e) {
      // Never block the admin — they can read the OTP to the student.
      debugPrint('[AdminAccountService] EmailJS send failed: $e');
      sentViaEmail = false;
      emailMessage =
          'Email could not be sent. Read the OTP to the student manually.';
    }

    return TopupOtpResult(
      requestId: reqRef.id,
      otp: randomOtp,
      sentViaEmail: sentViaEmail,
      message: emailMessage,
    );
  }

  /// Step 2 — verify the OTP against Firestore and apply the credits
  /// atomically. No Cloud Function required.
  Future<void> confirmCreditTopup({
    required String requestId,
    required String enteredOtp,
  }) async {
    final cleanOtp = enteredOtp.trim();
    if (cleanOtp.length != 6) {
      throw Exception('Please enter the full 6-digit OTP.');
    }

    final reqRef = _db.collection('credit_topup_requests').doc(requestId);
    final reqSnap = await reqRef.get();
    if (!reqSnap.exists) {
      throw Exception('Top-up request not found or has expired.');
    }

    final reqData = reqSnap.data()!;
    final status = (reqData['status'] ?? '').toString();
    if (status == 'confirmed') {
      throw Exception('This top-up request has already been confirmed.');
    }
    if (status == 'cancelled') {
      throw Exception('This top-up request was cancelled.');
    }
    if (status == 'expired') {
      throw Exception('The OTP has expired. Please request a new one.');
    }

    final expiresAt = (reqData['expiresAt'] as Timestamp?)?.toDate();
    if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
      await reqRef.update({'status': 'expired'});
      throw Exception('The OTP has expired. Please request a new one.');
    }

    final expectedOtp = (reqData['otp'] ?? '').toString().trim();
    if (expectedOtp.isEmpty || expectedOtp != cleanOtp) {
      throw Exception('Incorrect OTP. Please enter the valid 6-digit code.');
    }

    final uid = (reqData['uid'] ?? '').toString();
    final amount = (reqData['amount'] as num?)?.toDouble() ?? 0.0;
    final note = (reqData['note'] ?? 'Counter top-up').toString();

    if (uid.isEmpty || amount <= 0) {
      throw Exception('Invalid top-up request data.');
    }

    final userRef = _db.collection('users').doc(uid);
    final txRef = _db.collection('credit_transactions').doc();

    await _db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      if (!userSnap.exists) throw Exception('Student account not found.');

      final currentBalance =
          (userSnap.data()?['credits'] as num?)?.toDouble() ?? 0.0;
      final newBalance = currentBalance + amount;

      tx.update(userRef, {
        'credits': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(txRef, {
        'uid': uid,
        'type': 'credit',
        'amount': amount,
        'balanceAfter': newBalance,
        'note': note,
        'timestamp': FieldValue.serverTimestamp(),
      });

      tx.update(reqRef, {
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
        // Remove the plaintext OTP once used.
        'otp': FieldValue.delete(),
      });
    });
  }

  /// Cancels a pending credit top-up request.
  Future<void> cancelCreditTopup(String requestId) async {
    try {
      await _db.collection('credit_topup_requests').doc(requestId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'otp': FieldValue.delete(),
      });
    } catch (_) {}
  }
}