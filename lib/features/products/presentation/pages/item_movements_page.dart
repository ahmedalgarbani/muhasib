import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/products/domain/entities/item_movement_entity.dart';
import 'package:muhasib/features/products/presentation/cubit/item_movements_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:intl/intl.dart';

class ItemMovementsPage extends StatefulWidget {
  const ItemMovementsPage({Key? key}) : super(key: key);

  @override
  State<ItemMovementsPage> createState() => _ItemMovementsPageState();
}

class _ItemMovementsPageState extends State<ItemMovementsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  int? _selectedProductFilter;
  int? _selectedTypeFilter;
  DateTimeRange? _selectedDateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<ItemMovementsCubit>()..loadAllMovements(),
        ),
        BlocProvider(
          create: (context) => getIt<ProductsCubit>()..loadProducts(),
        ),
      ],
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: 
AppColors.gray50,
        appBar: CustomAppBar(
        ),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: BlocBuilder<ItemMovementsCubit, ItemMovementsState>(
                builder: (context, state) {
                  if (state is ItemMovementsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ItemMovementsError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  } else if (state is ItemMovementsLoaded) {
                    if (state.movements.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildMovementsList(state.movements);
                  }
                  return const Center(child: Text('لا توجد حركات'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'حركات المخزون',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث في الحركات...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      context.read<ItemMovementsCubit>().searchMovements(value);
                    } else {
                      context.read<ItemMovementsCubit>().loadAllMovements();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDateRange(context),
                tooltip: 'تصفية بالتاريخ',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              BlocBuilder<ProductsCubit, ProductsState>(
                builder: (context, productsState) {
                  if (productsState is ProductsLoaded) {
                    return Expanded(
                      child: DropdownButton<int?>(
                        value: _selectedProductFilter,
                        hint: const Text('كل المنتجات'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('كل المنتجات'),
                          ),
                          ...productsState.products.map(
                            (product) => DropdownMenuItem(
                              value: product.id,
                              child: Text(product.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedProductFilter = value);
                          if (value != null) {
                            context
                                .read<ItemMovementsCubit>()
                                .loadMovementsByProduct(value);
                          } else {
                            context
                                .read<ItemMovementsCubit>()
                                .loadAllMovements();
                          }
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<int?>(
                  value: _selectedTypeFilter,
                  hint: const Text('نوع الحركة'),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('كل الحركات')),
                    DropdownMenuItem(value: 1, child: Text('فاتورة مبيعات')),
                    DropdownMenuItem(value: 2, child: Text('فاتورة مشتريات')),
                    DropdownMenuItem(value: 3, child: Text('عرض سعر')),
                    DropdownMenuItem(value: 4, child: Text('مرتجع مبيعات')),
                    DropdownMenuItem(value: 5, child: Text('مرتجع مشتريات')),
                    DropdownMenuItem(value: 6, child: Text('تحويل مخزني')),
                    DropdownMenuItem(value: 7, child: Text('جرد مخزني')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedTypeFilter = value);
                    if (value != null) {
                      context.read<ItemMovementsCubit>().loadMovementsByType(
                        value,
                      );
                    } else {
                      context.read<ItemMovementsCubit>().loadAllMovements();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMovementsList(List<ItemMovementEntity> movements) {
    // Calculate running balance
    double runningBalance = 0;
    final movementsWithBalance = movements.map((movement) {
      runningBalance += movement.netQuantity;
      return {'movement': movement, 'balance': runningBalance};
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: movementsWithBalance.length,
      itemBuilder: (context, index) {
        final item = movementsWithBalance[index];
        final movement = item['movement'] as ItemMovementEntity;
        final balance = item['balance'] as double;
        final date = DateTime.fromMillisecondsSinceEpoch(
          movement.transDate * 1000,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: movement.transInOut
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            movement.transInOut
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: movement.transInOut
                                ? Colors.green
                                : Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movement.movementTypeString,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'رقم المستند: ${movement.docNo}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      DateFormat('yyyy-MM-dd').format(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(movement.statement, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildQuantityChip(
                          'دخول',
                          movement.quantityIn,
                          Colors.green,
                        ),
                        const SizedBox(width: 8),
                        _buildQuantityChip(
                          'خروج',
                          movement.quantityOut,
                          Colors.red,
                        ),
                        const SizedBox(width: 8),
                        _buildQuantityChip(
                          'الصافي',
                          movement.netQuantity,
                          movement.netQuantity >= 0
                              ? Colors.blue
                              : Colors.orange,
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          const Text('الرصيد:', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            balance.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: balance >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (movement.sellAmount != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'السعر: ${movement.sellAmount?.toStringAsFixed(2) ?? '0'} ${movement.currencyCode ?? 'ر.س'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (movement.costAmount != null) ...[
                        const SizedBox(width: 16),
                        Text(
                          'التكلفة: ${movement.costAmount?.toStringAsFixed(2)} ${movement.currencyCode ?? 'ر.س'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuantityChip(String label, double quantity, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(width: 4),
          Text(
            quantity.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.swap_vert_circle_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد حركات مخزون',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر هنا جميع حركات المخزون',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      locale: const Locale('ar'),
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      context.read<ItemMovementsCubit>().loadMovementsByDateRange(
        picked.start,
        picked.end,
      );
    }
  }
}
