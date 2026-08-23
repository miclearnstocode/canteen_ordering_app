import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
// 7. ADMIN PAYMENTS PAGE
// ==========================================
class AdminPaymentsPage extends StatefulWidget {
  const AdminPaymentsPage({super.key});

  @override
  State<AdminPaymentsPage> createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends State<AdminPaymentsPage> {
  final Color adminPurple = const Color(0xFF5E35B1);
  final Color green = const Color(0xFF2E7D32);
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _payments = [
    {'id': '#10025', 'time': '10:30 AM', 'name': 'Marianne Santos', 'method': 'Cash', 'amount': '₱315', 'status': 'Paid'},
    {'id': '#10026', 'time': '10:32 AM', 'name': 'John Dela Cruz', 'method': 'GCash', 'amount': '₱190', 'status': 'Verify'},
    {'id': '#10027', 'time': '10:34 AM', 'name': 'Andrea Reyes', 'method': 'Cash', 'amount': '₱120', 'status': 'Paid'},
    {'id': '#10028', 'time': '10:40 AM', 'name': 'Mark Garcia', 'method': 'GCash', 'amount': '₱250', 'status': 'Verify'},
    {'id': '#10029', 'time': '10:45 AM', 'name': 'Kyle Villanueva', 'method': 'Cash', 'amount': '₱85', 'status': 'Paid'},
  ];

  void _verifyPayment(int index) {
    setState(() {
      _payments[index]['status'] = 'Paid';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment ${_payments[index]['id']} verified!'), backgroundColor: green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == 'All'
        ? _payments
        : _payments.where((p) => (p['method'] as String).toLowerCase() == _selectedFilter.toLowerCase()).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payments & Transactions', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            // Filter Chips
            Row(
              children: ['All', 'Cash', 'GCash'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: adminPurple,
                    labelStyle: GoogleFonts.poppins(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFilter = filter);
                    },
                  ),
                );
              }).toList(),
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
                  itemCount: filtered.length,
                  separatorBuilder: (context, i) => Divider(color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isVerify = item['status'] == 'Verify';

                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (item['method'] == 'GCash' ? const Color(0xFF007DFE) : green).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item['method'] == 'GCash' ? Icons.account_balance_wallet : Icons.money,
                          color: item['method'] == 'GCash' ? const Color(0xFF007DFE) : green,
                          size: 20,
                        ),
                      ),
                      title: Text('${item['name']} (${item['id']})', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text('${item['time']} • Method: ${item['method']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item['amount'] as String, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(width: 12),
                          if (isVerify)
                            ElevatedButton(
                              onPressed: () => _verifyPayment(_payments.indexOf(item)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: adminPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Verify', style: TextStyle(fontSize: 12)),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Paid', style: GoogleFonts.poppins(fontSize: 12, color: green, fontWeight: FontWeight.bold)),
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
// 9. ADMIN ACCOUNTS PAGE
// ==========================================
class AdminAccountsPage extends StatefulWidget {
  const AdminAccountsPage({super.key});

  @override
  State<AdminAccountsPage> createState() => _AdminAccountsPageState();
}

class _AdminAccountsPageState extends State<AdminAccountsPage> {
  final Color adminPurple = const Color(0xFF5E35B1);
  final Color green = const Color(0xFF2E7D32);
  final _searchController = TextEditingController();
  int _currentPage = 1;

  final List<Map<String, dynamic>> _students = [
    {'name': 'Marianne Santos', 'id': '2023-12345', 'course': 'BSIT - 2A', 'points': '125', 'orders': '18', 'status': 'Active'},
    {'name': 'John Dela Cruz', 'id': '2023-12346', 'course': 'BSIT - 2A', 'points': '80', 'orders': '15', 'status': 'Active'},
    {'name': 'Andrea Reyes', 'id': '2023-12347', 'course': 'BSIT - 1B', 'points': '45', 'orders': '9', 'status': 'Active'},
    {'name': 'Mark Garcia', 'id': '2023-12348', 'course': 'BSIT - 3A', 'points': '60', 'orders': '12', 'status': 'Active'},
    {'name': 'Kyle Villanueva', 'id': '2023-12349', 'course': 'BSIT - 1A', 'points': '30', 'orders': '6', 'status': 'Active'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final filtered = _students.where((s) =>
        (s['name'] as String).toLowerCase().contains(query) ||
        (s['course'] as String).toLowerCase().contains(query)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student Accounts Directory', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by student name or section...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, i) => Divider(color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final s = filtered[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: adminPurple.withValues(alpha: 0.1),
                        child: Text(
                          (s['name'] as String)[0],
                          style: GoogleFonts.poppins(color: adminPurple, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(s['name'] as String, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('${s['course']} • ID: ${s['id']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${s['points']} pts', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: green)),
                              Text('${s['orders']} orders', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(s['status'] as String, style: GoogleFonts.poppins(fontSize: 11, color: green, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Pagination
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pageBtn('1', _currentPage == 1),
                _pageBtn('2', _currentPage == 2),
                _pageBtn('3', _currentPage == 3),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageBtn(String page, bool isCurrent) {
    return InkWell(
      onTap: () => setState(() => _currentPage = int.parse(page)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isCurrent ? adminPurple : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isCurrent ? adminPurple : Colors.grey.shade300),
        ),
        child: Text(
          page,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isCurrent ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}