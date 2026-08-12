import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/features/accounts/domain/entities/account_limit_entity.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/account_limits_cubit.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:muhasib/features/currencies/presentation/cubit/currencies_cubit.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';

class AccountLimitsScreen extends StatefulWidget {
  const AccountLimitsScreen({super.key});

  @override
  State<AccountLimitsScreen> createState() => _AccountLimitsScreenState();
}

class _AccountLimitsScreenState extends State<AccountLimitsScreen> {
  final _numberFormat = intl.NumberFormat('#,##0.00', 'ar');
  @override
  void initState() {
    super.initState();
    context.read<AccountLimitsCubit>().loadLimits();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'إدارة سقوف الحسابات',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<AccountLimitsCubit>().loadLimits(),
              tooltip: 'تحديث البيانات',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddLimitSheet(context),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'إضافة سقف حساب',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: BlocBuilder<AccountLimitsCubit, AccountLimitsState>(
          builder: (context, state) {
            if (state is AccountLimitsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AccountLimitsLoaded) {
              final limits = state.limits;
              if (limits.isEmpty) return _buildEmptyState();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: limits.length,
                itemBuilder: (context, index) => _AccountLimitCard(
                  limit: limits[index],
                  numberFormat: _numberFormat,
                  onEdit: () =>
                      _showAddLimitSheet(context, limit: limits[index]),
                  onDelete: () => _confirmDelete(limits[index]),
                ),
              );
            }

            if (state is AccountLimitsError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            return const SizedBox();
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
            Icons.security_update_warning_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد سقوف مفعّلة حالياً',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'استخدم السقوف لمنع التجاوزات المالية.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showAddLimitSheet(BuildContext context, {AccountLimitEntity? limit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditLimitSheet(limit: limit),
    );
  }

  void _confirmDelete(AccountLimitEntity limit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف السقف'),
        content: Text(
          'هل أنت متأكد من حذف سقف الحساب لـ ${limit.accountName}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AccountLimitsCubit>().deleteLimit(limit.id!);
            },
            child: const Text('نعم، احذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _AccountLimitCard extends StatelessWidget {
  final AccountLimitEntity limit;
  final intl.NumberFormat numberFormat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AccountLimitCard({
    required this.limit,
    required this.numberFormat,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usageLevel = limit.usageLevel;
    final color = usageLevel == UsageLevel.critical
        ? Colors.red
        : (usageLevel == UsageLevel.warning ? Colors.orange : Colors.green);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              limit.accountName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              'كود: ${limit.accountCode} | العملة: ${limit.currencyCode}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('تعديل'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('حذف', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (limit.debitLimit > 0)
                  _buildProgressBar(
                    'سقف المدين',
                    limit.debitUsagePercentage,
                    color,
                    limit.debitLimit,
                  ),
                if (limit.creditLimit > 0) ...[
                  const SizedBox(height: 16),
                  _buildProgressBar(
                    'سقف الدائن',
                    limit.creditUsagePercentage,
                    color,
                    limit.creditLimit,
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppRadius.lg20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  usageLevel == UsageLevel.critical
                      ? 'حالة حرجة!'
                      : (usageLevel == UsageLevel.warning
                            ? 'تنبيه تجاوز'
                            : 'مستوى آمن'),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  limit.isActive ? 'نشط' : 'متوقف',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    String label,
    double percentage,
    Color color,
    double max,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              '${numberFormat.format(max)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${percentage.toStringAsFixed(1)}% مستخدم',
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _AddEditLimitSheet extends StatefulWidget {
  final AccountLimitEntity? limit;
  const _AddEditLimitSheet({this.limit});

  @override
  State<_AddEditLimitSheet> createState() => _AddEditLimitSheetState();
}

class _AddEditLimitSheetState extends State<_AddEditLimitSheet> {
  final _debitController = TextEditingController();
  final _creditController = TextEditingController();
  AccountEntity? _selectedAccount;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.limit != null) {
      _debitController.text = widget.limit!.debitLimit.toString();
      _creditController.text = widget.limit!.creditLimit.toString();
      _isActive = widget.limit!.isActive;
    }
    context.read<AccountsCubit>().loadAllAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(AppRadius.xxs),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.limit == null
                      ? 'ضبط سقف مالي جديد'
                      : 'تعديل سقف الحساب',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'الحساب المستهدف',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 8),
                _buildAccountPicker(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildInput(
                        'سقف المدين',
                        _debitController,
                        Icons.arrow_downward,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInput(
                        'سقف الدائن',
                        _creditController,
                        Icons.arrow_upward,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  title: const Text('تفعيل السقف (نشط)'),
                  subtitle: const Text(
                    'سيتم إجراء تدقيق مالي عند التنشيط.',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    onPressed: _save,
                    child: const Text(
                      'حفظ السقف المالي',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountPicker() {
    return InkWell(
      onTap: widget.limit != null ? null : _pickAccount,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              widget.limit?.accountName ??
                  _selectedAccount?.name ??
                  'اضغط لاختيار الحساب...',
              style: TextStyle(
                color: widget.limit != null
                    ? Colors.grey
                    : (_selectedAccount == null ? Colors.grey : Colors.black87),
              ),
            ),
            const Spacer(),
            if (widget.limit == null)
              const Icon(Icons.search, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: color, size: 18),
            hintText: '0.00',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
        ),
      ],
    );
  }

  void _pickAccount() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AccountSearchSheet(
        onSelected: (acc) => setState(() => _selectedAccount = acc),
      ),
    );
  }

  void _save() {
    if (widget.limit == null && _selectedAccount == null) return;

    final limit =
        widget.limit?.copyWith(
          debitLimit: double.tryParse(_debitController.text) ?? 0,
          creditLimit: double.tryParse(_creditController.text) ?? 0,
          isActive: _isActive,
        ) ??
        AccountLimitEntity(
          accountId: _selectedAccount!.id!,
          accountName: _selectedAccount!.name,
          accountCode: _selectedAccount!.code,
          currencyId: 1, // Default currency
          currencyCode: 'SAR',
          debitLimit: double.tryParse(_debitController.text) ?? 0,
          creditLimit: double.tryParse(_creditController.text) ?? 0,
          isActive: _isActive,
        );

    context.read<AccountLimitsCubit>().saveLimit(limit);
    Navigator.pop(context);
  }
}

class _AccountSearchSheet extends StatefulWidget {
  final Function(AccountEntity) onSelected;
  const _AccountSearchSheet({required this.onSelected});

  @override
  State<_AccountSearchSheet> createState() => _AccountSearchSheetState();
}

class _AccountSearchSheetState extends State<_AccountSearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsCubit>().allAccounts ?? [];
    final filtered = accounts
        .where(
          (a) =>
              !a.isMaster &&
              (a.name.contains(_query) || a.code.contains(_query)),
        )
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'ابحث عن حساب...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(
                  filtered[i].name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(filtered[i].code),
                onTap: () {
                  widget.onSelected(filtered[i]);
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
