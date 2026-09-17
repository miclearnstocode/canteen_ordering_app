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