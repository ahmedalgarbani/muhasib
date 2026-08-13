import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/purchases/presentation/cubit/purchases_cubit.dart';
import 'package:muhasib/features/purchases/presentation/widgets/invoice_total_row.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class PurchaseFormTotalsCard extends StatelessWidget {
  final TextEditingController discountController;
  final TextEditingController taxController;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double total;
  final VoidCallback onCalculateTotals;

  const PurchaseFormTotalsCard({
    super.key,
    required this.discountController,
    required this.taxController,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.total,
    required this.onCalculateTotals,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: AppConstant.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الإجماليات',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextInputField(
                    label: 'الخصم',
                    controller: discountController,
                    decoration: InputDecoration(
                      labelStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.discount, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) => onCalculateTotals(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextInputField(
                    label: 'الضريبة %',
                    controller: taxController,
                    decoration: InputDecoration(
                      labelStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.receipt_long, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) => onCalculateTotals(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                children: [
                  InvoiceTotalRow(
                    label: 'المجموع الفرعي',
                    amount: subtotal,
                    normalFontSize: 12,
                  ),
                  const SizedBox(height: 8),
                  InvoiceTotalRow(
                    label: 'الخصم',
                    amount: -discountAmount,
                    color: Colors.orange,
                    normalFontSize: 12,
                  ),
                  const SizedBox(height: 8),
                  InvoiceTotalRow(
                    label: 'الضريبة',
                    amount: taxAmount,
                    color: Colors.blue,
                    normalFontSize: 12,
                  ),
                  const Divider(height: 16),
                  InvoiceTotalRow(
                    label: 'الإجمالي',
                    amount: total,
                    isTotal: true,
                    totalFontSize: 14,
                    normalFontSize: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PurchaseFormNotesCard extends StatelessWidget {
  final TextEditingController statementController;
  final TextEditingController shippingAddressController;

  const PurchaseFormNotesCard({
    super.key,
    required this.statementController,
    required this.shippingAddressController,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCardContainer(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: AppConstant.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات إضافية',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 12),
            TextInputField(
              label: 'البيان',
              hint: 'أدخل أي ملاحظات إضافية',
              controller: statementController,
              decoration: InputDecoration(
                labelStyle: const TextStyle(fontSize: 12),
                hintStyle: const TextStyle(fontSize: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(fontSize: 13),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextInputField(
              label: 'عنوان الشحن',
              hint: 'أدخل عنوان الشحن إن وجد',
              controller: shippingAddressController,
              decoration: InputDecoration(
                labelStyle: const TextStyle(fontSize: 12),
                hintStyle: const TextStyle(fontSize: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class PurchaseFormActionButtons extends StatelessWidget {
  final InvoiceEntity? invoice;
  final VoidCallback onSaveInvoice;

  const PurchaseFormActionButtons({
    super.key,
    required this.invoice,
    required this.onSaveInvoice,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BlocBuilder<PurchasesCubit, PurchasesState>(
            builder: (context, state) {
              final isLoading = state is PurchasesLoading;
              return HasibButton(
                label: isLoading
                    ? 'جاري الحفظ...'
                    : (invoice != null ? 'تحديث الفاتورة' : 'حفظ الفاتورة'),
                onPressed: isLoading ? null : onSaveInvoice,
                leading: const Icon(Icons.save, size: 18),
                loading: isLoading,
                variant: HasibButtonVariant.success,
                padding: const EdgeInsets.symmetric(vertical: 12),
                fontSize: 13,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('إلغاء', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
