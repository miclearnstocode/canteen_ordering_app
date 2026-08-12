// lib/pages/my_orders_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOrderCard(
            'ORD-2024-001',
            'Chicken Meal, Iced Tea, Burger',
            '₱190',
            'Completed',
            Colors.green,
            '2 hours ago',
          ),
          _buildOrderCard(
            'ORD-2024-002',
            'Pizza, Iced Tea',
            '₱150',
            'Preparing',
            Colors.orange,
            '30 mins ago',
          ),
          _buildOrderCard(
            'ORD-2024-003',
            'Burger, Fries',
            '₱110',
            'Ready for Pickup',
            Colors.blue,
            '15 mins ago',
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    String orderId,
    String items,
    String total,
    String status,
    Color statusColor,
    String time,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                orderId,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
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
            items,
            style: GoogleFonts.inter(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time,
                style: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              Text(
                total,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: const Color(0xFFFF6B35),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}