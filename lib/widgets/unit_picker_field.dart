import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/inventory_unit_service.dart';

class UnitPickerField extends StatefulWidget {
  const UnitPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Unit',
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String label;

  @override
  State<UnitPickerField> createState() => _UnitPickerFieldState();
}

class _UnitPickerFieldState extends State<UnitPickerField> {
  static const _addNewSentinel = '__add_new__';

  List<String> _units = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    try {
      final list = await InventoryUnitService.allUnitNames();
      if (!mounted) return;
      setState(() {
        _units = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _handleAddNew() async {
    final newUnit = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('Add New Unit',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Unit name',
              hintText: 'e.g. bottle, sack, tray',
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (newUnit == null || newUnit.isEmpty) return;

    final canonical = await InventoryUnitService.ensureUnit(newUnit);
    await _loadUnits();

    if (!mounted) return;
    widget.onChanged(canonical);
  }

  @override
  Widget build(BuildContext context) {
    final items = <String>{..._units};
    if (widget.value.isNotEmpty) items.add(widget.value);
    final sorted = items.toList()..sort();

    return DropdownButtonFormField<String>(
      initialValue: sorted.contains(widget.value) ? widget.value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: _loading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      items: [
        ...sorted.map((u) => DropdownMenuItem<String>(
              value: u,
              child: Text(u),
            )),
        const DropdownMenuItem<String>(
          value: _addNewSentinel,
          child: Row(
            children: [
              Icon(Icons.add, size: 16, color: Color(0xFF5E35B1)),
              SizedBox(width: 6),
              Text('Add new…',
                  style: TextStyle(
                    color: Color(0xFF5E35B1),
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),
      ],
      onChanged: (v) {
        if (v == null) return;
        if (v == _addNewSentinel) {
          _handleAddNew();
        } else {
          widget.onChanged(v);
        }
      },
    );
  }
}