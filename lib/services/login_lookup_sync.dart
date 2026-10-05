import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';


class LoginLookupSync {
  static final _db = FirebaseFirestore.instance;

  static Future<void> upsert(AppUser user) async {
    final payload = {
      'uid': user.uid,
      'email': user.email.toLowerCase(),
      'displayName': user.displayName,
      'username': user.username,
      'studentId': user.studentId,
      'accountStatus': user.accountStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final ids = <String>{};

    // Email is always present.
    if (user.email.isNotEmpty) ids.add(user.email.toLowerCase());

    // Username (if set).
    if (user.username != null && user.username!.trim().isNotEmpty) {
      ids.add(user.username!.trim().toLowerCase());
    }

    // Student ID — store BOTH the canonical form and a dashes-stripped
    // variant so users can type it either way.
    if (user.studentId != null && user.studentId!.trim().isNotEmpty) {
      final sid = user.studentId!.trim().toLowerCase();
      ids.add(sid);
      final stripped = sid.replaceAll(RegExp(r'[\s\-]'), '');
      if (stripped != sid) ids.add(stripped);
    }

    if (ids.isEmpty) return;

    final batch = _db.batch();
    for (final id in ids) {
      batch.set(
        _db.collection('login_lookup').doc(id),
        payload,
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  /// Updates only the `accountStatus` on all existing lookup docs for [uid].
  /// Used when admin flips pending → active, or active → suspended.
  ///
  /// We can't query by `uid` without a composite index and admin rights,
  /// so we look up the user doc first to know which identifiers exist.
  static Future<void> updateStatus({
    required String uid,
    required String email,
    String? username,
    String? studentId,
    required String newStatus,
  }) async {
    final ids = <String>{};
    if (email.isNotEmpty) ids.add(email.toLowerCase());
    if (username != null && username.trim().isNotEmpty) {
      ids.add(username.trim().toLowerCase());
    }
    if (studentId != null && studentId.trim().isNotEmpty) {
      final sid = studentId.trim().toLowerCase();
      ids.add(sid);
      final stripped = sid.replaceAll(RegExp(r'[\s\-]'), '');
      if (stripped != sid) ids.add(stripped);
    }

    final batch = _db.batch();
    for (final id in ids) {
      batch.update(
        _db.collection('login_lookup').doc(id),
        {
          'accountStatus': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    }
    await batch.commit();
  }

  /// Deletes all lookup docs for a user (used when account is deleted).
  static Future<void> remove({
    required String email,
    String? username,
    String? studentId,
  }) async {
    final ids = <String>{};
    if (email.isNotEmpty) ids.add(email.toLowerCase());
    if (username != null && username.trim().isNotEmpty) {
      ids.add(username.trim().toLowerCase());
    }
    if (studentId != null && studentId.trim().isNotEmpty) {
      final sid = studentId.trim().toLowerCase();
      ids.add(sid);
      final stripped = sid.replaceAll(RegExp(r'[\s\-]'), '');
      if (stripped != sid) ids.add(stripped);
    }

    final batch = _db.batch();
    for (final id in ids) {
      batch.delete(_db.collection('login_lookup').doc(id));
    }
    await batch.commit();
  }
}