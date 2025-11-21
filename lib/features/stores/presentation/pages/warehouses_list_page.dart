import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';

class WarehousesListPage extends StatelessWidget {
  const WarehousesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<WarehousesCubit>()..loadWarehouses(),
      child: const _WarehousesListView(),
    );
  }
}

class _WarehousesListView extends StatefulWidget {
  const _WarehousesListView();

  @override
  State<_WarehousesListView> createState() => _WarehousesListViewState();
}

class _WarehousesListViewState extends State<_WarehousesListView> {
  final TextEditingController _searchController = TextEditingController();
  bool _showActiveOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CustomAppBar(
        title: 'المخازن',
        actions: [
          IconButton(
            icon: Icon(_showActiveOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () {
              setState(() => _showActiveOnly = !_showActiveOnly);
              if (_showActiveOnly) {
                context.read<WarehousesCubit>().loadActiveWarehouses();
              } else {
                context.read<WarehousesCubit>().loadWarehouses();
              }
            },
            tooltip: _showActiveOnly ? 'عرض الكل' : 'النشطة فقط',
          ),
        ],
      ),
      body: BlocConsumer<WarehousesCubit, WarehousesState>(
        listener: (context, state) {
          if (state is WarehouseCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إضافة المخزن بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is WarehouseUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تحديث المخزن بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is WarehouseDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم حذف المخزن بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is MainWarehouseSet) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تعيين المخزن الرئيسي بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is WarehousesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is WarehousesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is WarehousesLoaded) {
            if (state.warehouses.isEmpty) {
              return _buildEmptyState();
            }
            return _buildWarehousesList(state.warehouses);
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.pushNamed(AppRoutes.warehouseForm);
          if (result == true && mounted) {
            context.read<WarehousesCubit>().loadWarehouses();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('مخزن جديد'),
        backgroundColor: const Color(0xFF1976D2),
      ),
    );
  }

  Widget _buildWarehousesList(List<WarehouseEntity> warehouses) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'بحث في المخازن...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<WarehousesCubit>().loadWarehouses();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              if (value.isEmpty) {
                context.read<WarehousesCubit>().loadWarehouses();
              } else {
                context.read<WarehousesCubit>().searchWarehouses(value);
              }
            },
          ),
        ),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: warehouses.length,
            itemBuilder: (context, index) {
              return _buildWarehouseCard(warehouses[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWarehouseCard(WarehouseEntity warehouse) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          final result = await context.pushNamed(
            AppRoutes.warehouseForm,
            extra: warehouse,
          );
          if (result == true && context.mounted) {
            context.read<WarehousesCubit>().loadWarehouses();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: warehouse.isMainStock
                          ? const Color(0xFF1976D2).withOpacity(0.1)
                          : const Color(0xFF00897B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      warehouse.isMainStock ? Icons.home_work : Icons.warehouse,
                      color: warehouse.isMainStock
                          ? const Color(0xFF1976D2)
                          : const Color(0xFF00897B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                warehouse.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (warehouse.isMainStock)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1976D2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'رئيسي',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              warehouse.isActive
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 16,
                              color: warehouse.isActive
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              warehouse.isActive ? 'نشط' : 'غير نشط',
                              style: TextStyle(
                                color: warehouse.isActive
                                    ? Colors.green
                                    : Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions menu
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('تعديل'),
                          ],
                        ),
                      ),
                      if (!warehouse.isMainStock)
                        const PopupMenuItem(
                          value: 'setMain',
                          child: Row(
                            children: [
                              Icon(Icons.star, size: 20),
                              SizedBox(width: 8),
                              Text('تعيين كرئيسي'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('حذف', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showWarehouseDialog(context, warehouse: warehouse);
                      } else if (value == 'setMain') {
                        _showSetMainWarehouseDialog(context, warehouse);
                      } else if (value == 'delete') {
                        _showDeleteDialog(context, warehouse);
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Address
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      warehouse.address,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

              // Manager (if exists)
              if (warehouse.managerName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'المدير: ${warehouse.managerName}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],

              // Capacity (if exists)
              if (warehouse.capacity != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.storage, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'السعة: ${warehouse.capacity} م³',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warehouse_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد مخازن',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على الزر أدناه لإضافة مخزن جديد',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showWarehouseDialog(BuildContext context, {WarehouseEntity? warehouse}) async {
    final result = await context.pushNamed(
      AppRoutes.warehouseForm,
      extra: warehouse,
    );
    if (!mounted) return;
    if (result == true) {
      context.read<WarehousesCubit>().loadWarehouses();
    }
  }

  void _showSetMainWarehouseDialog(BuildContext context, WarehouseEntity warehouse) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Color(0xFF1976D2),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'تعيين كمخزن رئيسي',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل تريد تعيين "${warehouse.name}" كمخزن رئيسي؟',
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1976D2).withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF1976D2),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم إلغاء تعيين المخزن الرئيسي الحالي',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<WarehousesCubit>().setMainWarehouse(warehouse.id!);
            },
            icon: const Icon(Icons.star, size: 20),
            label: const Text(
              'تعيين كرئيسي',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WarehouseEntity warehouse) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'حذف المخزن',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من حذف المخزن "${warehouse.name}"؟',
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تحذير: لا يمكن التراجع عن هذا الإجراء',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<WarehousesCubit>().deleteWarehouse(warehouse.id!);
            },
            icon: const Icon(Icons.delete_outline, size: 20),
            label: const Text(
              'حذف',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      ),
    );
  }
}
