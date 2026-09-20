// lib/pages/order_history_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});
  static const Color primaryColor = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Order History',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: uid == null
          ? _empty('Please log in to view your orders')
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

                final orders = (snapshot.data?.docs ?? [])
                    .map((d) => _Order.fromDoc(d))
                    .toList()
                  ..sort((a, b) {
                    final aT =
                        a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                    final bT =
                        b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                    return bT.compareTo(aT);
                  });

                if (orders.isEmpty) {
                  return _empty('No orders yet');
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, i) =>
                      _buildOrderCard(orders[i]),
                );
              },
            ),
    );
  }

  Widget _empty(String msg) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(msg,
                style: GoogleFonts.poppins(
                    fontSize: 18, color: Colors.grey.shade600)),
          ],
        ),
      );

  Widget _buildOrderCard(_Order order) {
    final statusColor = _statusColor(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
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
              Text('Order #${order.orderNumber}',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.formattedDateTime,
            style: GoogleFonts.inter(
                fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 6, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item.name} x${item.quantity}',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: Colors.grey.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: ₱${order.total.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
      orderNumber:
          data['orderNumber'] ?? doc.id.substring(0, 8).toUpperCase(),
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