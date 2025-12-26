import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/features/accounts/domain/entities/voucher_entity.dart';

import '../cubit/vouchers_cubit.dart';
import 'voucher_form_page.dart';

class VouchersPage extends StatefulWidget {
  const VouchersPage({super.key});

  @override
  State<VouchersPage> createState() => _VouchersPageState();
}

class _VouchersPageState extends State<VouchersPage> {
  VoucherType? _filter;

  @override
  void initState() {
    super.initState();
    context.read<VouchersCubit>().loadVouchers(type: _filter);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سندات الصرف والقبض'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _onAddVoucher,
          child: const Icon(Icons.add),
        ),
        body: BlocConsumer<VouchersCubit, VouchersState>(
          listener: (context, state) {
            if (state is VoucherActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            } else if (state is VoucherDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            } else if (state is VouchersFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is VouchersLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is VouchersLoaded) {
              final vouchers = state.vouchers;
              if (vouchers.isEmpty) {
                return Column(
                  children: [
                    _buildFilterRow(),
                    const Expanded(
                      child: Center(
                        child: Text('لا توجد سندات بعد'),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  _buildFilterRow(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: vouchers.length,
                      itemBuilder: (context, index) {
                        return _VoucherCard(
                          voucher: vouchers[index],
                          onEdit: _onEditVoucher,
                          onDelete: _onDeleteVoucher,
                        );
                      },
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _buildFilterRow(),
                const Expanded(
                  child: Center(child: Text('جارٍ التحميل...')),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('الكل'),
            selected: _filter == null,
            onSelected: (_) => _applyFilter(null),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('سند قبض'),
            selected: _filter == VoucherType.receipt,
            onSelected: (_) => _applyFilter(VoucherType.receipt),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('سند صرف'),
            selected: _filter == VoucherType.payment,
            onSelected: (_) => _applyFilter(VoucherType.payment),
          ),
        ],
      ),
    );
  }

  void _applyFilter(VoucherType? type) {
    setState(() => _filter = type);
    context.read<VouchersCubit>().loadVouchers(type: type);
  }

  Future<void> _onAddVoucher() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<VouchersCubit>(),
          child: VoucherFormPage(
            defaultType: _filter ?? VoucherType.receipt,
          ),
        ),
      ),
    );

    if (result == true) {
      context.read<VouchersCubit>().loadVouchers(type: _filter);
    }
  }

  Future<void> _onEditVoucher(VoucherEntity voucher) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<VouchersCubit>(),
          child: VoucherFormPage(
            voucher: voucher,
            defaultType: voucher.type,
          ),
        ),
      ),
    );

    if (result == true) {
      context.read<VouchersCubit>().loadVouchers(type: _filter);
    }
  }

  void _onDeleteVoucher(VoucherEntity voucher) {
    final cubit = context.read<VouchersCubit>();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف سند رقم ${voucher.number}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              cubit.removeVoucher(voucher.id ?? 0);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({
    required this.voucher,
    required this.onEdit,
    required this.onDelete,
  });

  final VoucherEntity voucher;
  final void Function(VoucherEntity) onEdit;
  final void Function(VoucherEntity) onDelete;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy/MM/dd');
    final amountText = voucher.amount.toStringAsFixed(2);
    final dateText = formatter.format(voucher.date);
    final accountLabel =
        voucher.accountName ?? 'الحساب رقم ${voucher.accountId}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text('${voucher.type.label} - رقم ${voucher.number}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('التاريخ: $dateText'),
            Text('الحساب: $accountLabel'),
            Text('البيان: ${voucher.statement}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              amountText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => onEdit(voucher),
                  tooltip: 'تعديل',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => onDelete(voucher),
                  tooltip: 'حذف',
                ),
              ],
            ),
          ],
        ),
        onTap: () => onEdit(voucher),
      ),
    );
  }
}

