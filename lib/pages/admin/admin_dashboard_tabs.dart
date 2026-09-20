import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import '../../models/menu_item_model.dart';
import '../../helpers/image_picker_helper.dart';
import '../../services/cloudinary_service.dart';

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
// 2. ADMIN ORDERS PAGE (Firestore-backed)
// ==========================================
class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final Color adminPurple = const Color(0xFF5E35B1);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedTab = 'All';
  String? _updatingId;

  // Cache: userId -> display name. Fetched lazily and reused across rebuilds.
  final Map<String, String> _nameCache = {};
  final Set<String> _loadingNames = {};

  static const List<String> _statuses = [
    'Pending',
    'Preparing',
    'Ready',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade800;
      case 'preparing':
        return adminPurple;
      case 'ready':
        return const Color(0xFF2E7D32);
      case 'completed':
        return Colors.grey.shade600;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  /// Look up a student's display name by uid. Caches the result.
  /// Returns null while loading (caller shows a placeholder).
  String? _nameFor(String uid) {
    if (_nameCache.containsKey(uid)) return _nameCache[uid];

    // Kick off a fetch once per uid.
    if (!_loadingNames.contains(uid)) {
      _loadingNames.add(uid);
      _firestore.collection('users').doc(uid).get().then((doc) {
        final data = doc.data();
        final name = (data?['displayName'] ??
                data?['username'] ??
                'Unknown Student')
            .toString();
        if (!mounted) return;
        setState(() {
          _nameCache[uid] = name;
          _loadingNames.remove(uid);
        });
      }).catchError((_) {
        if (!mounted) return;
        setState(() {
          _nameCache[uid] = 'Unknown Student';
          _loadingNames.remove(uid);
        });
      });
    }
    return null; // still loading
  }

  // ---- Status update with confirmation ----
  Future<void> _updateStatus(
      String orderId, String currentStatus, String newStatus) async {
    if (currentStatus == newStatus) return;

    if (currentStatus == 'Completed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completed orders can no longer be changed.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Change status?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Set order to "$newStatus"?',
            style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _statusColor(newStatus),
              foregroundColor: Colors.white,
            ),
            child: Text('Yes, $newStatus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _updatingId = orderId);
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order updated to $newStatus'),
            backgroundColor: _statusColor(newStatus),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingId = null);
    }
  }

  Future<void> _showStatusPicker(
      String orderId, String currentStatus) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Update Status',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ..._statuses.map((s) {
              final isCurrent = s == currentStatus;
              final color = _statusColor(s);
              return ListTile(
                leading: Icon(
                  isCurrent
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: color,
                ),
                title: Text(
                  s,
                  style: GoogleFonts.poppins(
                    fontWeight:
                        isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, s),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (picked != null && picked != currentStatus) {
      await _updateStatus(orderId, currentStatus, picked);
    }
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
            Text('Orders Management',
                style: GoogleFonts.poppins(
                    fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Live orders from students. Tap a status to update it.',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', ..._statuses].map((tab) {
                  final isSelected = _selectedTab == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      label: Text(tab),
                      selected: isSelected,
                      selectedColor: adminPurple,
                      labelStyle: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
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

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('orders').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Failed to load orders:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                                color: Colors.red.shade700, fontSize: 12),
                          ),
                        ),
                      );
                    }

                    final orders = (snapshot.data?.docs ?? [])
                        .map((d) => _AdminOrder.fromDoc(d))
                        .toList()
                      ..sort((a, b) {
                        final aT = a.createdAt ??
                            DateTime.fromMillisecondsSinceEpoch(0);
                        final bT = b.createdAt ??
                            DateTime.fromMillisecondsSinceEpoch(0);
                        return bT.compareTo(aT);
                      });

                    final filtered = _selectedTab == 'All'
                        ? orders
                        : orders
                            .where((o) =>
                                o.status.toLowerCase() ==
                                _selectedTab.toLowerCase())
                            .toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('No $_selectedTab orders',
                                style: GoogleFonts.poppins(
                                    color: Colors.grey.shade600)),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, i) =>
                          Divider(color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final order = filtered[index];
                        final color = _statusColor(order.status);
                        final isUpdating = _updatingId == order.id;

                        // Resolve buyer name via cache; returns null on
                        // the first frame while the fetch is in flight.
                        final cachedName = _nameFor(order.userId);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '#${order.orderNumber}',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: color),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  cachedName ?? 'Loading…',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: cachedName == null
                                          ? Colors.grey.shade500
                                          : Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${order.formattedDateTime}  •  ${order.itemsSummary}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey.shade600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Payment: ${order.paymentMethod}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₱${order.total.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              const SizedBox(width: 12),
                              isUpdating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : InkWell(
                                      onTap: () => _showStatusPicker(
                                          order.id, order.status),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color:
                                              color.withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              order.status,
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: color,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(Icons.expand_more,
                                                size: 16, color: color),
                                          ],
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        );
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

