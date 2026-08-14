import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/detail_row.dart';
import 'package:muhasib/core/widgets/custom_confirm_dialog.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/add_customer_dialog.dart';

class PartyProfileSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const PartyProfileSearchField({
    super.key,
    required this.controller,
    required this.query,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: AppConstant.defaultPadding,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextInputField(
        controller: controller,
        hint: hintText,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withAlpha(77),
        ),
      ),
    );
  }
}

class PartyProfileErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const PartyProfileErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: colorScheme.error)),
          const SizedBox(height: 16),
          HasibButton(
            label: 'إعادة المحاولة',
            onPressed: onRetry,
            leading: const Icon(Icons.refresh),
            variant: HasibButtonVariant.primary,
          ),
        ],
      ),
    );
  }
}

class PartyProfileEmptyState extends StatelessWidget {
  final String title;
  final IconData icon;

  const PartyProfileEmptyState({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(color: colorScheme.outline, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class PartyBalanceInfo {
  final String label;
  final Color color;
  final Color backgroundColor;
  final String formattedAmount;
  final bool isZero;

  const PartyBalanceInfo({
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.formattedAmount,
    required this.isZero,
  });

  factory PartyBalanceInfo.fromBalance({
    required double balance,
    required bool isSupplier,
  }) {
    final absAmount = balance.abs();
    final formattedAmount = '${absAmount.toStringAsFixed(2)} ر.س';

    if (absAmount < 0.001) {
      return PartyBalanceInfo(
        label: 'متوازن',
        color: Colors.grey.shade700,
        backgroundColor: Colors.grey.shade200,
        formattedAmount: '0.00 ر.س',
        isZero: true,
      );
    }

    if (!isSupplier) {
      // Customer:
      // balance > 0: Customer owes money (عليه / مدين / أحمر)
      // balance < 0: Customer has credit / is owed (له / دائن / أخضر)
      if (balance > 0) {
        return PartyBalanceInfo(
          label: 'عليه (مدين)',
          color: Colors.red.shade700,
          backgroundColor: Colors.red.shade50,
          formattedAmount: formattedAmount,
          isZero: false,
        );
      } else {
        return PartyBalanceInfo(
          label: 'له (دائن)',
          color: Colors.green.shade700,
          backgroundColor: Colors.green.shade50,
          formattedAmount: formattedAmount,
          isZero: false,
        );
      }
    } else {
      // Supplier (debit-normal convention):
      // balance < 0: business owes supplier (له / دائن / عنبري)
      // balance > 0: advance paid / supplier owes business (عليه / مدين / أخضر)
      if (balance < 0) {
        return PartyBalanceInfo(
          label: 'له (دائن)',
          color: Colors.orange.shade900,
          backgroundColor: Colors.orange.shade50,
          formattedAmount: formattedAmount,
          isZero: false,
        );
      } else {
        return PartyBalanceInfo(
          label: 'عليه (مدين)',
          color: Colors.green.shade700,
          backgroundColor: Colors.green.shade50,
          formattedAmount: formattedAmount,
          isZero: false,
        );
      }
    }
  }
}

class PartyProfileCard extends StatelessWidget {
  final Customer party;
  final bool isSupplier;
  final VoidCallback onTap;

  const PartyProfileCard({
    super.key,
    required this.party,
    required this.isSupplier,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final balanceInfo = PartyBalanceInfo.fromBalance(
      balance: party.balance,
      isSupplier: isSupplier,
    );

    final isOverLimit =
        !isSupplier &&
        party.creditLimit > 0 &&
        party.balance > party.creditLimit;

    return CustomCardContainer(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: AppConstant.defaultPadding,
          child: Column(
            children: [
              Row(
                children: [
                  PartyAvatar(party: party, isSupplier: isSupplier),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          party.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (party.phone?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 13,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                party.phone!,
                                style: TextStyle(
                                  color: colorScheme.outline,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        balanceInfo.formattedAmount,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: balanceInfo.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: balanceInfo.backgroundColor,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          border: Border.all(
                            color: balanceInfo.color.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          balanceInfo.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: balanceInfo.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (party.creditLimit > 0)
                _CreditLimitSummary(
                  party: party,
                  isSupplier: isSupplier,
                  isOverLimit: isOverLimit,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PartyAvatar extends StatelessWidget {
  final Customer party;
  final bool isSupplier;

  const PartyAvatar({super.key, required this.party, required this.isSupplier});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      backgroundColor: isSupplier
          ? colorScheme.secondaryContainer
          : colorScheme.primaryContainer,
      child: Text(
        party.name.isNotEmpty ? party.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: isSupplier
              ? colorScheme.onSecondaryContainer
              : colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CreditLimitSummary extends StatelessWidget {
  final Customer party;
  final bool isSupplier;
  final bool isOverLimit;

  const _CreditLimitSummary({
    required this.party,
    required this.isSupplier,
    required this.isOverLimit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (isSupplier) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Icon(Icons.credit_card, size: 16, color: colorScheme.outline),
            const SizedBox(width: 8),
            Text(
              'حد الائتمان: ${party.creditLimit.toStringAsFixed(0)} ر.س',
              style: TextStyle(fontSize: 12, color: colorScheme.outline),
            ),
          ],
        ),
      );
    }

    final usageRatio = party.balance > 0 && party.creditLimit > 0
        ? (party.balance / party.creditLimit).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: LinearProgressIndicator(
              value: usageRatio,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                isOverLimit ? Colors.red : colorScheme.primary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'حد الائتمان: ${party.creditLimit.toStringAsFixed(0)} ر.س',
                style: TextStyle(fontSize: 12, color: colorScheme.outline),
              ),
              if (isOverLimit)
                const Text(
                  'تجاوز الحد',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class PartyDetailsSheet extends StatelessWidget {
  final Customer party;
  final bool isSupplier;

  const PartyDetailsSheet({
    super.key,
    required this.party,
    required this.isSupplier,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final balanceInfo = PartyBalanceInfo.fromBalance(
      balance: party.balance,
      isSupplier: isSupplier,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.58,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      expand: false,
      builder: (sheetContext, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: colorScheme.outline.withAlpha(77),
                  borderRadius: BorderRadius.circular(AppRadius.xxs),
                ),
              ),
            ),
            Row(
              children: [
                PartyAvatar(party: party, isSupplier: isSupplier),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        party.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (party.phone != null && party.phone!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              party.phone!,
                              style: TextStyle(color: colorScheme.outline),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: party.phone!),
                                );
                                AppToast.showSuccess(
                                  sheetContext,
                                  'تم نسخ رقم الهاتف',
                                );
                              },
                              child: Icon(
                                Icons.copy,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'تعديل البيانات',
                  onPressed: () => _openEditDialog(sheetContext),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'حذف',
                  onPressed: () => _confirmDelete(sheetContext),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: balanceInfo.backgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: balanceInfo.color.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الرصيد الحالي',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الحالة: ${balanceInfo.label}',
                        style: TextStyle(
                          color: balanceInfo.color,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    balanceInfo.formattedAmount,
                    style: TextStyle(
                      color: balanceInfo.color,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (party.creditLimit > 0)
              DetailRow(
                icon: Icons.credit_card,
                label: 'حد الائتمان',
                value: '${party.creditLimit.toStringAsFixed(0)} ر.س',
              ),
            if (party.address?.isNotEmpty ?? false)
              DetailRow(
                icon: Icons.location_on,
                label: 'العنوان',
                value: party.address!,
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      context.push(
                        AppRoutes.reportsAccountStatement,
                        extra: party.accountId,
                      );
                    },
                    icon: const Icon(Icons.article),
                    label: const Text('كشف حساب'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HasibButton(
                    label: isSupplier ? 'فاتورة شراء' : 'فاتورة جديدة',
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      if (isSupplier) {
                        context.push(AppRoutes.purchasesAddInvoice);
                      } else {
                        context.push(AppRoutes.salesAddInvoice);
                      }
                    },
                    leading: const Icon(Icons.receipt),
                    variant: HasibButtonVariant.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditDialog(BuildContext context) async {
    final cubit = context.read<CustomersCubit>();
    Navigator.of(context).pop();

    await showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: AddCustomerDialog(
          partyType: isSupplier ? 2 : 1,
          initialCustomer: party,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<CustomersCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => CustomConfirmDialog(
        title: isSupplier ? 'حذف المورد' : 'حذف العميل',
        message: 'هل أنت متأكد من رغبتك في حذف "${party.name}"؟',
        confirmLabel: 'حذف',
        cancelLabel: 'إلغاء',
        isDanger: true,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop();
      final partyId = int.tryParse(party.id);
      if (partyId != null) {
        final success = await cubit.deleteCustomer(
          id: partyId,
          type: isSupplier ? 2 : 1,
        );
        if (success && context.mounted) {
          AppToast.showSuccess(
            context,
            isSupplier ? 'تم حذف المورد بنجاح' : 'تم حذف العميل بنجاح',
          );
        }
      }
    }
  }
}

void showPartyDetailsSheet(
  BuildContext context,
  Customer party,
  bool isSupplier,
) {
  final cubit = context.read<CustomersCubit>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg20)),
    ),
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: PartyDetailsSheet(party: party, isSupplier: isSupplier),
    ),
  );
}

class PartyAccountNotice extends StatelessWidget {
  final bool isSupplier;

  const PartyAccountNotice({super.key, required this.isSupplier});

  @override
  Widget build(BuildContext context) {
    final color = isSupplier ? Colors.orange : Colors.blue;
    final label = isSupplier ? 'المورد' : 'العميل';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'سيتم إنشاء حساب تلقائياً لـ $label في شجرة الحسابات',
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
