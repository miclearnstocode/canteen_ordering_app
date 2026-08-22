import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyInformationPage extends StatelessWidget {
  const MyInformationPage({super.key});

  final Color primaryColor = const Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('My Information', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=5'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Marianne Santos',
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Student ID: 2023-12345',
                    style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Information Fields
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.badge_outlined, 'Student ID', '2023-12345'),
                  const Divider(height: 24),
                  _infoRow(Icons.school_outlined, 'Course & Section', 'BSIT - 2A'),
                  const Divider(height: 24),
                  _infoRow(Icons.email_outlined, 'Email Address', 'marianne.santos@example.com'),
                  const Divider(height: 24),
                  _infoRow(Icons.phone_outlined, 'Phone Number', '0917 123 4567'),
                  const Divider(height: 24),
                  _infoRow(Icons.cake_outlined, 'Birthday', 'March 15, 2004'),
                  const Divider(height: 24),
                  _infoRow(Icons.location_on_outlined, 'Address', 'Quezon City, Philippines'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}