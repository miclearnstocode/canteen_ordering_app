import 'package:flutter/material.dart';

class StudentCartItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final IconData fallbackIcon;
  int quantity;

  StudentCartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.fallbackIcon,
    this.quantity = 1,
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

  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  void setTabIndex(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  int _loyaltyPoints = 125;
  int get loyaltyPoints => _loyaltyPoints;

  void deductPoints(int points) {
    if (_loyaltyPoints >= points) {
      _loyaltyPoints -= points;
      notifyListeners();
    }
  }

  // Cart items
  final List<StudentCartItem> _cartItems = [
    StudentCartItem(
      id: 'item_burger',
      name: 'Beef Burger',
      price: 75.0,
      imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300&q=80',
      fallbackIcon: Icons.lunch_dining,
      quantity: 2,
    ),
    StudentCartItem(
      id: 'item_fries',
      name: 'French Fries',
      price: 40.0,
      imageUrl: 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=300&q=80',
      fallbackIcon: Icons.fastfood,
      quantity: 1,
    ),
    StudentCartItem(
      id: 'item_coffee',
      name: 'Iced Coffee',
      price: 50.0,
      imageUrl: 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?w=300&q=80',
      fallbackIcon: Icons.local_cafe,
      quantity: 1,
    ),
  ];

  List<StudentCartItem> get cartItems => _cartItems;

  int get totalCartCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  void updateQuantity(String id, int delta) {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      final newQty = _cartItems[index].quantity + delta;
      if (newQty <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = newQty;
      }
      notifyListeners();
    }
  }

  void addToCart(String id, String name, double price, String imageUrl, IconData icon) {
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

  // Orders
  final List<StudentOrderItem> _orders = [
    StudentOrderItem(
      orderNumber: '#10025',
      status: 'Preparing',
      dateTime: 'May 15, 2024 • 10:30 AM',
      items: ['Chicken Meal x1', 'Beef Burger x2', 'Iced Coffee x1'],
      totalAmount: 315.0,
    ),
    StudentOrderItem(
      orderNumber: '#10020',
      status: 'Ready',
      dateTime: 'May 14, 2024 • 12:15 PM',
      items: ['Milk Tea x1', 'French Fries x1'],
      totalAmount: 110.0,
    ),
    StudentOrderItem(
      orderNumber: '#10018',
      status: 'Completed',
      dateTime: 'May 13, 2024 • 11:50 AM',
      items: ['Beef Burger x1'],
      totalAmount: 75.0,
    ),
  ];

  List<StudentOrderItem> get orders => _orders;

  void placeOrder(String paymentMethod) {
    if (_cartItems.isEmpty) return;

    final newOrder = StudentOrderItem(
      orderNumber: '#100${26 + _orders.length}',
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

