import 'package:flutter/material.dart';
import 'package:muhasib/features/sales/presentation/widgets/sale_form.dart';

class Step4Review extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onPrevious;
  final VoidCallback onSave;

  const Step4Review({
    Key? key,
    required this.invoice,
    required this.onPrevious,
    required this.onSave,
  }) : super(key: key);

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
                        style: AppTextStyles.headline2,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'تأكد من صحة البيانات قبل الحفظ',
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Invoice Details
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.grey200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('رقم الفاتورة', invoice.number),
                      const Divider(height: AppSpacing.lg),
                      _buildInfoRow('العميل', invoice.customer?.name ?? ''),
                      const Divider(height: AppSpacing.lg),
                      _buildInfoRow(
                        'التاريخ',
                        invoice.date.toString().split(' ')[0],
                      ),
                      const Divider(height: AppSpacing.lg),
                      _buildInfoRow(
                        'عدد الأصناف',
                        '${invoice.items.length} صنف',
                      ),
                      const Divider(height: AppSpacing.lg),
                      _buildInfoRow(
                        'المجموع الفرعي',
                        NumberFormatter.formatCurrency(invoice.subtotal),
                      ),
                      if (invoice.discountAmount > 0) ...[
                        const Divider(height: AppSpacing.lg),
                        _buildInfoRow(
                          'الخصم',
                          NumberFormatter.formatCurrency(
                            invoice.discountAmount,
                          ),
                          valueColor: AppColors.error,
                        ),
                      ],
                      if (invoice.otherCharges > 0) ...[
                        const Divider(height: AppSpacing.lg),
                        _buildInfoRow(
                          'رسوم أخرى',
                          NumberFormatter.formatCurrency(invoice.otherCharges),
                          valueColor: AppColors.primary,
                        ),
                      ],
                      const Divider(height: AppSpacing.lg),
                      _buildInfoRow(
                        'الإجمالي النهائي',
                        NumberFormatter.formatCurrency(invoice.total),
                        isHighlight: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Payment Summary
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    border: Border.all(color: AppColors.success),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ملخص الدفع', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('المدفوع', style: AppTextStyles.caption),
                          Text(
                            NumberFormatter.formatCurrency(invoice.paid),
                            style: AppTextStyles.title.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('المتبقي', style: AppTextStyles.caption),
                          Text(
                            NumberFormatter.formatCurrency(invoice.remaining),
                            style: AppTextStyles.title.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      if (invoice.payments.isNotEmpty) ...[
                        const Divider(height: AppSpacing.lg),
                        ...invoice.payments.map((payment) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getPaymentMethodLabel(payment.method),
                                  style: AppTextStyles.small,
                                ),
                                Text(
                                  NumberFormatter.formatCurrency(
                                    payment.amount,
                                  ),
                                  style: AppTextStyles.small.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),

                if (invoice.remaining > 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      border: Border.all(color: AppColors.warning),
                      borderRadius: BorderRadius.circular(12),
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
                                style: AppTextStyles.bodyMedium,
                              ),
                              Text(
                                'المبلغ المتبقي ${NumberFormatter.formatCurrency(invoice.remaining)} سيتم إضافته كمديونية على حساب العميل',
                                style: AppTextStyles.small,
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
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.grey200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SecondaryButton(text: 'رجوع', onPressed: onPrevious),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  text: 'حفظ الفاتورة',
                  icon: const Icon(Icons.check, size: 24),
                  onPressed: onSave,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isHighlight = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isHighlight ? AppTextStyles.title : AppTextStyles.caption,
        ),
        Text(
          value,
          style: isHighlight
              ? AppTextStyles.title.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                )
              : AppTextStyles.bodyMedium.copyWith(color: valueColor),
        ),
      ],
    );
  }
}
