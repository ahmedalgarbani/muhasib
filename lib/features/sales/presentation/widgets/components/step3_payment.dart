import 'package:flutter/material.dart';
import 'package:muhasib/features/sales/presentation/widgets/sale_form.dart';

class Step3Payment extends StatefulWidget {
  final Invoice invoice;
  final Function(Invoice) onInvoiceUpdate;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const Step3Payment({
    Key? key,
    required this.invoice,
    required this.onInvoiceUpdate,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  State<Step3Payment> createState() => _Step3PaymentState();
}

class _Step3PaymentState extends State<Step3Payment> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  late TextEditingController _amountController;
  String? _selectedCashBox = 'الصندوق الرئيسي';
  String? _selectedBank = 'الراجحي';
  String? _transferNumber;
  String? _senderName;
  DateTime? _deferredDate;
  bool _showOverpaymentWarning = false;
  bool _showUnderpaymentWarning = false;
  double _overpaymentAmount = 0;
  double _underpaymentAmount = 0;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.invoice.remaining.toStringAsFixed(0),
    );
    _amountController.addListener(_onAmountChanged);
    _deferredDate = DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final remaining = widget.invoice.remaining;
    
    setState(() {
      if (amount > remaining) {
        _showOverpaymentWarning = true;
        _showUnderpaymentWarning = false;
        _overpaymentAmount = amount - remaining;
        _underpaymentAmount = 0;
      } else if (amount < remaining && amount > 0) {
        _showUnderpaymentWarning = true;
        _showOverpaymentWarning = false;
        _underpaymentAmount = remaining - amount;
        _overpaymentAmount = 0;
      } else {
        _showOverpaymentWarning = false;
        _showUnderpaymentWarning = false;
        _overpaymentAmount = 0;
        _underpaymentAmount = 0;
      }
    });
  }

  void _updateAmountForNewMethod() {
    // Update amount controller when switching payment methods
    final currentRemaining = widget.invoice.remaining;
    if (currentRemaining > 0) {
      _amountController.text = currentRemaining.toStringAsFixed(0);
    }
  }

  void _addPayment() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount > 0) {
      Map<String, dynamic>? details;
      
      // Collect payment method specific details
      if (_selectedMethod == PaymentMethod.cash) {
        details = {'cashBox': _selectedCashBox};
      } else if (_selectedMethod == PaymentMethod.bank) {
        details = {
          'bank': _selectedBank,
          'transferNumber': _transferNumber,
          'senderName': _senderName,
        };
      } else if (_selectedMethod == PaymentMethod.deferred) {
        details = {
          'dueDate': _deferredDate?.toIso8601String(),
        };
      }
      
      final updatedPayments = [
        ...widget.invoice.payments,
        Payment(
          method: _selectedMethod,
          amount: amount,
          details: details,
        ),
      ];
      
      widget.onInvoiceUpdate(
        widget.invoice.copyWith(payments: updatedPayments),
      );
      
      // Update amount for next payment
      final newRemaining = widget.invoice.total - 
          updatedPayments.fold(0.0, (sum, p) => sum + p.amount);
      
      if (newRemaining > 0) {
        _amountController.text = newRemaining.toStringAsFixed(0);
      } else {
        _amountController.text = '0';
      }
      
      // Show appropriate message
      if (amount > widget.invoice.remaining) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إضافة دفعة ${NumberFormatter.formatCurrency(amount)} - المبلغ الزائد ${NumberFormatter.formatCurrency(_overpaymentAmount)} سيضاف لرصيد العميل',
            ),
            backgroundColor: Colors.orange,
          ),
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
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(16),
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

                // Payment Method Selection
                const Text('طريقة الدفع', style: AppTextStyles.body),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: PaymentMethod.values.map((method) {
                    final isSelected = _selectedMethod == method;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedMethod = method;
                              _updateAmountForNewMethod();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.1)
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.grey300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
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
                                  style: AppTextStyles.small.copyWith(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.grey700,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('المبلغ', style: AppTextStyles.caption),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'أدخل المبلغ',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
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
                        const Text('الصندوق', style: AppTextStyles.caption),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          value: _selectedCashBox,
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
                        const Text('البنك', style: AppTextStyles.caption),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          value: _selectedBank,
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
                              TextField(
                                onChanged: (value) => _transferNumber = value,
                                decoration: InputDecoration(
                                  labelText: 'رقم الحوالة',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextField(
                                onChanged: (value) => _senderName = value,
                                decoration: InputDecoration(
                                  labelText: 'اسم المرسل',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
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
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        InkWell(
                          onTap: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: _deferredDate ?? DateTime.now().add(
                                const Duration(days: 30),
                              ),
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  _deferredDate != null
                                      ? '${_deferredDate!.year}-${_deferredDate!.month.toString().padLeft(2, '0')}-${_deferredDate!.day.toString().padLeft(2, '0')}'
                                      : 'اختر التاريخ',
                                  style: AppTextStyles.body,
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
                      borderRadius: BorderRadius.circular(12),
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
                      borderRadius: BorderRadius.circular(12),
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
                          borderRadius: BorderRadius.circular(12),
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
                    style: AppTextStyles.bodyMedium,
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getPaymentMethodLabel(payment.method),
                                style: AppTextStyles.bodyMedium,
                              ),
                              Text(
                                NumberFormatter.formatCurrency(payment.amount),
                                style: AppTextStyles.small,
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
                                'المبلغ المتبقي ${NumberFormatter.formatCurrency(widget.invoice.remaining)} سيتم إضافته كمديونية',
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
                child: SecondaryButton(
                  text: 'رجوع',
                  onPressed: widget.onPrevious,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  text: 'مراجعة وحفظ',
                  onPressed: widget.onNext,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// lib/screens/sales_invoice/steps/step_4_review.dart
