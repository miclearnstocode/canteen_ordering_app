// lib/models/menu_item_model.dart

/// One line of a menu item's recipe:
/// "this dish uses X of ingredient Y per portion".
class RecipeIngredient {
  final String ingredientId;
  final String ingredientName; // denormalized for display
  final String unit;
  final double qtyPerPortion;

  RecipeIngredient({
    required this.ingredientId,
    required this.ingredientName,
    required this.unit,
    required this.qtyPerPortion,
  });

  factory RecipeIngredient.fromMap(Map<String, dynamic> m) {
    return RecipeIngredient(
      ingredientId: m['ingredientId'] ?? '',
      ingredientName: m['ingredientName'] ?? '',
      unit: m['unit'] ?? '',
      qtyPerPortion: (m['qtyPerPortion'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'ingredientId': ingredientId,
        'ingredientName': ingredientName,
        'unit': unit,
        'qtyPerPortion': qtyPerPortion,
      };
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
  List<RecipeIngredient> recipe;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.stock,
    this.isAvailable = true,
    this.imageUrl,
    List<RecipeIngredient>? recipe,
  }) : recipe = recipe ?? [];

  MenuItemModel copyWith({
    String? name,
    String? category,
    double? price,
    String? description,
    int? stock,
    bool? isAvailable,
    String? imageUrl,
    List<RecipeIngredient>? recipe,
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
      recipe: recipe ?? this.recipe,
    );
  }

  factory MenuItemModel.fromMap(String id, Map<String, dynamic> map) {
    final rawRecipe = (map['recipe'] as List?) ?? const [];
    return MenuItemModel(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? 'Meals',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      stock: map['stock'] ?? 0,
      isAvailable: map['isAvailable'] ?? true,
      imageUrl: (map['image_url'] ?? map['imageUrl']) as String?,
      recipe: rawRecipe
          .whereType<Map>()
          .map((e) => RecipeIngredient.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

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
      'recipe': recipe.map((r) => r.toMap()).toList(),
    };
  }
}