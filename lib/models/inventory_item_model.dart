import 'package:cloud_firestore/cloud_firestore.dart';


enum InventoryType {
  ingredient, 
  supply,    
}

class InventoryItemModel {
  final String id;
  String name;
  String unit;            
  double stock;        
  double minLevel;       
  InventoryType type;   
  String? supplier;
  DateTime? updatedAt;

  InventoryItemModel({
    required this.id,
    required this.name,
    required this.unit,
    required this.stock,
    required this.minLevel,
    this.type = InventoryType.ingredient,  
    this.supplier,
    this.updatedAt,
  });

  bool get isLow => stock <= minLevel;
  bool get isOut => stock <= 0;
  bool get isIngredient => type == InventoryType.ingredient;
  bool get isSupply => type == InventoryType.supply;

  InventoryItemModel copyWith({
    String? name,
    String? unit,
    double? stock,
    double? minLevel,
    InventoryType? type,
    String? supplier,
    DateTime? updatedAt,
  }) {
    return InventoryItemModel(
      id: id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      minLevel: minLevel ?? this.minLevel,
      type: type ?? this.type,
      supplier: supplier ?? this.supplier,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory InventoryItemModel.fromMap(String id, Map<String, dynamic> map) {
    InventoryType parsedType;
    final rawType = (map['type'] ?? '').toString().toLowerCase();
    switch (rawType) {
      case 'supply':
      case 'non-ingredient':
      case 'noningredient':
        parsedType = InventoryType.supply;
        break;
      case 'ingredient':
      default:
        parsedType = InventoryType.ingredient;
    }

    return InventoryItemModel(
      id: id,
      name: map['name'] ?? '',
      unit: map['unit'] ?? 'pcs',
      stock: (map['stock'] as num?)?.toDouble() ?? 0,
      minLevel: (map['minLevel'] as num?)?.toDouble() ?? 0,
      type: parsedType,
      supplier: map['supplier'] as String?,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'unit': unit,
      'stock': stock,
      'minLevel': minLevel,
      'type': type.name,             
      'supplier': supplier,
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}