import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/expandable_section.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_spacing.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';

class Step3Payment extends StatefulWidget {
  final Invoice invoice;
  final Function(Invoice) onInvoiceUpdate;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const Step3Payment({
    super.key,
    required this.invoice,
    required this.onInvoiceUpdate,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<Step3Payment> createState() => _Step3PaymentState();
}

class _Step3PaymentState extends State<Step3Payment> {
  final _amountController = TextEditingController();
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  String? _selectedCashBox = 'الصندوق الرئيسي';
  String? _selectedBank = 'الراجحي';
  String? _transferNumber;
  String? _senderName;
  DateTime? _deferredDate;

  bool _showOverpaymentWarning = false;
  double _overpaymentAmount = 0;
  bool _showUnderpaymentWarning = false;
  double _underpaymentAmount = 0;

  @override
  void initState() {
    super.initState();
    // Default payment amount is the full remaining balance
    _amountController.text = widget.invoice.remaining > 0
        ? widget.invoice.remaining.toStringAsFixed(0)
        : '0';

    _amountController.addListener(_validateAmount);
  }

  @override
  void dispose() {
    _amountController.removeListener(_validateAmount);
    _amountController.dispose();
    super.dispose();
  }

  void _validateAmount() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    setState(() {
      if (amount > widget.invoice.remaining && widget.invoice.remaining > 0) {
        _showOverpaymentWarning = true;
        _overpaymentAmount = amount - widget.invoice.remaining;
        _showUnderpaymentWarning = false;
        _underpaymentAmount = 0;
      } else if (amount < widget.invoice.remaining && amount > 0) {
        _showUnderpaymentWarning = true;
        _underpaymentAmount = widget.invoice.remaining - amount;
        _showOverpaymentWarning = false;
        _overpaymentAmount = 0;
      } else {
        _showOverpaymentWarning = false;
        _overpaymentAmount = 0;
        _showUnderpaymentWarning = false;
        _underpaymentAmount = 0;
      }
    });
  }

  void _addPayment() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    // Check if adding this payment causes overpayment
    final newPayment = Payment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      method: _selectedMethod,
      amount: amount,
      details: _selectedMethod == PaymentMethod.cash
          ? _selectedCashBox
          : _selectedMethod == PaymentMethod.bank
          ? '$_selectedBank - ${_transferNumber ?? ''}'
          : _deferredDate != null
          ? 'استحقاق: ${_deferredDate!.year}-${_deferredDate!.month}-${_deferredDate!.day}'
          : null,
      date: DateTime.now(),
    );

    final updatedPayments = [...widget.invoice.payments, newPayment];

