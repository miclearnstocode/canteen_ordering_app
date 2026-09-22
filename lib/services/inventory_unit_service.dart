import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_unit_model.dart';

class InventoryUnitService {
  static final _db = FirebaseFirestore.instance;
  static CollectionReference get _units =>
      _db.collection('inventory_units');

  static const List<String> _defaultUnits = [
    'pcs',
    'kg',
    'g',
    'L',
    'mL',
    'pack',
    'dozen',
  ];

  static Stream<List<InventoryUnitModel>> unitsStream() {
    return _units.orderBy('name').snapshots().map((s) => s.docs
        .map((d) => InventoryUnitModel.fromMap(
            d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  /// One-shot fetch (used by picker dialogs).
  static Future<List<String>> allUnitNames() async {
    final snap = await _units.orderBy('name').get();
    if (snap.docs.isEmpty) {
      await _seedDefaults();
      final again = await _units.orderBy('name').get();
      return again.docs
          .map((d) => (d.data() as Map)['name'] as String)
          .toList();
    }
    return snap.docs
        .map((d) => (d.data() as Map)['name'] as String)
        .toList();
  }

  static Future<String> ensureUnit(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) return 'pcs';

    // Case-insensitive lookup.
    final existing = await _units
        .where('nameLower', isEqualTo: name.toLowerCase())
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return (existing.docs.first.data() as Map)['name'] as String;
    }

    await _units.add({
      'name': name,
      'nameLower': name.toLowerCase(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return name;
  }

  /// Seeds default units — only if the collection is empty.
  static Future<void> _seedDefaults() async {
    final check = await _units.limit(1).get();
    if (check.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final u in _defaultUnits) {
      final ref = _units.doc();
      batch.set(ref, {
        'name': u,
        'nameLower': u.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Optional — call from a debug screen to populate defaults.
  static Future<void> seedDefaultsIfEmpty() => _seedDefaults();
}