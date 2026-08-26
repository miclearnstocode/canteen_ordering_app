import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ==========================================
// 1. ADMIN DASHBOARD PAGE
// ==========================================
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});
  static const Color adminPurple = Color(0xFF5E35B1);
  static const Color green = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Overview',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              'Real-time canteen performance and metrics',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // Responsive Stats Section
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 750;
                final double cardWidth = isWide
                    ? (constraints.maxWidth - 48) / 4
                    : (constraints.maxWidth - 16) / 2;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _statCard('Today\'s Sales', '₱18,500', Icons.payments, green, '+12% from yesterday'),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _statCard('Orders Today', '235', Icons.receipt_long, const Color(0xFF1976D2), '42 pending'),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _statCard('Pending Orders', '18', Icons.hourglass_top, Colors.orange.shade800, 'Requires action'),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _statCard('Low Stock Items', '6', Icons.warning_amber_rounded, Colors.red.shade700, 'Restock needed'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Sales Chart Container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly Sales Overview',
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'May 13 - May 19, 2024',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: adminPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Total: ₱112,450',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: adminPurple),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Mock Line Chart
                  SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: LineChartPainter(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Day Labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                        .map((day) => Text(
                              day,
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. ADMIN ORDERS PAGE
// ==========================================
class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final Color adminPurple = const Color(0xFF5E35B1);
  String _selectedTab = 'All';

  final List<Map<String, dynamic>> _orders = [
    {
      'id': '#10025',
      'time': '10:30 AM',
      'name': 'Marianne Santos',
      'method': 'Cash',
      'amount': '₱315',
      'status': 'Pending',
    },
    {
      'id': '#10026',
      'time': '10:32 AM',
      'name': 'John Dela Cruz',
      'method': 'GCash',
      'amount': '₱190',
      'status': 'Preparing',
    },
    {
      'id': '#10027',
      'time': '10:34 AM',
      'name': 'Andrea Reyes',
      'method': 'Cash',
      'amount': '₱120',
      'status': 'Ready',
    },
    {
      'id': '#10028',
      'time': '10:40 AM',
      'name': 'Mark Garcia',
      'method': 'GCash',
      'amount': '₱250',
      'status': 'Completed',
    },
    {
      'id': '#10029',
      'time': '10:45 AM',
      'name': 'Kyle Villanueva',
      'method': 'Cash',
      'amount': '₱85',
      'status': 'Pending',
    },
  ];

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade800;
      case 'preparing':
        return adminPurple;
      case 'ready':
        return const Color(0xFF2E7D32);
      case 'completed':
      default:
        return Colors.grey.shade600;
    }
  }

  void _cycleStatus(int index) {
    setState(() {
      final current = _orders[index]['status'] as String;
      if (current == 'Pending') {
        _orders[index]['status'] = 'Preparing';
      } else if (current == 'Preparing') {
        _orders[index]['status'] = 'Ready';
      } else if (current == 'Ready') {
        _orders[index]['status'] = 'Completed';
      } else {
        _orders[index]['status'] = 'Pending';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ${_orders[index]['id']} updated to ${_orders[index]['status']}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedTab == 'All'
        ? _orders
        : _orders.where((o) => (o['status'] as String).toLowerCase() == _selectedTab.toLowerCase()).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Orders Management', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            // Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Pending', 'Preparing', 'Ready', 'Completed'].map((tab) {
                  final isSelected = _selectedTab == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      label: Text(tab),
                      selected: isSelected,
                      selectedColor: adminPurple,
                      labelStyle: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedTab = tab);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            // Orders Table / List
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No $_selectedTab orders found',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (context, i) => Divider(color: Colors.grey.shade100),
                        itemBuilder: (context, index) {
                          final order = filtered[index];
                          final originalIndex = _orders.indexOf(order);
                          final color = _getStatusColor(order['status'] as String);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                order['id'] as String,
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: color),
                              ),
                            ),
                            title: Text(
                              order['name'] as String,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            subtitle: Text(
                              '${order['time']} • Payment: ${order['method']}',
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  order['amount'] as String,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                                const SizedBox(width: 14),
                                InkWell(
                                  onTap: () => _cycleStatus(originalIndex),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      order['status'] as String,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. ADMIN MENU MANAGEMENT PAGE
// ==========================================
class AdminMenuManagementPage extends StatefulWidget {
  const AdminMenuManagementPage({super.key});

  @override
  State<AdminMenuManagementPage> createState() => _AdminMenuManagementPageState();
}

class _AdminMenuManagementPageState extends State<AdminMenuManagementPage> {
  final Color adminPurple = const Color(0xFF5E35B1);
  final Color green = const Color(0xFF2E7D32);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Beef Burger');
  final _priceController = TextEditingController(text: '75');
  final _descController = TextEditingController(text: 'Juicy beef patty with fresh vegetables');
  String _selectedCategory = 'Meals';
  bool _isAvailable = true;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved "${_nameController.text}" (₱${_priceController.text}) successfully!'),
          backgroundColor: green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Menu Item Editor', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Food Name', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Chicken Meal',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Please enter name' : null,
                    ),
                    const SizedBox(height: 16),

                    Text('Category', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: ['Meals', 'Snacks', 'Drinks', 'Desserts', 'Pastas']
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    Text('Price (₱)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'e.g. 75',
                        prefixText: '₱ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Please enter price' : null,
                    ),
                    const SizedBox(height: 16),

                    Text('Description', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Enter food details...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Availability Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Available for ordering today', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                      value: _isAvailable,
                      activeThumbColor: green,
                      onChanged: (val) => setState(() => _isAvailable = val),
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _saveItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Save Food Item'),
                        ),
                        const SizedBox(width: 14),
                        OutlinedButton(
                          onPressed: () {
                            _nameController.clear();
                            _priceController.clear();
                            _descController.clear();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. ADMIN INVENTORY PAGE
// ==========================================
class AdminInventoryPage extends StatefulWidget {
  const AdminInventoryPage({super.key});

  @override
  State<AdminInventoryPage> createState() => _AdminInventoryPageState();
}

class _AdminInventoryPageState extends State<AdminInventoryPage> {
  final Color adminPurple = const Color(0xFF5E35B1);

  final List<Map<String, dynamic>> _inventory = [
    {'name': 'Beef Patty', 'stock': 35, 'min': 10},
    {'name': 'Chicken Fillet', 'stock': 8, 'min': 10},
    {'name': 'Rice (kg)', 'stock': 50, 'min': 20},
    {'name': 'French Fries (packs)', 'stock': 6, 'min': 10},
    {'name': 'Milk Tea Pearls (packs)', 'stock': 15, 'min': 10},
    {'name': 'Soft Drink Cans', 'stock': 25, 'min': 10},
  ];

  void _adjustStock(int index, int delta) {
    setState(() {
      final newStock = (_inventory[index]['stock'] as int) + delta;
      if (newStock >= 0) {
        _inventory[index]['stock'] = newStock;
      }
    });
  }

  void _addNewItemDialog() {
    final nameCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final minCtrl = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Inventory Item', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Item Name')),
            TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Initial Stock')),
            TextField(controller: minCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min Alert Level')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && stockCtrl.text.isNotEmpty) {
                setState(() {
                  _inventory.add({
                    'name': nameCtrl.text,
                    'stock': int.tryParse(stockCtrl.text) ?? 0,
                    'min': int.tryParse(minCtrl.text) ?? 10,
                  });
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: adminPurple, foregroundColor: Colors.white),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Inventory Stocks', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700)),
                ElevatedButton.icon(
                  onPressed: _addNewItemDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: adminPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListView.separated(
                  itemCount: _inventory.length,
                  separatorBuilder: (context, i) => Divider(color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final item = _inventory[index];
                    final int stock = item['stock'] as int;
                    final int min = item['min'] as int;
                    final bool isLow = stock <= min;

                    return ListTile(
                      title: Text(item['name'] as String, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      subtitle: Text('Min alert level: $min units', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            onPressed: () => _adjustStock(index, -1),
                          ),
                          Text(
                            '$stock',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isLow ? Colors.red.shade700 : Colors.black87,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            onPressed: () => _adjustStock(index, 1),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isLow ? Colors.red.shade50 : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isLow ? 'LOW' : 'OK',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isLow ? Colors.red.shade700 : Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 5. ADMIN LOYALTY REWARDS PAGE
// ==========================================
class AdminLoyaltyRewardsPage extends StatefulWidget {
  const AdminLoyaltyRewardsPage({super.key});

  @override
  State<AdminLoyaltyRewardsPage> createState() => _AdminLoyaltyRewardsPageState();
}

class _AdminLoyaltyRewardsPageState extends State<AdminLoyaltyRewardsPage> {
  final Color adminPurple = const Color(0xFF5E35B1);

  final List<Map<String, dynamic>> _rewards = [
    {'name': 'Free Rice', 'points': '20 Points', 'icon': Icons.rice_bowl, 'enabled': true},
    {'name': 'Free Soft Drink', 'points': '30 Points', 'icon': Icons.local_drink, 'enabled': true},
    {'name': 'Free Fries', 'points': '40 Points', 'icon': Icons.fastfood, 'enabled': true},
    {'name': 'Free Burger', 'points': '80 Points', 'icon': Icons.lunch_dining, 'enabled': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loyalty Reward Offerings', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListView.separated(
                  itemCount: _rewards.length,
                  separatorBuilder: (context, i) => Divider(color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final reward = _rewards[index];
                    return SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: adminPurple.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(reward['icon'] as IconData, color: adminPurple),
                      ),
                      title: Text(reward['name'] as String, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      subtitle: Text(reward['points'] as String, style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                      value: reward['enabled'] as bool,
                      activeThumbColor: adminPurple,
                      onChanged: (val) {
                        setState(() => _rewards[index]['enabled'] = val);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// Line Chart Painter
// ==========================================
class LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    // Draw horizontal grid lines
    for (int i = 1; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final paint = Paint()
      ..color = const Color(0xFF5E35B1)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.75)
      ..lineTo(size.width * 0.16, size.height * 0.55)
      ..lineTo(size.width * 0.33, size.height * 0.65)
      ..lineTo(size.width * 0.50, size.height * 0.35)
      ..lineTo(size.width * 0.66, size.height * 0.45)
      ..lineTo(size.width * 0.83, size.height * 0.20)
      ..lineTo(size.width, size.height * 0.15);

    canvas.drawPath(path, paint);

    // Draw point markers
    final dotPaint = Paint()..color = const Color(0xFF5E35B1);
    final dotWhite = Paint()..color = Colors.white;
    final points = [
      Offset(0, size.height * 0.75),
      Offset(size.width * 0.16, size.height * 0.55),
      Offset(size.width * 0.33, size.height * 0.65),
      Offset(size.width * 0.50, size.height * 0.35),
      Offset(size.width * 0.66, size.height * 0.45),
      Offset(size.width * 0.83, size.height * 0.20),
      Offset(size.width, size.height * 0.15),
    ];

    for (final p in points) {
      canvas.drawCircle(p, 5, dotPaint);
      canvas.drawCircle(p, 2.5, dotWhite);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}