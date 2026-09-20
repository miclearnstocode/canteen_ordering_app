// lib/pages/orders_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/student_state.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});
  static const Color primaryColor = Color(0xFF1E7B3B);

  @override
  Widget build(BuildContext context) {
    final state = StudentAppState();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.black87, size: 20),
            onPressed: () => state.setTabIndex(0),
          ),
          centerTitle: true,
          title: Text(
            'My Orders',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey.shade500,
            indicatorColor: primaryColor,
            indicatorWeight: 3,
            labelStyle:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle:
                GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Preparing'),
              Tab(text: 'Ready'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: uid == null
            ? _buildEmpty('Please log in to view orders')
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('userId', isEqualTo: uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Failed to load orders:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                    );
                  }

                  // Convert to a list of maps and sort newest first.
                  final orders = (snapshot.data?.docs ?? [])
                      .map((d) => _Order.fromDoc(d))
                      .toList()
                    ..sort((a, b) {
                      final aT = a.createdAt ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                      final bT = b.createdAt ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                      return bT.compareTo(aT);
                    });

                  return TabBarView(
                    children: [
                      _buildList(context, orders, null),
                      _buildList(context, orders, 'pending'),
                      _buildList(context, orders, 'preparing'),
                      _buildList(context, orders, 'ready'),
                      _buildList(context, orders, 'completed'),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
      BuildContext context, List<_Order> allOrders, String? filterStatus) {
    final filtered = filterStatus == null
        ? allOrders
        : allOrders
            .where((o) => o.status.toLowerCase() == filterStatus)
            .toList();

    if (filtered.isEmpty) {
      final label = filterStatus == null
          ? ''
          : '${filterStatus[0].toUpperCase()}${filterStatus.substring(1)} ';
      return _buildEmpty('No ${label}orders');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildOrderCard(filtered[index]),
    );
  }

  Widget _buildOrderCard(_Order order) {
    Color badgeBgColor;
    Color badgeTextColor;

    switch (order.status.toLowerCase()) {
      case 'preparing':
        badgeBgColor = const Color(0xFFFFF3E0);
        badgeTextColor = const Color(0xFFEF6C00);
        break;
      case 'ready':
        badgeBgColor = const Color(0xFFE8F5E9);
        badgeTextColor = const Color(0xFF2E7D32);
        break;
      case 'completed':
        badgeBgColor = const Color(0xFFE0F2F1);
        badgeTextColor = const Color(0xFF00796B);
        break;
      case 'cancelled':
        badgeBgColor = const Color(0xFFFFEBEE);
        badgeTextColor = const Color(0xFFC62828);
        break;
      case 'pending':
      default:
        badgeBgColor = const Color(0xFFFFF8E1);
        badgeTextColor = const Color(0xFFF57F17);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.orderNumber}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: badgeTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            order.formattedDateTime,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${item.name} x${item.quantity}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Total: ',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  TextSpan(
                    text: '₱${order.total.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Internal order model ----------
class _Order {
  final String id;
  final String orderNumber;
  final String status;
  final DateTime? createdAt;
  final List<_OrderLine> items;
  final double total;

  _Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.createdAt,
    required this.items,
    required this.total,
  });

  factory _Order.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawItems = (data['items'] as List?) ?? [];
    return _Order(
      id: doc.id,
      orderNumber: data['orderNumber'] ?? doc.id.substring(0, 8).toUpperCase(),
      status: (data['status'] ?? 'Pending').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      items: rawItems
          .map((e) => _OrderLine.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String get formattedDateTime {
    if (createdAt == null) return '';
    final local = createdAt!.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final minute = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, ${local.year} • '
        '$hour12:$minute $ampm';
  }
}

class _OrderLine {
  final String id;
  final String name;
  final double price;
  final int quantity;

  _OrderLine({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory _OrderLine.fromMap(Map<String, dynamic> map) {
    return _OrderLine(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}