import 'package:cloud_firestore/cloud_firestore.dart';

class LoginLookupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Future<LoginLookupRecord?> lookup(String identifier) async {
    final raw = identifier.trim();
    if (raw.isEmpty) return null;

    final lower = raw.toLowerCase();
    final candidates = <String>[lower];
    final stripped = lower.replaceAll(RegExp(r'[\s\-]'), '');
    if (stripped != lower) candidates.add(stripped);

    final digitsOnly = lower.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length >= 8 && digitsOnly.length <= 12) {
      final formatted =
          '${digitsOnly.substring(0, 4)}-${digitsOnly.substring(4)}';
      if (!candidates.contains(formatted)) candidates.add(formatted);
    }

    for (final id in candidates) {
      try {
        final doc = await _db.collection('login_lookup').doc(id).get();
        if (doc.exists) {
          return LoginLookupRecord.fromMap(doc.data()!);
        }
      } catch (_) {

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