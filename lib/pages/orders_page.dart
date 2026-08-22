import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/student_state.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});
  final Color primaryColor = const Color(0xFF1E7B3B);

  @override
  Widget build(BuildContext context) {
    final state = StudentAppState();

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
            onPressed: () => state.setTabIndex(0), // Back to Home
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
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Preparing'),
              Tab(text: 'Ready'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: AnimatedBuilder(
          animation: state,
          builder: (context, _) {
            return TabBarView(
              children: [
                _buildOrderList(context, state.orders, null),
                _buildOrderList(context, state.orders, 'Pending'),
                _buildOrderList(context, state.orders, 'Preparing'),
                _buildOrderList(context, state.orders, 'Ready'),
                _buildOrderList(context, state.orders, 'Completed'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, List<StudentOrderItem> allOrders, String? filterStatus) {
    final filtered = filterStatus == null
        ? allOrders
        : allOrders.where((order) => order.status.toLowerCase() == filterStatus.toLowerCase()).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No ${filterStatus ?? ''} orders',
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final order = filtered[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(StudentOrderItem order) {
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
          // Order ID & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order ${order.orderNumber}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

          // Date & Time
          Text(
            order.dateTime,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),

          // Items List
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: order.items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  item,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Divider and Total Amount
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
                    text: '₱${order.totalAmount.toStringAsFixed(0)}',
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