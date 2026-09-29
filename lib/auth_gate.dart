import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'services/student_state.dart'; 
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/admin/admin_dashboard_shell.dart';
import 'models/user_model.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  final StudentAppState _studentState = StudentAppState();  // ← singleton

  bool _isLoading = true;
  AppUser? _currentUser;
  String? _cartLoadedForUid;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _authService.authStateChanges.listen((User? user) async {
      setState(() => _isLoading = true);

      if (user != null) {
        final appUser = await _authService.getCurrentUserData();

        // If user is inactive, update to active
        if (appUser != null && appUser.isActive == false) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'isActive': true});

          final updatedUser = await _authService.getCurrentUserData();
          _loadCartOnce(user.uid);              // ← load cart
          setState(() {
            _currentUser = updatedUser;
            _isLoading = false;
          });
          return;
        }

        _loadCartOnce(user.uid);                // ← load cart
        setState(() {
          _currentUser = appUser;
          _isLoading = false;
        });
      } else {
        // Signed out — reset the flag so the next login reloads.
        _cartLoadedForUid = null;
        _studentState.clearCart();              // optional: wipe in-memory cart
        setState(() {
          _currentUser = null;
          _isLoading = false;
        });
      }
    });
  }

  /// Loads the cart from Firestore exactly once per UID.
  void _loadCartOnce(String uid) {
    if (_cartLoadedForUid == uid) return;
    _cartLoadedForUid = uid;
    // Fire-and-forget; no need to await here — the cart will
    // appear as soon as Firestore responds and notifies listeners.
    _studentState.loadCartFromFirestore();
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
      if (_currentUser!.isAdmin) {
        return const AdminDashboardShell();
      } else {
        return const HomePage();
      }
    }

    return const LoginPage();
  }
}