// ---------- Admin-side order model ----------
class _AdminOrder {
  final String id;
  final String orderNumber;
  final String status;
  final String userId;
  final String paymentMethod;
  final DateTime? createdAt;
  final double total;
  final List<Map<String, dynamic>> items;

  _AdminOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.userId,
    required this.paymentMethod,
    required this.createdAt,
    required this.total,
    required this.items,
  });

  factory _AdminOrder.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawItems = (data['items'] as List?) ?? const [];
    return _AdminOrder(
      id: doc.id,
      orderNumber: (data['orderNumber'] ?? doc.id.substring(0, 8))
          .toString()
          .toUpperCase(),
      status: (data['status'] ?? 'Pending').toString(),
      userId: (data['userId'] ?? '').toString(),
      paymentMethod: (data['paymentMethod'] ?? 'Credits').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      items: rawItems
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }

  String get itemsSummary {
    if (items.isEmpty) return 'No items';
    return items
        .map((e) => '${e['name'] ?? 'Item'} x${e['quantity'] ?? 1}')
        .join(', ');
  }

  String get formattedDateTime {
    if (createdAt == null) return '';
    final local = createdAt!.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final minute = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, $hour12:$minute $ampm';
  }
}

// ==========================================
// 3. ADMIN MENU MANAGEMENT PAGE (Firebase with Image)
// ==========================================
class AdminMenuManagementPage extends StatefulWidget {
  const AdminMenuManagementPage({super.key});

  @override
  State<AdminMenuManagementPage> createState() => _AdminMenuManagementPageState();
}

class _AdminMenuManagementPageState extends State<AdminMenuManagementPage> {
  final Color adminPurple = const Color(0xFF5E35B1);
  final Color green = const Color(0xFF2E7D32);
  final CollectionReference _menuCollection = FirebaseFirestore.instance.collection('menu_items');

  // Add new item with image (uploaded to Cloudinary, image_url saved to Firebase)
  Future<void> _addItem(MenuItemModel item, XFile? imageFile) async {
    String? imageUrl;
    
    // Upload image to Cloudinary if selected
    if (imageFile != null) {
      imageUrl = await CloudinaryService.uploadImage(imageFile, folder: 'menu_items');
    }
    
    // Add item with image_url to Firebase Firestore
    final itemWithImage = item.copyWith(imageUrl: imageUrl);
    await _menuCollection.add(itemWithImage.toMap());
  }

  // Update item with image (uploaded to Cloudinary, image_url saved to Firebase)
  Future<void> _updateItem(String id, MenuItemModel updatedItem, XFile? imageFile) async {
    String? imageUrl = updatedItem.imageUrl;
    
    // Upload new image to Cloudinary if selected
    if (imageFile != null) {
      imageUrl = await CloudinaryService.uploadImage(imageFile, folder: 'menu_items');
    }
    
    // Update item with image_url in Firebase Firestore
    final itemWithImage = updatedItem.copyWith(imageUrl: imageUrl);
    await _menuCollection.doc(id).update(itemWithImage.toMap());
  }

