import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_dashboard_tabs.dart';
import 'admin_second_tabs.dart';

class AdminDashboardShell extends StatefulWidget {
  const AdminDashboardShell({super.key});

  @override
  State<AdminDashboardShell> createState() => _AdminDashboardShellState();
}

class _AdminDashboardShellState extends State<AdminDashboardShell> {
  int _selectedIndex = 0;
  final Color adminPurple = const Color(0xFF5E35B1);

  final List<Widget> _pages = [
    const AdminDashboardPage(),
    const AdminOrdersPage(),
    const AdminMenuManagementPage(),
    const AdminInventoryPage(),
    const AdminLoyaltyRewardsPage(),
    const AdminRedemptionPage(),
    const AdminPaymentsPage(),
    const AdminReportsPage(),
    const AdminAccountsPage(),
  ];

  final List<IconData> _icons = [
    Icons.dashboard_outlined,
    Icons.receipt_long_outlined,
    Icons.restaurant_menu_outlined,
    Icons.inventory_2_outlined,
    Icons.stars_outlined,
    Icons.qr_code_scanner_outlined,
    Icons.payments_outlined,
    Icons.insert_chart_outlined,
    Icons.people_outline,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Dark Sidebar
          Container(
            width: 90,
            color: const Color(0xFF1E1E1E),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E2E2E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_cafe, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: ListView.builder(
                    itemCount: _icons.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIndex = index),
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: _selectedIndex == index ? adminPurple : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                            ),
                          ),
                          child: Icon(
                            _icons[index],
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}