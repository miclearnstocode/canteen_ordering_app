// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Color primaryColor = const Color(0xFF2E7D32);
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _sectionController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isSaving = false;
  bool _isLoading = true;
  String? _error;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _sectionController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = await _authService.getCurrentUserData();
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _error = 'No user data found. Please log in again.';
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _nameController.text = user.displayName ?? user.username ?? '';
        _studentIdController.text = user.studentId ?? '';
        _sectionController.text = user.course ?? '';
        _emailController.text = user.email;
        _usernameController.text = user.username ?? '';
        _avatarUrl = _resolveAvatar(user);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  String _resolveAvatar(AppUser user) {
    if (user.photoURL != null && user.photoURL!.isNotEmpty) {
      return user.photoURL!;
    }
    final seed = Uri.encodeComponent(
      user.displayName ?? user.username ?? user.uid,
    );
    return 'https://api.dicebear.com/7.x/adventurer/png?seed=$seed&backgroundColor=ffd5dc';
  }

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    final studentId = _studentIdController.text.trim();
    final section = _sectionController.text.trim();
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();

    // ---- Validation ----
    if (name.isEmpty) {
      _showError('Full name cannot be empty.');
      return;
    }
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _showError('Please enter a valid email address.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('You are not logged in.');
      }

      // ---- 1. Update Firebase Auth displayName if it changed ----
      if (currentUser.displayName != name) {
        try {
          await currentUser.updateDisplayName(name);
        } catch (_) {
          // Non-fatal — Firestore is the source of truth.
        }
      }

      // ---- 2. Update Firestore user doc ----
      // Use AuthService.updateUserProfile for the standard fields, then
      // patch studentId/course directly since updateUserProfile doesn't
      // handle those.
      await _authService.updateUserProfile(
        displayName: name,
        username: username.isEmpty ? null : username,
      );

      // Patch fields that updateUserProfile doesn't cover.
      final updates = <String, dynamic>{
        'studentId': studentId.isEmpty ? null : studentId,
        'course': section.isEmpty ? null : section,
        'email': email,
        'displayName': name,
        'username': username.isEmpty ? name : username,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update(updates);

      // ---- 3. Refresh cached user ----
      await _loadUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to save: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Settings',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildForm(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadUser,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Picture Section
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: NetworkImage(_avatarUrl ?? ''),
                      onBackgroundImageError: (_, __) {},
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Profile picture upload coming soon.'),
                      ),
                    );
                  },
                  child: Text(
                    'Change Profile Picture',
                    style: GoogleFonts.poppins(color: primaryColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Personal Information
          Text('Personal Information',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          _buildTextField('Full Name', _nameController, Icons.person_outline),
          const SizedBox(height: 16),
          _buildTextField(
            'Student ID',
            _studentIdController,
            Icons.badge_outlined,
            readOnly: true, // students shouldn't edit their own ID
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Course / Section',
            _sectionController,
            Icons.school_outlined,
          ),

          const SizedBox(height: 24),
          Text('Account Information',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildTextField(
              'Username', _usernameController, Icons.alternate_email),
          const SizedBox(height: 16),
          _buildTextField('Email Address', _emailController, Icons.email_outlined,
              readOnly: true), // email is tied to Firebase Auth

          const SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: _isSaving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    child: Text(
                      'Save Changes',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      style: GoogleFonts.inter(
        color: readOnly ? Colors.grey.shade600 : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: readOnly ? Colors.grey : primaryColor),
        suffixIcon: readOnly
            ? Icon(Icons.lock_outline, size: 18, color: Colors.grey.shade400)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
      ),
    );
  }
}