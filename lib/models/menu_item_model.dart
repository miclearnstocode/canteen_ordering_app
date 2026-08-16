// lib/models/menu_item_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum MenuCategory {
  meals,
  drinks,
  pastas,
  snacks,
  desserts,
  others,
}

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final MenuCategory category;
  final String? imageUrl;
  final bool isAvailable;
  final int stock;
  final bool isFeatured;
  final int preparationTime; // in minutes
  final List<String> tags;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    this.isAvailable = true,
    this.stock = 0,
    this.isFeatured = false,
    this.preparationTime = 10,
    this.tags = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MenuItem(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: _parseCategory(data['category'] ?? 'others'),
      imageUrl: data['imageUrl'],
      isAvailable: data['isAvailable'] ?? true,
      stock: data['stock'] ?? 0,
      isFeatured: data['isFeatured'] ?? false,
      preparationTime: data['preparationTime'] ?? 10,
      tags: List<String>.from(data['tags'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static MenuCategory _parseCategory(String value) {
    switch (value.toLowerCase()) {
      case 'meals':
        return MenuCategory.meals;
      case 'drinks':
        return MenuCategory.drinks;
      case 'pastas':
        return MenuCategory.pastas;
      case 'snacks':
        return MenuCategory.snacks;
      case 'desserts':
        return MenuCategory.desserts;
      case 'others':
        return MenuCategory.others;
      default:
        return MenuCategory.others;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category.name,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'stock': stock,
      'isFeatured': isFeatured,
      'preparationTime': preparationTime,
      'tags': tags,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String get formattedPrice => '₱${price.toStringAsFixed(2)}';
  String get categoryDisplayName => category.name.toUpperCase();
  bool get isInStock => stock > 0 && isAvailable;
}