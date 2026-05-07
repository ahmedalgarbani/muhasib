import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/services/export_service.dart';
import 'package:muhasib/features/accounts/domain/entities/voucher_entity.dart';
import '../cubit/vouchers_cubit.dart';
import 'voucher_form_page.dart';

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
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'سندات القبض والصرف',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: AppColors.gradientPrimary),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download_for_offline_outlined),
              onPressed: () => _showExportOptions(context),
              tooltip: 'تصدير البيانات',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
            ),
            tabs: const [
              Tab(text: 'الكل'),
              Tab(text: 'سندات القبض'),
              Tab(text: 'سندات الصرف'),
            ],
          ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
            borderRadius: BorderRadius.circular(20),
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
                  borderRadius: BorderRadius.circular(10),
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

class _VoucherListItem extends StatelessWidget {
  final VoucherEntity voucher;
  final intl.NumberFormat numberFormat;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VoucherListItem({
    required this.voucher,
    required this.numberFormat,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isReceipt = voucher.type == VoucherType.receipt;
    final color = isReceipt ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isReceipt ? Icons.arrow_downward : Icons.arrow_upward,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voucher.type.label,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'رقم ${voucher.number}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    numberFormat.format(voucher.amount),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      voucher.accountName ?? 'حساب غير معروف',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    intl.DateFormat('yyyy/MM/dd').format(voucher.date),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Colors.blue,
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.grey.shade300,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoucherDetailsSheet extends StatelessWidget {
  final VoucherEntity voucher;
  final intl.NumberFormat numberFormat;

  const _VoucherDetailsSheet({
    required this.voucher,
    required this.numberFormat,
  });

  @override
  Widget build(BuildContext context) {
    final isReceipt = voucher.type == VoucherType.receipt;
    final color = isReceipt ? Colors.green : Colors.red;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      'تفاصيل ${voucher.type.label}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildInfoCard(color),
                    const SizedBox(height: 24),
                    const Text(
                      'الأسطر والتوزيع المالي',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (voucher.lines.isNotEmpty)
                      ...voucher.lines.map(
                        (line) => _buildLineItem(line, color),
                      )
                    else
                      _buildSingleLineItem(color),
                    const SizedBox(height: 32),
                    _buildStatementCard(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _DetailRow(
            label: 'رقم السند',
            value: voucher.number.toString(),
            icon: Icons.tag,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'تاريخ السند',
            value: intl.DateFormat('yyyy/MM/dd').format(voucher.date),
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'الحساب الرئيسي',
            value: voucher.accountName ?? '',
            icon: Icons.account_balance_wallet,
            isBold: true,
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إجمالي المبلغ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                numberFormat.format(voucher.amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineItem(VoucherLineEntity line, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.accountName ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (line.statement.isNotEmpty)
                  Text(
                    line.statement,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          Text(
            numberFormat.format(line.amount ?? 0),
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleLineItem(Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'هذا السند لا يحتوي على أسطر تفصيلية، تم تسجيل المبلغ بالكامل على الحساب الرئيسي.',
        style: TextStyle(fontSize: 13, color: Colors.grey),
      ),
    );
  }

  Widget _buildStatementCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'البيان العام',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade100),
          ),
          child: Text(
            voucher.statement.isEmpty
                ? 'لا يوجد بيان مسجل لهذا السند.'
                : voucher.statement,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isBold;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