    // Auto convert to deferred if cash is insufficient and remaining is leftover
    if (_selectedMethod == PaymentMethod.cash &&
        amount < widget.invoice.remaining) {
      final remainingAmount = widget.invoice.remaining - amount;
      final deferredPayment = Payment(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        method: PaymentMethod.deferred,
        amount: remainingAmount,
        details: 'آجل تلقائي',
        date: DateTime.now(),
      );

      widget.onInvoiceUpdate(
        widget.invoice.copyWith(
          payments: [...updatedPayments, deferredPayment],
        ),
      );

      _amountController.text = '0';

      AppToast.showSuccess(
        context,
        'تم تسجيل ${NumberFormatter.formatCurrency(amount)} نقداً و ${NumberFormatter.formatCurrency(remainingAmount)} كدين على العميل',
      );
    } else {
      widget.onInvoiceUpdate(
        widget.invoice.copyWith(payments: updatedPayments),
      );

      // Update amount for next payment
      final newRemaining =
          widget.invoice.total -
          updatedPayments.fold(0.0, (sum, p) => sum + p.amount);

      if (newRemaining > 0) {
        _amountController.text = newRemaining.toStringAsFixed(0);
      } else {
        _amountController.text = '0';
      }

      // Show appropriate message
      if (amount > widget.invoice.remaining) {
        AppToast.showWarning(
          context,
          'تم إضافة دفعة ${NumberFormatter.formatCurrency(amount)} - المبلغ الزائد ${NumberFormatter.formatCurrency(_overpaymentAmount)} سيضاف لرصيد العميل',
        );
      }
    }
  }

  void _removePayment(int index) {
    final updatedPayments = List<Payment>.from(widget.invoice.payments);
    updatedPayments.removeAt(index);
    widget.onInvoiceUpdate(widget.invoice.copyWith(payments: updatedPayments));
  }

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

  String _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return '💵';
      case PaymentMethod.bank:
        return '🏦';
      case PaymentMethod.deferred:
        return '📅';
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'المبلغ الإجمالي',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        NumberFormatter.formatCurrency(widget.invoice.total),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'مدفوع',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                NumberFormatter.formatNumber(
                                  widget.invoice.paid,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'متبقي',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                NumberFormatter.formatNumber(
                                  widget.invoice.remaining,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Payment Method Selector
                Row(
                  children: PaymentMethod.values.map((method) {
                    final isSelected = _selectedMethod == method;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedMethod = method),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.gray300,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _getPaymentMethodIcon(method),
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getPaymentMethodLabel(method),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.gray800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Payment Form
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'المبلغ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: AppColors.gray600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextInputField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'أدخل المبلغ',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: BorderSide(
                              color: _showOverpaymentWarning
                                  ? Colors.orange
                                  : (_showUnderpaymentWarning
                                        ? Colors.blue
                                        : AppColors.grey300),
                              width: 2,
                            ),
                          ),
                          suffixText: 'ريال',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Method-specific fields
                      if (_selectedMethod == PaymentMethod.cash) ...[
                        const Text(
                          'الصندوق',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: AppColors.gray600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          initialValue: _selectedCashBox,
                          items: const [
                            DropdownMenuItem(
                              value: 'الصندوق الرئيسي',
                              child: Text('الصندوق الرئيسي'),
                            ),
                            DropdownMenuItem(
                              value: 'صندوق فرع الشمال',
                              child: Text('صندوق فرع الشمال'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedCashBox = value);
                          },
                        ),
                      ],

                      if (_selectedMethod == PaymentMethod.bank) ...[
                        const Text(
                          'البنك',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: AppColors.gray600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          initialValue: _selectedBank,
                          items: const [
                            DropdownMenuItem(
                              value: 'الراجحي',
                              child: Text('الراجحي'),
                            ),
                            DropdownMenuItem(
                              value: 'الأهلي',
                              child: Text('الأهلي'),
                            ),
                            DropdownMenuItem(
                              value: 'الإنماء',
                              child: Text('الإنماء'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedBank = value);
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ExpandableSection(
                          title: 'تفاصيل التحويل',
                          child: Column(
                            children: [
                              const SizedBox(height: AppSpacing.md),
                              TextInputField(
                                onChanged: (value) => _transferNumber = value,
                                decoration: InputDecoration(
                                  labelText: 'رقم الحوالة',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextInputField(
                                onChanged: (value) => _senderName = value,
                                decoration: InputDecoration(
                                  labelText: 'اسم المرسل',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_selectedMethod == PaymentMethod.deferred) ...[
                        const Text(
                          'تاريخ الاستحقاق',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: AppColors.gray600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        InkWell(
                          onTap: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate:
                                  _deferredDate ??
                                  DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (selectedDate != null) {
                              setState(() => _deferredDate = selectedDate);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: AppColors.grey300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  _deferredDate != null
                                      ? '${_deferredDate!.year}-${_deferredDate!.month.toString().padLeft(2, '0')}-${_deferredDate!.day.toString().padLeft(2, '0')}'
                                      : 'اختر التاريخ',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                    color: AppColors.gray900,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Show warnings for overpayment or underpayment
                if (_showOverpaymentWarning) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.orange),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'مبلغ زائد',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              Text(
                                'المبلغ الزائد ${NumberFormatter.formatCurrency(_overpaymentAmount)} سيتم إضافته لرصيد العميل',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_showUnderpaymentWarning) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'دفعة جزئية',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                'المبلغ المتبقي ${NumberFormatter.formatCurrency(_underpaymentAmount)} سيتم تسجيله كدين على العميل',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (widget.invoice.remaining > 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(
                        widget.invoice.remaining == widget.invoice.total
                            ? 'إضافة دفعة (${NumberFormatter.formatCurrency(double.tryParse(_amountController.text) ?? 0)})'
                            : 'إضافة باقي المبلغ (${NumberFormatter.formatCurrency(widget.invoice.remaining)})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],

                // Added Payments
                if (widget.invoice.payments.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'الدفعات المضافة:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray900,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...List.generate(widget.invoice.payments.length, (index) {
                    final payment = widget.invoice.payments[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getPaymentMethodLabel(payment.method),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray900,
                                  height: 1.5,
                                ),
                              ),
                              Text(
                                NumberFormatter.formatCurrency(payment.amount),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                  color: AppColors.gray600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => _removePayment(index),
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.error,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                if (widget.invoice.remaining > 0 &&
                    _selectedMethod == PaymentMethod.deferred) ...[
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
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray900,
                                  height: 1.5,
                                ),
                              ),
                              Text(
                                'المبلغ المتبقي ${NumberFormatter.formatCurrency(widget.invoice.remaining)} سيتم إضافته كمديونية',
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
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.grey200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: HasibButton(
                  label: 'رجوع',
                  onPressed: widget.onPrevious,
                  variant: HasibButtonVariant.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: HasibButton(
                  label: 'مراجعة وحفظ',
                  onPressed: widget.onNext,
                  variant: HasibButtonVariant.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
