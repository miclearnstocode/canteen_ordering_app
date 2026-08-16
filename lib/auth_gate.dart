// lib/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/home_dashboard.dart';
import 'pages/admin/admin_dashboard.dart';
import 'models/user_model.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        print('👤 User authenticated: ${user.uid}');
        final appUser = await _authService.getCurrentUserData();
        print('📊 User data: ${appUser?.toMap()}');
        print('👑 User role: ${appUser?.role}');
        print('👑 Is Admin: ${appUser?.isAdmin}');
        setState(() {
          _currentUser = appUser;
          _isLoading = false;
        });
      } else {
        print('👤 No user authenticated');
        setState(() {
          _currentUser = null;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF6B35),
          ),
        ),
      );
    }

    if (_currentUser != null) {
      print('🔍 Routing user with role: ${_currentUser!.role}');
      // Route based on role
      if (_currentUser!.isAdmin) {
        print('🏢 Navigating to Admin Dashboard');
        return const AdminDashboard();
      } else {
        print('🏠 Navigating to User Home Dashboard');
        return const HomeDashboard();
      }
    }

    return const LoginPage();
  }
}