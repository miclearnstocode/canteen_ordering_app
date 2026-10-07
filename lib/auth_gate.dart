import 'dart:async';

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
  final StudentAppState _studentState = StudentAppState();

  StreamSubscription<User?>? _authSub;

  bool _isLoading = true;
  AppUser? _currentUser;
  String? _cartLoadedForUid;

  @override
  void initState() {
    super.initState();
    _authSub = _authService.authStateChanges.listen(_onAuthChanged);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _onAuthChanged(User? user) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      if (user == null) {
        _cartLoadedForUid = null;
        _studentState.clearCart();
        if (!mounted) return;
        setState(() {
          _currentUser = null;
          _isLoading = false;
        });
        return;
      }

      // ── Signed in ──
      AppUser? appUser;
      try {
        appUser = await _authService.getCurrentUserData();
      } catch (e, st) {
        debugPrint('[AuthGate] getCurrentUserData failed: $e\n$st');
        appUser = null;
      }

      // Fallback: if the users/{uid} doc read failed for any reason,
      // synthesise a minimal AppUser from the Firebase Auth record so
      // the user can still get past the login form.
      if (appUser == null) {
        final fallbackIsAdmin =
            (user.email ?? '').toLowerCase() == 'canteenadmin1@gmail.com';
        appUser = AppUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          username: user.displayName,
          role: fallbackIsAdmin ? UserRole.admin : UserRole.user,
          accountStatus: AccountStatus.active,
          isActive: true,
        );
      }

      // Cart load is best-effort — never block routing on it.
      try {
        _loadCartOnce(user.uid);
      } catch (e) {
        debugPrint('[AuthGate] cart load failed: $e');
      }

      if (!mounted) return;
      setState(() {
        _currentUser = appUser;
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('[AuthGate] auth handler failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _currentUser = null;
        _isLoading = false;
      });
    }
  }

  void _loadCartOnce(String uid) {
    if (_cartLoadedForUid == uid) return;
    _cartLoadedForUid = uid;
    _studentState.loadCartFromFirestore();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    }

    final user = _currentUser;
    if (user != null) {
      return user.isAdmin
          ? const AdminDashboardShell()
          : const HomePage();
    }

    return const LoginPage();
  }
}