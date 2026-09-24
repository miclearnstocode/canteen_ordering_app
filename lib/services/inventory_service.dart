// lib/services/inventory_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // for debugPrint
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
      // If we already have a valid ingredientId, verify it still exists.
      if (r.ingredientId.isNotEmpty) {
        final check = await _inv.doc(r.ingredientId).get();
        if (check.exists) {
          result.add(r);
          continue;
        }
        // Doc was deleted — fall through to recreate by name.
      }

      // Match by name only (no compound query → no index needed).
      final existing = await _inv
          .where('name', isEqualTo: r.ingredientName)
          .limit(5)
          .get();

      DocumentSnapshot? match;
      for (final doc in existing.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final type =
            (data['type'] ?? 'ingredient').toString().toLowerCase();
        if (type == 'ingredient' || type.isEmpty) {
          match = doc;
          break;
        }
      }

      if (match != null) {
        result.add(RecipeIngredient(
          ingredientId: match.id,
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
          'type': 'ingredient',
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
  // APPLY RECIPE DELTA (ingredients only)
  //
  // Called when admin saves a menu item (add or edit).
  //
  //   newQty > oldQty  →  consumed more  →  stock DECREASES
  //   newQty < oldQty  →  consumed less  →  stock INCREASES (refund)
  //   newQty == oldQty →  no change
  //
  // Only docs with type == 'ingredient' are touched.
  // ─────────────────────────────────────────────
  static Future<void> applyRecipeStockDelta({
    required List<RecipeIngredient> oldRecipe,
    required List<RecipeIngredient> newRecipe,
  }) async {
    // Collapse duplicate rows by summing qty per ingredientId.
    final oldMap = <String, double>{};
    for (final r in oldRecipe) {
      if (r.ingredientId.isEmpty) continue;
      oldMap[r.ingredientId] =
          (oldMap[r.ingredientId] ?? 0) + r.qtyPerPortion;
    }
    final newMap = <String, double>{};
    for (final r in newRecipe) {
      if (r.ingredientId.isEmpty) continue;
      newMap[r.ingredientId] =
          (newMap[r.ingredientId] ?? 0) + r.qtyPerPortion;
    }

    final ids = <String>{...oldMap.keys, ...newMap.keys};
    if (ids.isEmpty) return;

    debugPrint('[InventoryService] applyRecipeStockDelta');
    debugPrint('  oldMap = $oldMap');
    debugPrint('  newMap = $newMap');

    await _db.runTransaction((tx) async {
      final snaps = <String, DocumentSnapshot>{};
      for (final id in ids) {
        snaps[id] = await tx.get(_inv.doc(id));
      }

      for (final id in ids) {
        final snap = snaps[id]!;
        if (!snap.exists) {
          debugPrint('  skip $id — doc missing');
          continue;
        }

        final data = snap.data() as Map<String, dynamic>? ?? {};
        final type =
            (data['type'] ?? 'ingredient').toString().toLowerCase();
        if (type != 'ingredient') {
          debugPrint('  skip $id — type=$type');
          continue;
        }

        final current = (data['stock'] as num?)?.toDouble() ?? 0;
        final oldQty = oldMap[id] ?? 0;
        final newQty = newMap[id] ?? 0;

        // Positive = more consumed → subtract from stock.
        // Negative = refund → add back to stock.
        final consumedDelta = newQty - oldQty;
        if (consumedDelta == 0) {
          debugPrint('  $id — no change');
          continue;
        }

        final next =
            (current - consumedDelta).clamp(0, double.infinity);

        debugPrint(
            '  $id: $current → $next (delta = $consumedDelta)');

        tx.update(_inv.doc(id), {
          'stock': next,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // ─────────────────────────────────────────────
  // RESTOCK / ADJUST (works for both types)
  // ─────────────────────────────────────────────
  static Future<void> adjustStock(String id, double delta) async {
    await _db.runTransaction((tx) async {
      final ref = _inv.doc(id);
      final snap = await tx.get(ref);
      if (!snap.exists) return;
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
  // DEDUCT when an order is placed (INGREDIENTS)
  //
  // With the "deduct on menu add/edit" flow, ingredient stock
  // already moves when the admin edits a recipe. Do NOT call
  // this from your checkout if you want ingredients to move
  // only at menu-edit time.
  // ─────────────────────────────────────────────
  static Future<void> deductForOrder(Map<String, int> portions) async {
    final deductions = <String, double>{};

    for (final entry in portions.entries) {
      final menuDoc =
          await _db.collection('menu_items').doc(entry.key).get();
      if (!menuDoc.exists) continue;
      final menu = MenuItemModel.fromMap(menuDoc.id, menuDoc.data()!);
      for (final r in menu.recipe) {
        if (r.ingredientId.isEmpty) continue;
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
        if (!snaps[id]!.exists) continue;
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
  // Used at checkout. Does NOT touch ingredients.
  // ─────────────────────────────────────────────
  static Future<void> deductSupplies(Map<String, double> supplies) async {
    if (supplies.isEmpty) return;
    await _db.runTransaction((tx) async {
      final snaps = <String, DocumentSnapshot>{};
      for (final id in supplies.keys) {
        snaps[id] = await tx.get(_inv.doc(id));
      }
      for (final id in supplies.keys) {
        if (!snaps[id]!.exists) continue;
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
      if (r.ingredientId.isEmpty) continue;
      final snap = await _inv.doc(r.ingredientId).get();
      if (!snap.exists) return 0;
      final stock =
          ((snap.data() as Map?)?['stock'] as num?)?.toDouble() ?? 0;
      final possible = (stock / r.qtyPerPortion).floor();
      if (possible < best) best = possible;
    }
    return best == (1 << 30) ? 0 : best;
  }
}