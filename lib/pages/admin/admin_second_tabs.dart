import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/admin_account_service.dart';

// ==========================================
// 6. ADMIN REDEMPTION PAGE
// ==========================================
class AdminRedemptionPage extends StatefulWidget {
  const AdminRedemptionPage({super.key});

  @override
  State<AdminRedemptionPage> createState() => _AdminRedemptionPageState();
}

class _AdminRedemptionPageState extends State<AdminRedemptionPage> {
  final Color adminPurple = const Color(0xFF5E35B1);
  final Color green = const Color(0xFF2E7D32);
  final _codeController = TextEditingController();

  final List<Map<String, dynamic>> _history = [
    {'code': 'RW-8921', 'reward': 'Free Burger', 'student': 'Marianne Santos', 'time': '10:15 AM', 'status': 'Claimed'},
    {'code': 'RW-8918', 'reward': 'Free Soft Drink', 'student': 'John Dela Cruz', 'time': '9:40 AM', 'status': 'Claimed'},
    {'code': 'RW-8904', 'reward': 'Free Rice', 'student': 'Andrea Reyes', 'time': 'Yesterday', 'status': 'Claimed'},
  ];

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _verifyCode() {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a redemption code')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: green, size: 28),
            const SizedBox(width: 10),
            Text('Valid Reward Found', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Redemption Code', code),
            _infoRow('Reward Item', 'Free Burger (80 Points)'),
            _infoRow('Student Name', 'Marianne Santos (2023-12345)'),
            _infoRow('Claim Status', 'Ready for Claiming'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _history.insert(0, {
                  'code': code,
                  'reward': 'Free Burger',
                  'student': 'Marianne Santos',
                  'time': 'Just now',
                  'status': 'Claimed',
                });
                _codeController.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Code $code marked as Claimed!'), backgroundColor: green),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white),
            child: const Text('Confirm Claim'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$label:', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600))),
          Expanded(child: Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
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
            Text('Scan & Claim Rewards', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Mock Scanner Frame
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: green, width: 2.5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, size: 64, color: green),
                        const SizedBox(height: 8),
                        Text('Camera Scanner Ready', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('— OR ENTER CODE MANUALLY —', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'e.g. RW-8921',
                            prefixIcon: const Icon(Icons.confirmation_number_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Verify'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Recent Redemptions
            Text('Recent Redemptions', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                separatorBuilder: (context, i) => Divider(color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final item = _history[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: green.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(Icons.check, color: green, size: 20),
                    ),
                    title: Text('${item['reward']} (${item['code']})', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text('${item['student']} • ${item['time']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                    trailing: Text(item['status'] as String, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: green, fontSize: 12)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 7. ADMIN PAYMENTS PAGE (LIVE)
// ==========================================
class AdminPaymentsPage extends StatefulWidget {
  const AdminPaymentsPage({super.key});

  @override
  State<AdminPaymentsPage> createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends State<AdminPaymentsPage> {
  final Color adminPurple = const Color(0xFF5E35B1);
  final Color green = const Color(0xFF2E7D32);
  final Color debitColor = const Color(0xFFC62828);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 'all' | 'credit' | 'debit'
  String _selectedFilter = 'all';

  // Cache: uid -> display name. Fetched lazily.
  final Map<String, String> _nameCache = {};
  final Set<String> _loadingNames = {};

  String? _nameFor(String uid) {
    if (uid.isEmpty) return 'Unknown';
    if (_nameCache.containsKey(uid)) return _nameCache[uid];
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
    return null;
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '—';
    final local = dt.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final min = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, $h12:$min $ampm';
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
            Text('Payments & Transactions',
                style: GoogleFonts.poppins(
                    fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Live credit top-ups and order payments from students.',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // ── Filter chips ──
            Row(
              children: [
                _buildFilterChip('all', 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('credit', 'Top-ups'),
                const SizedBox(width: 8),
                _buildFilterChip('debit', 'Order Payments'),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // No orderBy → no index needed; we sort client-side.
                stream: _firestore
                    .collection('credit_transactions')
                    .limit(200)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Failed to load payments:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              color: Colors.red.shade700,
                              fontSize: 12),
                        ),
                      ),
                    );
                  }

                  // ── Parse and sort newest first ──
                  final allTx = (snapshot.data?.docs ?? [])
                      .map((d) => _CreditTx.fromDoc(d))
                      .toList()
                    ..sort((a, b) {
                      final aT = a.timestamp ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                      final bT = b.timestamp ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                      return bT.compareTo(aT);
                    });

                  // ── Apply filter ──
                  final filtered = _selectedFilter == 'all'
                      ? allTx
                      : allTx
                          .where((t) => t.type == _selectedFilter)
                          .toList();

                  // ── Aggregate totals for the header strip ──
                  double totalTopUps = 0;
                  double totalSpent = 0;
                  for (final t in allTx) {
                    if (t.type == 'credit') totalTopUps += t.amount;
                    if (t.type == 'debit') totalSpent += t.amount;
                  }

                  return Column(
                    children: [
                      // ── Summary strip ──
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 600;
                          final w = wide
                              ? (constraints.maxWidth - 16) / 2
                              : constraints.maxWidth;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: w,
                                child: _summaryCard(
                                  label: 'Total Top-ups Received',
                                  amount: totalTopUps,
                                  icon: Icons.south_west,
                                  color: green,
                                ),
                              ),
                              SizedBox(
                                width: w,
                                child: _summaryCard(
                                  label: 'Total Spent on Orders',
                                  amount: totalSpent,
                                  icon: Icons.north_east,
                                  color: debitColor,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Transactions list ──
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: filtered.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.receipt_long_outlined,
                                          size: 60,
                                          color: Colors.grey.shade400),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No transactions yet',
                                        style: GoogleFonts.poppins(
                                            color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => Divider(
                                      color: Colors.grey.shade100),
                                  itemBuilder: (context, i) {
                                    final tx = filtered[i];
                                    final isCredit = tx.type == 'credit';
                                    final color =
                                        isCredit ? green : debitColor;
                                    final icon = isCredit
                                        ? Icons.add_card
                                        : Icons.shopping_bag_outlined;
                                    final label = isCredit
                                        ? 'Credit Top-up'
                                        : 'Order Payment';
                                    final sign = isCredit ? '+' : '-';
                                    final cachedName = _nameFor(tx.uid);

                                    return ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6),
                                      leading: Container(
                                        padding:
                                            const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: color.withValues(
                                              alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(icon,
                                            color: color, size: 20),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              cachedName ??
                                                  'Loading…',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: cachedName == null
                                                    ? Colors.grey.shade500
                                                    : Colors.black87,
                                              ),
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 8,
                                                vertical: 2),
                                            decoration: BoxDecoration(
                                              color: color.withValues(
                                                  alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      6),
                                            ),
                                            child: Text(
                                              label,
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight:
                                                    FontWeight.bold,
                                                color: color,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 2),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tx.note.isEmpty
                                                  ? _formatDateTime(
                                                      tx.timestamp)
                                                  : '${tx.note}  •  ${_formatDateTime(tx.timestamp)}',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: Colors
                                                      .grey.shade600),
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Balance after: ₱${tx.balanceAfter.toStringAsFixed(2)}',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: Colors
                                                      .grey.shade500),
                                            ),
                                          ],
                                        ),
                                      ),
                                      trailing: Text(
                                        '$sign₱${tx.amount.toStringAsFixed(2)}',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: color,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final selected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: adminPurple,
      labelStyle: GoogleFonts.poppins(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      onSelected: (s) {
        if (s) setState(() => _selectedFilter = value);
      },
    );
  }

  Widget _summaryCard({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
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
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₱${amount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Internal model ----------
class _CreditTx {
  final String id;
  final String uid;
  final String type; // 'credit' | 'debit'
  final double amount;
  final double balanceAfter;
  final String note;
  final DateTime? timestamp;

  _CreditTx({
    required this.id,
    required this.uid,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.note,
    required this.timestamp,
  });

  factory _CreditTx.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return _CreditTx(
      id: doc.id,
      uid: (d['uid'] ?? '').toString(),
      type: (d['type'] ?? 'credit').toString(),
      amount: (d['amount'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (d['balanceAfter'] as num?)?.toDouble() ?? 0.0,
      note: (d['note'] ?? '').toString(),
      timestamp: (d['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}

// ==========================================
// 8. ADMIN REPORTS PAGE
// ==========================================
class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});
  static const Color adminPurple = Color(0xFF5E35B1);
  static const Color green = Color(0xFF2E7D32);

  void _showReportDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Report generated for the period.\n\nTotal Entries: 235\nTotal Volume: ₱18,500\nAverage Ticket Size: ₱78.72', style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading $title...'), backgroundColor: green));
            },
            style: ElevatedButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white),
            child: const Text('Download PDF'),
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
            Text('Sales & Analytical Reports', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _reportTile(context, Icons.calendar_today, 'Daily Sales Report', 'Summary of all transactions today'),
                  const Divider(height: 1),
                  _reportTile(context, Icons.calendar_month, 'Monthly Sales Report', 'Revenue breakdown for current month'),
                  const Divider(height: 1),
                  _reportTile(context, Icons.restaurant, 'Best Selling Foods', 'Top ordered food items & quantity'),
                  const Divider(height: 1),
                  _reportTile(context, Icons.inventory_2_outlined, 'Inventory Restock Report', 'Low stock items and alert history'),
                  const Divider(height: 1),
                  _reportTile(context, Icons.stars, 'Loyalty Points Redemption Report', 'Rewards claimed and points deducted'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting PDF...')));
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export All PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting Excel spreadsheet...'), backgroundColor: green));
                    },
                    icon: const Icon(Icons.grid_on),
                    label: const Text('Export Excel (CSV)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportTile(BuildContext context, IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: adminPurple.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: adminPurple, size: 20),
      ),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () => _showReportDialog(context, title),
    );
  }
}

// ==========================================
// 9. ADMIN ACCOUNTS PAGE (REWORKED)
// ==========================================
class AdminAccountsPage extends StatefulWidget {
  const AdminAccountsPage({super.key});

  @override
  State<AdminAccountsPage> createState() => _AdminAccountsPageState();
}

class _AdminAccountsPageState extends State<AdminAccountsPage> {
  final Color adminPurple = const Color(0xFF5E35B1);
  final Color green = const Color(0xFF2E7D32);
  final Color amber = const Color(0xFFF9A825);

  final _searchController = TextEditingController();
  final _service = AdminAccountService();

  // ---- Create-account dialog ----
  Future<void> _showCreateAccountDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    final courseCtrl = TextEditingController();
    final pwCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        bool obscurePassword = true; // local visibility state

        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text('Create Student Account',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(nameCtrl, 'Full Name', Icons.person_outline),
                  _field(emailCtrl, 'Email', Icons.email_outlined),
                  _field(idCtrl, 'Student ID', Icons.badge_outlined),
                  _field(courseCtrl, 'Course / Section', Icons.school_outlined),
                  _field(
                    pwCtrl,
                    'Temporary Password',
                    Icons.lock_outline,
                    obscure: obscurePassword,
                    suffix: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The account will be marked PENDING. Release the credentials '
                    'only when the student inquires at the counter.',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: adminPurple, foregroundColor: Colors.white),
                onPressed: () async {
                  if (nameCtrl.text.isEmpty ||
                      emailCtrl.text.isEmpty ||
                      idCtrl.text.isEmpty ||
                      pwCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill in all fields')),
                    );
                    return;
                  }
                  try {
                    await _service.createPendingAccount(
                      fullName: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      studentId: idCtrl.text.trim(),
                      course: courseCtrl.text.trim(),
                      tempPassword: pwCtrl.text.trim(),
                    );
                    if (mounted) Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Pending account for ${nameCtrl.text} created'),
                          backgroundColor: green),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    bool obscure = false,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          suffixIcon: suffix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  // ---- Release credentials ----
  Future<void> _releaseAccount(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Release Credentials',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hand these credentials to the student:',
                style: GoogleFonts.poppins(fontSize: 12)),
            const SizedBox(height: 10),
            _credRow('Email', user.email),
            _credRow('Password', user.tempPassword ?? '(not set)'),
            _credRow('Student ID', user.studentId ?? '-'),
            const SizedBox(height: 8),
            Text('Once released, the student can log in.',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.red.shade400)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: green, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark as Released'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.releaseAccount(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${user.displayName} can now log in'),
              backgroundColor: green),
        );
      }
    }
  }

  Widget _credRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            SizedBox(
                width: 90,
                child: Text('$label:',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey.shade600))),
            Expanded(
              child: SelectableText(value,
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  // ---- Add credit ----
  Future<void> _showAddCreditDialog(AppUser user) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Add Credit — ${user.displayName}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: green, size: 18),
                  const SizedBox(width: 8),
                  Text('Current balance: ₱${user.credits.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount received (₱)',
                prefixText: '₱ ',
                helperText: '1 credit = 1 peso',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. Cash top-up at counter',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: green, foregroundColor: Colors.white),
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid amount')),
                );
                return;
              }
              try {
                await _service.addCredits(
                  uid: user.uid,
                  amountInPesos: amount,
                  note: noteCtrl.text.trim(),
                );
                if (mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Added ₱${amount.toStringAsFixed(2)} to ${user.displayName}'),
                    backgroundColor: green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Add Credits'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateAccountDialog,
        backgroundColor: adminPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text('Create Account',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student Accounts Directory',
                style: GoogleFonts.poppins(
                    fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Create credentials, release on inquiry, and top up credits.',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by student name or section...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<AppUser>>(
                stream: _service.studentsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text('No accounts yet. Tap "Create Account".',
                          style: GoogleFonts.poppins(
                              color: Colors.grey.shade600)),
                    );
                  }

                  final students = snapshot.data!.where((s) {
                    final name =
                        (s.displayName ?? s.username ?? '').toLowerCase();
                    final course = (s.course ?? '').toLowerCase();
                    return name.contains(query) || course.contains(query);
                  }).toList();

                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListView.separated(
                      itemCount: students.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final s = students[index];
                        final isPending = s.isPending;
                        final statusColor = isPending ? amber : green;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: adminPurple.withValues(alpha: 0.1),
                            child: Text(
                              (s.displayName ?? 'U')[0].toUpperCase(),
                              style: GoogleFonts.poppins(
                                  color: adminPurple,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  s.displayName ?? s.username ?? 'Unnamed',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isPending ? 'PENDING' : 'ACTIVE',
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${s.course ?? "-"} • ID: ${s.studentId ?? "-"}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.account_balance_wallet,
                                        size: 14, color: green),
                                    const SizedBox(width: 4),
                                    Text(
                                      '₱${s.credits.toStringAsFixed(2)} credits',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: green),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.stars,
                                        size: 14, color: adminPurple),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${s.points ?? 0} pts',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: adminPurple),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            onSelected: (value) {
                              if (value == 'release') _releaseAccount(s);
                              if (value == 'credit') _showAddCreditDialog(s);
                            },
                            itemBuilder: (_) => [
                              if (isPending)
                                PopupMenuItem(
                                  value: 'release',
                                  child: Row(
                                    children: [
                                      Icon(Icons.vpn_key,
                                          size: 18, color: green),
                                      const SizedBox(width: 8),
                                      const Text('Release Credentials'),
                                    ],
                                  ),
                                ),
                              PopupMenuItem(
                                value: 'credit',
                                child: Row(
                                  children: [
                                    Icon(Icons.add_card,
                                        size: 18, color: adminPurple),
                                    const SizedBox(width: 8),
                                    const Text('Add Credit'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 80), // space for FAB
          ],
        ),
      ),
    );
  }
}