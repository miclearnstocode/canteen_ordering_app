// lib/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_page.dart';
import 'loyalty_history_page.dart';
import 'order_history_page.dart';
import 'rewards_page.dart';
import 'my_information_page.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  static const Color primaryColor = Color(0xFF1E7B3B);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color primaryColor = Color(0xFF1E7B3B);

  final AuthService _authService = AuthService();
  AppUser? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _authService.getCurrentUserData();
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
        if (user == null) {
          _error = 'No user data found. Please log in again.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load profile: $e';
        _loading = false;
      });
    }
  }

  // Logout function with confirmation dialog
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to log out of Canteen Click?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                  color: Colors.grey.shade700, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _authService.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: $e'),
                      backgroundColor: Colors.red.shade400,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _avatarUrl(AppUser user) {
    if (user.photoURL != null && user.photoURL!.isNotEmpty) {
      return user.photoURL!;
    }
    // Fallback: generate a deterministic avatar from the user's name/uid.
    final seed = Uri.encodeComponent(
      (user.displayName ?? user.username ?? user.uid),
    );
    return 'https://api.dicebear.com/7.x/adventurer/png?seed=$seed&backgroundColor=ffd5dc';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: _loadUser,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              _buildMenu(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Header (real user data) ----------------
  Widget _buildHeader() {
    if (_loading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    if (_error != null || _user == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        color: Colors.white,
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 40),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unable to load profile.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loadUser,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text('Retry',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    final user = _user!;
    final displayName = user.displayName ?? user.username ?? 'Student';
    final studentId = user.studentId ?? '—';
    final course = user.course ?? '—';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      color: Colors.white,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: primaryColor.withValues(alpha: 0.3), width: 3),
            ),
            child: CircleAvatar(
              radius: 46,
              backgroundColor: const Color(0xFFFFE0B2),
              backgroundImage: NetworkImage(_avatarUrl(user)),
              onBackgroundImageError: (_, __) {},
            ),
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Student ID: $studentId',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            course,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Menu list ----------------
  Widget _buildMenu() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
        children: [
          _menuTile(
            context,
            Icons.person_outline_rounded,
            'My Information',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const MyInformationPage()),
              );
            },
          ),
          _buildDivider(),
          _menuTile(
            context,
            Icons.receipt_long_outlined,
            'Order History',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const OrderHistoryPage()),
              );
            },
          ),
          _buildDivider(),
          _menuTile(
            context,
            Icons.stars_outlined,
            'Loyalty Points History',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const LoyaltyHistoryPage()),
              );
            },
          ),
          _buildDivider(),
          _menuTile(
            context,
            Icons.card_giftcard_outlined,
            'Redeemed Rewards',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RewardsPage()),
              );
            },
          ),
          _buildDivider(),
          _menuTile(
            context,
            Icons.settings_outlined,
            'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          _buildDivider(),
          _menuTile(
            context,
            Icons.logout_rounded,
            'Logout',
            color: Colors.red.shade600,
            isDestructive: true,
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 56,
      endIndent: 16,
    );
  }

  Widget _menuTile(
    BuildContext context,
    IconData icon,
    String title, {
    Color? color,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final itemColor = color ?? Colors.black87;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: itemColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight:
                      isDestructive ? FontWeight.w600 : FontWeight.w500,
                  color: itemColor,
                ),
              ),
            ),
            if (!isDestructive)
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}