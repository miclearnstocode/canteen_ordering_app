// lib/pages/orders_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
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

                  // Convert to a list of models and sort newest first.
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
          Icon(Icons.receipt_long_outlined,
              size: 60, color: Colors.grey.shade400),
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
      itemBuilder: (context, index) => _buildOrderCard(context, filtered[index]),
    );
  }

  Widget _buildOrderCard(BuildContext context, _Order order) {
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

    final isReady = order.status.toLowerCase() == 'ready';
    final hasToken = order.pickupToken != null &&
        order.pickupToken!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isReady && hasToken
              ? const Color(0xFFA5D6A7)
              : Colors.grey.shade200,
          width: isReady && hasToken ? 1.4 : 1,
        ),
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
              Expanded(
                child: Text(
                  'Order #${order.orderNumber}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isReady && hasToken)
                    IconButton(
                      icon: const Icon(Icons.qr_code_2_rounded,
                          color: primaryColor, size: 24),
                      tooltip: 'Show pickup QR',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                      onPressed: () => _showPickupQr(context, order),
                    ),
                  if (isReady && hasToken) const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
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

          // ── Ready banner ──
          if (isReady && hasToken) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_2,
                      color: primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your order is ready! Tap the QR icon above and show it at the counter.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

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

  // ─────────────────────────────────────────────
  // PICKUP QR DIALOG
  // ─────────────────────────────────────────────
  void _showPickupQr(BuildContext context, _Order order) {
    final token = order.pickupToken ?? '';
    // Structured payload — the admin scanner will parse it.
    final payload = 'CANTEEN_PICKUP:${order.id}:$token';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.qr_code_2, color: primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Order #${order.orderNumber}',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFA5D6A7), width: 1.5),
                ),
                child: QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: 240,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: primaryColor,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Show this at the canteen counter.\nThe staff will scan it to complete your order.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ref: $token',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
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
  final String? pickupToken;

  _Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.createdAt,
    required this.items,
    required this.total,
    this.pickupToken,
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
      pickupToken: data['pickupToken'] as String?,
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