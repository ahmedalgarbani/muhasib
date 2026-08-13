import 'package:flutter/material.dart';
import 'package:muhasib/core/services/unit_conversion_service.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';

/// Widget for selecting product unit in invoice lines
/// Displays available units for a product and handles conversion
class ProductUnitSelector extends StatefulWidget {
  final int productId;
  final double quantity;
  final UnitConversionService unitConversionService;
  final Function(UnitSelectionResult) onUnitSelected;
  final int? initialUnitId;

  const ProductUnitSelector({
    super.key,
    required this.productId,
    required this.quantity,
    required this.unitConversionService,
    required this.onUnitSelected,
    this.initialUnitId,
  });

  @override
  State<ProductUnitSelector> createState() => _ProductUnitSelectorState();
}

class _ProductUnitSelectorState extends State<ProductUnitSelector> {
  List<ProductUnitOption> _units = [];
  ProductUnitOption? _selectedUnit;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  @override
  void didUpdateWidget(covariant ProductUnitSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      _loadUnits();
    } else if (oldWidget.quantity != widget.quantity && _selectedUnit != null) {
      _notifySelection(_selectedUnit!);
    }
  }

  Future<void> _loadUnits() async {
    setState(() => _isLoading = true);

    try {
      final units = await widget.unitConversionService.getUnitsForProduct(
        widget.productId,
      );

      setState(() {
        _units = units;
        _isLoading = false;

        // Select initial unit or main unit
        if (units.isNotEmpty) {
          if (widget.initialUnitId != null) {
            _selectedUnit = units.firstWhere(
              (u) => u.unitId == widget.initialUnitId,
              orElse: () => units.first,
            );
          } else {
            // Select main unit by default
            _selectedUnit = units.firstWhere(
              (u) => u.isMainUnit,
              orElse: () => units.first,
            );
          }
          _notifySelection(_selectedUnit!);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _units = [];
      });
    }
  }

  void _notifySelection(ProductUnitOption unit) {
    final baseQuantity = widget.quantity * unit.totalConversion;

    widget.onUnitSelected(
      UnitSelectionResult(
        unitId: unit.unitId,
        unitName: unit.unitName,
        unitShort: unit.unitShort,
        quantity: widget.quantity,
        baseQuantity: baseQuantity,
        conversionRate: unit.conversionRate,
        packaging: unit.packaging,
        isMainUnit: unit.isMainUnit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_units.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: const Text('وحدة', style: TextStyle(color: Colors.grey)),
      );
    }

    if (_units.length == 1) {
      // Only one unit, show as text
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          _units.first.unitShort,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      );
    }

    return CustomDropdownField<ProductUnitOption>(
      value: _selectedUnit,
      label: 'الوحدة',
      items: _units
          .map(
            (unit) => DropdownMenuItem(
              value: unit,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(unit.unitShort),
                  if (!unit.isMainUnit) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(${unit.packaging})',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (unit) {
        if (unit != null) {
          setState(() => _selectedUnit = unit);
          _notifySelection(unit);
        }
      },
    );
  }
}

/// Result of unit selection with conversion data
class UnitSelectionResult {
  final int? unitId;
  final String unitName;
  final String unitShort;
  final double quantity;
  final double baseQuantity;
  final double conversionRate;
  final int packaging;
  final bool isMainUnit;

  UnitSelectionResult({
    this.unitId,
    required this.unitName,
    required this.unitShort,
    required this.quantity,
    required this.baseQuantity,
    required this.conversionRate,
    required this.packaging,
    required this.isMainUnit,
  });

  /// Create invoice line data with conversion info
  Map<String, dynamic> toInvoiceLineData() {
    return {
      'unit_id': unitId,
      'quantity': quantity,
      'base_quantity': baseQuantity,
      'conversion_rate': conversionRate,
      'packaging': packaging,
    };
  }
}

/// Helper extension to add unit conversion fields to invoice line
extension InvoiceLineUnitExtension on Map<String, dynamic> {
  /// Apply unit selection result to invoice line data
  void applyUnitSelection(UnitSelectionResult result) {
    this['unit_id'] = result.unitId;
    this['quantity'] = result.quantity;
    this['base_quantity'] = result.baseQuantity;
    this['conversion_rate'] = result.conversionRate;
    this['packaging'] = result.packaging;
  }
}
