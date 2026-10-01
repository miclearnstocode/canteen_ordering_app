// lib/pages/cart_page.dart
// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/student_state.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Color primaryColor = const Color(0xFF1E7B3B);
  final StudentAppState _state = StudentAppState();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _placingOrder = false;

  Future<double> _loadCredits() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 0;
    final doc = await _firestore.collection('users').doc(uid).get();
    return (doc.data()?['credits'] as num?)?.toDouble() ?? 0.0;
  }

  // ---------- Delete confirmation ----------
  Future<bool> _confirmDelete(StudentCartItem item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red.shade600, size: 24),
            const SizedBox(width: 10),
            Text(
              'Remove item?',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Remove "${item.name}" from your cart?',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No',
                style: GoogleFonts.poppins(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Yes, remove',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleRemove(StudentCartItem item) async {
    final confirmed = await _confirmDelete(item);
    if (!confirmed) return;
    _state.removeFromCart(item.id);
    if (mounted) {
      _snack('${item.name} removed from cart');
    }
  }

  Future<void> _checkout() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _snack('You must be logged in to checkout.', isError: true);
      return;
    }
    if (_state.cartItems.isEmpty) return;

    setState(() => _placingOrder = true);
    final total = _state.subtotal;

    try {
      await _firestore.runTransaction((tx) async {
        final userRef = _firestore.collection('users').doc(uid);
        final userSnap = await tx.get(userRef);
        if (!userSnap.exists) throw Exception('User not found.');

        final currentCredits =
            (userSnap.data()?['credits'] as num?)?.toDouble() ?? 0.0;
        if (currentCredits < total) {
          throw Exception(
              'Insufficient credits. You have ₱${currentCredits.toStringAsFixed(2)}, need ₱${total.toStringAsFixed(2)}.');
        }

        // ── Validate menu stock ──
        final menuSnaps = <String, DocumentSnapshot>{};
        for (final item in _state.cartItems) {
          final ref = _firestore.collection('menu_items').doc(item.id);
          final snap = await tx.get(ref);
          if (!snap.exists) {
            throw Exception('${item.name} is no longer on the menu.');
          }
          final stock = (snap.data()?['stock'] as num?)?.toInt() ?? 0;
          if (stock < item.quantity) {
            throw Exception(
                'Not enough stock for ${item.name} (only $stock left).');
          }
          menuSnaps[item.id] = snap;
        }

        // ── Deduct credits ONLY. Points are awarded on completion. ──
        final newBalance = currentCredits - total;

        tx.update(userRef, {
          'credits': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // ── Reduce menu stock ──
        for (final item in _state.cartItems) {
          final snap = menuSnaps[item.id]!;
          final stock = (snap.data() as Map)['stock'] as num? ?? 0;
          tx.update(_firestore.collection('menu_items').doc(item.id), {
            'stock': stock.toInt() - item.quantity,
            'isAvailable': (stock.toInt() - item.quantity) > 0,
          });
        }

        // ── Create order ──
        final orderRef = _firestore.collection('orders').doc();
        tx.set(orderRef, {
          'orderNumber': orderRef.id.substring(0, 8).toUpperCase(),
          'userId': uid,
          'items': _state.cartItems
              .map((e) => {
                    'id': e.id,
                    'name': e.name,
                    'price': e.price,
                    'quantity': e.quantity,
                  })
              .toList(),
          'total': total,
          'paymentMethod': 'Credits',
          'status': 'Pending',
          'pointsEarned': 0,          // filled in when Completed
          'pointsAwarded': false,     // flag so we never double-award
          'createdAt': FieldValue.serverTimestamp(),
        });

        // ── Credit transaction log ──
        final txLogRef =
            _firestore.collection('credit_transactions').doc();
        tx.set(txLogRef, {
          'uid': uid,
          'type': 'debit',
          'amount': total,
          'balanceAfter': newBalance,
          'note': 'Order payment',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      _state.clearCart();
      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade600 : primaryColor,
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded,
                    color: primaryColor, size: 50),
              ),
              const SizedBox(height: 16),
              Text('Order Placed!',
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Your order has been submitted to the canteen. Credits were deducted from your balance.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Loyalty points will be credited once the canteen completes your order.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _state.setTabIndex(3);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('View in Orders',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final cartItems = _state.cartItems;
        final subtotal = _state.subtotal;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.black87, size: 20),
              onPressed: () => _state.setTabIndex(0),
            ),
            centerTitle: true,
            title: Text('My Cart',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.black87)),
          ),
          body: cartItems.isEmpty
              ? _buildEmptyCart()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          // Each item gets a unique Dismissible key so
                          // Flutter can track it across rebuilds.
                          return Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              return await _confirmDelete(item);
                            },
                            onDismissed: (_) {
                              _state.removeFromCart(item.id);
                              _snack('${item.name} removed from cart');
                            },
                            background: _buildSwipeBackground(),
                            child: _buildCartItemCard(item),
                          );
                        },
                      ),
                    ),
                    _buildCheckoutSheet(subtotal),
                  ],
                ),
        );
      },
    );
  }

  // Red background revealed while swiping an item to the left.
  Widget _buildSwipeBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.delete_outline, color: Colors.white, size: 26),
          const SizedBox(width: 8),
          Text(
            'Remove',
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 70, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Your cart is empty',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Text('Add items from the menu to get started',
              style: GoogleFonts.poppins(
                  color: Colors.grey.shade500, fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _state.setTabIndex(1),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Browse Menu',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSheet(double subtotal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<double>(
              future: _loadCredits(),
              builder: (context, snap) {
                final credits = snap.data ?? 0;
                final insufficient = snap.hasData && credits < subtotal;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: insufficient
                        ? Colors.red.withValues(alpha: 0.08)
                        : primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet,
                          color:
                              insufficient ? Colors.red.shade600 : primaryColor,
                          size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Paying with Credits',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            Text(
                              snap.hasData
                                  ? 'Balance: ₱${credits.toStringAsFixed(2)}'
                                  : 'Loading balance...',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      if (insufficient)
                        Text('Insufficient',
                            style: GoogleFonts.poppins(
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87)),
                Text('₱${subtotal.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _placingOrder ? null : _checkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _placingOrder
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        'Pay with Credits ( ₱${subtotal.toStringAsFixed(0)} )',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard(StudentCartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
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
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                          child: Icon(item.fallbackIcon,
                              size: 36, color: primaryColor)),
                    )
                  : Center(
                      child: Icon(item.fallbackIcon,
                          size: 36, color: primaryColor)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black87)),
                const SizedBox(height: 6),
                Text('₱${item.price.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.black87)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => _state.updateQuantity(item.id, -1),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text('-',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('${item.quantity}',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                InkWell(
                  onTap: () => _state.updateQuantity(item.id, 1),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text('+',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
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