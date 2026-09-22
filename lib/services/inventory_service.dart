// lib/services/inventory_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item_model.dart';
import '../models/menu_item_model.dart';

class InventoryService {
  static final _db = FirebaseFirestore.instance;
  static CollectionReference get _inv => _db.collection('inventory');

  // ─────────────────────────────────────────────
  // AUTO-CREATE ingredients that don't exist yet
  // ─────────────────────────────────────────────
  static Future<List<RecipeIngredient>> ensureIngredientsExist(
    List<RecipeIngredient> recipe,
  ) async {
    final result = <RecipeIngredient>[];

    for (final r in recipe) {
      if (r.ingredientId.isNotEmpty) {
        result.add(r);
        continue;
      }

      // Match by name AND type=ingredient so we don't accidentally
      // reuse a "supply" with the same name.
      final existing = await _inv
          .where('name', isEqualTo: r.ingredientName)
          .where('type', isEqualTo: 'ingredient')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        result.add(RecipeIngredient(
          ingredientId: doc.id,
          ingredientName: r.ingredientName,
          unit: r.unit,
          qtyPerPortion: r.qtyPerPortion,
        ));
      } else {
        // Auto-create as ingredient, stock 0, min 5.
        final newDoc = await _inv.add({
          'name': r.ingredientName,
          'unit': r.unit,
          'stock': 0,
          'minLevel': 5,
          'type': 'ingredient',              // ← important
          'updatedAt': FieldValue.serverTimestamp(),
        });
        result.add(RecipeIngredient(
          ingredientId: newDoc.id,
          ingredientName: r.ingredientName,
          unit: r.unit,
          qtyPerPortion: r.qtyPerPortion,
        ));
      }
    }
    return result;
  }

  // ─────────────────────────────────────────────
  // RESTOCK / ADJUST (works for both types)
  // ─────────────────────────────────────────────
  static Future<void> adjustStock(String id, double delta) async {
    await _db.runTransaction((tx) async {
      final ref = _inv.doc(id);
      final snap = await tx.get(ref);
      final current = (snap.data() as Map?)?['stock'] as num? ?? 0;
      final next = (current.toDouble() + delta).clamp(0, double.infinity);
      tx.update(ref, {
        'stock': next,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> setStock(String id, double value) async {
    await _inv.doc(id).update({
      'stock': value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────
  // DEDUCT when an order is placed
  // ─────────────────────────────────────────────
  static Future<void> deductForOrder(Map<String, int> portions) async {
    final deductions = <String, double>{};

    for (final entry in portions.entries) {
      final menuDoc =
          await _db.collection('menu_items').doc(entry.key).get();
      if (!menuDoc.exists) continue;
      final menu = MenuItemModel.fromMap(menuDoc.id, menuDoc.data()!);
      for (final r in menu.recipe) {
        deductions[r.ingredientId] =
            (deductions[r.ingredientId] ?? 0) +
                r.qtyPerPortion * entry.value;
      }
    }

    if (deductions.isEmpty) return;

    await _db.runTransaction((tx) async {
      final snaps = <String, DocumentSnapshot>{};
      for (final id in deductions.keys) {
        snaps[id] = await tx.get(_inv.doc(id));
      }
      for (final id in deductions.keys) {
        final data = snaps[id]!.data() as Map?;
        final current = (data?['stock'] as num?)?.toDouble() ?? 0;
        final next =
            (current - deductions[id]!).clamp(0, double.infinity);
        tx.update(_inv.doc(id), {
          'stock': next,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // ─────────────────────────────────────────────
  // DEDUCT a standalone supply (cups, spoons, etc.)
  // Use this from the checkout flow alongside deductForOrder.
  // ─────────────────────────────────────────────
  /// [supplies] = map of inventoryId -> qty to deduct.
  static Future<void> deductSupplies(Map<String, double> supplies) async {
    if (supplies.isEmpty) return;
    await _db.runTransaction((tx) async {
      final snaps = <String, DocumentSnapshot>{};
      for (final id in supplies.keys) {
        snaps[id] = await tx.get(_inv.doc(id));
      }
      for (final id in supplies.keys) {
        final data = snaps[id]!.data() as Map?;
        final current = (data?['stock'] as num?)?.toDouble() ?? 0;
        final next =
            (current - supplies[id]!).clamp(0, double.infinity);
        tx.update(_inv.doc(id), {
          'stock': next,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // ─────────────────────────────────────────────
  // Compute how many portions are still makeable
  // ─────────────────────────────────────────────
  static Future<int> maxPortions(MenuItemModel menu) async {
    if (menu.recipe.isEmpty) return menu.stock;

    int best = 1 << 30;
    for (final r in menu.recipe) {
      if (r.qtyPerPortion <= 0) continue;
      final snap = await _inv.doc(r.ingredientId).get();
      final stock =
          ((snap.data() as Map?)?['stock'] as num?)?.toDouble() ?? 0;
      final possible = (stock / r.qtyPerPortion).floor();
      if (possible < best) best = possible;
    }
    return best == (1 << 30) ? 0 : best;
  }
}