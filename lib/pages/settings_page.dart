import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Color primaryColor = const Color(0xFF2E7D32);

  // Controllers for user data
  final _nameController = TextEditingController(text: 'Marianne Santos');
  final _studentIdController = TextEditingController(text: '2023-12345');
  final _sectionController = TextEditingController(text: 'BSIT - 2A');
  final _emailController = TextEditingController(text: 'marianne.santos@example.com');
  final _usernameController = TextEditingController(text: 'marianne_santos');
  
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _sectionController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    
    // Simulate a save process
    await Future.delayed(const Duration(seconds: 2));
    
    // TODO: Implement actual logic here using Firebase
    // await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
    //   'displayName': _nameController.text,
    //   'studentId': _studentIdController.text,
    //   'section': _sectionController.text,
    //   'email': _emailController.text,
    //   'username': _usernameController.text,
    // });

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
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
                        backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=5'),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {}, // Implement image picker
                    child: Text('Change Profile Picture', style: GoogleFonts.poppins(color: primaryColor)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // User Information Form
            Text('Personal Information', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildTextField('Full Name', _nameController, Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField('Student ID', _studentIdController, Icons.badge_outlined),
            const SizedBox(height: 16),
            _buildTextField('Section', _sectionController, Icons.school_outlined),
            
            const SizedBox(height: 24),
            Text('Account Information', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTextField('Username', _usernameController, Icons.alternate_email),
            const SizedBox(height: 16),
            _buildTextField('Email Address', _emailController, Icons.email_outlined),

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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    child: Text('Save Changes', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}