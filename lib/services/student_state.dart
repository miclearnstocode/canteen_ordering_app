// lib/services/student_state.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentCartItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final IconData fallbackIcon;
  int quantity;
  int availableStock;

  StudentCartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.fallbackIcon,
    this.quantity = 1,
    this.availableStock = 0,
  });

  // ---- Persistence helpers ----
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
        'fallbackIconCodePoint': fallbackIcon.codePoint,
        'quantity': quantity,
        'availableStock': availableStock,
      };

  factory StudentCartItem.fromMap(Map<String, dynamic> map) {
    return StudentCartItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'] ?? '',
      fallbackIcon: _iconFromCodePoint(
          (map['fallbackIconCodePoint'] as num?)?.toInt()),
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      availableStock: (map['availableStock'] as num?)?.toInt() ?? 0,
    );
  }

  // Map a stored codePoint back to an IconData. Falls back to a
  // sensible default if the codePoint is missing/unknown.
  static IconData _iconFromCodePoint(int? codePoint) {
    if (codePoint == null) return Icons.fastfood;
    // Add more cases here if you use other icons in the cart.
    if (codePoint == Icons.local_cafe.codePoint) return Icons.local_cafe;
    if (codePoint == Icons.fastfood.codePoint) return Icons.fastfood;
    if (codePoint == Icons.lunch_dining.codePoint) return Icons.lunch_dining;
    return Icons.fastfood;
  }
}

class StudentRewardItem {
  final String id;
  final String name;
  final int points;
  final String imageUrl;
  final IconData icon;

  StudentRewardItem({
    required this.id,
    required this.name,
    required this.points,
    required this.imageUrl,
    required this.icon,
  });
}

class StudentOrderItem {
  final String orderNumber;
  final String status; // Pending, Preparing, Ready, Completed
  final String dateTime;
  final List<String> items;
  final double totalAmount;

  StudentOrderItem({
    required this.orderNumber,
    required this.status,
    required this.dateTime,
    required this.items,
    required this.totalAmount,
  });
}

class StudentAppState extends ChangeNotifier {
  // ---------------- Singleton ----------------
  static final StudentAppState _instance = StudentAppState._internal();
  factory StudentAppState() => _instance;
  StudentAppState._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------------- Tabs ----------------
  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  void setTabIndex(int index) {
    if (_selectedTabIndex == index) return;
    _selectedTabIndex = index;
    notifyListeners();
  }

  // ---------------- Loyalty points ----------------
  int _loyaltyPoints = 0;
  int get loyaltyPoints => _loyaltyPoints;

  void setLoyaltyPoints(int points) {
    _loyaltyPoints = points;
    notifyListeners();
  }

  void deductPoints(int points) {
    if (_loyaltyPoints >= points) {
      _loyaltyPoints -= points;
      notifyListeners();
    }
  }

  // ---------------- Cart ----------------
  final List<StudentCartItem> _cartItems = [];
  List<StudentCartItem> get cartItems => _cartItems;

  int get totalCartCount =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  // Prevent overlapping writes when the user taps +/- rapidly.
  bool _persisting = false;

  /// Load the cart from Firestore for the current user.
  /// Call this once on app start or right after sign-in.
  Future<void> loadCartFromFirestore() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final raw = doc.data()?['cart'];
      if (raw is List) {
        _cartItems
          ..clear()
          ..addAll(raw
              .whereType<Map>()
              .map((m) => StudentCartItem.fromMap(
                  Map<String, dynamic>.from(m))));
        notifyListeners();
      }
    } catch (_) {
      // Silently ignore — cart just stays empty.
    }
  }

  /// Save the current cart to Firestore under the user's doc.
  Future<void> _persistCart() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    if (_persisting) return;
    _persisting = true;
    try {
      await _firestore.collection('users').doc(uid).set(
        {
          'cart': _cartItems.map((e) => e.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Ignore — next mutation will retry.
    } finally {
      _persisting = false;
    }
  }

  void updateQuantity(String id, int delta) {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final item = _cartItems[index];
    final newQty = item.quantity + delta;

    if (newQty <= 0) {
      _cartItems.removeAt(index);
    } else if (item.availableStock > 0 && newQty > item.availableStock) {
      // Cap at available stock — don't let the user exceed it.
      item.quantity = item.availableStock;
    } else {
      item.quantity = newQty;
    }

    notifyListeners();
    _persistCart();
  }

  void addToCart(
    String id,
    String name,
    double price,
    String imageUrl,
    IconData icon, {
    int availableStock = 0,
  }) {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = _cartItems[index];
      // Respect stock if we know it.
      if (item.availableStock > 0 && item.quantity >= item.availableStock) {
        // Already at max — just notify so UI can show the badge count.
        notifyListeners();
        return;
      }
      item.quantity += 1;
    } else {
      _cartItems.add(
        StudentCartItem(
          id: id,
          name: name,
          price: price,
          imageUrl: imageUrl,
          fallbackIcon: icon,
          quantity: 1,
          availableStock: availableStock,
        ),
      );
    }
    notifyListeners();
    _persistCart();
  }

  void removeFromCart(String id) {
    _cartItems.removeWhere((item) => item.id == id);
    notifyListeners();
    _persistCart();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
    _persistCart();
  }

  // ---------------- Orders ----------------
  final List<StudentOrderItem> _orders = [];
  List<StudentOrderItem> get orders => _orders;

  void placeOrder(String paymentMethod) {
    if (_cartItems.isEmpty) return;

    final newOrder = StudentOrderItem(
      orderNumber:
          '#${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      status: 'Pending',
      dateTime: 'Just now',
      items: _cartItems.map((e) => '${e.name} x${e.quantity}').toList(),
      totalAmount: subtotal,
    );

    _orders.insert(0, newOrder);
    _cartItems.clear();
    notifyListeners();
    _persistCart();
  }
}