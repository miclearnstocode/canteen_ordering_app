
enum MenuCategory {
  meals,
  drinks,
  pastas,
  snacks,
  desserts,
  others,
}

class MenuItemModel {
  final String id;
  String name;
  String category;
  double price;
  String description;
  int stock;
  bool isAvailable;
  String? imageUrl;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.stock,
    this.isAvailable = true,
    this.imageUrl,
  });

  // Copy with method for updating
  MenuItemModel copyWith({
    String? name,
    String? category,
    double? price,
    String? description,
    int? stock,
    bool? isAvailable,
    String? imageUrl,
  }) {
    return MenuItemModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      description: description ?? this.description,
      stock: stock ?? this.stock,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // Convert from Firestore
  factory MenuItemModel.fromMap(String id, Map<String, dynamic> map) {
    return MenuItemModel(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? 'Meals',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      stock: map['stock'] ?? 0,
      isAvailable: map['isAvailable'] ?? true,
      imageUrl: (map['image_url'] ?? map['imageUrl']) as String?,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'description': description,
      'stock': stock,
      'isAvailable': isAvailable,
      'image_url': imageUrl,
      'imageUrl': imageUrl,
    };
  }
}