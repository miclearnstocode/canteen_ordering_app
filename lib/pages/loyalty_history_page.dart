import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/user_stream_service.dart';

class LoyaltyHistoryPage extends StatelessWidget {
  const LoyaltyHistoryPage({super.key});

  static const Color primaryColor = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Loyalty History',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: uid == null
          ? _empty('Please log in to view your history')
          : Column(
              children: [
                // ── Live balance card ──
                StreamBuilder<AppUser?>(
                  stream: UserStreamService.currentUserStream(),
                  builder: (context, snap) {
                    final points = snap.data?.points ?? 0;
                    return _balanceCard(points);
                  },
                ),

                // ── Transaction list ──
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('points_transactions')
                        .where('uid', isEqualTo: uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return _empty(
                            'Failed to load history:\n${snapshot.error}');
                      }

                      // Parse + sort newest first (client-side, no index needed).
                      final txs = (snapshot.data?.docs ?? [])
                          .map((d) => _PointsTx.fromDoc(d))
                          .toList()
                        ..sort((a, b) {
                          final aT = a.timestamp ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                          final bT = b.timestamp ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                          return bT.compareTo(aT);
                        });

                      if (txs.isEmpty) {
                        return _empty(
                            'No loyalty activity yet.\n'
                            'Place an order to start earning points!');
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: txs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) =>
                            _historyTile(txs[i]),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // ─────────────────────────────────────────────
  // Balance card (top)
  // ─────────────────────────────────────────────
  static Widget _balanceCard(int points) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars,
                  color: primaryColor, size: 32),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Balance',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey[600]),
                ),
                Text(
                  '$points Points',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Transaction tile
  // ─────────────────────────────────────────────
  static Widget _historyTile(_PointsTx tx) {
    // Map type → color + icon + sign + label
    late final Color color;
    late final IconData icon;
    late final String sign;
    late final String label;

    switch (tx.type) {
      case 'earn':
        color = Colors.green.shade700;
        icon = Icons.add_circle_outline;
        sign = '+';
        label = tx.note.isEmpty ? 'Earned points' : tx.note;
        break;
      case 'redeem':
        color = Colors.red.shade600;
        icon = Icons.remove_circle_outline;
        sign = '−';
        label = tx.note.isEmpty ? 'Redeemed reward' : tx.note;
        break;
      case 'refund':
        color = Colors.blue.shade600;
        icon = Icons.refresh;
        sign = '+';
        label = tx.note.isEmpty ? 'Refunded points' : tx.note;
        break;
      default:
        color = Colors.grey.shade600;
        icon = Icons.circle_outlined;
        sign = '';
        label = tx.note.isEmpty ? 'Adjustment' : tx.note;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  tx.formattedDateTime,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Balance: ${tx.balanceAfter} pts',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sign${tx.amount.abs()} pts',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Empty state
  // ─────────────────────────────────────────────
  static Widget _empty(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off,
                size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Internal model — matches what gets written to
// `points_transactions/{id}` by the app.
// ═══════════════════════════════════════════════════════════════
class _PointsTx {
  final String id;
  final String uid;
  final String type;         // 'earn' | 'redeem' | 'refund'
  final int amount;          // positive for earn/refund, positive for redeem too
  final int balanceAfter;
  final String note;
  final DateTime? timestamp;

  _PointsTx({
    required this.id,
    required this.uid,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.note,
    required this.timestamp,
  });

  factory _PointsTx.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return _PointsTx(
      id: doc.id,
      uid: (d['uid'] ?? '').toString(),
      type: (d['type'] ?? 'earn').toString(),
      amount: (d['amount'] as num?)?.toInt() ?? 0,
      balanceAfter: (d['balanceAfter'] as num?)?.toInt() ?? 0,
      note: (d['note'] ?? '').toString(),
      timestamp: (d['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  String get formattedDateTime {
    if (timestamp == null) return '—';
    final local = timestamp!.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final min = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, ${local.year} • '
        '$h12:$min $ampm';
  }
}