import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/splash_screen.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_dashboard.dart';
import 'pages/menu_page.dart';
import 'pages/cart_page.dart';
import 'pages/checkout_page.dart';
import 'pages/order_success.dart';
import 'pages/loyalty_page.dart';
import 'pages/profile_page.dart';

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
        colorSchemeSeed: const Color(0xFFFF6B35),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomeDashboard(),
        '/menu': (context) => const MenuPage(),
        '/cart': (context) => const CartPage(),
        '/checkout': (context) => const CheckoutPage(),
        '/order-success': (context) => const OrderSuccessPage(),
        '/rewards': (context) => const LoyaltyPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}