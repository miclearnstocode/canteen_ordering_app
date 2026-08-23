import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_gate.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
// Student pages
import 'pages/home_page.dart';
import 'pages/menu_page.dart';
import 'pages/cart_page.dart';
import 'pages/orders_page.dart';
import 'pages/rewards_page.dart';
import 'pages/profile_page.dart';
// Admin pages
import 'pages/admin/admin_dashboard_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CanteenApp());
}

class CanteenApp extends StatelessWidget {
  const CanteenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CanteenQR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Updated Color Palette to match the green theme in the image
        colorSchemeSeed: const Color(0xFF2E7D32), // Deep Green
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        fontFamily: GoogleFonts.poppins().fontFamily,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
      ),
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/menu': (context) => const MenuPage(),
        '/cart': (context) => const CartPage(),
        '/orders': (context) => const OrdersPage(),
        '/rewards': (context) => const RewardsPage(),
        '/profile': (context) => const ProfilePage(),
        '/admin': (context) => const AdminDashboardShell(),
      },
    );
  }
}