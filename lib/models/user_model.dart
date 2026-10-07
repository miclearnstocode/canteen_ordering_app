// lib/models/user_model.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, admin }

enum AccountStatus {
  pending,   // created by admin, credentials not yet released
  active,    // credentials released to student
  suspended,
}

class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? username;
  final UserRole role;
  final AccountStatus accountStatus;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final bool? isActive;
  final int? points;
  final double credits;              // 1 credit = ₱1
  final String? studentId;           // e.g. "2023-12345"
  final String? course;
  final String? tempPassword;        // only used while pending
  final Map<String, dynamic>? preferences;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.username,
    this.role = UserRole.user,
    this.accountStatus = AccountStatus.pending,
    this.createdAt,
    this.lastLoginAt,
    this.isActive,
    this.points,
    this.credits = 0.0,
    this.studentId,
    this.course,
    this.tempPassword,
    this.preferences,
  });

  factory AppUser.fromFirebaseUser(User user, {UserRole role = UserRole.user}) {
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
      username: user.displayName,
      role: role,
      accountStatus: AccountStatus.active,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isActive: true,
      points: 0,
      credits: 0.0,
      preferences: {'notifications': true, 'theme': 'light'},
    );
  }

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final isAdminDoc = data['role'] == 'admin';
    final UserRole role = isAdminDoc ? UserRole.admin : UserRole.user;

    // ── Admin bypass: admins are never gated by account status ──
    // If the doc is an admin, short-circuit every status check and
    // return immediately with a forced-active account.
    if (isAdminDoc) {
      return AppUser(
        uid: doc.id,
        email: data['email'] ?? '',
        displayName: data['displayName'] ?? data['username'],
        photoURL: data['photoURL'],
        username: data['username'],
        role: UserRole.admin,
        accountStatus: AccountStatus.active,   // forced, ignores stored field
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
        isActive: data['isActive'] ?? true,
        points: data['points'] ?? 0,
        credits: (data['credits'] as num?)?.toDouble() ?? 0.0,
        studentId: data['studentId'],
        course: data['course'],
        tempPassword: data['tempPassword'],
        preferences: data['preferences'] ?? {},
      );
    }

    // ── Non-admin path: status logic as before ──
    AccountStatus status;
    switch (data['accountStatus']) {
      case 'pending':
        status = AccountStatus.pending;
        break;
      case 'suspended':
        status = AccountStatus.suspended;
        break;
      case 'active':
        status = AccountStatus.active;
        break;
      default:
        status = AccountStatus.active;
        break;
    }

    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? data['username'],
      photoURL: data['photoURL'],
      username: data['username'],
      role: role,
      accountStatus: status,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      points: data['points'] ?? 0,
      credits: (data['credits'] as num?)?.toDouble() ?? 0.0,
      studentId: data['studentId'],
      course: data['course'],
      tempPassword: data['tempPassword'],
      preferences: data['preferences'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'username': username,
      'role': role == UserRole.admin ? 'admin' : 'user',
      'accountStatus': accountStatus.name,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : FieldValue.serverTimestamp(),
      'isActive': isActive ?? true,
      'points': points ?? 0,
      'credits': credits,
      'studentId': studentId,
      'course': course,
      'tempPassword': tempPassword,
      'preferences': preferences ?? {},
    };
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isUser => role == UserRole.user;
  bool get isPending => accountStatus == AccountStatus.pending;
  bool get isActiveAccount => accountStatus == AccountStatus.active;

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? username,
    UserRole? role,
    AccountStatus? accountStatus,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    int? points,
    double? credits,
    String? studentId,
    String? course,
    String? tempPassword,
    Map<String, dynamic>? preferences,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      username: username ?? this.username,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      points: points ?? this.points,
      credits: credits ?? this.credits,
      studentId: studentId ?? this.studentId,
      course: course ?? this.course,
      tempPassword: tempPassword ?? this.tempPassword,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  String toString() =>
      'AppUser(uid: $uid, email: $email, role: $role, status: $accountStatus, credits: $credits)';
}