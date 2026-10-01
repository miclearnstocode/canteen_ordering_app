// lib/pages/my_information_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import '../services/cloudinary_service.dart';
import '../helpers/image_picker_helper.dart';

class MyInformationPage extends StatefulWidget {
  const MyInformationPage({super.key});

  @override
  State<MyInformationPage> createState() => _MyInformationPageState();
}

class _MyInformationPageState extends State<MyInformationPage> {
  static const Color primaryColor = Color(0xFF2E7D32);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AppUser? _user;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _loading = false;
        _error = 'You are not signed in.';
      });
      return;
    }
    try {
      final snap = await _firestore.collection('users').doc(uid).get();
      if (!snap.exists) {
        setState(() {
          _loading = false;
          _error = 'Profile not found.';
        });
        return;
      }
      setState(() {
        _user = AppUser.fromFirestore(snap);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ─────────────────────────────────────────────
  // EDIT DIALOG
  // ─────────────────────────────────────────────
  Future<void> _showEditDialog() async {
    final user = _user;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.displayName ?? '');
    final studentIdCtrl = TextEditingController(text: user.studentId ?? '');
    final courseCtrl = TextEditingController(text: user.course ?? '');
    final phoneCtrl = TextEditingController(
        text: (user.preferences?['phone'] as String?) ?? '');
    final birthdayCtrl = TextEditingController(
        text: (user.preferences?['birthday'] as String?) ?? '');
    final addressCtrl = TextEditingController(
        text: (user.preferences?['address'] as String?) ?? '');

    XFile? newImage;
    bool uploading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Edit Information',
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      IconButton(
                        onPressed:
                            uploading ? null : () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Avatar picker ──
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: newImage != null
                              ? null
                              : (user.photoURL != null &&
                                      user.photoURL!.isNotEmpty)
                                  ? NetworkImage(user.photoURL!)
                                  : null,
                          child: newImage == null &&
                                  (user.photoURL == null ||
                                      user.photoURL!.isEmpty)
                              ? Icon(Icons.person,
                                  size: 48, color: Colors.grey.shade500)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Material(
                            color: primaryColor,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: uploading
                                  ? null
                                  : () async {
                                      final picked = await ImagePickerHelper
                                          .pickImage();
                                      if (picked != null) {
                                        setModalState(
                                            () => newImage = picked);
                                      }
                                    },
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.camera_alt,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (newImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Text(
                          'New photo selected',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // ── Fields ──
                  _field('Full Name', nameCtrl, Icons.person_outline),
                  const SizedBox(height: 12),
                  _field('Student ID', studentIdCtrl, Icons.badge_outlined,
                      enabled: false),
                  const SizedBox(height: 12),
                  _field('Course & Section', courseCtrl,
                      Icons.school_outlined),
                  const SizedBox(height: 12),
                  _field('Phone Number', phoneCtrl, Icons.phone_outlined,
                      keyboard: TextInputType.phone),
                  const SizedBox(height: 12),
                  _field('Birthday', birthdayCtrl, Icons.cake_outlined,
                      hint: 'e.g. March 15, 2004'),
                  const SizedBox(height: 12),
                  _field('Address', addressCtrl,
                      Icons.location_on_outlined),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: uploading
                              ? null
                              : () async {
                                  setModalState(() => uploading = true);
                                  try {
                                    await _saveProfile(
                                      newDisplayName:
                                          nameCtrl.text.trim(),
                                      course: courseCtrl.text.trim(),
                                      phone: phoneCtrl.text.trim(),
                                      birthday: birthdayCtrl.text.trim(),
                                      address: addressCtrl.text.trim(),
                                      newImage: newImage,
                                    );
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content:
                                            Text('Profile updated'),
                                        backgroundColor: primaryColor,
                                      ));
                                    }
                                  } catch (e) {
                                    setModalState(
                                        () => uploading = false);
                                    if (ctx.mounted) {
                                      // ignore: use_build_context_synchronously
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text('Failed: $e'),
                                        backgroundColor: Colors.red,
                                      ));
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: uploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save Changes'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: uploading
                              ? null
                              : () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    bool enabled = true,
    TextInputType? keyboard,
    String? hint,
  }) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SAVE
  // ─────────────────────────────────────────────
  Future<void> _saveProfile({
    required String newDisplayName,
    required String course,
    required String phone,
    required String birthday,
    required String address,
    XFile? newImage,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in.');

    setState(() => _saving = true);

    try {
      // 1. Upload new photo to Cloudinary (if selected)
      String? newPhotoUrl;
      if (newImage != null) {
        newPhotoUrl = await CloudinaryService.uploadImage(
          newImage,
          folder: 'profile_pictures',
        );
      }

      // 2. Merge preferences
      final existingPrefs = _user?.preferences ?? {};
      final updatedPrefs = {
        ...existingPrefs,
        'phone': phone,
        'birthday': birthday,
        'address': address,
      };

      // 3. Build updates
      final updates = <String, dynamic>{
        'displayName': newDisplayName,
        'username': newDisplayName,
        'course': course,
        'preferences': updatedPrefs,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (newPhotoUrl != null) {
        updates['photoURL'] = newPhotoUrl;
      }

      await _firestore.collection('users').doc(uid).update(updates);

      // 4. Sync Firebase Auth profile
      final authUser = _auth.currentUser;
      if (authUser != null) {
        if (newDisplayName.isNotEmpty) {
          await authUser.updateDisplayName(newDisplayName);
        }
        if (newPhotoUrl != null) {
          await authUser.updatePhotoURL(newPhotoUrl);
        }
      }

      // 5. Reload
      await _loadUser();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('My Information',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        actions: [
          if (_user != null && !_loading)
            IconButton(
              onPressed: _saving ? null : _showEditDialog,
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            color: Colors.red.shade700)),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUser,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // ── Profile header ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: (_user?.photoURL != null &&
                                        _user!.photoURL!.isNotEmpty)
                                    ? NetworkImage(_user!.photoURL!)
                                    : null,
                                child: (_user?.photoURL == null ||
                                        _user!.photoURL!.isEmpty)
                                    ? Icon(Icons.person,
                                        size: 40,
                                        color: Colors.grey.shade500)
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _user?.displayName ?? 'No name',
                                style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Student ID: ${_user?.studentId ?? '-'}',
                                style: GoogleFonts.inter(
                                    color: Colors.grey[600],
                                    fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed:
                                    _saving ? null : _showEditDialog,
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit Profile'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryColor,
                                  side: BorderSide(
                                      color: primaryColor
                                          .withValues(alpha: 0.5)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Info rows ──
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _infoRow(Icons.badge_outlined, 'Student ID',
                                  _user?.studentId ?? '-'),
                              const Divider(height: 24),
                              _infoRow(Icons.school_outlined,
                                  'Course & Section',
                                  _user?.course ?? '-'),
                              const Divider(height: 24),
                              _infoRow(Icons.email_outlined,
                                  'Email Address', _user?.email ?? '-'),
                              const Divider(height: 24),
                              _infoRow(
                                  Icons.phone_outlined,
                                  'Phone Number',
                                  (_user?.preferences?['phone']
                                          as String?) ??
                                      '-'),
                              const Divider(height: 24),
                              _infoRow(
                                  Icons.cake_outlined,
                                  'Birthday',
                                  (_user?.preferences?['birthday']
                                          as String?) ??
                                      '-'),
                              const Divider(height: 24),
                              _infoRow(
                                  Icons.location_on_outlined,
                                  'Address',
                                  (_user?.preferences?['address']
                                          as String?) ??
                                      '-'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? '-' : value,
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}