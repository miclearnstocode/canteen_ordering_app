import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/home_dashboard.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        print('🔐 AuthGate: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}');
        
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('⏳ Waiting for auth...');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            ),
          );
        }
        
        // If user is logged in, go to home
        if (snapshot.hasData && snapshot.data != null) {
          print('✅ User logged in: ${snapshot.data?.uid}');
          return const HomeDashboard();
        }
        
        // Otherwise, show login
        print('❌ No user, showing login');
        return const LoginPage();
      },
    );
  }
}