import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/custom_confirm_dialog.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/payment_method_chip_widget.dart';
import 'package:muhasib/features/settings_entities/domain/entities/bank_entity.dart';
import 'package:muhasib/features/settings_entities/domain/repositories/bank_repository.dart';

class PaymentDialog extends StatefulWidget {
  final double totalAmount;
  final List<Payment> existingPayments;
  final Function(List<Payment>) onPaymentsUpdate;

  const PaymentDialog({
    super.key,
    required this.totalAmount,
    required this.existingPayments,
    required this.onPaymentsUpdate,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  List<Payment> _payments = [];
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  String? _errorMessage;
  List<BankEntity> _banks = [];
  int? _selectedBankId;
  bool _loadingBanks = false;

  @override
  void initState() {
    super.initState();
    _payments = List.from(widget.existingPayments);
    _updateSuggestedAmount();
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    setState(() => _loadingBanks = true);
    try {
      final repo = getIt<BankRepository>();
      final res = await repo.getActiveBanks();
      final list = res.fold((_) => <BankEntity>[], (l) => l);
      if (mounted) {
        setState(() {
          _banks = list;
          if (_banks.isNotEmpty && _selectedBankId == null) {
            _selectedBankId = _banks.first.id;
          }
          _loadingBanks = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBanks = false);
    }
  }

  double get _totalPaid => _payments.fold(0, (sum, p) => sum + p.amount);
  double get _remainingAmount => widget.totalAmount - _totalPaid;
  bool get _isFullyPaid => _remainingAmount <= 0;
  bool get _hasOverpayment => _remainingAmount < 0;

  void _updateSuggestedAmount() {
    if (_remainingAmount > 0) {
      _amountController.text = _remainingAmount.toStringAsFixed(2);
    } else {
      _amountController.clear();
    }
  }

  void _addPayment() {
    final amount = double.tryParse(_amountController.text);

    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'يرجى إدخال مبلغ صحيح');
      return;
    }

    final newTotal = _totalPaid + amount;
    if (newTotal > widget.totalAmount) {
      final overpayment = newTotal - widget.totalAmount;
      showDialog(
        context: context,
        builder: (context) => CustomConfirmDialog(
          title: 'دفعة زائدة',
          message:
              'المبلغ المدخل يزيد عن إجمالي الفاتورة بمقدار ${NumberFormatter.formatCurrency(overpayment)}\nسيتم ترحيل المبلغ الزائد إلى رصيد العميل.',
          confirmLabel: 'موافق',
          onConfirm: () => _confirmAddPayment(amount),
        ),
      );
    } else {
      _confirmAddPayment(amount);
    }
  }

  void _confirmAddPayment(double amount) {
    String? bankName;
    if (_selectedMethod == PaymentMethod.bank && _selectedBankId != null) {
      try {
        bankName = _banks.firstWhere((b) => b.id == _selectedBankId).name;
      } catch (_) {}
    }
    setState(() {
      _payments.add(
        Payment(
          method: _selectedMethod,
          amount: amount,
          details: _selectedMethod == PaymentMethod.bank
              ? {
                  if (_referenceController.text.isNotEmpty)
                    'reference': _referenceController.text,
                  if (_selectedBankId != null) 'bank_id': _selectedBankId,
                  if (bankName != null) 'bank_name': bankName,
                }
              : null,
        ),
      );
      _errorMessage = null;
      _amountController.clear();
      _referenceController.clear();
      _updateSuggestedAmount();
    });
  }

  void _removePayment(int index) {
    setState(() {
      _payments.removeAt(index);
      _updateSuggestedAmount();
    });
  }

  void _savePayments() {
    if (_payments.isEmpty) {
      setState(() => _errorMessage = 'يرجى إضافة طريقة دفع واحدة على الأقل');
      return;
    }

    if (_remainingAmount > 0) {
      showDialog(
        context: context,
        builder: (context) => CustomConfirmDialog(
          title: 'دفعة جزئية',
          message:
              'المبلغ المدفوع أقل من إجمالي الفاتورة بمقدار ${NumberFormatter.formatCurrency(_remainingAmount)}\nسيتم تسجيل المبلغ المتبقي كدين على العميل.',
          confirmLabel: 'موافق',
          onConfirm: () {
            widget.onPaymentsUpdate(_payments);
            Navigator.pop(this.context);
          },
        ),
      );
    } else {
      widget.onPaymentsUpdate(_payments);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'طرق الدفع',
      subtitle:
          'إجمالي الفاتورة: ${NumberFormatter.formatCurrency(widget.totalAmount)} | المدفوع: ${NumberFormatter.formatCurrency(_totalPaid)} | المتبقي: ${NumberFormatter.formatCurrency(_remainingAmount.abs())}',
      icon: Icons.payments,
      maxWidth: 600,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'طريقة الدفع',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(

            children: [
              PaymentMethodChipWidget(
                method: PaymentMethod.cash,
                label: 'نقدي',
                icon: Icons.payments,
                isSelected: _selectedMethod == PaymentMethod.cash,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedMethod = PaymentMethod.cash);
                  }
                },
              ),
              const SizedBox(width: 8),
              PaymentMethodChipWidget(
                method: PaymentMethod.bank,
                label: 'بنكي',
                icon: Icons.account_balance,
                isSelected: _selectedMethod == PaymentMethod.bank,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedMethod = PaymentMethod.bank);
                  }
                },
              ),
              const SizedBox(width: 8),
              PaymentMethodChipWidget(
                method: PaymentMethod.deferred,
                label: 'آجل',
                icon: Icons.schedule,
                isSelected: _selectedMethod == PaymentMethod.deferred,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedMethod = PaymentMethod.deferred);
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextInputField(
                  label: 'المبلغ',
                  textEditingController: _amountController,
                  inputType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    DecimalTextInputFormatter(),
                  ],
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixIcon: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('ريال'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: HasibButton(
                  label: _remainingAmount > 0
                      ? 'إضافة ${NumberFormatter.formatCurrency(_remainingAmount)}'
                      : 'مكتمل',
                  onPressed: _remainingAmount > 0
                      ? () {
                          _amountController.text = _remainingAmount
                              .toStringAsFixed(2);
                        }
                      : null,
                  variant: HasibButtonVariant.secondary,
                ),
              ),
            ],
          ),

          if (_selectedMethod == PaymentMethod.bank) ...[
            const SizedBox(height: 16),
            if (_loadingBanks)
              const LinearProgressIndicator()
            else if (_banks.isNotEmpty)
              CustomDropdownField<int>(
                value: _selectedBankId,
                label: 'البنك',
                prefixIcon: const Icon(Icons.account_balance, size: 18),
                items: _banks
                    .map(
                      (b) => DropdownMenuItem<int>(
                        value: b.id,
                        child: Text(b.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedBankId = v),
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Text(
                  'لا توجد بنوك مفعلة. أضف بنكاً من الإعدادات.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            TextInputField(
              label: 'رقم المرجع / الحوالة (اختياري)',
              textEditingController: _referenceController,
              prefixIcon: const Icon(Icons.confirmation_number),
              hint: 'مرجع العملية البنكية',
            ),
          ],

          const SizedBox(height: 16),
          HasibButton(
            label: 'إضافة دفعة',
            leading: const Icon(Icons.add, color: Colors.white),
            onPressed: _addPayment,
            variant: HasibButtonVariant.primary,
          ),

          if (_payments.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'الدفعات المضافة',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._payments.asMap().entries.map((entry) {
              final index = entry.key;
              final payment = entry.value;
              return CustomCardContainer(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    payment.method == PaymentMethod.cash
                        ? Icons.payments
                        : payment.method == PaymentMethod.bank
                        ? Icons.account_balance
                        : Icons.schedule,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    _getPaymentMethodName(payment.method),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: (payment.details?['bank_name'] != null ||
                          payment.details?['reference'] != null)
                      ? Text(
                          [
                            if (payment.details?['bank_name'] != null)
                              'البنك: ${payment.details!['bank_name']}',
                            if (payment.details?['reference'] != null)
                              'مرجع: ${payment.details!['reference']}',
                          ].join(' • '),
                          style: const TextStyle(fontSize: 11),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        NumberFormatter.formatCurrency(payment.amount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removePayment(index),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
      actions: [
        HasibButton(
          label: 'إلغاء',
          onPressed: () => Navigator.pop(context),
          variant: HasibButtonVariant.secondary,
        ),
        const SizedBox(width: 12),
        HasibButton(
          label: _isFullyPaid ? 'تأكيد الدفع' : 'حفظ الدفعات',
          onPressed: _savePayments,
          variant: _isFullyPaid
              ? HasibButtonVariant.success
              : HasibButtonVariant.primary,
        ),
      ],
    );
  }

  String _getPaymentMethodName(PaymentMethod method) {

    switch (method) {
      case PaymentMethod.cash:
        return 'نقدي';
      case PaymentMethod.bank:
        return 'بنكي';
      case PaymentMethod.deferred:
        return 'آجل';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }
}
