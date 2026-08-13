import 'package:flutter/material.dart';
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_spacing.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/review_info_row_widget.dart';

class Step4Review extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onPrevious;
  final VoidCallback onSave;
  final bool isQuotation;

  const Step4Review({
    super.key,
    required this.invoice,
    required this.onPrevious,
    required this.onSave,
    this.isQuotation = false,
  });

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'نقداً';
      case PaymentMethod.bank:
        return 'تحويل بنكي';
      case PaymentMethod.deferred:
        return 'آجل';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                // Success Icon
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 48,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'مراجعة الفاتورة',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray900,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'تأكد من صحة البيانات قبل الحفظ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: AppColors.gray600,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Invoice Details
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),

                  child: Column(
                    children: [
                      ReviewInfoRowWidget(label: 'رقم الفاتورة', value: invoice.number),
                      const Divider(height: AppSpacing.lg),
                      ReviewInfoRowWidget(label: 'العميل', value: invoice.customer?.name ?? ''),
                      const Divider(height: AppSpacing.lg),
                      ReviewInfoRowWidget(
                        label: 'التاريخ',
                        value: DateFormatter.formatDate(invoice.date),
                      ),
                      const Divider(height: AppSpacing.lg),
                      ReviewInfoRowWidget(
                        label: 'عدد الأصناف',
                        value: '${invoice.items.length} صنف',
                      ),
                      const Divider(height: AppSpacing.lg),
                      ReviewInfoRowWidget(
                        label: 'المجموع الفرعي',
                        value: NumberFormatter.formatCurrency(invoice.subtotal),
                      ),
                      if (SettingsCache.taxEnabled) ...[
                        const Divider(height: AppSpacing.lg),
                        ReviewInfoRowWidget(
                          label: SettingsCache.taxName,
                          value: NumberFormatter.formatCurrency(
                            invoice.taxAmount,
                          ),
                        ),
                      ],
                      if (invoice.discountAmount > 0) ...[
                        const Divider(height: AppSpacing.lg),
                        ReviewInfoRowWidget(
                          label: 'الخصم',
                          value: NumberFormatter.formatCurrency(
                            invoice.discountAmount,
                          ),
                          valueColor: AppColors.error,
                        ),
                      ],
                      if (invoice.otherCharges > 0) ...[
                        const Divider(height: AppSpacing.lg),
                        ReviewInfoRowWidget(
                          label: 'رسوم أخرى',
                          value: NumberFormatter.formatCurrency(invoice.otherCharges),
                          valueColor: AppColors.primary,
                        ),
                      ],
                      const Divider(height: AppSpacing.lg),
                      ReviewInfoRowWidget(
                        label: 'الإجمالي النهائي',
                        value: NumberFormatter.formatCurrency(invoice.total),
                        isHighlight: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),


                // Payment Summary (hidden for quotations)
                if (!isQuotation)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      border: Border.all(color: AppColors.success),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ملخص الدفع',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: AppColors.gray900,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'المدفوع',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: AppColors.gray600,
                                height: 1.4,
                              ),
                            ),
                            Text(
                              NumberFormatter.formatCurrency(invoice.paid),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gray900,
                                height: 1.4,
                              ).copyWith(color: AppColors.success),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'المتبقي',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: AppColors.gray600,
                                height: 1.4,
                              ),
                            ),
                            Text(
                              NumberFormatter.formatCurrency(invoice.remaining),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gray900,
                                height: 1.4,
                              ).copyWith(color: AppColors.warning),
                            ),
                          ],
                        ),
                        if (invoice.payments.isNotEmpty) ...[
                          const Divider(height: AppSpacing.lg),
                          ...invoice.payments.map((payment) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _getPaymentMethodLabel(payment.method),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.normal,
                                      color: AppColors.gray600,
                                      height: 1.4,
                                    ),
                                  ),
                                  Text(
                                    NumberFormatter.formatCurrency(
                                      payment.amount,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.normal,
                                      color: AppColors.gray600,
                                      height: 1.4,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),

                if (!isQuotation &&
                    invoice.remaining > 0 &&
                    invoice.payments.any(
                      (p) => p.method == PaymentMethod.deferred,
                    )) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      border: Border.all(color: AppColors.warning),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Text('⚠️', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'فاتورة آجلة',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                  color: AppColors.gray900,
                                  height: 1.5,
                                ),
                              ),
                              Text(
                                'المبلغ المتبقي ${NumberFormatter.formatCurrency(invoice.remaining)} سيتم إضافته كمديونية على حساب العميل',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                  color: AppColors.gray600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bottom Buttons
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: HasibButton(
                  label: 'رجوع',
                  onPressed: onPrevious,
                  variant: HasibButtonVariant.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: HasibButton(
                  label: isQuotation ? 'حفظ عرض السعر' : 'حفظ الفاتورة',
                  onPressed: onSave,
                  leading: const Icon(Icons.check, size: 20, color: Colors.white),
                  variant: HasibButtonVariant.success,
                ),
              ),
      ],
          ),
          ),
      ]
    );
  }
}

