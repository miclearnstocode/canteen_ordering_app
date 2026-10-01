import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import '../../models/menu_item_model.dart';
import '../../helpers/image_picker_helper.dart';
import '../../services/cloudinary_service.dart';
import '../../services/inventory_service.dart';
import '../../models/inventory_item_model.dart';
import '../../widgets/unit_picker_field.dart';
import '../../models/loyalty_reward_model.dart';
import 'dart:math';
import 'package:mobile_scanner/mobile_scanner.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});
  static const Color adminPurple = Color(0xFF5E35B1);
  static const Color green = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('orders').snapshots(),
        builder: (context, snapshot) {
          // ── Parse orders once ──
          final orders = (snapshot.data?.docs ?? [])
              .map((d) => d.data() as Map<String, dynamic>)
              .toList();

          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);

          double todaySales = 0;
          int todayOrders = 0;
          int pendingOrders = 0;
          double totalEarnings = 0;
          int completedCount = 0;

          // Weekly buckets (index 0 = 6 days ago, index 6 = today)
          final weeklyEarnings = List<double>.filled(7, 0);
          final weeklyLabels = List<String>.generate(7, (i) {
            final d = todayStart.subtract(Duration(days: 6 - i));
            return _shortDayLabel(d);
          });

          for (final data in orders) {
            final status =
                (data['status'] ?? '').toString().toLowerCase();
            final total = (data['total'] as num?)?.toDouble() ?? 0;
            final created = (data['createdAt'] as Timestamp?)?.toDate();

            if (created != null &&
                created.isAfter(todayStart) &&
                status != 'cancelled') {
              todayOrders++;
            }

            if (status == 'pending') pendingOrders++;

            if (status == 'completed') {
              completedCount++;
              totalEarnings += total;

              if (created != null && created.isAfter(todayStart)) {
                todaySales += total;
              }

              // Weekly bucket
              if (created != null) {
                final localCreated = created.toLocal();
                final orderDay = DateTime(
                    localCreated.year,
                    localCreated.month,
                    localCreated.day);
                final diff = todayStart.difference(orderDay).inDays;
                if (diff >= 0 && diff <= 6) {
                  final bucketIndex = 6 - diff;
                  weeklyEarnings[bucketIndex] += total;
                }
              }
            }
          }

          final avgTicket =
              completedCount > 0 ? totalEarnings / completedCount : 0.0;
          final weeklyTotal =
              weeklyEarnings.fold<double>(0, (a, b) => a + b);

          final isLoading =
              snapshot.connectionState == ConnectionState.waiting;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Overview',
                  style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real-time canteen performance and metrics',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),

                // ── STAT CARDS ──
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
                          child: _statCard(
                            "Today's Sales",
                            isLoading
                                ? '…'
                                : '₱${todaySales.toStringAsFixed(0)}',
                            Icons.payments,
                            green,
                            'From completed orders',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _statCard(
                            'Orders Today',
                            isLoading ? '…' : '$todayOrders',
                            Icons.receipt_long,
                            const Color(0xFF1976D2),
                            '$pendingOrders pending',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _statCard(
                            'Total Earnings',
                            isLoading
                                ? '…'
                                : '₱${totalEarnings.toStringAsFixed(0)}',
                            Icons.account_balance_wallet,
                            adminPurple,
                            '$completedCount completed orders',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _statCard(
                            'Avg. Ticket',
                            isLoading
                                ? '…'
                                : '₱${avgTicket.toStringAsFixed(0)}',
                            Icons.trending_up,
                            Colors.orange.shade800,
                            'Per completed order',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ── WEEKLY EARNINGS LINE GRAPH ──
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(                         // <-- takes remaining width, forces the Column to shrink
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Weekly Earnings',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Last 7 days • based on completed orders',
                                  maxLines: 2,              // allow wrap on very narrow screens
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),         // guarantee a gap before the badge
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: adminPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Total: ₱${weeklyTotal.toStringAsFixed(0)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: adminPurple),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: EarningsLineChart(
                          values: weeklyEarnings,
                          labels: weeklyLabels,
                          lineColor: adminPurple,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: weeklyLabels
                            .map((label) => Text(
                                  label,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── EARNINGS BREAKDOWN ──
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
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Earnings Breakdown',
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Based on completed orders only',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  adminPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Total: ₱${totalEarnings.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: adminPurple),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _earningRow(
                        label: "Today's Earnings",
                        amount: todaySales,
                        icon: Icons.today,
                        color: green,
                      ),
                      const SizedBox(height: 12),
                      _earningRow(
                        label: 'All-Time Earnings',
                        amount: totalEarnings,
                        icon: Icons.history,
                        color: adminPurple,
                      ),
                      const SizedBox(height: 12),
                      _earningRow(
                        label: 'Average Order Value',
                        amount: avgTicket,
                        icon: Icons.show_chart,
                        color: Colors.orange.shade800,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _shortDayLabel(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }

  Widget _statCard(String title, String value, IconData icon, Color color,
      String subtitle) {
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
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500),
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
            style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
                fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _earningRow({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// 2. ADMIN ORDERS PAGE
class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final Color adminPurple = const Color(0xFF5E35B1);
  final Color green = const Color(0xFF2E7D32);
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

  String? _nameFor(String uid) {
    if (_nameCache.containsKey(uid)) return _nameCache[uid];
    if (!_loadingNames.contains(uid)) {
      _loadingNames.add(uid);
      _firestore.collection('users').doc(uid).get().then((doc) {
        final data = doc.data();
        final name =
            (data?['displayName'] ?? data?['username'] ?? 'Unknown Student')
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
    return null;
  }

  // ─────────────────────────────────────────────
  // PICKUP TOKEN (generated on → Ready)
  // ─────────────────────────────────────────────
  // Avoids 0/O/1/I so it stays readable if typed manually.
  String _generatePickupToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(24, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  // ─────────────────────────────────────────────
  // QR SCANNER
  // ─────────────────────────────────────────────
  Future<void> _openScanner({String? expectedOrderId}) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _QrScannerScreen()),
    );
    if (result == null || !mounted) return;
    await _processScannedPayload(result, expectedOrderId: expectedOrderId);
  }

  Future<void> _processScannedPayload(
    String raw, {
    String? expectedOrderId,
  }) async {
    const prefix = 'CANTEEN_PICKUP:';
    if (!raw.startsWith(prefix)) {
      _scannerFeedback('Not a Canteen Click pickup QR.', isError: true);
      return;
    }

    final rest = raw.substring(prefix.length);
    final parts = rest.split(':');
    if (parts.length != 2) {
      _scannerFeedback('Malformed QR code.', isError: true);
      return;
    }
    final orderId = parts[0];
    final token = parts[1];

    // If we launched the scanner from a specific order, enforce it.
    if (expectedOrderId != null && orderId != expectedOrderId) {
      _scannerFeedback(
        'This QR belongs to a different order. Please scan the correct one.',
        isError: true,
      );
      return;
    }

    final snap = await _firestore.collection('orders').doc(orderId).get();
    if (!snap.exists) {
      _scannerFeedback('Order not found.', isError: true);
      return;
    }
    final data = snap.data()!;
    final status = (data['status'] ?? '').toString();
    final storedToken = (data['pickupToken'] ?? '').toString();

    if (status.toLowerCase() != 'ready') {
      _scannerFeedback(
        'Order is not Ready yet (currently $status).',
        isError: true,
      );
      return;
    }
    if (storedToken.isEmpty || storedToken != token) {
      _scannerFeedback('Invalid or expired QR.', isError: true);
      return;
    }

    final orderNumber =
        (data['orderNumber'] ?? orderId.substring(0, 8))
            .toString()
            .toUpperCase();

    final confirmed = await showDialog<bool>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Complete order?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #$orderNumber',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Mark this order as Completed and award loyalty points to the student?',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: adminPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Only now — after a valid QR + explicit confirmation — do we write.
    await _updateStatus(
      orderId,
      'Ready',
      'Completed',
      allowCompletion: true,
    );
  }

  void _scannerFeedback(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade600 : green,
      ),
    );
  }

  // EARNINGS SUMMARY CARD
  Widget _buildEarningsSummary(List<_AdminOrder> orders) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    double todayTotal = 0;
    int todayCount = 0;
    double allTimeTotal = 0;
    int allTimeCount = 0;

    for (final o in orders) {
      if (o.status.toLowerCase() != 'completed') continue;

      allTimeTotal += o.total;
      allTimeCount++;

      final created = o.createdAt;
      if (created != null && created.isAfter(todayStart)) {
        todayTotal += o.total;
        todayCount++;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 650;
        final cardWidth =
            isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: cardWidth,
              child: _earningCard(
                title: "Today's Earnings",
                amount: todayTotal,
                orderCount: todayCount,
                color: green,
                icon: Icons.today,
                subtitle: 'From completed orders today',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _earningCard(
                title: 'Total Earnings',
                amount: allTimeTotal,
                orderCount: allTimeCount,
                color: adminPurple,
                icon: Icons.account_balance_wallet,
                subtitle: 'All-time completed orders',
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _orderBadge(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: green),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _earningCard({
    required String title,
    required double amount,
    required int orderCount,
    required Color color,
    required IconData icon,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.receipt_long, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '$orderCount completed order${orderCount == 1 ? '' : 's'}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // UPDATE STATUS
  // ─────────────────────────────────────────────
  Future<void> _updateStatus(
    String orderId,
    String currentStatus,
    String newStatus, {
    bool allowCompletion = false,
  }) async {
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

    // ── Guard: any non-QR attempt to complete → route to the scanner ──
    if (newStatus == 'Completed' && !allowCompletion) {
      await _openScanner(expectedOrderId: orderId);
      return;
    }

    // ── Show confirmation, with a preview of points to be awarded ──
    String? bonusMessage;
    if (newStatus == 'Completed') {
      final orderSnap =
          await _firestore.collection('orders').doc(orderId).get();
      final total = (orderSnap.data()?['total'] as num?)?.toDouble() ?? 0;
      final pts = (total / 20).floor();
      bonusMessage =
          'Student will earn $pts loyalty point${pts == 1 ? '' : 's'}.';
    }

    final confirmed = await showDialog<bool>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Change status?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set order to "$newStatus"?',
                style: GoogleFonts.poppins(fontSize: 13)),
            if (bonusMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.stars, size: 18, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bonusMessage,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
      final orderRef = _firestore.collection('orders').doc(orderId);

      await _firestore.runTransaction((tx) async {
        // ═══════════════════════════════════════════════
        // PHASE 1 — READS ONLY (no writes yet!)
        // ═══════════════════════════════════════════════

        final orderSnap = await tx.get(orderRef);
        if (!orderSnap.exists) {
          throw Exception('Order no longer exists.');
        }
        final orderData = orderSnap.data()!;
        final total = (orderData['total'] as num?)?.toDouble() ?? 0;
        final userId = (orderData['userId'] ?? '').toString();
        final alreadyAwarded = orderData['pointsAwarded'] == true;
        final alreadyDeducted = orderData['inventoryDeducted'] == true;

        // Prepare the order update map (not applied yet).
        final orderUpdate = <String, dynamic>{
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // 1a. Pickup token for Ready
        if (newStatus == 'Ready' && currentStatus != 'Ready') {
          orderUpdate['pickupToken'] = _generatePickupToken();
          orderUpdate['readyAt'] = FieldValue.serverTimestamp();
        }

        // 1b. Clear the token when leaving Ready
        if (currentStatus == 'Ready' && newStatus != 'Ready') {
          orderUpdate['pickupToken'] = FieldValue.delete();
        }

        // 1c. Stamp completion + clear token
        if (newStatus == 'Completed') {
          orderUpdate['completedAt'] = FieldValue.serverTimestamp();
          orderUpdate['pickupToken'] = FieldValue.delete();
        }

        // ── Inventory: collect reads + computed deltas ──
        // Map of inventory doc → new stock value
        final inventoryUpdates = <DocumentReference, double>{};

        if (newStatus == 'Completed' &&
            currentStatus != 'Completed' &&
            !alreadyDeducted) {
          final rawItems = (orderData['items'] as List?) ?? const [];

          for (final raw in rawItems) {
            if (raw is! Map) continue;
            final menuItemId = (raw['id'] ?? '').toString();
            final orderQty = (raw['quantity'] as num?)?.toInt() ?? 0;
            if (menuItemId.isEmpty || orderQty <= 0) continue;

            final menuRef =
                _firestore.collection('menu_items').doc(menuItemId);
            final menuSnap = await tx.get(menuRef);
            if (!menuSnap.exists) continue;

            final menuData = menuSnap.data()!;
            final kind = (menuData['kind'] ?? 'madeToOrder').toString();
            if (kind != 'madeToOrder') continue;

            final recipe = (menuData['recipe'] as List?) ?? const [];

            for (final r in recipe) {
              if (r is! Map) continue;
              final ingredientId = (r['ingredientId'] ?? '').toString();
              final qtyPerPortion =
                  (r['qtyPerPortion'] as num?)?.toDouble() ?? 0;
              if (ingredientId.isEmpty || qtyPerPortion <= 0) continue;

              final invRef =
                  _firestore.collection('inventory').doc(ingredientId);
              final invSnap = await tx.get(invRef);
              if (!invSnap.exists) continue;

              final currentStock =
                  (invSnap.data()?['stock'] as num?)?.toDouble() ?? 0;
              final deduct = qtyPerPortion * orderQty;

              inventoryUpdates[invRef] =
                  (inventoryUpdates[invRef] ?? currentStock) - deduct;
            }
          }
          orderUpdate['inventoryDeducted'] = true;
        }

        // ── Points: collect user read + computed new balance ──
        DocumentReference? pointsUserRef;
        Map<String, dynamic>? pointsUserUpdate;
        Map<String, dynamic>? pointsLogEntry;

        if (newStatus == 'Completed' &&
            currentStatus != 'Completed' &&
            !alreadyAwarded &&
            userId.isNotEmpty) {
          final pointsEarned = (total / 20).floor();

          if (pointsEarned > 0) {
            final userRef = _firestore.collection('users').doc(userId);
            final userSnap = await tx.get(userRef);

            if (userSnap.exists) {
              final currentPoints =
                  (userSnap.data()?['points'] as num?)?.toInt() ?? 0;
              final newPoints = currentPoints + pointsEarned;

              pointsUserRef = userRef;
              pointsUserUpdate = {
                'points': newPoints,
                'updatedAt': FieldValue.serverTimestamp(),
              };

              pointsLogEntry = {
                'uid': userId,
                'type': 'earn',
                'amount': pointsEarned,
                'balanceAfter': newPoints,
                'note':
                    'Order #${orderData['orderNumber']} completed (₱${total.toStringAsFixed(0)})',
                'orderId': orderId,
                'timestamp': FieldValue.serverTimestamp(),
              };

              orderUpdate['pointsEarned'] = pointsEarned;
              orderUpdate['pointsAwarded'] = true;
            }
          } else {
            orderUpdate['pointsEarned'] = 0;
            orderUpdate['pointsAwarded'] = true;
          }
        }

        // ── Refund points: collect user read ──
        DocumentReference? refundUserRef;
        Map<String, dynamic>? refundUserUpdate;
        Map<String, dynamic>? refundLogEntry;

        if (currentStatus == 'Completed' &&
            newStatus != 'Completed' &&
            alreadyAwarded &&
            userId.isNotEmpty) {
          final pointsToRefund =
              (orderData['pointsEarned'] as num?)?.toInt() ?? 0;

          if (pointsToRefund > 0) {
            final userRef = _firestore.collection('users').doc(userId);
            final userSnap = await tx.get(userRef);
            if (userSnap.exists) {
              final currentPoints =
                  (userSnap.data()?['points'] as num?)?.toInt() ?? 0;
              final newPoints =
                  (currentPoints - pointsToRefund).clamp(0, 1 << 30);

              refundUserRef = userRef;
              refundUserUpdate = {
                'points': newPoints,
                'updatedAt': FieldValue.serverTimestamp(),
              };

              refundLogEntry = {
                'uid': userId,
                'type': 'refund',
                'amount': -pointsToRefund,
                'balanceAfter': newPoints,
                'note':
                    'Order #${orderData['orderNumber']} reopened from Completed',
                'orderId': orderId,
                'timestamp': FieldValue.serverTimestamp(),
              };

              orderUpdate['pointsAwarded'] = false;
              orderUpdate['pointsEarned'] = 0;
            }
          }
        }

        // ── Cancel: restore reserved stock / portions ──
        final menuRestoreUpdates = <DocumentReference, Map<String, int>>{};

        if (newStatus == 'Cancelled' &&
            currentStatus != 'Cancelled' &&
            currentStatus != 'Completed') {
          final rawItems = (orderData['items'] as List?) ?? const [];

          for (final raw in rawItems) {
            if (raw is! Map) continue;
            final menuItemId = (raw['id'] ?? '').toString();
            final orderQty = (raw['quantity'] as num?)?.toInt() ?? 0;
            if (menuItemId.isEmpty || orderQty <= 0) continue;

            final menuRef =
                _firestore.collection('menu_items').doc(menuItemId);
            final menuSnap = await tx.get(menuRef);
            if (!menuSnap.exists) continue;

            final menuData = menuSnap.data()!;
            final kind = (menuData['kind'] ?? 'madeToOrder').toString();

            if (kind == 'batchCooked') {
              final prepared =
                  (menuData['preparedPortions'] as num?)?.toInt() ?? 0;
              menuRestoreUpdates[menuRef] = {
                'preparedPortions': prepared + orderQty,
              };
            } else {
              final stock = (menuData['stock'] as num?)?.toInt() ?? 0;
              menuRestoreUpdates[menuRef] = {
                'stock': stock + orderQty,
              };
            }
          }
        }

        // ═══════════════════════════════════════════════
        // PHASE 2 — WRITES ONLY (no more tx.get!)
        // ═══════════════════════════════════════════════

        // 1. Inventory deduction
        for (final entry in inventoryUpdates.entries) {
          tx.update(entry.key, {
            'stock': entry.value.clamp(0.0, 1 << 30),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // 2. Points awarded
        if (pointsUserRef != null && pointsUserUpdate != null) {
          tx.update(pointsUserRef, pointsUserUpdate);
        }
        if (pointsLogEntry != null) {
          final logRef = _firestore.collection('points_transactions').doc();
          tx.set(logRef, pointsLogEntry);
        }

        // 3. Points refunded
        if (refundUserRef != null && refundUserUpdate != null) {
          tx.update(refundUserRef, refundUserUpdate);
        }
        if (refundLogEntry != null) {
          final logRef = _firestore.collection('points_transactions').doc();
          tx.set(logRef, refundLogEntry);
        }

        // 4. Cancel restore
        for (final entry in menuRestoreUpdates.entries) {
          final updates = <String, dynamic>{
            'isAvailable': true,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          updates.addAll(entry.value.map((k, v) => MapEntry(k, v)));
          tx.update(entry.key, updates);
        }

        // 5. Finally — the order itself
        tx.update(orderRef, orderUpdate);
      });

      if (mounted) {
        final msg = newStatus == 'Completed'
            ? 'Order completed — student awarded loyalty points'
            : newStatus == 'Ready'
                ? 'Order is Ready — student can now show their pickup QR'
                : 'Order updated to $newStatus';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
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

  // ─────────────────────────────────────────────
  // STATUS PICKER
  // ─────────────────────────────────────────────
  Future<void> _showStatusPicker(
    String orderId,
    String currentStatus,
  ) async {
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
              final isCompleted = s == 'Completed';
              final color = _statusColor(s);

              return ListTile(
                leading: Icon(
                  isCurrent
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: color,
                ),
                title: Row(
                  children: [
                    Text(
                      s,
                      style: GoogleFonts.poppins(
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: color,
                      ),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.qr_code_scanner,
                                size: 10, color: green),
                            const SizedBox(width: 3),
                            Text(
                              'REQUIRES QR',
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: isCompleted
                    ? Text(
                        "You will be asked to scan the student's pickup QR.",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      )
                    : null,
                onTap: () => Navigator.pop(ctx, s),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (picked == null || picked == currentStatus) return;

    // Intercept Completed → go straight to the scanner. No Firestore write
    // happens here; the write only fires after a valid scan + confirm.
    if (picked == 'Completed') {
      await _openScanner(expectedOrderId: orderId);
      return;
    }

    // Anything else updates immediately.
    await _updateStatus(orderId, currentStatus, picked);
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('orders').snapshots(),
          builder: (context, snapshot) {
            final allOrders = (snapshot.data?.docs ?? [])
                .map((d) => _AdminOrder.fromDoc(d))
                .toList();

            final orders = [...allOrders]..sort((a, b) {
                final aT =
                    a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                final bT =
                    b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                return bT.compareTo(aT);
              });

            final filtered = _selectedTab == 'All'
                ? orders
                : orders
                    .where((o) =>
                        o.status.toLowerCase() ==
                        _selectedTab.toLowerCase())
                    .toList();

            final filterCount = _selectedTab == 'All'
                ? orders.length
                : orders
                    .where((o) =>
                        o.status.toLowerCase() ==
                        _selectedTab.toLowerCase())
                    .length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row: title + Scan QR button ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Orders Management',
                            style: GoogleFonts.poppins(
                                fontSize: 24, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Monitor live orders and completed earnings.',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _openScanner(),
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: Text(
                        'Scan QR',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: adminPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── EARNINGS SUMMARY ──
                if (snapshot.hasData) _buildEarningsSummary(allOrders),
                const SizedBox(height: 16),

                // ── Status dropdown ──
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedTab,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Filter by status',
                          prefixIcon: const Icon(
                              Icons.filter_list_rounded,
                              size: 20),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: adminPurple, width: 1.6),
                          ),
                        ),
                        items: ['All', ..._statuses].map((tab) {
                          return DropdownMenuItem<String>(
                            value: tab,
                            child: Row(
                              children: [
                                if (tab != 'All')
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: _statusColor(tab),
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                else
                                  Icon(Icons.apps,
                                      size: 14, color: adminPurple),
                                const SizedBox(width: 8),
                                Text(tab),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedTab = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: adminPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$filterCount',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: adminPurple,
                          fontSize: 14,
                        ),
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
                    child: _buildOrdersList(
                      snapshot: snapshot,
                      filtered: filtered,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrdersList({
    required AsyncSnapshot<QuerySnapshot> snapshot,
    required List<_AdminOrder> filtered,
  }) {
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
        final cachedName = _nameFor(order.userId);
        final isCompleted = order.status.toLowerCase() == 'completed';
        final isReady = order.status.toLowerCase() == 'ready';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── LEADING: order number badge (fixed width) ──
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '#${order.orderNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // ── MIDDLE: name, badges, meta (takes remaining width) ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name + status badges on their own line if needed
                    Text(
                      cachedName ?? 'Loading…',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: cachedName == null
                            ? Colors.grey.shade500
                            : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isCompleted || isReady)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            if (isCompleted) _orderBadge('EARNED'),
                            if (isReady)
                              _orderBadge('QR READY', icon: Icons.qr_code_2),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.formattedDateTime}  •  ${order.itemsSummary}',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Payment: ${order.paymentMethod}',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // ── TRAILING: price + status chip (kept compact) ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₱${order.total.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isCompleted ? green : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (isUpdating)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline,
                              size: 13, color: Colors.grey.shade600),
                          const SizedBox(width: 3),
                          Text(
                            'Completed',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    InkWell(
                      onTap: () => _showStatusPicker(order.id, order.status),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              order.status,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(Icons.expand_more, size: 14, color: color),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
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

// ═══════════════════════════════════════════════════════════════
// QR SCANNER SCREEN
// ═══════════════════════════════════════════════════════════════
class _QrScannerScreen extends StatefulWidget {
  const _QrScannerScreen();

  @override
  State<_QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<_QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Scan Pickup QR',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_handled) return;
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final raw = barcodes.first.rawValue;
              if (raw == null || raw.isEmpty) return;
              _handled = true;
              Navigator.of(context).pop(raw);
            },
          ),

          // Viewfinder frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Corner accents for a scanner look
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 145,
            left: MediaQuery.of(context).size.width / 2 - 145,
            child: _corner(Alignment.topLeft),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 145,
            right: MediaQuery.of(context).size.width / 2 - 145,
            child: _corner(Alignment.topRight),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height / 2 - 145,
            left: MediaQuery.of(context).size.width / 2 - 145,
            child: _corner(Alignment.bottomLeft),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height / 2 - 145,
            right: MediaQuery.of(context).size.width / 2 - 145,
            child: _corner(Alignment.bottomRight),
          ),

          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Text(
              "Point the camera at the student's pickup QR",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner(Alignment alignment) {
    return SizedBox(
      width: 32,
      height: 32,
      child: CustomPaint(
        painter: _CornerPainter(alignment: alignment),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({required this.alignment});
  final Alignment alignment;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const path = 22.0;

    switch (alignment) {
      case Alignment.topLeft:
        canvas.drawLine(const Offset(0, 0), const Offset(path, 0), paint);
        canvas.drawLine(const Offset(0, 0), const Offset(0, path), paint);
        break;
      case Alignment.topRight:
        canvas.drawLine(Offset(size.width, 0),
            Offset(size.width - path, 0), paint);
        canvas.drawLine(Offset(size.width, 0), Offset(size.width, path),
            paint);
        break;
      case Alignment.bottomLeft:
        canvas.drawLine(Offset(0, size.height),
            Offset(path, size.height), paint);
        canvas.drawLine(Offset(0, size.height),
            Offset(0, size.height - path), paint);
        break;
      case Alignment.bottomRight:
        canvas.drawLine(Offset(size.width, size.height),
            Offset(size.width - path, size.height), paint);
        canvas.drawLine(Offset(size.width, size.height),
            Offset(size.width, size.height - path), paint);
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) => false;
}

// 3. ADMIN MENU MANAGEMENT PAGE
class AdminMenuManagementPage extends StatefulWidget {
  const AdminMenuManagementPage({super.key});

  @override
  State<AdminMenuManagementPage> createState() =>
      _AdminMenuManagementPageState();
}

class _AdminMenuManagementPageState extends State<AdminMenuManagementPage> {
  final Color adminPurple = const Color(0xFF5E35B1);
  final Color green = const Color(0xFF2E7D32);
  final Color amber = const Color(0xFFF9A825);
  final CollectionReference _menuCollection =
      FirebaseFirestore.instance.collection('menu_items');

  /// 'all' | 'specials'
  String _menuFilter = 'all';

  // ─────────────────────────────────────────────
  // ADD ITEM
  // ─────────────────────────────────────────────
  Future<void> _addItem(MenuItemModel item, XFile? imageFile) async {
    String? imageUrl;

    if (imageFile != null) {
      imageUrl = await CloudinaryService.uploadImage(
        imageFile,
        folder: 'menu_items',
      );
    }

    final resolvedRecipe =
        await InventoryService.ensureIngredientsExist(item.recipe);

    // ── Batch-cooked: deduct ingredients once, at creation ──
    if (item.isBatchCooked) {
      await InventoryService.applyRecipeStockDelta(
        oldRecipe: const [],
        newRecipe: resolvedRecipe,
      );
    }
    // ── Made-to-order: no deduction at creation ──
    //    Ingredients are consumed on each completed order.

    final finalItem = item.copyWith(
      imageUrl: imageUrl,
      recipe: resolvedRecipe,
      preparedPortions: item.isBatchCooked ? item.batchYield : 0,
    );

    await _menuCollection.add(finalItem.toMap());
  }

  // ─────────────────────────────────────────────
  // UPDATE ITEM
  // ─────────────────────────────────────────────
  Future<void> _updateItem(
    String id,
    MenuItemModel updatedItem,
    XFile? imageFile,
  ) async {
    final existingSnap = await _menuCollection.doc(id).get();
    if (!existingSnap.exists) {
      throw Exception('Menu item no longer exists.');
    }
    final existingItem = MenuItemModel.fromMap(
      id,
      existingSnap.data() as Map<String, dynamic>,
    );
    final oldRecipe = existingItem.recipe;

    String? imageUrl = updatedItem.imageUrl;
    if (imageFile != null) {
      imageUrl = await CloudinaryService.uploadImage(
        imageFile,
        folder: 'menu_items',
      );
    }

    final resolvedRecipe =
        await InventoryService.ensureIngredientsExist(updatedItem.recipe);

    final itemWithImage = updatedItem.copyWith(
      imageUrl: imageUrl,
      recipe: resolvedRecipe,
    );

    await _menuCollection.doc(id).update(itemWithImage.toMap());

    // Only reconcile ingredient stock for batch-cooked items — their
    // recipe is what's already been consumed. Made-to-order items have
    // no inventory attached to the recipe itself.
    if (existingItem.isBatchCooked && updatedItem.isBatchCooked) {
      debugPrint('=== MENU EDIT: RECIPE DELTA (batch-cooked) ===');
      debugPrint(
          'old: ${oldRecipe.map((r) => "${r.ingredientName}=${r.qtyPerPortion}${r.unit}").toList()}');
      debugPrint(
          'new: ${resolvedRecipe.map((r) => "${r.ingredientName}=${r.qtyPerPortion}${r.unit}").toList()}');

      await InventoryService.applyRecipeStockDelta(
        oldRecipe: oldRecipe,
        newRecipe: resolvedRecipe,
      );
    }
  }

  // ─────────────────────────────────────────────
  // DELETE ITEM
  // ─────────────────────────────────────────────
  Future<void> _deleteItem(String id, String? imageUrl) async {
    await _menuCollection.doc(id).delete();
  }

  // ─────────────────────────────────────────────
  // TOGGLE SPECIAL
  // ─────────────────────────────────────────────
  Future<void> _toggleSpecial(MenuItemModel item) async {
    await _menuCollection.doc(item.id).update({
      'isSpecial': !item.isSpecial,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(item.isSpecial
            ? '"${item.name}" removed from specials'
            : '"${item.name}" marked as special'),
        backgroundColor: item.isSpecial ? Colors.grey.shade700 : amber,
      ));
    }
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
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
                Expanded(
                  child: Text(
                    'Menu Management',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showAddItemDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: adminPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Tap to edit • Swipe left to delete',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 12),

            // ── FILTER CHIPS ──
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'all',
                  label: Text('All Items'),
                  icon: Icon(Icons.list, size: 16),
                ),
                ButtonSegment(
                  value: 'specials',
                  label: Text("Today's Specials"),
                  icon: Icon(Icons.star_rounded, size: 16),
                ),
              ],
              selected: {_menuFilter},
              onSelectionChanged: (s) =>
                  setState(() => _menuFilter = s.first),
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
                  stream: _menuCollection.orderBy('name').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error: ${snapshot.error}'));
                    }
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF5E35B1)));
                    }
                    if (snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    // Apply filter
                    final allDocs = snapshot.data!.docs;
                    final docs = _menuFilter == 'specials'
                        ? allDocs.where((d) {
                            final data =
                                d.data() as Map<String, dynamic>;
                            return data['isSpecial'] == true;
                          }).toList()
                        : allDocs;

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star_border_rounded,
                                size: 64,
                                color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _menuFilter == 'specials'
                                  ? "No specials yet. Mark an item as special to feature it."
                                  : 'No items yet.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (context, i) =>
                          Divider(color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final item = MenuItemModel.fromMap(
                            doc.id, doc.data() as Map<String, dynamic>);

                        return Dismissible(
                          key: Key(doc.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16)),
                                  title: Text('Delete Item?',
                                      style: GoogleFonts.poppins(
                                          fontWeight:
                                              FontWeight.bold)),
                                  content: Text(
                                      'Are you sure you want to delete "${item.name}"? This action cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(
                                              context)
                                          .pop(false),
                                      child: const Text('Cancel',
                                          style: TextStyle(
                                              color: Colors.grey)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(
                                              context)
                                          .pop(true),
                                      style: TextButton.styleFrom(
                                          foregroundColor: Colors.red),
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
                              SnackBar(
                                  content:
                                      Text('Deleted "${item.name}"'),
                                  backgroundColor:
                                      Colors.red.shade400),
                            );
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20),
                            margin: const EdgeInsets.symmetric(
                                vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.delete,
                                color: Colors.white),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                              onTap: () =>
                                  _showEditItemDialog(context, item),
                              leading: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  color: Colors.grey.shade100,
                                  image: item.imageUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(
                                              item.imageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: item.imageUrl == null
                                    ? Icon(
                                        item.category == 'Drinks'
                                            ? Icons.local_cafe
                                            : item.category ==
                                                    'Snacks'
                                                ? Icons.fastfood
                                                : Icons.lunch_dining,
                                        color: adminPurple,
                                        size: 28,
                                      )
                                    : null,
                              ),
                              title: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.name,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (item.isSpecial) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets
                                          .symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        border: Border.all(
                                            color: Colors
                                                .amber.shade300),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star_rounded,
                                              size: 10,
                                              color: Colors
                                                  .amber.shade900),
                                          const SizedBox(width: 2),
                                          Text(
                                            'SPECIAL',
                                            style:
                                                GoogleFonts.poppins(
                                              fontSize: 8,
                                              fontWeight:
                                                  FontWeight.bold,
                                              color: Colors
                                                  .amber.shade900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (item.isBatchCooked) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets
                                          .symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        border: Border.all(
                                            color: Colors
                                                .green.shade200),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.soup_kitchen,
                                              size: 10,
                                              color: Colors
                                                  .green.shade800),
                                          const SizedBox(width: 2),
                                          Text(
                                            'BATCH',
                                            style:
                                                GoogleFonts.poppins(
                                              fontSize: 8,
                                              fontWeight:
                                                  FontWeight.bold,
                                              color: Colors
                                                  .green.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.isBatchCooked
                                        ? '${item.category} • ${item.preparedPortions} portion(s) ready'
                                        : '${item.category} • Stock: ${item.stock}'
                                            '${item.recipe.isNotEmpty ? " • ${item.recipe.length} ingredient(s)" : ""}',
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
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
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 8,
                                            vertical: 3),
                                        decoration: BoxDecoration(
                                          color: item.isAvailable
                                              ? Colors.green.shade50
                                              : Colors.red.shade50,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.isAvailable
                                              ? 'Available'
                                              : 'Unavailable',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight:
                                                FontWeight.w600,
                                            color: item.isAvailable
                                                ? Colors
                                                    .green.shade700
                                                : Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(
                                      item.isSpecial
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: item.isSpecial
                                          ? amber
                                          : Colors.grey.shade400,
                                      size: 22,
                                    ),
                                    tooltip: item.isSpecial
                                        ? 'Remove from specials'
                                        : "Mark as today's special",
                                    onPressed: () =>
                                        _toggleSpecial(item),
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

  // ─────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────
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
            child:
                Icon(Icons.restaurant_menu, size: 64, color: adminPurple),
          ),
          const SizedBox(height: 20),
          Text(
            'No Menu Items Yet',
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Click "Add New Item" to create your first menu item.',
            style: GoogleFonts.poppins(
                fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // INGREDIENT PICKER
  // (Now shows both ingredients AND supplies.)
  // ─────────────────────────────────────────────
  Future<Map<String, dynamic>?> _pickIngredient(
      BuildContext context) async {
    final snap = await FirebaseFirestore.instance
        .collection('inventory')
        .orderBy('name')
        .get();
    final items = snap.docs
        .map((d) => InventoryItemModel.fromMap(d.id, d.data()))
        .toList();

    if (!context.mounted) return null;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        String q = '';
        String rawName = '';
        String unit = 'pcs';
        final qtyCtrl = TextEditingController(text: '1');
        InventoryItemModel? selected;
        bool creating = false;

        return StatefulBuilder(
          builder: (ctx, setD) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text('Add Ingredient',
                style:
                    GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search or type new name...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) {
                      setD(() {
                        rawName = v.trim();
                        q = rawName.toLowerCase();
                        selected = null;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  if (items.isNotEmpty)
                    ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxHeight: 200),
                      child: ListView(
                        shrinkWrap: true,
                        children: items
                            .where((i) =>
                                i.name.toLowerCase().contains(q))
                            .map((i) => ListTile(
                                  dense: true,
                                  title: Text(i.name),
                                  subtitle: Text(
                                      '${i.stock} ${i.unit} • ${i.isIngredient ? "ingredient" : "supply"}'),
                                  selected: selected?.id == i.id,
                                  trailing: selected?.id == i.id
                                      ? const Icon(Icons.check,
                                          color: Color(0xFF5E35B1))
                                      : null,
                                  onTap: () => setD(() {
                                    selected = i;
                                    unit = i.unit;
                                  }),
                                ))
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (selected == null && rawName.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text(
                        'New ingredient "$rawName" will be created in inventory with 0 stock.',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.amber.shade900),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Qty per portion'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 110,
                        child: UnitPickerField(
                          value: unit,
                          onChanged: (v) => setD(() => unit = v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    creating ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: creating
                    ? null
                    : () async {
                        final qty =
                            double.tryParse(qtyCtrl.text) ?? 1;
                        if (qty <= 0) return;

                        if (selected != null) {
                          Navigator.pop(ctx, {
                            'ingredientId': selected!.id,
                            'ingredientName': selected!.name,
                            'unit': selected!.unit,
                            'qtyPerPortion': qty,
                          });
                          return;
                        }

                        if (rawName.isEmpty) return;

                        setD(() => creating = true);
                        try {
                          final newDoc = await FirebaseFirestore
                              .instance
                              .collection('inventory')
                              .add({
                            'name': rawName,
                            'unit': unit,
                            'stock': 0,
                            'minLevel': 5,
                            'type': 'ingredient',
                            'updatedAt':
                                FieldValue.serverTimestamp(),
                          });

                          if (ctx.mounted) {
                            Navigator.pop(ctx, {
                              'ingredientId': newDoc.id,
                              'ingredientName': rawName,
                              'unit': unit,
                              'qtyPerPortion': qty,
                            });
                          }
                        } catch (e) {
                          setD(() => creating = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text(
                                  'Failed to create ingredient: $e'),
                              backgroundColor: Colors.red,
                            ));
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: adminPurple,
                  foregroundColor: Colors.white,
                ),
                child: creating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // SHARED RECIPE EDITOR UI
  // ─────────────────────────────────────────────
  Widget _buildRecipeSection({
    required BuildContext ctx,
    required List<Map<String, dynamic>> rows,
    required void Function(VoidCallback) setModalState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recipe (per portion)',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            TextButton.icon(
              onPressed: () async {
                final picked = await _pickIngredient(ctx);
                if (picked != null) {
                  setModalState(() => rows.add(picked));
                }
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
            ),
          ],
        ),
        if (rows.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'No ingredients yet. Tap "Add" to link to inventory.',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey.shade600),
            ),
          )
        else
          Column(
            children: rows.asMap().entries.map((e) {
              final i = e.key;
              final r = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['ingredientName'],
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          Text(
                            '${r['qtyPerPortion']} ${r['unit']} per portion',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit,
                          size: 18, color: Color(0xFF5E35B1)),
                      tooltip: 'Edit qty / unit',
                      onPressed: () async {
                        final qtyCtrl = TextEditingController(
                            text: (r['qtyPerPortion'] as num)
                                .toString());
                        String localUnit = r['unit'];

                        final ok = await showDialog<bool>(
                          context: ctx,
                          builder: (dCtx) => StatefulBuilder(
                            builder: (dCtx, setD) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(16)),
                              title: Text(
                                  'Edit ${r['ingredientName']}',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold)),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: qtyCtrl,
                                    keyboardType:
                                        TextInputType.number,
                                    decoration: const InputDecoration(
                                        labelText: 'Qty per portion'),
                                  ),
                                  const SizedBox(height: 8),
                                  UnitPickerField(
                                    value: localUnit,
                                    onChanged: (v) =>
                                        setD(() => localUnit = v),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dCtx, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(dCtx, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF5E35B1),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          ),
                        );

                        if (ok == true) {
                          final newQty =
                              double.tryParse(qtyCtrl.text) ?? 0;
                          if (newQty > 0) {
                            setModalState(() {
                              r['qtyPerPortion'] = newQty;
                              r['unit'] = localUnit;
                            });
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 18, color: Colors.red),
                      tooltip: 'Remove from recipe',
                      onPressed: () =>
                          setModalState(() => rows.removeAt(i)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // ADD ITEM DIALOG
  // ─────────────────────────────────────────────
  void _showAddItemDialog(BuildContext outerCtx) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final descController = TextEditingController();
    final batchYieldController = TextEditingController(text: '10');
    String selectedCategory = 'Meals';
    bool isAvailable = true;
    bool isSpecial = false;
    MenuItemKind selectedKind = MenuItemKind.madeToOrder;
    XFile? selectedImage;
    bool isUploading = false;
    List<Map<String, dynamic>> recipeRows = [];

    showModalBottomSheet(
      context: outerCtx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
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
                              borderRadius:
                                  BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Add New Menu Item',
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          color: Colors.grey.shade600),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildImagePicker(
                    context: context,
                    selectedImage: selectedImage,
                    existingImageUrl: null,
                    hintLine1: kIsWeb
                        ? 'Click to select image'
                        : 'Tap to upload image',
                    hintLine2: 'Supports PNG, JPG, GIF, WEBP',
                    onPick: (img) =>
                        setModalState(() => selectedImage = img),
                    onClear: () =>
                        setModalState(() => selectedImage = null),
                  ),
                  const SizedBox(height: 16),

                  Text('Food Name',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                          hintText: 'e.g. Chicken Meal',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12))),
                  const SizedBox(height: 16),

                  Text('Category',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12)),
                    items: [
                      'Meals',
                      'Snacks',
                      'Drinks',
                      'Desserts',
                      'Pastas'
                    ]
                        .map((cat) => DropdownMenuItem(
                            value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── ITEM TYPE ──
                  Text('Item type',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  SegmentedButton<MenuItemKind>(
                    segments: const [
                      ButtonSegment(
                        value: MenuItemKind.madeToOrder,
                        label: Text('Made to order'),
                        icon: Icon(Icons.restaurant, size: 16),
                      ),
                      ButtonSegment(
                        value: MenuItemKind.batchCooked,
                        label: Text('Batch cooked'),
                        icon: Icon(Icons.soup_kitchen, size: 16),
                      ),
                    ],
                    selected: {selectedKind},
                    onSelectionChanged: (s) =>
                        setModalState(() => selectedKind = s.first),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedKind == MenuItemKind.madeToOrder
                        ? 'Ingredients are deducted from inventory on every completed order.'
                        : 'Ingredients are deducted once when you save. Portions are then drawn down as orders complete.',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade600),
                  ),

                  // Batch yield — only for batch-cooked
                  if (selectedKind == MenuItemKind.batchCooked) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: batchYieldController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Portions per batch',
                        hintText: 'e.g. 10',
                        prefixIcon: const Icon(Icons.group, size: 20),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  Text('Price (₱)',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          hintText: 'e.g. 75',
                          prefixText: '₱ ',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12))),
                  const SizedBox(height: 16),

                  Text(
                      selectedKind == MenuItemKind.batchCooked
                          ? 'Portions ready to sell'
                          : 'Stock Quantity',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          hintText: 'e.g. 20',
                          prefixIcon: const Icon(
                              Icons.inventory_2_outlined,
                              size: 20),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12))),
                  const SizedBox(height: 16),

                  Text('Description',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                          hintText: 'Enter food details...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.all(12))),
                  const SizedBox(height: 16),

                  _buildRecipeSection(
                    ctx: context,
                    rows: recipeRows,
                    setModalState: setModalState,
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Available for ordering today',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500)),
                    value: isAvailable,
                    activeThumbColor: green,
                    onChanged: (val) =>
                        setModalState(() => isAvailable = val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text("Mark as Today's Special",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      'Shows up in the student home screen',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600),
                    ),
                    value: isSpecial,
                    activeThumbColor: amber,
                    onChanged: (val) =>
                        setModalState(() => isSpecial = val),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isUploading
                              ? null
                              : () async {
                                  if (nameController.text.isEmpty ||
                                      priceController.text.isEmpty) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Name and price are required.'),
                                      backgroundColor: Colors.red,
                                    ));
                                    return;
                                  }
                                  setModalState(
                                      () => isUploading = true);
                                  try {
                                    final recipe = recipeRows
                                        .map((r) => RecipeIngredient(
                                              ingredientId: r[
                                                      'ingredientId'] ??
                                                  '',
                                              ingredientName:
                                                  r['ingredientName'],
                                              unit: r['unit'],
                                              qtyPerPortion:
                                                  (r['qtyPerPortion']
                                                          as num)
                                                      .toDouble(),
                                            ))
                                        .toList();

                                    final newItem = MenuItemModel(
                                      id: '',
                                      name: nameController.text,
                                      category: selectedCategory,
                                      price: double.tryParse(
                                              priceController.text) ??
                                          0,
                                      description: descController.text,
                                      stock: int.tryParse(
                                              stockController.text) ??
                                          0,
                                      isAvailable: isAvailable,
                                      isSpecial: isSpecial,
                                      recipe: recipe,
                                      kind: selectedKind,
                                      batchYield: selectedKind ==
                                              MenuItemKind.batchCooked
                                          ? (int.tryParse(
                                                  batchYieldController
                                                      .text) ??
                                              1)
                                          : 1,
                                    );
                                    await _addItem(
                                        newItem, selectedImage);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            'Added "${newItem.name}" successfully!'),
                                        backgroundColor: green,
                                      ));
                                    }
                                  } catch (e) {
                                    setModalState(
                                        () => isUploading = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            'Error adding item: $e'),
                                        backgroundColor: Colors.red,
                                      ));
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: adminPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
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
                          onPressed: isUploading
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
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

  // ─────────────────────────────────────────────
  // EDIT ITEM DIALOG
  // ─────────────────────────────────────────────
  void _showEditItemDialog(BuildContext outerCtx, MenuItemModel item) {
    final nameController = TextEditingController(text: item.name);
    final priceController =
        TextEditingController(text: item.price.toString());
    final stockController =
        TextEditingController(text: item.stock.toString());
    final descController =
        TextEditingController(text: item.description);
    final batchYieldController =
        TextEditingController(text: item.batchYield.toString());
    String selectedCategory = item.category;
    bool isAvailable = item.isAvailable;
    bool isSpecial = item.isSpecial;
    MenuItemKind selectedKind = item.kind;
    XFile? selectedImage;
    bool isUploading = false;
    String? existingImageUrl = item.imageUrl;

    List<Map<String, dynamic>> recipeRows = item.recipe
        .map((r) => {
              'ingredientId': r.ingredientId,
              'ingredientName': r.ingredientName,
              'unit': r.unit,
              'qtyPerPortion': r.qtyPerPortion,
            })
        .toList();

    showModalBottomSheet(
      context: outerCtx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
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
                              borderRadius:
                                  BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('Edit ${item.name}',
                            style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis),
                      ),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          color: Colors.grey.shade600),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildImagePicker(
                    context: context,
                    selectedImage: selectedImage,
                    existingImageUrl: existingImageUrl,
                    hintLine1: kIsWeb
                        ? 'Click to select image'
                        : 'Tap to upload image',
                    hintLine2: 'Recommended: 800x800px',
                    onPick: (img) =>
                        setModalState(() => selectedImage = img),
                    onClear: () {
                      setModalState(() => selectedImage = null);
                    },
                    onClearExisting: () {
                      setModalState(() => existingImageUrl = null);
                    },
                  ),
                  const SizedBox(height: 16),

                  Text('Food Name',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                          hintText: 'e.g. Chicken Meal',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12))),
                  const SizedBox(height: 16),

                  Text('Category',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12)),
                    items: [
                      'Meals',
                      'Snacks',
                      'Drinks',
                      'Desserts',
                      'Pastas'
                    ]
                        .map((cat) => DropdownMenuItem(
                            value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── ITEM TYPE ──
                  Text('Item type',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  SegmentedButton<MenuItemKind>(
                    segments: const [
                      ButtonSegment(
                        value: MenuItemKind.madeToOrder,
                        label: Text('Made to order'),
                        icon: Icon(Icons.restaurant, size: 16),
                      ),
                      ButtonSegment(
                        value: MenuItemKind.batchCooked,
                        label: Text('Batch cooked'),
                        icon: Icon(Icons.soup_kitchen, size: 16),
                      ),
                    ],
                    selected: {selectedKind},
                    onSelectionChanged: (s) =>
                        setModalState(() => selectedKind = s.first),
                  ),

                  // Batch yield — only for batch-cooked
                  if (selectedKind == MenuItemKind.batchCooked) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: batchYieldController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Portions per batch',
                        hintText: 'e.g. 10',
                        prefixIcon: const Icon(Icons.group, size: 20),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── COOK BATCH ──
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.soup_kitchen,
                              size: 20,
                              color: Colors.green.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ready portions: ${item.preparedPortions}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                                Text(
                                  'Cook another batch to deduct ingredients '
                                  'and add ${item.batchYield} portions.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.play_arrow,
                                size: 16),
                            label: const Text('Cook batch'),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text(
                                      'Cook a new batch?'),
                                  content: Text(
                                    'This will deduct the recipe ingredients '
                                    'once and add ${item.batchYield} ready portions.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(c, false),
                                      child:
                                          const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(c, true),
                                      child: const Text('Cook'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await InventoryService
                                    .applyRecipeStockDelta(
                                  oldRecipe: const [],
                                  newRecipe: item.recipe,
                                );
                                await _menuCollection
                                    .doc(item.id)
                                    .update({
                                  'preparedPortions':
                                      FieldValue.increment(
                                          item.batchYield),
                                  'isAvailable': true,
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        'Cooked ${item.batchYield} portions of "${item.name}"'),
                                    backgroundColor:
                                        Colors.green.shade700,
                                  ));
                                  Navigator.pop(context);
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  Text('Price (₱)',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          hintText: 'e.g. 75',
                          prefixText: '₱ ',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12))),
                  const SizedBox(height: 16),

                  Text('Stock Quantity',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          hintText: 'e.g. 20',
                          prefixIcon: const Icon(
                              Icons.inventory_2_outlined,
                              size: 20),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12))),
                  const SizedBox(height: 16),

                  Text('Description',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                          hintText: 'Enter food details...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.all(12))),
                  const SizedBox(height: 16),

                  _buildRecipeSection(
                    ctx: context,
                    rows: recipeRows,
                    setModalState: setModalState,
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Available for ordering today',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500)),
                    value: isAvailable,
                    activeThumbColor: green,
                    onChanged: (val) =>
                        setModalState(() => isAvailable = val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text("Mark as Today's Special",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      'Shows up in the student home screen',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600),
                    ),
                    value: isSpecial,
                    activeThumbColor: amber,
                    onChanged: (val) =>
                        setModalState(() => isSpecial = val),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isUploading
                              ? null
                              : () async {
                                  setModalState(
                                      () => isUploading = true);
                                  try {
                                    final recipe = recipeRows
                                        .map((r) => RecipeIngredient(
                                              ingredientId: r[
                                                      'ingredientId'] ??
                                                  '',
                                              ingredientName:
                                                  r['ingredientName'],
                                              unit: r['unit'],
                                              qtyPerPortion:
                                                  (r['qtyPerPortion']
                                                          as num)
                                                      .toDouble(),
                                            ))
                                        .toList();

                                    final updatedItem =
                                        item.copyWith(
                                      name: nameController.text,
                                      category: selectedCategory,
                                      price: double.tryParse(
                                              priceController.text) ??
                                          item.price,
                                      description:
                                          descController.text,
                                      stock: int.tryParse(
                                              stockController.text) ??
                                          item.stock,
                                      isAvailable: isAvailable,
                                      isSpecial: isSpecial,
                                      imageUrl: existingImageUrl,
                                      recipe: recipe,
                                      kind: selectedKind,
                                      batchYield: selectedKind ==
                                              MenuItemKind.batchCooked
                                          ? (int.tryParse(
                                                  batchYieldController
                                                      .text) ??
                                              item.batchYield)
                                          : item.batchYield,
                                    );

                                    await _updateItem(item.id,
                                        updatedItem, selectedImage);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            'Updated "${updatedItem.name}" successfully!'),
                                        backgroundColor: green,
                                      ));
                                    }
                                  } catch (e) {
                                    setModalState(
                                        () => isUploading = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            'Error updating item: $e'),
                                        backgroundColor: Colors.red,
                                      ));
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
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
                          onPressed: isUploading
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
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

  // ─────────────────────────────────────────────
  // SHARED IMAGE PICKER
  // ─────────────────────────────────────────────
  Widget _buildImagePicker({
    required BuildContext context,
    required XFile? selectedImage,
    required String? existingImageUrl,
    required String hintLine1,
    required String hintLine2,
    required void Function(XFile) onPick,
    required VoidCallback onClear,
    VoidCallback? onClearExisting,
  }) {
    return Container(
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
                    future: selectedImage.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData &&
                          snapshot.data != null) {
                        return Image.memory(
                          snapshot.data!,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        );
                      } else if (snapshot.hasError) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image,
                              size: 50, color: Colors.grey),
                        );
                      } else {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor:
                        Colors.black.withValues(alpha: 0.7),
                    radius: 18,
                    child: IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                      onPressed: onClear,
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
                        existingImageUrl,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image,
                                size: 50, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor:
                            Colors.black.withValues(alpha: 0.7),
                        radius: 18,
                        child: IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                          onPressed: onClearExisting ?? () {},
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                )
              : InkWell(
                  onTap: () async {
                    final XFile? image =
                        await ImagePickerHelper.pickImage();
                    if (image != null) onPick(image);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        kIsWeb
                            ? Icons.cloud_upload
                            : Icons.photo_library,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hintLine1,
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        hintLine2,
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// 4. ADMIN INVENTORY PAGE
class AdminInventoryPage extends StatefulWidget {
  const AdminInventoryPage({super.key});

  @override
  State<AdminInventoryPage> createState() => _AdminInventoryPageState();
}

class _AdminInventoryPageState extends State<AdminInventoryPage> {
  final Color adminPurple = const Color(0xFF5E35B1);
  final Color green = const Color(0xFF2E7D32);
  final CollectionReference _inv =
      FirebaseFirestore.instance.collection('inventory');

  /// 'all' | 'ingredient' | 'supply'
  String _typeFilter = 'all';

  // ─────────────────────────────────────────────
  // SMALL STOCK +/- BUTTON
  // ─────────────────────────────────────────────
  Widget _stockButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 20,
          color: onTap == null ? Colors.grey.shade400 : Colors.grey.shade800,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ADD ITEM DIALOG (ingredient OR supply)
  // ─────────────────────────────────────────────
  void _showAddIngredientDialog(
      {InventoryType initialType = InventoryType.ingredient}) {
    final nameCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '0');
    final minCtrl = TextEditingController(text: '5');
    String unit = 'pcs';
    InventoryType type = initialType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(
            type == InventoryType.ingredient ? 'Add Ingredient' : 'Add Supply',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type toggle
                SegmentedButton<InventoryType>(
                  segments: const [
                    ButtonSegment(
                      value: InventoryType.ingredient,
                      label: Text('Ingredient'),
                      icon: Icon(Icons.restaurant, size: 16),
                    ),
                    ButtonSegment(
                      value: InventoryType.supply,
                      label: Text('Supply'),
                      icon: Icon(Icons.inventory_2, size: 16),
                    ),
                  ],
                  selected: {type},
                  onSelectionChanged: (s) => setD(() => type = s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: type == InventoryType.ingredient
                        ? 'Ingredient name'
                        : 'Supply name (e.g. Plastic Cup)',
                  ),
                ),
                const SizedBox(height: 8),
                UnitPickerField(
                  value: unit,
                  onChanged: (v) => setD(() => unit = v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Initial stock'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: minCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Min alert level'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await _inv.add(InventoryItemModel(
                  id: '',
                  name: nameCtrl.text.trim(),
                  unit: unit,
                  stock: double.tryParse(stockCtrl.text) ?? 0,
                  minLevel: double.tryParse(minCtrl.text) ?? 0,
                  type: type,
                  updatedAt: DateTime.now(),
                ).toMap());
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: adminPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EDIT ITEM DIALOG
  // ─────────────────────────────────────────────
  void _showEditIngredientDialog(InventoryItemModel item) {
    final nameCtrl = TextEditingController(text: item.name);
    final stockCtrl = TextEditingController(text: item.stock.toString());
    final minCtrl = TextEditingController(text: item.minLevel.toString());
    String unit = item.unit;
    InventoryType type = item.type;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('Edit ${item.name}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<InventoryType>(
                  segments: const [
                    ButtonSegment(
                      value: InventoryType.ingredient,
                      label: Text('Ingredient'),
                      icon: Icon(Icons.restaurant, size: 16),
                    ),
                    ButtonSegment(
                      value: InventoryType.supply,
                      label: Text('Supply'),
                      icon: Icon(Icons.inventory_2, size: 16),
                    ),
                  ],
                  selected: {type},
                  onSelectionChanged: (s) => setD(() => type = s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 8),
                UnitPickerField(
                  value: unit,
                  onChanged: (v) => setD(() => unit = v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: minCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Min level'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _inv.doc(item.id).update({
                  'name': nameCtrl.text.trim(),
                  'unit': unit,
                  'stock': double.tryParse(stockCtrl.text) ?? item.stock,
                  'minLevel': double.tryParse(minCtrl.text) ?? item.minLevel,
                  'type': type.name,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: adminPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER ──
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 420;

                final title = Text(
                  'Inventory Stocks',
                  style: GoogleFonts.poppins(
                      fontSize: 24, fontWeight: FontWeight.w700),
                );

                final addButton = ElevatedButton.icon(
                  onPressed: () => _showAddIngredientDialog(
                    initialType: _typeFilter == 'supply'
                        ? InventoryType.supply
                        : InventoryType.ingredient,
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                      _typeFilter == 'supply' ? 'Add Supply' : 'Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: adminPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: 12),
                      SizedBox(width: double.infinity, child: addButton),
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 12),
                    addButton,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: _typeFilter,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Filter by type',
                prefixIcon: const Icon(Icons.filter_list_rounded, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: adminPurple, width: 1.6),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'all',
                  child: Row(
                    children: [
                      Icon(Icons.list, size: 18, color: Color(0xFF5E35B1)),
                      SizedBox(width: 8),
                      Text('All'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'ingredient',
                  child: Row(
                    children: [
                      Icon(Icons.restaurant, size: 18, color: Color(0xFF5E35B1)),
                      SizedBox(width: 8),
                      Text('Ingredients'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'supply',
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2, size: 18, color: Color(0xFF5E35B1)),
                      SizedBox(width: 8),
                      Text('Supplies'),
                    ],
                  ),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _typeFilter = v);
              },
            ),
            const SizedBox(height: 16),

            // ── LIST (wrapped in Material so InkWell ripples work) ──
            Expanded(
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _inv.orderBy('name').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                            child: Text('Error: ${snapshot.error}'));
                      }

                      // Parse + filter
                      var items = (snapshot.data?.docs ?? [])
                          .map((d) => InventoryItemModel.fromMap(
                              d.id, d.data() as Map<String, dynamic>))
                          .toList();

                      if (_typeFilter == 'ingredient') {
                        items =
                            items.where((i) => i.isIngredient).toList();
                      } else if (_typeFilter == 'supply') {
                        items = items.where((i) => i.isSupply).toList();
                      }

                      if (items.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _typeFilter == 'supply'
                                    ? Icons.inventory_2_outlined
                                    : Icons.restaurant_menu,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _typeFilter == 'all'
                                    ? 'No items yet'
                                    : _typeFilter == 'supply'
                                        ? 'No supplies yet'
                                        : 'No ingredients yet',
                                style: GoogleFonts.poppins(
                                    color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: Colors.grey.shade100),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isLow = item.isLow;
                          final isOut = item.isOut;
                          final isIngredient = item.isIngredient;

                          return InkWell(
                            onTap: () =>
                                _showEditIngredientDialog(item),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // leading icon
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isIngredient
                                          ? adminPurple
                                              .withValues(alpha: 0.1)
                                          : Colors.blue.shade50,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isIngredient
                                          ? Icons.restaurant
                                          : Icons.inventory_2,
                                      color: isIngredient
                                          ? adminPurple
                                          : Colors.blue.shade700,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // middle: name + badge + min
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.name,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style:
                                                    GoogleFonts.poppins(
                                                        fontWeight:
                                                            FontWeight
                                                                .w600),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isIngredient
                                                    ? adminPurple
                                                        .withValues(
                                                            alpha: 0.1)
                                                    : Colors.blue.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        4),
                                              ),
                                              child: Text(
                                                isIngredient
                                                    ? 'ING'
                                                    : 'SUP',
                                                style:
                                                    GoogleFonts.poppins(
                                                  fontSize: 9,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  color: isIngredient
                                                      ? adminPurple
                                                      : Colors
                                                          .blue.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Min: ${item.minLevel} ${item.unit}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // trailing: badge + stock controls
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isOut
                                              ? Colors.red.shade50
                                              : isLow
                                                  ? Colors.orange.shade50
                                                  : Colors.green.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isOut
                                              ? 'OUT'
                                              : isLow
                                                  ? 'LOW'
                                                  : 'OK',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isOut
                                                ? Colors.red.shade700
                                                : isLow
                                                    ? Colors.orange
                                                        .shade800
                                                    : Colors
                                                        .green.shade700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _stockButton(
                                            icon: Icons
                                                .remove_circle_outline,
                                            onTap: item.stock <= 0
                                                ? null
                                                : () => InventoryService
                                                    .adjustStock(
                                                        item.id, -1),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets
                                                .symmetric(horizontal: 4),
                                            child: Text(
                                              '${item.stock} ${item.unit}',
                                              style:
                                                  GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.w700,
                                                color: isOut
                                                    ? Colors
                                                        .red.shade700
                                                    : isLow
                                                        ? Colors.orange
                                                            .shade800
                                                        : Colors
                                                            .black87,
                                              ),
                                            ),
                                          ),
                                          _stockButton(
                                            icon: Icons
                                                .add_circle_outline,
                                            onTap: () =>
                                                InventoryService
                                                    .adjustStock(
                                                        item.id, 1),
                                          ),
                                        ],
                                      ),
                                    ],
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 5. ADMIN LOYALTY REWARDS PAGE — dynamic CRUD
class AdminLoyaltyRewardsPage extends StatefulWidget {
  const AdminLoyaltyRewardsPage({super.key});

  @override
  State<AdminLoyaltyRewardsPage> createState() =>
      _AdminLoyaltyRewardsPageState();
}

class _AdminLoyaltyRewardsPageState extends State<AdminLoyaltyRewardsPage> {
  final Color adminPurple = const Color(0xFF5E35B1);
  final Color green = const Color(0xFF2E7D32);
  final CollectionReference _rewardsRef =
      FirebaseFirestore.instance.collection('loyalty_rewards');

  // ─────────────────────────────────────────────
  // ADD / EDIT DIALOG
  // ─────────────────────────────────────────────
  void _showRewardDialog({LoyaltyReward? existing}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final pointsCtrl = TextEditingController(
        text: existing?.points.toString() ?? '20');
    bool isActive = existing?.isActive ?? true;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
          title: Text(
            isEdit ? 'Edit Reward' : 'Add Reward',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Reward name',
                    hintText: 'e.g. Free Rice',
                    prefixIcon: const Icon(Icons.card_giftcard),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pointsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Points required',
                    hintText: 'e.g. 20',
                    prefixIcon: const Icon(Icons.stars),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Available to students',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500),
                  ),
                  value: isActive,
                  activeThumbColor: adminPurple,
                  onChanged: (v) => setD(() => isActive = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final points =
                          int.tryParse(pointsCtrl.text.trim()) ?? 0;
                      if (name.isEmpty || points <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Enter a valid name and points value.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setD(() => saving = true);
                      try {
                        if (isEdit) {
                          await _rewardsRef.doc(existing.id).update({
                            'name': name,
                            'points': points,
                            'isActive': isActive,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                        } else {
                          await _rewardsRef.add({
                            'name': name,
                            'points': points,
                            'isActive': isActive,
                            'updatedAt': FieldValue.serverTimestamp(),
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                        }

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                            content: Text(isEdit
                                ? 'Updated "$name"'
                                : 'Added "$name"'),
                            backgroundColor: green,
                          ));
                        }
                      } catch (e) {
                        setD(() => saving = false);
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
                backgroundColor: adminPurple,
                foregroundColor: Colors.white,
              ),
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // DELETE WITH CONFIRMATION
  // ─────────────────────────────────────────────
  Future<void> _deleteReward(LoyaltyReward r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Reward?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to delete "${r.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _rewardsRef.doc(r.id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Deleted "${r.name}"'),
          backgroundColor: Colors.red.shade400,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRewardDialog(),
        backgroundColor: adminPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Add Reward',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loyalty Reward Offerings',
                style: GoogleFonts.poppins(
                    fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Add, edit, or remove rewards that students can redeem with points.',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _rewardsRef.orderBy('points').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error: ${snapshot.error}'));
                    }

                    final rewards = (snapshot.data?.docs ?? [])
                        .map((d) => LoyaltyReward.fromMap(
                            d.id, d.data() as Map<String, dynamic>))
                        .toList();

                    if (rewards.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.card_giftcard,
                                size: 64,
                                color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('No rewards yet',
                                style: GoogleFonts.poppins(
                                    color: Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            Text('Tap "Add Reward" to create one.',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade500)),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: rewards.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final r = rewards[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          onTap: () => _showRewardDialog(existing: r),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: adminPurple
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.card_giftcard,
                              color: adminPurple,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(r.name,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Container(
                                margin:
                                    const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: r.isActive
                                      ? Colors.green.shade50
                                      : Colors.grey.shade200,
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: Text(
                                  r.isActive ? 'ACTIVE' : 'HIDDEN',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: r.isActive
                                        ? Colors.green.shade700
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${r.points} Points',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600),
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                            onSelected: (v) {
                              if (v == 'edit') {
                                _showRewardDialog(existing: r);
                              } else if (v == 'toggle') {
                                _rewardsRef.doc(r.id).update({
                                  'isActive': !r.isActive,
                                  'updatedAt':
                                      FieldValue.serverTimestamp(),
                                });
                              } else if (v == 'delete') {
                                _deleteReward(r);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Row(
                                  children: [
                                    Icon(
                                      r.isActive
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(r.isActive
                                        ? 'Hide from students'
                                        : 'Show to students'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete,
                                        size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete',
                                        style:
                                            TextStyle(color: Colors.red)),
                                  ],
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

class EarningsLineChart extends StatelessWidget {
  const EarningsLineChart({
    super.key,
    required this.values,
    required this.labels,
    required this.lineColor,
  });

  final List<double> values;
  final List<String> labels;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _EarningsChartPainter(
        values: values,
        labels: labels,
        lineColor: lineColor,
        gridColor: Colors.grey.shade200,
        textStyle: GoogleFonts.poppins(
          fontSize: 10,
          color: Colors.grey.shade600,
        ),
      ),
      size: Size.infinite,
    );
  }
}

class _EarningsChartPainter extends CustomPainter {
  _EarningsChartPainter({
    required this.values,
    required this.labels,
    required this.lineColor,
    required this.gridColor,
    required this.textStyle,
  });

  final List<double> values;
  final List<String> labels;
  final Color lineColor;
  final Color gridColor;
  final TextStyle textStyle;

  static const double _leftPad = 44;
  static const double _rightPad = 12;
  static const double _topPad = 16;
  static const double _bottomPad = 12;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final chartWidth = size.width - _leftPad - _rightPad;
    final chartHeight = size.height - _topPad - _bottomPad;

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    // Round up to a "nice" ceiling so the top label is clean.
    final niceMax = _niceCeiling(maxValue);
    // If all values are 0, still draw a flat line at the bottom.
    final safeMax = niceMax == 0 ? 1.0 : niceMax;

    // ── Y-axis grid + labels ──
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    const int gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final y = _topPad + chartHeight * (i / gridLines);
      canvas.drawLine(
        Offset(_leftPad, y),
        Offset(size.width - _rightPad, y),
        gridPaint,
      );

      final value = safeMax * (1 - i / gridLines);
      final tp = TextPainter(
        text: TextSpan(
          text: _formatAxisLabel(value),
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(_leftPad - tp.width - 6, y - tp.height / 2),
      );
    }

    // ── Compute point positions ──
    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? _leftPad + chartWidth / 2
          : _leftPad + chartWidth * (i / (values.length - 1));
      final y = _topPad +
          chartHeight * (1 - (values[i] / safeMax).clamp(0.0, 1.0));
      points.add(Offset(x, y));
    }

    // ── Area fill under the line ──
    final areaPath = Path()
      ..moveTo(points.first.dx, _topPad + chartHeight)
      ..lineTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      areaPath.lineTo(points[i].dx, points[i].dy);
    }
    areaPath
      ..lineTo(points.last.dx, _topPad + chartHeight)
      ..close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.25),
          lineColor.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(
        _leftPad,
        _topPad,
        chartWidth,
        chartHeight,
      ));
    canvas.drawPath(areaPath, areaPaint);

    // ── The line itself ──
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // ── Data point dots ──
    final dotFill = Paint()..color = Colors.white;
    final dotStroke = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (final p in points) {
      canvas.drawCircle(p, 5, dotFill);
      canvas.drawCircle(p, 5, dotStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _EarningsChartPainter old) {
    return old.values != values ||
        old.labels != labels ||
        old.lineColor != lineColor;
  }

  /// Round up to a friendly number for the Y-axis ceiling.
  static double _niceCeiling(double v) {
    if (v <= 0) return 0;
    if (v <= 10) return 10;
    if (v <= 50) return 50;
    if (v <= 100) return 100;
    if (v <= 250) return 250;
    if (v <= 500) return 500;
    if (v <= 1000) return 1000;
    if (v <= 2500) return 2500;
    if (v <= 5000) return 5000;
    // Round up to the next 1000 for larger values.
    return (v / 1000).ceil() * 1000.0;
  }

  static String _formatAxisLabel(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      return '₱${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}k';
    }
    return '₱${v.toStringAsFixed(0)}';
  }
}