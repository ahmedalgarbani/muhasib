import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/features/inventory_reports/domain/entities/items_balance_entity.dart';
import 'package:muhasib/features/inventory_reports/presentation/cubit/items_balance_cubit.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';

class ItemsBalanceReportPage extends StatefulWidget {
  const ItemsBalanceReportPage({super.key});

  @override
  State<ItemsBalanceReportPage> createState() => _ItemsBalanceReportPageState();
}

class _ItemsBalanceReportPageState extends State<ItemsBalanceReportPage> {
  int? _selectedWarehouseId;
  bool _showSearch = false;
  final TextEditingController _searchCtrl = TextEditingController();
  List<ItemsBalanceEntity> _lastList = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _exportPdf(List<ItemsBalanceEntity> list) async {
    final headers = ['الصنف', 'الكمية', 'الوارد', 'المنصرف', 'التكلفة'];
    final data = list
        .map((e) => [
              '${e.productName} - ${e.unitName}',
              e.currentQuantity.toStringAsFixed(0),
              e.totalInbound.toStringAsFixed(0),
              e.totalOutbound.toStringAsFixed(0),
              e.unitCost.toStringAsFixed(2),
            ])
        .toList();
    await ExportService.printData(
      title: 'إجمالي الأصناف في المخازن',
      headers: headers,
      data: data,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ItemsBalanceCubit>()..loadBalances()),
        BlocProvider(create: (_) => getIt<WarehousesCubit>()..loadActiveWarehouses()),
      ],
      child: Builder(
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: AppColors.neutral100,
            appBar: CustomAppBar(
              title: 'الأصناف في المخازن',
              actions: [
                IconButton(
                  icon: Icon(_showSearch ? Icons.close : Icons.search),
                  onPressed: () => setState(() => _showSearch = !_showSearch),
                  tooltip: 'بحث',
                ),
                IconButton(
                  icon: const Icon(Icons.filter_alt_outlined),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('اختر المخزن من الشريط أدناه'))),
                  tooltip: 'تصفية',
                ),
                BlocBuilder<ItemsBalanceCubit, ItemsBalanceState>(
                  builder: (context, state) {
                    final hasData = state is ItemsBalanceLoaded && state.balances.isNotEmpty;
                    return IconButton(
                      icon: const Icon(Icons.picture_as_pdf),
                      onPressed: hasData
                          ? () => _exportPdf((state as ItemsBalanceLoaded).balances)
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
                      hint: 'بحث باسم الصنف أو الباركود...',
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  context.read<ItemsBalanceCubit>().updateSearch('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (v) => context.read<ItemsBalanceCubit>().updateSearch(v),
                    ),
                  ),
                _WarehouseChipsBalance(
                  selectedId: _selectedWarehouseId,
                  onSelected: (id) {
                    setState(() => _selectedWarehouseId = id);
                    context.read<ItemsBalanceCubit>().filterByWarehouse(id);
                  },
                ),
                // Table header
                Container(
                  color: AppColors.materialDeepOrange500,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: Text('الصنف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(flex: 1, child: Text('الكمية', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(flex: 1, child: Text('الوارد', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(flex: 1, child: Text('المنصرف', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(flex: 1, child: Text('التكلفة', textAlign: TextAlign.end, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocConsumer<ItemsBalanceCubit, ItemsBalanceState>(
                    listener: (context, state) {
                      if (state is ItemsBalanceLoaded) _lastList = state.balances;
                    },
                    builder: (context, state) {
                      if (state is ItemsBalanceLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is ItemsBalanceError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                              const SizedBox(height: 8),
                              Text(state.message),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => context.read<ItemsBalanceCubit>().refresh(),
                                icon: const Icon(Icons.refresh),
                                label: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        );
                      }
                      if (state is ItemsBalanceEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('لا توجد أرصدة', style: TextStyle(color: Colors.grey)),
                              Text('لا توجد أصناف مطابقة للفلتر', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        );
                      }
                      if (state is ItemsBalanceLoaded) {
                        final list = state.balances;
                        return RefreshIndicator(
                          onRefresh: () async => context.read<ItemsBalanceCubit>().refresh(),
                          child: ListView.separated(
                            padding: AppConstant.defaultPadding,
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (context, i) {
                              final e = list[i];
                              return _BalanceRow(balance: e);
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
      ),
    );
  }
}

class _WarehouseChipsBalance extends StatelessWidget {
  final int? selectedId;
  final ValueChanged<int?> onSelected;
  const _WarehouseChipsBalance({required this.selectedId, required this.onSelected});

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
                  selectedColor: AppColors.materialDeepOrange500.withOpacity(0.15),
                ),
                const SizedBox(width: 8),
                ...warehouses.map((w) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (w.isMainStock) const Icon(Icons.star, size: 14, color: Colors.amber),
                            if (w.isMainStock) const SizedBox(width: 4),
                            Text(w.name, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        selected: selectedId == w.id,
                        onSelected: (_) => onSelected(w.id),
                        selectedColor: AppColors.materialDeepOrange500.withOpacity(0.15),
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final ItemsBalanceEntity balance;
  const _BalanceRow({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${balance.productName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 2),
                Text(balance.unitName, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              balance.currentQuantity.toStringAsFixed(0),
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue[700]),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              balance.totalInbound.toStringAsFixed(0),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              balance.totalOutbound.toStringAsFixed(0),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.red[700], fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              balance.unitCost.toStringAsFixed(0),
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 12, color: Colors.grey[800], fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
