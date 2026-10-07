// lib/services/login_lookup_sync.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class LoginLookupSync {
  static final _db = FirebaseFirestore.instance;

  /// Upserts the lookup docs for [user].
  /// Writes one doc per identifier: email, username, studentId (both
  /// canonical and dash/space-stripped).
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

    final ids = _idsFor(
      email: user.email,
      username: user.username,
      studentId: user.studentId,
    );

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

  /// Updates only the `accountStatus` on all lookup docs for a user.
  /// Uses set+merge so a missing doc is created rather than failing
  /// the whole batch.
  static Future<void> updateStatus({
    required String uid,
    required String email,
    String? username,
    String? studentId,
    required String newStatus,
  }) async {
    final ids = _idsFor(
      email: email,
      username: username,
      studentId: studentId,
    );

    if (ids.isEmpty) return;

    final batch = _db.batch();
    for (final id in ids) {
      batch.set(
        _db.collection('login_lookup').doc(id),
        {
          'uid': uid,
          'email': email.toLowerCase(),
          'username': username,
          'studentId': studentId,
          'accountStatus': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  /// Deletes all lookup docs for a user.
  static Future<void> remove({
    required String email,
    String? username,
    String? studentId,
  }) async {
    final ids = _idsFor(
      email: email,
      username: username,
      studentId: studentId,
    );

    if (ids.isEmpty) return;

    final batch = _db.batch();
    for (final id in ids) {
      batch.delete(_db.collection('login_lookup').doc(id));
    }
    await batch.commit();
  }

  // ── Internals ─────────────────────────────────────────────────────────

  static Set<String> _idsFor({
    required String email,
    String? username,
    String? studentId,
  }) {
    final ids = <String>{};

    if (email.trim().isNotEmpty) {
      ids.add(email.trim().toLowerCase());
    }

    if (username != null && username.trim().isNotEmpty) {
      final u = username.trim().toLowerCase();
      ids.add(u);
      // Also add a whitespace-collapsed variant ("canteen admin" stays,
      // but "canteen   admin" becomes "canteen admin").
      final collapsed = u.replaceAll(RegExp(r'\s+'), ' ');
      if (collapsed != u) ids.add(collapsed);
    }

    if (studentId != null && studentId.trim().isNotEmpty) {
      final sid = studentId.trim().toLowerCase();
      ids.add(sid);
      final stripped = sid.replaceAll(RegExp(r'[\s\-]'), '');
      if (stripped != sid) ids.add(stripped);
    }

    return ids;
  }
}