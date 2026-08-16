import 'package:cloud_firestore/cloud_firestore.dart';
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
      setState(() => _isLoading = true);
      
      if (user != null) {
        print('👤 User authenticated: ${user.uid}');
        final appUser = await _authService.getCurrentUserData();
        print('📊 User data: ${appUser?.toMap()}');
        print('👑 User role: ${appUser?.role}');
        print('👑 Is Admin: ${appUser?.isAdmin}');
        print('👑 Is Active: ${appUser?.isActive}');
        
        // If user is inactive, update to active
        if (appUser != null && appUser.isActive == false) {
          print('🔄 User was inactive, updating to active...');
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'isActive': true});
          
          // Reload user data
          final updatedUser = await _authService.getCurrentUserData();
          setState(() {
            _currentUser = updatedUser;
            _isLoading = false;
          });
          return;
        }
        
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