  // Delete item from Firebase
  Future<void> _deleteItem(String id, String? imageUrl) async {
    // Delete document from Firestore
    await _menuCollection.doc(id).delete();
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
                Text('Menu Management', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700)),
                ElevatedButton.icon(
                  onPressed: () => _showAddItemDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: adminPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Tap to edit • Swipe left to delete', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            
            // Firebase StreamBuilder
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _menuCollection.orderBy('name').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF5E35B1)));
                    }

                    if (snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (context, i) => Divider(color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final item = MenuItemModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);

                        return Dismissible(
                          key: Key(doc.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Text('Delete Item?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                  content: Text('Are you sure you want to delete "${item.name}"? This action cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          onDismissed: (direction) {
                            _deleteItem(doc.id, item.imageUrl);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Deleted "${item.name}"'), backgroundColor: Colors.red.shade400),
                            );
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              onTap: () => _showEditItemDialog(context, item),
                              leading: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.shade100,
                                  image: item.imageUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(item.imageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: item.imageUrl == null
                                    ? Icon(
                                        item.category == 'Drinks' ? Icons.local_cafe : 
                                        item.category == 'Snacks' ? Icons.fastfood : 
                                        Icons.lunch_dining,
                                        color: adminPurple,
                                        size: 28,
                                      )
                                    : null,
                              ),
                              title: Text(
                                item.name,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.category} • Stock: ${item.stock}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    item.description,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '₱${item.price.toStringAsFixed(0)}',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: adminPurple,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: item.isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.isAvailable ? 'Available' : 'Unavailable',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: item.isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.edit,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                                                  
                        );
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

  // Empty State Widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: adminPurple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.restaurant_menu, size: 64, color: adminPurple),
          ),
          const SizedBox(height: 20),
          Text(
            'No Menu Items Yet',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Click "Add New Item" to create your first menu item.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ADD ITEM with Image (Web Compatible)
  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'Meals';
    bool isAvailable = true;
    XFile? selectedImage;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Add New Menu Item', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), color: Colors.grey.shade600),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: selectedImage != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: FutureBuilder<Uint8List>(
                                  future: selectedImage!.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData && snapshot.data != null) {
                                      return Image.memory(
                                        snapshot.data!,
                                        width: double.infinity,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      );
                                    } else if (snapshot.hasError) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                      );
                                    } else {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                  },
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black.withValues(alpha: 0.7),
                                  radius: 18,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white, size: 16),
                                    onPressed: () {
                                      setModalState(() => selectedImage = null);
                                    },
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : InkWell(
                            onTap: () async {
                              final XFile? image = await ImagePickerHelper.pickImage();
                              if (image != null) {
                                setModalState(() => selectedImage = image);
                              }
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  kIsWeb ? Icons.cloud_upload : Icons.photo_library,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  kIsWeb ? 'Click to select image' : 'Tap to upload image',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Supports PNG, JPG, GIF, WEBP',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                                    
                  const SizedBox(height: 16),

                  Text('Food Name', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(controller: nameController, decoration: InputDecoration(hintText: 'e.g. Chicken Meal', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
                  const SizedBox(height: 16),

                  Text('Category', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                    items: ['Meals', 'Snacks', 'Drinks', 'Desserts', 'Pastas'].map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                    onChanged: (val) { if (val != null) setModalState(() => selectedCategory = val); },
                  ),
                  const SizedBox(height: 16),

                  Text('Price (₱)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(controller: priceController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'e.g. 75', prefixText: '₱ ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
                  const SizedBox(height: 16),

                  Text('Stock Quantity', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(controller: stockController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'e.g. 20', prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
                  const SizedBox(height: 16),

                  Text('Description', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(controller: descController, maxLines: 3, decoration: InputDecoration(hintText: 'Enter food details...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.all(12))),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Available for ordering today', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    value: isAvailable,
                    activeThumbColor: green,
                    onChanged: (val) => setModalState(() => isAvailable = val),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isUploading
                              ? null
                              : () async {
                                  if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                                    setModalState(() => isUploading = true);
                                    try {
                                      final newItem = MenuItemModel(
                                        id: '',
                                        name: nameController.text,
                                        category: selectedCategory,
                                        price: double.tryParse(priceController.text) ?? 0,
                                        description: descController.text,
                                        stock: int.tryParse(stockController.text) ?? 0,
                                        isAvailable: isAvailable,
                                      );
                                      await _addItem(newItem, selectedImage);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Added "${newItem.name}" successfully!'), backgroundColor: green),
                                        );
                                      }
                                    } catch (e) {
                                      setModalState(() => isUploading = false);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error adding item: $e'), backgroundColor: Colors.red),
                                        );
                                      }
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: adminPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: isUploading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Add Item'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isUploading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // EDIT ITEM with Image (Web Compatible)
  void _showEditItemDialog(BuildContext context, MenuItemModel item) {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toString());
    final stockController = TextEditingController(text: item.stock.toString());
    final descController = TextEditingController(text: item.description);
    String selectedCategory = item.category;
    bool isAvailable = item.isAvailable;
    XFile? selectedImage;
    bool isUploading = false;
    String? existingImageUrl = item.imageUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Edit ${item.name}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), color: Colors.grey.shade600),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Image Upload Section (Web Compatible)
                  Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: selectedImage != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: FutureBuilder<Uint8List>(
                                  future: selectedImage!.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData && snapshot.data != null) {
                                      return Image.memory(
                                        snapshot.data!,
                                        width: double.infinity,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      );
                                    } else if (snapshot.hasError) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                      );
                                    } else {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                  },
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black.withValues(alpha: 0.7),
                                  radius: 18,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white, size: 16),
                                    onPressed: () {
                                      setModalState(() => selectedImage = null);
                                    },
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : existingImageUrl != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      existingImageUrl!,
                                      width: double.infinity,
                                      height: 150,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black.withValues(alpha: 0.7),
                                      radius: 18,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white, size: 16),
                                        onPressed: () {
                                          setModalState(() => existingImageUrl = null);
                                        },
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : InkWell(
                                onTap: () async {
                                  final XFile? image = await ImagePickerHelper.pickImage();
                                  if (image != null) {
                                    setModalState(() => selectedImage = image);
                                  }
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      kIsWeb ? Icons.cloud_upload : Icons.photo_library,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      kIsWeb ? 'Click to select image' : 'Tap to upload image',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Recommended: 800x800px',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade400,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                  const SizedBox(height: 16),

                  Text('Food Name', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(controller: nameController, decoration: InputDecoration(hintText: 'e.g. Chicken Meal', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
                  const SizedBox(height: 16),

                  Text('Category', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                    items: ['Meals', 'Snacks', 'Drinks', 'Desserts', 'Pastas'].map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                    onChanged: (val) { if (val != null) setModalState(() => selectedCategory = val); },
                  ),
                  const SizedBox(height: 16),

                  Text('Price (₱)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(controller: priceController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'e.g. 75', prefixText: '₱ ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
                  const SizedBox(height: 16),

                  Text('Stock Quantity', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(controller: stockController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'e.g. 20', prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
                  const SizedBox(height: 16),

                  Text('Description', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(controller: descController, maxLines: 3, decoration: InputDecoration(hintText: 'Enter food details...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.all(12))),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Available for ordering today', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    value: isAvailable,
                    activeThumbColor: green,
                    onChanged: (val) => setModalState(() => isAvailable = val),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isUploading
                              ? null
                              : () async {
                                  final updatedItem = item.copyWith(
                                    name: nameController.text,
                                    category: selectedCategory,
                                    price: double.tryParse(priceController.text) ?? item.price,
                                    description: descController.text,
                                    stock: int.tryParse(stockController.text) ?? item.stock,
                                    isAvailable: isAvailable,
                                  );
                                  
                                  setModalState(() => isUploading = true);
                                  try {
                                    await _updateItem(item.id, updatedItem, selectedImage);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Updated "${updatedItem.name}" successfully!'), backgroundColor: green),
                                      );
                                    }
                                  } catch (e) {
                                    setModalState(() => isUploading = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error updating item: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: isUploading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
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
                          onPressed: isUploading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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