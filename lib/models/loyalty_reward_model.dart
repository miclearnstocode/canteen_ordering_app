// lib/models/loyalty_reward_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LoyaltyReward {
  final String id;
  String name;
  int points;
  String? imageUrl;
  bool isActive;
  DateTime? updatedAt;

  LoyaltyReward({
    required this.id,
    required this.name,
    required this.points,
    this.imageUrl,
    this.isActive = true,
    this.updatedAt,
  });

  factory LoyaltyReward.fromMap(String id, Map<String, dynamic> map) {
    return LoyaltyReward(
      id: id,
      name: map['name'] ?? '',
      points: (map['points'] as num?)?.toInt() ?? 0,
      imageUrl: map['imageUrl'] as String?,
      isActive: map['isActive'] ?? true,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'points': points,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  LoyaltyReward copyWith({
    String? name,
    int? points,
    String? imageUrl,
    bool? isActive,
  }) {
    return LoyaltyReward(
      id: id,
      name: name ?? this.name,
      points: points ?? this.points,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt,
    );
  }
}