import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/widgets/custom_confirm_dialog.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:muhasib/features/stores/presentation/widgets/warehouses_list_widget.dart';

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
      backgroundColor: AppColors.neutral100,
      appBar: CustomAppBar(
        title: 'المخازن',
        actions: [
          IconButton(
            icon: Icon(
              _showActiveOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
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
            AppToast.showSuccess(context, 'تم إضافة المخزن بنجاح');
          } else if (state is WarehouseUpdated) {
            AppToast.showSuccess(context, 'تم تحديث المخزن بنجاح');
          } else if (state is WarehouseDeleted) {
            AppToast.showSuccess(context, 'تم حذف المخزن بنجاح');
          } else if (state is MainWarehouseSet) {
            AppToast.showSuccess(context, 'تم تعيين المخزن الرئيسي بنجاح');
          } else if (state is WarehousesError) {
            AppToast.showError(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is WarehousesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is WarehousesLoaded) {
            if (state.warehouses.isEmpty) {
              return const EmptyStateWidget(
                title: 'لا توجد مخازن',
                subtitle: 'اضغط على الزر أدناه لإضافة مخزن جديد',
                icon: Icons.warehouse_outlined,
              );
            }
            return WarehousesListWidget(
              warehouses: state.warehouses,
              searchController: _searchController,
              onSearchChanged: (value) {
                if (value.isEmpty) {
                  context.read<WarehousesCubit>().loadWarehouses();
                } else {
                  context.read<WarehousesCubit>().searchWarehouses(value);
                }
              },
              onClearSearch: () {
                _searchController.clear();
                context.read<WarehousesCubit>().loadWarehouses();
              },
              onWarehouseTap: (warehouse) =>
                  _showWarehouseDialog(context, warehouse: warehouse),
              onWarehouseEdit: (warehouse) =>
                  _showWarehouseDialog(context, warehouse: warehouse),
              onWarehouseSetMain: (warehouse) =>
                  _showSetMainWarehouseDialog(context, warehouse),
              onWarehouseDelete: (warehouse) =>
                  _showDeleteDialog(context, warehouse),
            );
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
        backgroundColor: AppColors.materialBlue700,
      ),
    );
  }

  void _showWarehouseDialog(
    BuildContext context, {
    WarehouseEntity? warehouse,
  }) async {
    final result = await context.pushNamed(
      AppRoutes.warehouseForm,
      extra: warehouse,
    );
    if (!mounted) return;
    if (result == true) {
      context.read<WarehousesCubit>().loadWarehouses();
    }
  }

  void _showSetMainWarehouseDialog(
    BuildContext context,
    WarehouseEntity warehouse,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => CustomConfirmDialog(
        title: 'تعيين كمخزن رئيسي',
        message:
            'هل تريد تعيين "${warehouse.name}" كمخزن رئيسي؟ سيتم إلغاء تعيين المخزن الرئيسي الحالي.',
        confirmLabel: 'تعيين كرئيسي',
        icon: Icons.star_rounded,
        onConfirm: () {
          context.read<WarehousesCubit>().setMainWarehouse(warehouse.id!);
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WarehouseEntity warehouse) {
    showDialog(
      context: context,
      builder: (dialogContext) => CustomConfirmDialog(
        title: 'حذف المخزن',
        message:
            'هل أنت متأكد من حذف المخزن "${warehouse.name}"؟ لن تتمكن من التراجع عن هذه العملية.',
        confirmLabel: 'حذف',
        isDanger: true,
        onConfirm: () {
          context.read<WarehousesCubit>().deleteWarehouse(warehouse.id!);
        },
      ),
    );
  }
}
