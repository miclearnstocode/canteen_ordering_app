import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_dashboard_tabs.dart';
import 'admin_second_tabs.dart';
import '../../services/auth_service.dart';
import '../login_page.dart';

class AdminDashboardShell extends StatefulWidget {
  const AdminDashboardShell({super.key});

  @override
  State<AdminDashboardShell> createState() => _AdminDashboardShellState();
}

class _AdminDashboardShellState extends State<AdminDashboardShell> {
  int _selectedIndex = 0;
  final Color adminPurple = const Color(0xFF5E35B1);

  final List<Widget> _pages = const [
    AdminDashboardPage(),
    AdminOrdersPage(),
    AdminMenuManagementPage(),
    AdminInventoryPage(),
    AdminLoyaltyRewardsPage(),
    AdminRedemptionPage(),
    AdminPaymentsPage(),
    AdminReportsPage(),
    AdminAccountsPage(),
  ];

  final List<Map<String, dynamic>> _navItems = const [
    {'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard, 'label': 'Dashboard'},
    {'icon': Icons.receipt_long_outlined, 'activeIcon': Icons.receipt_long, 'label': 'Orders'},
    {'icon': Icons.restaurant_menu_outlined, 'activeIcon': Icons.restaurant_menu, 'label': 'Menu'},
    {'icon': Icons.inventory_2_outlined, 'activeIcon': Icons.inventory_2, 'label': 'Inventory'},
    {'icon': Icons.stars_outlined, 'activeIcon': Icons.stars, 'label': 'Rewards'},
    {'icon': Icons.qr_code_scanner_outlined, 'activeIcon': Icons.qr_code_scanner, 'label': 'Scanner'},
    {'icon': Icons.payments_outlined, 'activeIcon': Icons.payments, 'label': 'Payments'},
    {'icon': Icons.insert_chart_outlined, 'activeIcon': Icons.insert_chart, 'label': 'Reports'},
    {'icon': Icons.people_outline, 'activeIcon': Icons.people, 'label': 'Accounts'},
  ];

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Admin Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to log out of the Admin Portal?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final authService = AuthService();
                await authService.signOut();
              } catch (_) {}
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: isSmallScreen
          ? AppBar(
              backgroundColor: const Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              title: Text(
                _navItems[_selectedIndex]['label'] as String,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white70),
                  tooltip: 'Logout',
                  onPressed: _handleLogout,
                ),
              ],
            )
          : null,
      drawer: isSmallScreen
          ? Drawer(
              backgroundColor: const Color(0xFF1E1E1E),
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFF5E35B1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.storefront, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Admin Portal',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _navItems.length,
                        itemBuilder: (context, index) {
                          final item = _navItems[index];
                          final isSelected = _selectedIndex == index;
                          return ListTile(
                            leading: Icon(
                              isSelected ? (item['activeIcon'] as IconData) : (item['icon'] as IconData),
                              color: isSelected ? adminPurple : Colors.white70,
                            ),
                            title: Text(
                              item['label'] as String,
                              style: GoogleFonts.poppins(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                            selected: isSelected,
                            selectedTileColor: adminPurple.withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            onTap: () {
                              setState(() => _selectedIndex = index);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                    const Divider(color: Colors.white12),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.redAccent),
                      title: Text(
                        'Logout',
                        style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.w600),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _handleLogout();
                      },
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: Row(
        children: [
          // Sidebar for Tablet/Desktop
          if (!isSmallScreen)
            Container(
              width: 96,
              color: const Color(0xFF1E1E1E),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Logo
                  Tooltip(
                    message: 'Admin Portal',
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF5E35B1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Navigation Items
                  Expanded(
                    child: ListView.builder(
                      itemCount: _navItems.length,
                      itemBuilder: (context, index) {
                        final item = _navItems[index];
                        final isSelected = _selectedIndex == index;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Tooltip(
                            message: item['label'] as String,
                            preferBelow: false,
                            child: InkWell(
                              onTap: () => setState(() => _selectedIndex = index),
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isSelected ? adminPurple : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isSelected
                                          ? (item['activeIcon'] as IconData)
                                          : (item['icon'] as IconData),
                                      color: isSelected ? Colors.white : Colors.white60,
                                      size: 22,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item['label'] as String,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        color: isSelected ? Colors.white : Colors.white60,
                                        fontSize: 9,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Logout Button
                  Tooltip(
                    message: 'Logout',
                    child: InkWell(
                      onTap: _handleLogout,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            const Icon(Icons.logout, color: Colors.redAccent, size: 22),
                            const SizedBox(height: 2),
                            Text(
                              'Logout',
                              style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          // Main Content View
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}