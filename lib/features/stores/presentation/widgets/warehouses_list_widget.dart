import 'package:flutter/material.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/presentation/widgets/warehouse_card_widget.dart';

/// Standalone Warehouses List Widget with search field and warehouse card items.
class WarehousesListWidget extends StatelessWidget {
  final List<WarehouseEntity> warehouses;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final Function(WarehouseEntity) onWarehouseTap;
  final Function(WarehouseEntity) onWarehouseEdit;
  final Function(WarehouseEntity) onWarehouseSetMain;
  final Function(WarehouseEntity) onWarehouseDelete;

  const WarehousesListWidget({
    super.key,
    required this.warehouses,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onWarehouseTap,
    required this.onWarehouseEdit,
    required this.onWarehouseSetMain,
    required this.onWarehouseDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextInputField(
            controller: searchController,
            hint: 'بحث في المخازن...',
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClearSearch,
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: warehouses.length,
            itemBuilder: (context, index) {
              final warehouse = warehouses[index];
              return WarehouseCardWidget(
                warehouse: warehouse,
                onTap: () => onWarehouseTap(warehouse),
                onEdit: () => onWarehouseEdit(warehouse),
                onSetMain: () => onWarehouseSetMain(warehouse),
                onDelete: () => onWarehouseDelete(warehouse),
              );
            },
          ),
        ),
      ],
    );
  }
}
