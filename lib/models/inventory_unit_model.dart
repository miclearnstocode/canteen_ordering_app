// lib/models/inventory_unit_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryUnitModel {
  final String id;
  String name;
  DateTime? createdAt;

  InventoryUnitModel({
    required this.id,
    required this.name,
    this.createdAt,
  });

  factory InventoryUnitModel.fromMap(String id, Map<String, dynamic> map) {
    return InventoryUnitModel(
      id: id,
      name: map['name'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}