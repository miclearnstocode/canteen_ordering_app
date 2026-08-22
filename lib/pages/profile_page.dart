import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_page.dart'; // Import the new page
import 'loyalty_history_page.dart'; // Import the new page

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  final Color primaryColor = const Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to Settings page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=5'),
                ),
                const SizedBox(height: 12),
                Text('Marianne Santos', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Student ID: 2023-12345\nBSIT - 2A', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey[600])),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                _menuTile(context, Icons.person_outline, 'My Information'),
                _menuTile(context, Icons.receipt_long_outlined, 'Order History'),
                // Updated to link to Loyalty History Page
                _menuTile(context, Icons.stars_outlined, 'Loyalty Points History', 
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoyaltyHistoryPage()),
                    );
                  }
                ),
                _menuTile(context, Icons.redeem_outlined, 'Redeemed Rewards'),
                // Link to Settings Page
                _menuTile(context, Icons.settings_outlined, 'Settings',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsPage()),
                    );
                  }
                ),
                const Divider(),
                _menuTile(context, Icons.logout, 'Logout', color: Colors.red, onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(BuildContext context, IconData icon, String title, {Color? color, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black87),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap ?? () {},
    );
  }
}