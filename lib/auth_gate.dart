import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/admin/admin_dashboard.dart';
import 'pages/admin/admin_dashboard_shell.dart';
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
      if (mounted) setState(() => _isLoading = true);
      
      if (user != null) {
        final appUser = await _authService.getCurrentUserData();
        
        // If user is inactive, update to active
        if (appUser != null && appUser.isActive == false) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'isActive': true});
          
          // Reload user data
          final updatedUser = await _authService.getCurrentUserData();
          if (mounted) {
            setState(() {
              _currentUser = updatedUser;
              _isLoading = false;
            });
          }
          return;
        }
        
        if (mounted) {
          setState(() {
            _currentUser = updatedUser;
            _currentUser = appUser;
            _isLoading = false;
          });
          return;
        }
        
        setState(() {
          _currentUser = appUser;
          _isLoading = false;
        });
      } else {
        setState(() {
          _currentUser = null;
          _isLoading = false;
        });
        if (mounted) {
          setState(() {
            _currentUser = null;
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2E7D32),
          ),
        ),
      );
    }

    if (_currentUser != null) {
      // Route based on role
      if (_currentUser!.isAdmin) {
        return const AdminDashboard();
        return const AdminDashboardShell();
      } else {
        return const HomePage();
      }
    }

    return const LoginPage();
  }
}