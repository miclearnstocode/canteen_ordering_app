// lib/pages/rewards_page.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/loyalty_reward_model.dart';
import '../models/user_model.dart';
import '../services/user_stream_service.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E7B3B);
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Rewards',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
      ),
      body: StreamBuilder<AppUser?>(
        stream: UserStreamService.currentUserStream(),
        builder: (context, userSnap) {
          final user = userSnap.data;
          final points = user?.points ?? 0;

          return StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('loyalty_rewards')
                .orderBy('points')
                .snapshots(),
            builder: (context, rewardSnap) {
              final rewards = (rewardSnap.data?.docs ?? [])
                  .map((d) => LoyaltyReward.fromMap(
                      d.id, d.data() as Map<String, dynamic>))
                  .where((r) => r.isActive)
                  .toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Points card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Points',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: primaryColor, size: 28),
                                  const SizedBox(width: 6),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '$points ',
                                          style: GoogleFonts.poppins(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w800,
                                            color: primaryColor,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Points',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              size: 38,
                              color: Color(0xFFFFA000),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Pending redemptions ──
                    const _PendingRedemptionsSection(),
                    const SizedBox(height: 24),

                    Text(
                      'Available Rewards',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (rewardSnap.connectionState ==
                        ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                            child: CircularProgressIndicator()),
                      )
                    else if (rewards.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 40),
                        child: Center(
                          child: Text(
                            'No rewards available right now.',
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade600),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: rewards
                            .map((r) => _RewardCard(
                                  reward: r,
                                  currentPoints: points,
                                ))
                            .toList(),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Pending redemptions — lets students re-open the QR they got.
// ═══════════════════════════════════════════════════════════════
class _PendingRedemptionsSection extends StatelessWidget {
  const _PendingRedemptionsSection();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('redemptions')
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        // Sort newest first client-side.
        docs.sort((a, b) {
          final aT = ((a.data() as Map)['createdAt'] as Timestamp?)
                  ?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bT = ((b.data() as Map)['createdAt'] as Timestamp?)
                  ?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bT.compareTo(aT);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_2_rounded,
                    color: Color(0xFF1E7B3B), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Pending Rewards',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Show the QR at the counter to claim.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 10),
            ...docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              final code = (data['code'] ?? '').toString();
              final rewardName =
                  (data['rewardName'] ?? 'Reward').toString();
              final pointsCost =
                  (data['pointsCost'] as num?)?.toInt() ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.card_giftcard,
                          color: Color(0xFFE65100), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            rewardName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ref: $code • $pointsCost pts',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _showQrDialog(context, rewardName, code),
                      icon: const Icon(Icons.qr_code_2, size: 16),
                      label: Text(
                        'Show QR',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E7B3B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Reward card
// ═══════════════════════════════════════════════════════════════
class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.currentPoints,
  });

  final LoyaltyReward reward;
  final int currentPoints;

  static const primaryColor = Color(0xFF1E7B3B);

  IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('rice')) return Icons.rice_bowl_rounded;
    if (n.contains('drink') || n.contains('juice')) {
      return Icons.local_drink_rounded;
    }
    if (n.contains('fries') || n.contains('snack')) {
      return Icons.fastfood_rounded;
    }
    if (n.contains('burger') || n.contains('meal')) {
      return Icons.lunch_dining_rounded;
    }
    return Icons.card_giftcard_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final bool canRedeem = currentPoints >= reward.points;
    final icon = _iconFor(reward.name);

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
              width: 70,
              height: 70,
              color: Colors.grey.shade100,
              child: reward.imageUrl != null &&
                      reward.imageUrl!.isNotEmpty
                  ? Image.network(
                      reward.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(icon,
                            size: 36, color: primaryColor),
                      ),
                    )
                  : Center(
                      child: Icon(icon,
                          size: 36, color: primaryColor),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${reward.points} Points',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _handleRedeem(context, canRedeem),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  canRedeem ? primaryColor : Colors.grey.shade400,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Redeem',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRedeem(
      BuildContext context, bool canRedeem) async {
    if (!canRedeem) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Not enough points! You need ${reward.points} points.'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first.')),
      );
      return;
    }

    // Loading indicator while we write to Firestore.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      final code = await _createRedemption(uid: uid, reward: reward);
      if (context.mounted) Navigator.pop(context); // close loader
      if (context.mounted) {
        _showQrDialog(context, reward.name, code);
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // close loader
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _createRedemption({
    required String uid,
    required LoyaltyReward reward,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final code = _generateRedemptionCode();
    final redemptionRef = firestore.collection('redemptions').doc();

    await firestore.runTransaction((tx) async {
      final userRef = firestore.collection('users').doc(uid);
      final userSnap = await tx.get(userRef);
      final current =
          (userSnap.data()?['points'] as num?)?.toInt() ?? 0;
      if (current < reward.points) {
        throw Exception('Insufficient points.');
      }
      final newPoints = current - reward.points;

      // 1. Deduct points now — prevents double-spend.
      tx.update(userRef, {
        'points': newPoints,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Points ledger entry.
      final ledgerRef =
          firestore.collection('points_transactions').doc();
      tx.set(ledgerRef, {
        'uid': uid,
        'type': 'redeem',
        'amount': reward.points,
        'balanceAfter': newPoints,
        'note': 'Redeemed: ${reward.name}',
        'rewardId': reward.id,
        'redemptionId': redemptionRef.id,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 3. Redemption doc — the QR encodes this code.
      tx.set(redemptionRef, {
        'code': code,
        'userId': uid,
        'rewardId': reward.id,
        'rewardName': reward.name,
        'pointsCost': reward.points,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'claimedAt': null,
        'claimedBy': null,
      });
    });

    return code;
  }

  static String _generateRedemptionCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    final body =
        List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
    return 'RW-$body';
  }
}

// ═══════════════════════════════════════════════════════════════
// QR dialog — shared by the redeem flow and the pending list
// ═══════════════════════════════════════════════════════════════
void _showQrDialog(
  BuildContext context,
  String rewardName,
  String code,
) {
  const primaryColor = Color(0xFF1E7B3B);
  final payload = 'REWARD_REDEEM:$code';

  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Show this to the staff',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              rewardName,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                data: payload,
                version: QrVersions.auto,
                size: 200,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: primaryColor,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ref: $code',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade600,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: Text(
                'Status: Pending Claim',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFE65100),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Points have already been deducted. This QR can only be used once.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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