import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'menu_page.dart';
import 'cart_page.dart';
import 'orders_page.dart';
import 'rewards_page.dart';
import 'profile_page.dart';
import '../services/student_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryColor = const Color(0xFF1E7B3B);
  final StudentAppState _state = StudentAppState();

  final List<Widget> _pages = const [
    HomeScreen(),
    MenuPage(),
    CartPage(),
    OrdersPage(),
    RewardsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(
            index: _state.selectedTabIndex,
            children: _pages,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _state.selectedTabIndex,
              onTap: (index) => _state.setTabIndex(index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: primaryColor,
              unselectedItemColor: Colors.grey.shade500,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              elevation: 0,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined, size: 22),
                  activeIcon: Icon(Icons.home, size: 22),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_outlined, size: 22),
                  activeIcon: Icon(Icons.grid_view_rounded, size: 22),
                  label: 'Menu',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    label: Text(
                      '${_state.totalCartCount}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    isLabelVisible: _state.totalCartCount > 0,
                    backgroundColor: Colors.red.shade600,
                    child: const Icon(Icons.shopping_cart_outlined, size: 22),
                  ),
                  activeIcon: Badge(
                    label: Text(
                      '${_state.totalCartCount}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    isLabelVisible: _state.totalCartCount > 0,
                    backgroundColor: Colors.red.shade600,
                    child: const Icon(Icons.shopping_cart, size: 22),
                  ),
                  label: 'Cart',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined, size: 22),
                  activeIcon: Icon(Icons.receipt_long, size: 22),
                  label: 'Orders',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.stars_outlined, size: 22),
                  activeIcon: Icon(Icons.stars, size: 22),
                  label: 'Rewards',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline, size: 22),
                  activeIcon: Icon(Icons.person, size: 22),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}