import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/menu_item_model.dart';

class AdminMenuManagement extends StatefulWidget {
  const AdminMenuManagement({super.key});

  @override
  State<AdminMenuManagement> createState() => _AdminMenuManagementState();
}

class _AdminMenuManagementState extends State<AdminMenuManagement> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _preparationTimeController = TextEditingController();
  
  MenuCategory _selectedCategory = MenuCategory.meals;
  bool _isAvailable = true;
  bool _isFeatured = false;
  bool _isLoading = false;
  File? _imageFile;
  
  String? _editingId;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _preparationTimeController.dispose();
    super.dispose();
  }

  // Helper method to parse category from string
  MenuCategory _parseCategoryFromString(String value) {
    switch (value.toLowerCase()) {
      case 'meals':
        return MenuCategory.meals;
      case 'drinks':
        return MenuCategory.drinks;
      case 'pastas':
        return MenuCategory.pastas;
      case 'snacks':
        return MenuCategory.snacks;
      case 'desserts':
        return MenuCategory.desserts;
      default:
        return MenuCategory.others;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveMenuItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_imageFile != null) {
        // In production, upload to Firebase Storage
        // imageUrl = await _uploadImage(_imageFile!);
        imageUrl = 'https://via.placeholder.com/150?text=${_nameController.text}';
      }

      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'category': _selectedCategory.name,
        'stock': int.parse(_stockController.text.trim()),
        'isAvailable': _isAvailable,
        'isFeatured': _isFeatured,
        'preparationTime': int.tryParse(_preparationTimeController.text.trim()) ?? 10,
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_editingId != null) {
        await FirebaseFirestore.instance
            .collection('menu_items')
            .doc(_editingId)
            .update(data);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Menu item updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        setState(() => _editingId = null);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('menu_items').add(data);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Menu item added!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      _clearForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _priceController.clear();
    _stockController.clear();
    _descriptionController.clear();
    _preparationTimeController.clear();
    setState(() {
      _selectedCategory = MenuCategory.meals;
      _isAvailable = true;
      _isFeatured = false;
      _imageFile = null;
      _editingId = null;
    });
  }

  void _editMenuItem(Map<String, dynamic> data, String id) {
    _nameController.text = data['name'] ?? '';
    _priceController.text = (data['price'] ?? 0).toString();
    _stockController.text = (data['stock'] ?? 0).toString();
    _descriptionController.text = data['description'] ?? '';
    _preparationTimeController.text = (data['preparationTime'] ?? 10).toString();
    setState(() {
      _selectedCategory = _parseCategoryFromString(data['category'] ?? 'others');
      _isAvailable = data['isAvailable'] ?? true;
      _isFeatured = data['isFeatured'] ?? false;
      _editingId = id;
    });
  }

  Future<void> _deleteMenuItem(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('menu_items')
            .doc(id)
            .delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menu item deleted'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Menu Management',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_editingId != null)
            TextButton(
              onPressed: _clearForm,
              child: const Text('Cancel'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Image Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                          image: _imageFile != null
                              ? DecorationImage(
                                  image: FileImage(_imageFile!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _imageFile == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate,
                                      color: Colors.grey[400]),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to add image',
                                    style: GoogleFonts.inter(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Food Name',
                              hintText: 'e.g., Chicken Adobo',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter food name';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Price',
                              hintText: '0.00',
                              prefixText: '₱',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter price';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<MenuCategory>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            items: MenuCategory.values.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category.name.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedCategory = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Stock',
                              hintText: '0',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter stock';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe the food item...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _preparationTimeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Prep Time (min)',
                              hintText: '10',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: SwitchListTile(
                                  title: Text(
                                    'Available',
                                    style: GoogleFonts.inter(fontSize: 12),
                                  ),
                                  value: _isAvailable,
                                  onChanged: (value) {
                                    setState(() => _isAvailable = value);
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                              Expanded(
                                child: SwitchListTile(
                                  title: Text(
                                    'Featured',
                                    style: GoogleFonts.inter(fontSize: 12),
                                  ),
                                  value: _isFeatured,
                                  onChanged: (value) {
                                    setState(() => _isFeatured = value);
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveMenuItem,
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
                                _editingId != null ? 'Update Item' : 'Add Item',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Menu List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('menu_items')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu,
                            size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No menu items yet',
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isAvailable = data['isAvailable'] ?? true;
                    final stock = data['stock'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            image: data['imageUrl'] != null
                                ? DecorationImage(
                                    image: NetworkImage(data['imageUrl']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: data['imageUrl'] == null
                              ? Icon(Icons.fastfood, color: Colors.orange[700])
                              : null,
                        ),
                        title: Text(
                          data['name'] ?? '',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('₱${data['price'] ?? 0} • ${data['category'] ?? ''}'),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isAvailable
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isAvailable ? 'Available' : 'Sold Out',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: isAvailable ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                if (stock < 10)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Stock: $stock',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _editMenuItem(data, doc.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => _deleteMenuItem(doc.id),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}