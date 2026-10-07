// lib/services/login_lookup_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginLookupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Try to resolve an identifier (email / username / student ID) to a
  /// login record via the public `login_lookup` collection.
  ///
  /// Handles:
  ///   • Case-insensitivity  → lowercased doc IDs
  ///   • Spaces in usernames → tries "canteen admin" first
  ///   • Student IDs        → "2023-12345" and "202312345"
  Future<LoginLookupRecord?> lookup(String identifier) async {
    final raw = identifier.trim();
    if (raw.isEmpty) return null;

    final lower = raw.toLowerCase();

    // Build candidate doc IDs (in priority order).
    final candidates = <String>[];
    void addIfNew(String s) {
      if (s.isNotEmpty && !candidates.contains(s)) candidates.add(s);
    }

    // 1. Raw lowercased form ("canteen admin", "juan@x.com")
    addIfNew(lower);

    // 2. Trimmed whitespace variants (in case of double spaces)
    addIfNew(lower.replaceAll(RegExp(r'\s+'), ' '));

    // 3. Dash/space stripped ("202312345", "canteenadmin")
    final stripped = lower.replaceAll(RegExp(r'[\s\-]'), '');
    addIfNew(stripped);

    // 4. Student ID formatted with dash: 2023-12345
    final digitsOnly = lower.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length >= 8 && digitsOnly.length <= 12) {
      addIfNew('${digitsOnly.substring(0, 4)}-${digitsOnly.substring(4)}');
    }

    for (final id in candidates) {
      try {
        final doc = await _db.collection('login_lookup').doc(id).get();
        if (doc.exists) {
          return LoginLookupRecord.fromMap(doc.data()!);
        }
      } catch (_) {
        // Permission/network error — try next candidate.
      }
    }

    return null;
  }
}

class LoginLookupRecord {
  final String uid;
  final String email;
  final String? displayName;
  final String? username;
  final String? studentId;
  final String accountStatus;

  LoginLookupRecord({
    required this.uid,
    required this.email,
    required this.accountStatus,
    this.displayName,
    this.username,
    this.studentId,
  });

  factory LoginLookupRecord.fromMap(Map<String, dynamic> m) {
    return LoginLookupRecord(
      uid: (m['uid'] ?? '').toString(),
      email: (m['email'] ?? '').toString(),
      displayName: m['displayName']?.toString(),
      username: m['username']?.toString(),
      studentId: m['studentId']?.toString(),
      accountStatus: (m['accountStatus'] ?? 'active').toString(),
    );
  }

  bool get isPending => accountStatus == 'pending';
  bool get isSuspended => accountStatus == 'suspended';
  bool get isActive => accountStatus == 'active';
}