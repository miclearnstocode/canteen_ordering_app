// lib/services/user_stream_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserStreamService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Streams the current logged-in user's Firestore doc as an AppUser.
  /// Emits null when nobody is signed in.
  static Stream<AppUser?> currentUserStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromFirestore(snap);
    });
  }

  /// One-shot fetch (used when you just need the value once).
  static Future<AppUser?> currentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromFirestore(snap);
  }
}