// lib/pages/menu_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/student_state.dart';
import '../models/menu_item_model.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final Color primaryColor = const Color(0xFF1E7B3B);
  final StudentAppState _state = StudentAppState();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'meals':
        return Icons.rice_bowl_rounded;
      case 'snacks':
        return Icons.fastfood_rounded;
      case 'drinks':
        return Icons.local_cafe_rounded;
      case 'pastas':
        return Icons.dinner_dining_rounded;
      case 'desserts':
        return Icons.cake_rounded;
      default:
        return Icons.restaurant_menu_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Menu',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: _state,
            builder: (context, _) {
              return IconButton(
                icon: Badge(
                  label: Text(
                    '${_state.totalCartCount}',
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  isLabelVisible: _state.totalCartCount > 0,
                  backgroundColor: primaryColor,
                  child: const Icon(Icons.shopping_cart_outlined,
                      color: Colors.black87),
                ),
                onPressed: () => _state.setTabIndex(2),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('menu_items')
            .where('isAvailable', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load menu:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.red.shade700),
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No menu items available yet.',
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
            );
          }

          final items = snapshot.data!.docs
              .map((doc) =>
                  MenuItemModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .toList();

          // Client-side filtering — avoids needing a composite index.
          final filtered = items.where((item) {
            final matchesCategory = _selectedCategory == 'All' ||
                item.category.toLowerCase() ==
                    _selectedCategory.toLowerCase();
            final matchesSearch = item.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
            return matchesCategory && matchesSearch;
          }).toList();

          // Build category list dynamically from real data.
          final categories = <String>{
            'All',
            ...items.map((e) => e.category),
          }.toList();

          return Column(
            children: [
              _buildSearchRow(),
              _buildCategoryRow(categories),
              const SizedBox(height: 6),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No food items found',
                          style: GoogleFonts.poppins(
                              color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) =>
                            _buildFoodCard(filtered[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search food...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.grey, size: 22),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(List<String> categories) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final label = categories[i];
          return _buildCategoryItem(label, _iconForCategory(label));
        },
      ),
    );
  }

  Widget _buildCategoryItem(String label, IconData icon) {
    final bool isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : Colors.grey.shade800,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodCard(MenuItemModel item) {
    final icon = _iconForCategory(item.category);
    final outOfStock = item.stock <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 76,
              height: 76,
              color: Colors.grey.shade100,
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child:
                            Icon(icon, size: 36, color: primaryColor),
                      ),
                    )
                  : Center(child: Icon(icon, size: 36, color: primaryColor)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '₱${item.price.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${item.stock} left',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: outOfStock
                            ? Colors.red.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: outOfStock
                ? null
                : () {
                    _state.addToCart(
                      item.id,
                      item.name,
                      item.price,
                      item.imageUrl ?? '',
                      icon,
                    );
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added ${item.name} to cart!'),
                        duration: const Duration(milliseconds: 1200),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: primaryColor,
                      ),
                    );
                  },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: outOfStock ? Colors.grey.shade400 : primaryColor,
                shape: BoxShape.circle,
                boxShadow: outOfStock
                    ? []
                    : [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Icon(
                outOfStock ? Icons.block : Icons.add,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}