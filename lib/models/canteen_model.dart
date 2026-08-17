
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Canteen {
  final String id;
  final String name;
  final String location;
  final String openTime;
  final String closeTime;
  final bool isOpen;
  final String? phoneNumber;
  final String? email;
  final String? description;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Canteen({
    required this.id,
    required this.name,
    required this.location,
    required this.openTime,
    required this.closeTime,
    required this.isOpen,
    this.phoneNumber,
    this.email,
    this.description,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Canteen.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Canteen(
      id: doc.id,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      openTime: data['openTime'] ?? '',
      closeTime: data['closeTime'] ?? '',
      isOpen: data['isOpen'] ?? true,
      phoneNumber: data['phoneNumber'],
      email: data['email'],
      description: data['description'],
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'openTime': openTime,
      'closeTime': closeTime,
      'isOpen': isOpen,
      'phoneNumber': phoneNumber,
      'email': email,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String get statusText => isOpen ? 'Open' : 'Closed';
  Color get statusColor => isOpen ? Colors.green : Colors.red;
  String get formattedHours => '$openTime - $closeTime';
}