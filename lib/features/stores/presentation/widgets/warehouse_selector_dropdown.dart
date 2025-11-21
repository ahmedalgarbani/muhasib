import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';

class WarehouseSelectorDropdown extends StatefulWidget {
  final WarehouseEntity? selectedWarehouse;
  final ValueChanged<WarehouseEntity?> onChanged;
  final String? label;
  final String? hint;
  final bool showOnlyActive;
  final bool showMainFirst;
  final FormFieldValidator<WarehouseEntity>? validator;
  final bool enabled;
  final Widget? prefixIcon;

  const WarehouseSelectorDropdown({
    super.key,
    this.selectedWarehouse,
    required this.onChanged,
    this.label,
    this.hint,
    this.showOnlyActive = true,
    this.showMainFirst = true,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
  });

  @override
  State<WarehouseSelectorDropdown> createState() => _WarehouseSelectorDropdownState();
}

class _WarehouseSelectorDropdownState extends State<WarehouseSelectorDropdown> {
  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  void _loadWarehouses() {
    final cubit = context.read<WarehousesCubit>();
    if (widget.showOnlyActive) {
      cubit.loadActiveWarehouses();
    } else {
      cubit.loadWarehouses();
    }
  }

  List<WarehouseEntity> _sortWarehouses(List<WarehouseEntity> warehouses) {
    if (!widget.showMainFirst) return warehouses;
    
    final sorted = List<WarehouseEntity>.from(warehouses);
    sorted.sort((a, b) {
      if (a.isMainStock && !b.isMainStock) return -1;
      if (!a.isMainStock && b.isMainStock) return 1;
      return a.name.compareTo(b.name);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WarehousesCubit, WarehousesState>(
      builder: (context, state) {
        List<WarehouseEntity> warehouses = [];
        bool isLoading = false;
        String? errorMessage;

        if (state is WarehousesLoading) {
          isLoading = true;
        } else if (state is WarehousesLoaded) {
          warehouses = _sortWarehouses(state.warehouses);
        } else if (state is WarehousesError) {
          errorMessage = state.message;
        }

        return DropdownButtonFormField<WarehouseEntity>(
          value: widget.selectedWarehouse,
          decoration: InputDecoration(
            labelText: widget.label ?? 'المخزن',
            hintText: widget.hint ?? 'اختر المخزن',
            prefixIcon: widget.prefixIcon ?? const Icon(Icons.warehouse),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: widget.enabled ? Colors.grey[50] : Colors.grey[200],
            errorText: errorMessage,
            suffixIcon: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          items: warehouses.map((warehouse) {
            return DropdownMenuItem<WarehouseEntity>(
              value: warehouse,
              child: Row(
                children: [
                  if (warehouse.isMainStock)
                    const Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    ),
                  if (warehouse.isMainStock) const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      warehouse.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!warehouse.isActive)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'غير نشط',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: widget.enabled ? widget.onChanged : null,
          validator: widget.validator,
          isExpanded: true,
        );
      },
    );
  }
}

class WarehouseSearchableDropdown extends StatefulWidget {
  final WarehouseEntity? selectedWarehouse;
  final ValueChanged<WarehouseEntity?> onChanged;
  final String? label;
  final bool showOnlyActive;
  final FormFieldValidator<WarehouseEntity>? validator;

  const WarehouseSearchableDropdown({
    super.key,
    this.selectedWarehouse,
    required this.onChanged,
    this.label,
    this.showOnlyActive = true,
    this.validator,
  });

  @override
  State<WarehouseSearchableDropdown> createState() => _WarehouseSearchableDropdownState();
}

class _WarehouseSearchableDropdownState extends State<WarehouseSearchableDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  List<WarehouseEntity> _filteredWarehouses = [];
  List<WarehouseEntity> _allWarehouses = [];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.selectedWarehouse?.name ?? '';
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _searchController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _filterWarehouses(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredWarehouses = _allWarehouses;
      } else {
        _filteredWarehouses = _allWarehouses
            .where((warehouse) =>
                warehouse.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
    _overlayEntry?.markNeedsBuild();
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 5,
        width: size.width,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _filteredWarehouses.length,
              itemBuilder: (context, index) {
                final warehouse = _filteredWarehouses[index];
                return ListTile(
                  leading: Icon(
                    warehouse.isMainStock ? Icons.star : Icons.warehouse,
                    color: warehouse.isMainStock
                        ? Colors.amber
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(warehouse.name),
                  subtitle: warehouse.address != null
                      ? Text(
                          warehouse.address!,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: !warehouse.isActive
                      ? const Chip(
                          label: Text(
                            'غير نشط',
                            style: TextStyle(fontSize: 10),
                          ),
                          backgroundColor: Colors.grey,
                          padding: EdgeInsets.zero,
                        )
                      : null,
                  onTap: () {
                    widget.onChanged(warehouse);
                    _searchController.text = warehouse.name;
                    _focusNode.unfocus();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WarehousesCubit, WarehousesState>(
      builder: (context, state) {
        if (state is WarehousesLoaded) {
          _allWarehouses = state.warehouses;
          if (_filteredWarehouses.isEmpty) {
            _filteredWarehouses = _allWarehouses;
          }
        }

        return TextFormField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.label ?? 'المخزن',
            hintText: 'ابحث عن المخزن',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: state is WarehousesLoading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      widget.onChanged(null);
                      _filterWarehouses('');
                    },
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          onChanged: _filterWarehouses,
          validator: widget.validator != null
              ? (value) {
                  final selected = _allWarehouses.firstWhere(
                    (w) => w.name == value,
                    orElse: () => WarehouseEntity(
                      id: -1,
                      name: '',
                      address: '',
                      isActive: false,
                      isMainStock: false,
                    ),
                  );
                  if (selected.id == -1) {
                    return 'يرجى اختيار مخزن صحيح';
                  }
                  return widget.validator!(selected);
                }
              : null,
        );
      },
    );
  }
}
