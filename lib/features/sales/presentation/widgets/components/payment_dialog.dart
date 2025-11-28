import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muhasib/features/sales/presentation/widgets/sale_form.dart';

class PaymentDialog extends StatefulWidget {
  final double totalAmount;
  final List<Payment> existingPayments;
  final Function(List<Payment>) onPaymentsUpdate;

  const PaymentDialog({
    Key? key,
    required this.totalAmount,
    required this.existingPayments,
    required this.onPaymentsUpdate,
  }) : super(key: key);

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  List<Payment> _payments = [];
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _payments = List.from(widget.existingPayments);
    _updateSuggestedAmount();
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

    // Check for overpayment
    final newTotal = _totalPaid + amount;
    if (newTotal > widget.totalAmount) {
      final overpayment = newTotal - widget.totalAmount;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('دفعة زائدة'),
          content: Text(
            'المبلغ المدخل يزيد عن إجمالي الفاتورة بمقدار ${NumberFormatter.formatCurrency(overpayment)}\n'
            'سيتم ترحيل المبلغ الزائد إلى رصيد العميل.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmAddPayment(amount);
              },
              child: const Text('موافق'),
            ),
          ],
        ),
      );
    } else {
      _confirmAddPayment(amount);
    }
  }

  void _confirmAddPayment(double amount) {
    setState(() {
      _payments.add(Payment(
        method: _selectedMethod,
        amount: amount,
        details: _selectedMethod == PaymentMethod.bank && _referenceController.text.isNotEmpty
            ? {'reference': _referenceController.text}
            : null,
      ));
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
        builder: (context) => AlertDialog(
          title: const Text('دفعة جزئية'),
          content: Text(
            'المبلغ المدفوع أقل من إجمالي الفاتورة بمقدار ${NumberFormatter.formatCurrency(_remainingAmount)}\n'
            'سيتم تسجيل المبلغ المتبقي كدين على العميل.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onPaymentsUpdate(_payments);
                Navigator.pop(this.context);
              },
              child: const Text('موافق'),
            ),
          ],
        ),
      );
    } else {
      widget.onPaymentsUpdate(_payments);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'طرق الدفع',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAmountInfo(
                          'الإجمالي',
                          widget.totalAmount,
                          Colors.white,
                        ),
                        _buildAmountInfo(
                          'المدفوع',
                          _totalPaid,
                          Colors.greenAccent,
                        ),
                        _buildAmountInfo(
                          'المتبقي',
                          _remainingAmount.abs(),
                          _hasOverpayment ? Colors.orangeAccent : Colors.yellowAccent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Payment Methods
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Method Selection
                    const Text(
                      'طريقة الدفع',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPaymentMethodChip(
                          PaymentMethod.cash,
                          'نقدي',
                          Icons.payments,
                        ),
                        const SizedBox(width: 8),
                        _buildPaymentMethodChip(
                          PaymentMethod.bank,
                          'بنكي',
                          Icons.account_balance,
                        ),
                        const SizedBox(width: 8),
                        _buildPaymentMethodChip(
                          PaymentMethod.deferred,
                          'آجل',
                          Icons.schedule,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Amount Input
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _amountController,
                            decoration: InputDecoration(
                              labelText: 'المبلغ',
                              prefixIcon: const Icon(Icons.attach_money),
                              suffixText: 'ريال',
                              border: const OutlineInputBorder(),
                              errorText: _errorMessage,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _remainingAmount > 0 ? () {
                            _amountController.text = _remainingAmount.toStringAsFixed(2);
                          } : null,
                          icon: const Icon(Icons.auto_fix_high),
                          label: Text(
                            _remainingAmount > 0 
                                ? 'إضافة ${NumberFormatter.formatCurrency(_remainingAmount)}'
                                : 'مكتمل',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                    
                    // Bank Reference (if bank payment)
                    if (_selectedMethod == PaymentMethod.bank) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _referenceController,
                        decoration: const InputDecoration(
                          labelText: 'رقم المرجع (اختياري)',
                          prefixIcon: Icon(Icons.confirmation_number),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addPayment,
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة دفعة'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    
                    // Payments List
                    if (_payments.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'الدفعات المضافة',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ..._payments.asMap().entries.map((entry) {
                        final index = entry.key;
                        final payment = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              payment.method == PaymentMethod.cash
                                  ? Icons.payments
                                  : payment.method == PaymentMethod.bank
                                      ? Icons.account_balance
                                      : Icons.schedule,
                              color: const Color(0xFF2563EB),
                            ),
                            title: Text(
                              _getPaymentMethodName(payment.method),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: payment.details?['reference'] != null
                                ? Text('مرجع: ${payment.details!['reference']}')
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
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _savePayments,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFullyPaid ? Colors.green : const Color(0xFF2563EB),
                    ),
                    child: Text(_isFullyPaid ? 'تأكيد الدفع' : 'حفظ الدفعات'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInfo(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          NumberFormatter.formatCurrency(amount),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodChip(PaymentMethod method, String label, IconData icon) {
    final isSelected = _selectedMethod == method;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedMethod = method);
        }
      },
      selectedColor: const Color(0xFF2563EB).withOpacity(0.2),
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
