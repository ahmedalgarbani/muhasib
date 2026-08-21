import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/features/inventory_reports/domain/entities/item_movement_entity.dart';
import 'package:muhasib/features/inventory_reports/presentation/cubit/item_movement_cubit.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';

class ItemMovementReportPage extends StatefulWidget {
  const ItemMovementReportPage({super.key});

  @override
  State<ItemMovementReportPage> createState() => _ItemMovementReportPageState();
}

class _ItemMovementReportPageState extends State<ItemMovementReportPage> {
  late final ItemMovementCubit _itemMovementCubit;
  late final WarehousesCubit _warehousesCubit;
  int? _selectedWarehouseId;
  bool _showSearch = false;
  final TextEditingController _searchCtrl = TextEditingController();
  List<ItemMovementEntity> _lastList = [];

  @override
  void initState() {
    super.initState();
    _itemMovementCubit = getIt<ItemMovementCubit>()..loadMovements();
    _warehousesCubit = getIt<WarehousesCubit>()..loadActiveWarehouses();
  }

  @override
  void dispose() {
    _itemMovementCubit.close();
    _warehousesCubit.close();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _exportPdf(List<ItemMovementEntity> list) async {
    final headers = ['الصنف', 'الكمية', 'التكلفة', 'المخزن', 'المستند'];
    final data = list
        .map((e) => [
              '${e.productName} - ${e.unitName}',
              '${e.quantity > 0 ? '+' : ''}${e.quantity}',
              e.unitCost.toStringAsFixed(2),
              e.warehouseName,
              e.documentLabel,
            ])
        .toList();
    await ExportService.printData(
      title: 'حركة الأصناف',
      headers: headers,
      data: data,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _itemMovementCubit),
        BlocProvider.value(value: _warehousesCubit),
      ],
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.neutral100,
          appBar: CustomAppBar(
            title: 'حركة الأصناف',
            actions: [
              IconButton(
                icon: Icon(_showSearch ? Icons.close : Icons.search),
                onPressed: () => setState(() => _showSearch = !_showSearch),
                tooltip: 'بحث',
              ),
              IconButton(
                icon: const Icon(Icons.filter_alt_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تصفية المخزن عبر الشريط أدناه')),
                  );
                },
                tooltip: 'تصفية',
              ),
              BlocBuilder<ItemMovementCubit, ItemMovementState>(
                bloc: _itemMovementCubit,
                builder: (context, state) {
                  final hasData = state is ItemMovementLoaded && state.movements.isNotEmpty;
                  return IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    onPressed: hasData
                        ? () => _exportPdf(state.movements)
                        : _lastList.isEmpty
                            ? null
                            : () => _exportPdf(_lastList),
                    tooltip: 'تصدير PDF',
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              if (_showSearch)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: TextInputField(
                    controller: _searchCtrl,
                    hint: 'بحث باسم الصنف، الباركود أو رقم المستند...',
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                _itemMovementCubit.updateSearch('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      fillColor: Colors.grey[50],
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (v) => _itemMovementCubit.updateSearch(v),
                  ),
                ),
              _WarehouseChips(
                selectedId: _selectedWarehouseId,
                onSelected: (id) {
                  setState(() => _selectedWarehouseId = id);
                  _itemMovementCubit.filterByWarehouse(id);
                },
              ),
              // Table header
              Container(
                color: AppColors.materialBlue700,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: const Row(
                    children: [
                      Expanded(flex: 3, child: Text('الصنف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 2, child: Text('الكمية', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 2, child: Text('التكلفة', textAlign: TextAlign.end, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocConsumer<ItemMovementCubit, ItemMovementState>(
                    listener: (context, state) {
                      if (state is ItemMovementLoaded) _lastList = state.movements;
                    },
                    builder: (context, state) {
                      if (state is ItemMovementLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is ItemMovementError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                              const SizedBox(height: 8),
                              Text(state.message, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _itemMovementCubit.refresh(),
                                icon: const Icon(Icons.refresh),
                                label: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        );
                      }
                      if (state is ItemMovementEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('لا توجد حركات', style: TextStyle(color: Colors.grey)),
                              Text('لا توجد حركات مخزنية مطابقة للفلتر الحالي', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        );
                      }
                      if (state is ItemMovementLoaded) {
                        final list = state.movements;
                        return RefreshIndicator(
                          onRefresh: () async => _itemMovementCubit.refresh(),
                          child: ListView.separated(
                            padding: AppConstant.defaultPadding,
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final e = list[i];
                              return _MovementCard(movement: e);
                            },
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

class _WarehouseChips extends StatelessWidget {
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  const _WarehouseChips({required this.selectedId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WarehousesCubit, WarehousesState>(
      builder: (context, state) {
        List<WarehouseEntity> warehouses = [];
        if (state is WarehousesLoaded) warehouses = state.warehouses;

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('الكل'),
                  selected: selectedId == null,
                  onSelected: (_) => onSelected(null),
                  selectedColor: AppColors.materialBlue700.withValues(alpha: 0.15),
                ),
                const SizedBox(width: 8),
                ...warehouses.map((w) {
                  final isSelected = selectedId == w.id;
                  final isMain = w.isMainStock;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isMain) const Icon(Icons.star, size: 14, color: Colors.amber),
                          if (isMain) const SizedBox(width: 4),
                          Text(w.name),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (_) => onSelected(w.id),
                      selectedColor: AppColors.materialBlue700.withValues(alpha: 0.15),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MovementCard extends StatelessWidget {
  final ItemMovementEntity movement;
  const _MovementCard({required this.movement});

  @override
  Widget build(BuildContext context) {
    final isIn = movement.isInbound;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Icon(
                  isIn ? Icons.call_received : Icons.call_made,
                  size: 14,
                  color: isIn ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    movement.documentLabel,
                    style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isIn ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isIn ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    movement.directionLabel,
                    style: TextStyle(fontSize: 11, color: isIn ? Colors.green[700] : Colors.red[700], fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Right: product + warehouse + date
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${movement.productName} - ${movement.unitName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.warehouse, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              movement.warehouseName,
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            movement.formattedDate,
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Middle: quantity with badge
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Text(
                        '${movement.quantity.abs().toInt()}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isIn ? Colors.green[700] : Colors.red[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isIn ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          movement.directionLabel,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                // Left: unit cost
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'التكلفة',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        movement.unitCost.toStringAsFixed(0),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[700]),
                      ),
                    ],
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
