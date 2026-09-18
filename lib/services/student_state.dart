// lib/services/student_state.dart
import 'package:flutter/material.dart';

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
  static final StudentAppState _instance = StudentAppState._internal();
  factory StudentAppState() => _instance;
  StudentAppState._internal();

  // ---------------- Tabs ----------------
  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  void setTabIndex(int index) {
    if (_selectedTabIndex == index) return;
    _selectedTabIndex = index;
    notifyListeners();
  }

  // ---------------- Loyalty points ----------------
  // Starts at 0; load real value from Firestore where needed.
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

  void updateQuantity(String id, int delta) {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final newQty = _cartItems[index].quantity + delta;
    if (newQty <= 0) {
      _cartItems.removeAt(index);
    } else {
      _cartItems[index].quantity = newQty;
    }
    notifyListeners();
  }

  void addToCart(
    String id,
    String name,
    double price,
    String imageUrl,
    IconData icon,
  ) {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      _cartItems[index].quantity += 1;
    } else {
      _cartItems.add(
        StudentCartItem(
          id: id,
          name: name,
          price: price,
          imageUrl: imageUrl,
          fallbackIcon: icon,
          quantity: 1,
        ),
      );
    }
    notifyListeners();
  }

  void removeFromCart(String id) {
    _cartItems.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // ---------------- Orders ----------------
  final List<StudentOrderItem> _orders = [];
  List<StudentOrderItem> get orders => _orders;

  void placeOrder(String paymentMethod) {
    if (_cartItems.isEmpty) return;

    final newOrder = StudentOrderItem(
      orderNumber: '#${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      status: 'Pending',
      dateTime: 'Just now',
      items: _cartItems.map((e) => '${e.name} x${e.quantity}').toList(),
      totalAmount: subtotal,
    );

    _orders.insert(0, newOrder);
    _cartItems.clear();
    notifyListeners();
  }
}