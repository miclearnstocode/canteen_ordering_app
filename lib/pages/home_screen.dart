import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item_model.dart';
import '../models/user_model.dart';
import '../services/student_state.dart';
import '../services/user_stream_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  final Color primaryColor = const Color(0xFF1E7B3B);

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 18) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final state = StudentAppState();
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Canteen Click',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none_rounded,
                    color: Colors.black87, size: 26),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new notifications right now.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      // ── Wrap in a user stream so greeting / avatar / points are live ──
      body: StreamBuilder<AppUser?>(
        stream: UserStreamService.currentUserStream(),
        builder: (context, userSnap) {
          final user = userSnap.data;
          final name = _displayName(user);
          final seed = _avatarSeed(user);
          final points = user?.points ?? 0;

          return SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Greeting ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => state.setTabIndex(5),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color:
                                  primaryColor.withValues(alpha: 0.3),
                              width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFFFE0B2),
                          backgroundImage: NetworkImage(
                            'https://api.dicebear.com/7.x/adventurer/png?seed=$seed&backgroundColor=ffd5dc',
                          ),
                          child: const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── Loyalty Points Card (LIVE) ──
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
                        color:
                            Colors.black.withValues(alpha: 0.04),
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
                            'Loyalty Points',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.star_rounded,
                                  color: primaryColor, size: 28),
                              const SizedBox(width: 6),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$points ',
                                      style:
                                          GoogleFonts.poppins(
                                        fontSize: 26,
                                        fontWeight:
                                            FontWeight.w800,
                                        color: primaryColor,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Points',
                                      style:
                                          GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight.w600,
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
                      GestureDetector(
                        onTap: () => state.setTabIndex(4),
                        child: Container(
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── Today's Specials ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Specials",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () => state.setTabIndex(1),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'See all',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection('menu_items')
                      .where('isSpecial', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox(
                        height: 175,
                        child: Center(
                            child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return SizedBox(
                        height: 175,
                        child: Center(
                          child: Text(
                            'Failed to load specials',
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade600),
                          ),
                        ),
                      );
                    }

                    final specials = (snapshot.data?.docs ?? [])
                        .map((d) => MenuItemModel.fromMap(
                            d.id, d.data() as Map<String, dynamic>))
                        .where((m) => m.isAvailable)
                        .toList();

                    if (specials.isEmpty) {
                      return SizedBox(
                        height: 140,
                        child: Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star_border_rounded,
                                  size: 42,
                                  color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                'No specials today',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Check back later!',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 185,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: specials.length,
                        itemBuilder: (context, i) {
                          final item = specials[i];
                          return _buildSpecialCard(context, item);
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 22),

                // ── Announcement ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFC8E6C9), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.campaign_outlined,
                              color: primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Announcement',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'New menu items are available today!\nThank you for using Canteen Click.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w400,
                        ),
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

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────
  String _displayName(AppUser? user) {
    if (user == null) return 'Student';
    final raw = (user.displayName ?? user.username ?? '').trim();
    if (raw.isEmpty) return 'Student';
    // Use only the first word for the greeting line.
    return raw.split(RegExp(r'\s+')).first;
  }

  String _avatarSeed(AppUser? user) {
    if (user == null) return 'guest';
    final name = (user.displayName ?? user.username ?? '').trim();
    if (name.isNotEmpty) return Uri.encodeComponent(name);
    if (user.email.isNotEmpty) return Uri.encodeComponent(user.email);
    return user.uid;
  }

  Widget _buildSpecialCard(BuildContext context, MenuItemModel item) {
    final state = StudentAppState();
    return GestureDetector(
      onTap: () {
        state.addToCart(
          item.id,
          item.name,
          item.price,
          item.imageUrl ?? '',
          item.category == 'Drinks'
              ? Icons.local_cafe
              : item.category == 'Snacks'
                  ? Icons.fastfood
                  : Icons.lunch_dining,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} added to cart'),
            duration: const Duration(milliseconds: 1200),
            backgroundColor: primaryColor,
          ),
        );
      },
      child: Container(
        width: 155,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.amber.shade200, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(17)),
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: item.imageUrl != null &&
                            item.imageUrl!.isNotEmpty
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(
                                item.category == 'Drinks'
                                    ? Icons.local_cafe
                                    : item.category == 'Snacks'
                                        ? Icons.fastfood
                                        : Icons.lunch_dining,
                                size: 40,
                                color: primaryColor,
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              item.category == 'Drinks'
                                  ? Icons.local_cafe
                                  : item.category == 'Snacks'
                                      ? Icons.fastfood
                                      : Icons.lunch_dining,
                              size: 40,
                              color: primaryColor,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade600,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 10, color: Colors.white),
                        const SizedBox(width: 2),
                        Text(
                          'SPECIAL',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₱${item.price.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.add,
                            size: 14, color: primaryColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}