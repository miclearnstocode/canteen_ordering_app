import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoyaltyHistoryPage extends StatelessWidget {
  const LoyaltyHistoryPage({super.key});
  final Color primaryColor = const Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Loyalty History', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary at top
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.stars, color: primaryColor, size: 40),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Balance', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                    Text('125 Points', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // List of Transactions
          _historyTile('Order #10025', 'Earned points from purchase', '+15 Points', true, DateTime(2024, 5, 15)),
          _historyTile('Redeemed - Free Burger', 'Redeemed reward', '-80 Points', false, DateTime(2024, 5, 14)),
          _historyTile('Order #10020', 'Earned points from purchase', '+10 Points', true, DateTime(2024, 5, 14)),
          _historyTile('Weekly Bonus', 'Loyalty bonus', '+50 Points', true, DateTime(2024, 5, 10)),
          _historyTile('Redeemed - Soft Drink', 'Redeemed reward', '-30 Points', false, DateTime(2024, 5, 8)),
          _historyTile('Order #10018', 'Earned points from purchase', '+5 Points', true, DateTime(2024, 5, 13)),
        ],
      ),
    );
  }

  Widget _historyTile(String title, String subtitle, String points, bool isEarned, DateTime date) {
    final Color pointColor = isEarned ? Colors.green : Colors.red;
    final IconData icon = isEarned ? Icons.add_circle_outline : Icons.remove_circle_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: pointColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: pointColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text('${date.month}/${date.day}/${date.year}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Text(
            points,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: pointColor),
          ),
        ],
      ),
    );
  }
}