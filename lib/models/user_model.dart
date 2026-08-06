import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? username;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final bool? isActive;
  final int? points;
  final Map<String, dynamic>? preferences;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.username,
    this.createdAt,
    this.lastLoginAt,
    this.isActive,
    this.points,
    this.preferences,
  });

  // Create from Firebase User (Auth)
  factory AppUser.fromFirebaseUser(User user) {
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
      username: user.displayName, // Default to displayName
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isActive: true,
      points: 0,
      preferences: {
        'notifications': true,
        'theme': 'light',
      },
    );
  }

  // Create from Firestore Document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? data['username'],
      photoURL: data['photoURL'],
      username: data['username'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      points: data['points'] ?? 0,
      preferences: data['preferences'] ?? {},
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'username': username,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : FieldValue.serverTimestamp(),
      'isActive': isActive ?? true,
      'points': points ?? 0,
      'preferences': preferences ?? {},
    };
  }

  // Update User Data
  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? username,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    int? points,
    Map<String, dynamic>? preferences,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      points: points ?? this.points,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, displayName: $displayName, username: $username)';
  }
}