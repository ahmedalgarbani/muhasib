import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/custom_confirm_dialog.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/widgets/empty_state_widget.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/stores/domain/entities/stock_transfer_entity.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/domain/enums/stock_enums.dart';
import 'package:muhasib/features/stores/presentation/cubit/stock_transfers_cubit.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class StockTransfersListPage extends StatelessWidget {
  const StockTransfersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) => getIt<StockTransfersCubit>()..loadTransfers()),
        BlocProvider(
            create: (_) => getIt<WarehousesCubit>()..loadActiveWarehouses()),
      ],
      child: const _StockTransfersListView(),
    );
  }
}

class _StockTransfersListView extends StatefulWidget {
  const _StockTransfersListView();

  @override
  State<_StockTransfersListView> createState() =>
      _StockTransfersListViewState();
}

class _StockTransfersListViewState extends State<_StockTransfersListView> {
  int? _selectedWarehouseId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Map<int, String> _warehouseNames = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onWarehouseFilterChanged(int? id) {
    setState(() => _selectedWarehouseId = id);
    if (id == null) {
      context.read<StockTransfersCubit>().loadTransfers();
    } else {
      context.read<StockTransfersCubit>().loadTransfersByWarehouse(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: CustomAppBar(
        title: 'التحويلات المخزنية',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_selectedWarehouseId == null) {
                context.read<StockTransfersCubit>().loadTransfers();
              } else {
                context.read<StockTransfersCubit>()
                    .loadTransfersByWarehouse(_selectedWarehouseId!);
              }
            },
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Warehouse filter
                BlocBuilder<WarehousesCubit, WarehousesState>(
                  builder: (context, wState) {
                    if (wState is WarehousesLoaded) {
                      _warehouseNames = {
                        for (var w in wState.warehouses) w.id!: w.name
                      };
                    }
                    List<WarehouseEntity> warehouses = [];
                    if (wState is WarehousesLoaded) warehouses = wState.warehouses;
                    final isLoading = wState is WarehousesLoading;

                    return Row(
                      children: [
                        const Icon(Icons.warehouse,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text('المخزن:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(width: 8),
                        if (isLoading)
                          const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                        else
                          Expanded(
                            child: CustomDropdownField<int?>(
                              value: _selectedWarehouseId,
                              hint: 'كل المخازن',
                              items: [
                                const DropdownMenuItem<int?>(
                                    value: null, child: Text('كل المخازن')),
                                ...warehouses.map((w) => DropdownMenuItem(
                                    value: w.id, child: Text(w.name))),
                              ],
                              onChanged: _onWarehouseFilterChanged,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                // Search
                TextInputField(
                  controller: _searchController,
                  hint: 'بحث برقم التحويل أو البيان...',
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocConsumer<StockTransfersCubit, StockTransfersState>(
              listener: (context, state) {
                if (state is StockTransfersError) {
                  AppToast.showError(context, state.message);
                } else if (state is TransferDeleted) {
                  AppToast.showSuccess(context, 'تم حذف التحويل');
                } else if (state is TransferStatusUpdated) {
                  AppToast.showSuccess(context, 'تم تحديث حالة التحويل');
                }
              },
              builder: (context, state) {
                if (state is StockTransfersLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is StockTransfersError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.red[300]),
                        const SizedBox(height: 8),
                        Text(state.message, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () =>
                              context.read<StockTransfersCubit>().loadTransfers(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is StockTransfersLoaded) {
                  var transfers = state.transfers;
                  // client-side search filter
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    transfers = transfers.where((t) {
                      return t.number.toLowerCase().contains(q) ||
                          t.statement.toLowerCase().contains(q);
                    }).toList();
                  }
                  if (transfers.isEmpty) {
                    return EmptyStateWidget(
                      title: _searchQuery.isNotEmpty
                          ? 'لا توجد نتائج'
                          : 'لا توجد تحويلات',
                      subtitle: _searchQuery.isNotEmpty
                          ? 'جرّب كلمات بحث أخرى'
                          : 'اضغط + لإنشاء تحويل جديد',
                      icon: Icons.swap_horiz,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      if (_selectedWarehouseId == null) {
                        await context.read<StockTransfersCubit>().loadTransfers();
                      } else {
                        await context
                            .read<StockTransfersCubit>()
                            .loadTransfersByWarehouse(_selectedWarehouseId!);
                      }
                    },
                    child: ListView.builder(
                      padding: AppConstant.defaultPadding,
                      itemCount: transfers.length,
                      itemBuilder: (context, index) {
                        final transfer = transfers[index];
                        return _TransferCard(
                          transfer: transfer,
                          warehouseNames: _warehouseNames,
                          onTap: () => _showTransferDetails(transfer),
                          onDelete: transfer.status == TransferStatus.completed
                              ? null
                              : () => _confirmDelete(transfer),
                          onPost: transfer.status == TransferStatus.completed
                              ? null
                              : () => _confirmPost(transfer),
                        );
                      },
                    ),
                  );
                }
                // For transient states like TransferCreated/Deleted, show loader will be handled above,
                // but if state is not loaded, trigger load
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result =
              await context.pushNamed(AppRoutes.warehousesTransferForm);
          if (result == true && mounted) {
            // reload after creation
            if (_selectedWarehouseId == null) {
              context.read<StockTransfersCubit>().loadTransfers();
            } else {
              context
                  .read<StockTransfersCubit>()
                  .loadTransfersByWarehouse(_selectedWarehouseId!);
            }
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('تحويل جديد'),
        backgroundColor: AppColors.materialPurple500,
      ),
    );
  }

  void _showTransferDetails(StockTransferEntity transfer) {
    final fromName = transfer.fromStockId != null
        ? (_warehouseNames[transfer.fromStockId!] ?? 'مخزن ${transfer.fromStockId}')
        : '—';
    final toName = transfer.toStockId != null
        ? (_warehouseNames[transfer.toStockId!] ?? 'مخزن ${transfer.toStockId}')
        : '—';
    final date = DateTime.fromMillisecondsSinceEpoch(transfer.date * 1000);
    final statusLabel = _statusLabel(transfer.status);
    final statusColor = _statusColor(transfer.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(transfer.number,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3))),
                    child: Text(statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('التاريخ: ${date.day}/${date.month}/${date.year}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.output, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('من: $fromName',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  const Icon(Icons.input, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('إلى: $toName',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              if (transfer.statement.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('البيان: ${transfer.statement}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13)),
              ],
              const Divider(height: 24),
              Text('الأصناف (${transfer.lines.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              ...transfer.lines.map((l) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 3,
                            child: Text(l.statement,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13))),
                        Expanded(
                            child: Text('الكمية: ${l.quantity}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12))),
                        Expanded(
                            child: Text(
                                'التكلفة: ${NumberFormatter.formatNumber(l.costAmount ?? 0)}',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600]))),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                      label: const Text('إغلاق'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(StockTransferEntity t) {
    showDialog(
      context: context,
      builder: (ctx) => CustomConfirmDialog(
        title: 'حذف التحويل',
        message: 'هل أنت متأكد من حذف التحويل "${t.number}"؟',
        confirmLabel: 'حذف',
        isDanger: true,
        onConfirm: () {
          context.read<StockTransfersCubit>().deleteTransfer(t.id!);
        },
      ),
    );
  }

  void _confirmPost(StockTransferEntity t) {
    showDialog(
      context: context,
      builder: (ctx) => CustomConfirmDialog(
        title: 'ترحيل التحويل',
        message:
            'سيتم خصم الكميات من المخزن المصدر وإضافتها للوجهة بسعر المتوسط. هل تريد المتابعة؟',
        confirmLabel: 'ترحيل',
        icon: Icons.send,
        onConfirm: () {
          context
              .read<StockTransfersCubit>()
              .updateTransferStatus(t.id!, TransferStatus.completed);
        },
      ),
    );
  }

  String _statusLabel(TransferStatus s) {
    switch (s) {
      case TransferStatus.draft:
        return 'مسودة';
      case TransferStatus.pendingApproval:
        return 'بانتظار الموافقة';
      case TransferStatus.approved:
        return 'معتمد';
      case TransferStatus.inTransit:
        return 'قيد النقل';
      case TransferStatus.completed:
        return 'مرحّل';
      case TransferStatus.rejected:
        return 'مرفوض';
      case TransferStatus.cancelled:
        return 'ملغي';
    }
  }

  Color _statusColor(TransferStatus s) {
    switch (s) {
      case TransferStatus.draft:
        return Colors.grey;
      case TransferStatus.pendingApproval:
        return Colors.orange;
      case TransferStatus.approved:
        return Colors.blue;
      case TransferStatus.inTransit:
        return Colors.teal;
      case TransferStatus.completed:
        return Colors.green;
      case TransferStatus.rejected:
        return Colors.red;
      case TransferStatus.cancelled:
        return Colors.grey;
    }
  }
}

class _TransferCard extends StatelessWidget {
  final StockTransferEntity transfer;
  final Map<int, String> warehouseNames;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onPost;

  const _TransferCard({
    required this.transfer,
    required this.warehouseNames,
    required this.onTap,
    this.onDelete,
    this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    final fromName = transfer.fromStockId != null
        ? (warehouseNames[transfer.fromStockId!] ?? 'مخزن ${transfer.fromStockId}')
        : '—';
    final toName = transfer.toStockId != null
        ? (warehouseNames[transfer.toStockId!] ?? 'مخزن ${transfer.toStockId}')
        : '—';
    final date = DateTime.fromMillisecondsSinceEpoch(transfer.date * 1000);
    final statusLabel = switch (transfer.status) {
      TransferStatus.draft => 'مسودة',
      TransferStatus.pendingApproval => 'بانتظار الموافقة',
      TransferStatus.approved => 'معتمد',
      TransferStatus.inTransit => 'قيد النقل',
      TransferStatus.completed => 'مرحّل',
      TransferStatus.rejected => 'مرفوض',
      TransferStatus.cancelled => 'ملغي',
    };
    final statusColor = switch (transfer.status) {
      TransferStatus.draft => Colors.grey,
      TransferStatus.pendingApproval => Colors.orange,
      TransferStatus.approved => Colors.blue,
      TransferStatus.inTransit => Colors.teal,
      TransferStatus.completed => Colors.green,
      TransferStatus.rejected => Colors.red,
      TransferStatus.cancelled => Colors.grey,
    };

    return CustomCardContainer(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.swap_horiz,
                          size: 18, color: AppColors.materialPurple500),
                      const SizedBox(width: 6),
                      Text(transfer.number,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withOpacity(0.3))),
                    child: Text(statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.output, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(fromName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12))),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward,
                              size: 14, color: Colors.grey),
                        ),
                        const Icon(Icons.input, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(toName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${date.day}/${date.month}/${date.year}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  Text('${transfer.lines.length} صنف',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
              if (transfer.statement.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(transfer.statement,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey[700])),
              ],
              if (onPost != null || onDelete != null) ...[
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onPost != null)
                      TextButton.icon(
                        onPressed: onPost,
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('ترحيل',
                            style: TextStyle(fontSize: 12)),
                      ),
                    if (onDelete != null)
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: Colors.red),
                        label: const Text('حذف',
                            style: TextStyle(fontSize: 12, color: Colors.red)),
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
}
