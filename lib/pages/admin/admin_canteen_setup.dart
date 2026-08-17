// lib/pages/admin/admin_canteen_setup.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCanteenSetup extends StatefulWidget {
  const AdminCanteenSetup({super.key});

  @override
  State<AdminCanteenSetup> createState() => _AdminCanteenSetupState();
}

class _AdminCanteenSetupState extends State<AdminCanteenSetup> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _openTimeController = TextEditingController();
  final _closeTimeController = TextEditingController();
  bool _isOpen = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _openTimeController.dispose();
    _closeTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveCanteenData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('canteen').doc('main').set({
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'openTime': _openTimeController.text.trim(),
        'closeTime': _closeTimeController.text.trim(),
        'isOpen': _isOpen,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Canteen data saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Canteen Setup',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Load existing data
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('canteen')
                    .doc('main')
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    _nameController.text = data['name'] ?? '';
                    _locationController.text = data['location'] ?? '';
                    _openTimeController.text = data['openTime'] ?? '';
                    _closeTimeController.text = data['closeTime'] ?? '';
                    _isOpen = data['isOpen'] ?? true;
                  }
                  return Container();
                },
              ),
              
              Text(
                'Canteen Information',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              // Canteen Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Canteen Name',
                  hintText: 'e.g., Main Canteen',
                  prefixIcon: const Icon(Icons.storefront),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter canteen name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Location
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g., Main Building, First Floor',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Opening Hours
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _openTimeController,
                      decoration: InputDecoration(
                        labelText: 'Opening Time',
                        hintText: '7:00 AM',
                        prefixIcon: const Icon(Icons.access_time),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter opening time';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _closeTimeController,
                      decoration: InputDecoration(
                        labelText: 'Closing Time',
                        hintText: '6:00 PM',
                        prefixIcon: const Icon(Icons.access_time),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter closing time';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Canteen Status',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _isOpen,
                      onChanged: (value) {
                        setState(() {
                          _isOpen = value;
                        });
                      },
                      activeThumbColor: const Color(0xFFFF6B35),
                    ),
                    Text(
                      _isOpen ? 'Open' : 'Closed',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: _isOpen ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCanteenData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Save Canteen Information',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}