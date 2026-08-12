import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/accounts/domain/entities/voucher_entity.dart';
import '../cubit/vouchers_cubit.dart';
import 'voucher_form_page.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_text_style.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';


part 'vouchers_widgets.dart';

class VouchersPage extends StatefulWidget {
  const VouchersPage({super.key});

  @override
  State<VouchersPage> createState() => _VouchersPageState();
}

class _VouchersPageState extends State<VouchersPage>
    with SingleTickerProviderStateMixin {
  VoucherType? _filter;
  late TabController _tabController;
  final _numberFormat = intl.NumberFormat('#,##0.00', 'ar');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        VoucherType? newFilter;
        if (_tabController.index == 1) newFilter = VoucherType.receipt;
        if (_tabController.index == 2) newFilter = VoucherType.payment;
        if (newFilter != _filter) {
          _applyFilter(newFilter);
        }
      }
    });
    context.read<VouchersCubit>().loadVouchers(type: _filter);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'سندات القبض والصرف',
          actions: [
            IconButton(
              icon: const Icon(Icons.download_for_offline_outlined),
              onPressed: () => _showExportOptions(context),
              tooltip: 'تصدير البيانات',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _onAddVoucher,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'سند جديد',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: BlocBuilder<VouchersCubit, VouchersState>(
          builder: (context, state) {
            if (state is VouchersLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is VouchersLoaded) {
              final vouchers = state.vouchers;
              if (vouchers.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () async =>
                    context.read<VouchersCubit>().loadVouchers(type: _filter),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vouchers.length,
                  itemBuilder: (context, index) {
                    return _VoucherListItem(
                      voucher: vouchers[index],
                      numberFormat: _numberFormat,
                      onTap: () => _showVoucherDetails(vouchers[index]),
                      onEdit: () => _onEditVoucher(vouchers[index]),
                      onDelete: () => _onDeleteVoucher(vouchers[index]),
                    );
                  },
                ),
              );
            }
            return const Center(child: Text('حدث خطأ في تحميل البيانات'));
          },
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
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد سندات مسجلة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ابدأ بإضافة أول سند قبض أو صرف الآن.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _applyFilter(VoucherType? type) {
    setState(() => _filter = type);
    context.read<VouchersCubit>().loadVouchers(type: type);
  }

  void _showExportOptions(BuildContext context) {
    final state = context.read<VouchersCubit>().state;
    if (state is! VouchersLoaded) return;

    final vouchers = state.vouchers;
    final headers = ['الرقم', 'التاريخ', 'الحساب', 'البيان', 'المبلغ', 'النوع'];
    final data = vouchers
        .map(
          (v) => [
            v.number.toString(),
            intl.DateFormat('yyyy/MM/dd').format(v.date),
            v.accountName ?? '',
            v.statement,
            _numberFormat.format(v.amount),
            v.type.label,
          ],
        )
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg20)),
      ),
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'خيارات التصدير والطباعة',
                  style: AppTextStyles.titleMedium,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.print, color: Colors.blue),
                title: const Text('طباعة / PDF'),
                onTap: () {
                  Navigator.pop(context);
                  ExportService.printData(
                    title: 'سجل سندات القبض والصرف',
                    headers: headers,
                    data: data,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: const Text('تصدير إلى Excel'),
                onTap: () {
                  Navigator.pop(context);
                  ExportService.exportToExcel(
                    fileName:
                        'سجل_السندات_${intl.DateFormat('yyyyMMdd').format(DateTime.now())}',
                    headers: headers,
                    data: data,
                  ).then((path) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم حفظ الملف في: $path')),
                    );
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showVoucherDetails(VoucherEntity voucher) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _VoucherDetailsSheet(voucher: voucher, numberFormat: _numberFormat),
    );
  }

  Future<void> _onAddVoucher() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<VouchersCubit>(),
          child: VoucherFormPage(defaultType: _filter ?? VoucherType.receipt),
        ),
      ),
    );
    if (result == true)
      context.read<VouchersCubit>().loadVouchers(type: _filter);
  }

  Future<void> _onEditVoucher(VoucherEntity voucher) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<VouchersCubit>(),
          child: VoucherFormPage(voucher: voucher, defaultType: voucher.type),
        ),
      ),
    );
    if (result == true)
      context.read<VouchersCubit>().loadVouchers(type: _filter);
  }

  void _onDeleteVoucher(VoucherEntity voucher) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg20),
          ),
          title: const Text('تأكيد الحذف'),
          content: Text(
            'هل أنت متأكد من حذف ${voucher.type.label} رقم ${voucher.number}؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                context.read<VouchersCubit>().removeVoucher(voucher.id ?? 0);
              },
              child: const Text(
                'حذف الآن',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

