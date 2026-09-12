import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/formatters.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_card_container.dart';
import 'package:muhasib/core/widgets/custom_dropdown_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/payment_method_chip_widget.dart';
import 'package:muhasib/features/settings_entities/domain/entities/bank_entity.dart';
import 'package:muhasib/features/settings_entities/domain/repositories/bank_repository.dart';

/// صفحة تحرير الدفعات - كصفحة كاملة بدل Dialog
class PaymentEditorPage extends StatefulWidget {
  final double totalAmount;
  final List<Payment> existingPayments;

  const PaymentEditorPage({
    super.key,
    required this.totalAmount,
    required this.existingPayments,
  });

  @override
  State<PaymentEditorPage> createState() => _PaymentEditorPageState();
}

class _PaymentEditorPageState extends State<PaymentEditorPage> {
  late List<Payment> _payments;
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  List<BankEntity> _banks = [];
  int? _selectedBankId;
  bool _loadingBanks = false;

  double get _totalPaid => _payments.fold(0, (s, p) => s + p.amount);
  double get _remaining => widget.totalAmount - _totalPaid;
  bool get _fullyPaid => _remaining <= 0;

  @override
  void initState() {
    super.initState();
    _payments = List.from(widget.existingPayments);
    _amountCtrl.text = _remaining > 0 ? _remaining.toStringAsFixed(2) : '';
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    setState(() => _loadingBanks = true);
    try {
      final res = await getIt<BankRepository>().getActiveBanks();
      final list = res.fold((_) => <BankEntity>[], (l) => l);
      if (mounted) {
        setState(() {
          _banks = list;
          if (_banks.isNotEmpty) _selectedBankId = _banks.first.id;
          _loadingBanks = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBanks = false);
    }
  }

  void _addPayment() {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال مبلغ صحيح')));
      return;
    }
    String? bankName;
    if (_selectedMethod == PaymentMethod.bank && _selectedBankId != null) {
      try {
        bankName = _banks.firstWhere((b) => b.id == _selectedBankId).name;
      } catch (_) {}
    }
    setState(() {
      _payments.add(Payment(
        method: _selectedMethod,
        amount: amount,
        details: _selectedMethod == PaymentMethod.bank
            ? {
                if (_refCtrl.text.isNotEmpty) 'reference': _refCtrl.text,
                if (_selectedBankId != null) 'bank_id': _selectedBankId,
                if (bankName != null) 'bank_name': bankName,
              }
            : null,
        date: DateTime.now(),
      ));
      _amountCtrl.text = (_remaining > 0 ? _remaining.toStringAsFixed(2) : '');
      _refCtrl.clear();
    });
  }

  void _removeAt(int idx) => setState(() => _payments.removeAt(idx));

  void _save() {
    if (_payments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف طريقة دفع واحدة على الأقل')));
      return;
    }
    Navigator.pop(context, _payments);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(title: 'طرق الدفع'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CustomCardContainer(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('الإجمالي', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    Text(NumberFormatter.formatCurrency(widget.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('المدفوع', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(NumberFormatter.formatCurrency(_totalPaid), style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                  ]),
                  const Divider(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('المتبقي', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(NumberFormatter.formatCurrency(_remaining.abs()), style: TextStyle(fontWeight: FontWeight.bold, color: _remaining > 0 ? Colors.orange : Colors.green)),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('اختر طريقة الدفع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: PaymentMethod.values.map((m) {
            final isSel = _selectedMethod == m;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(m == PaymentMethod.cash ? 'نقدي' : m == PaymentMethod.bank ? 'بنكي' : 'آجل'),
                  avatar: Icon(m == PaymentMethod.cash ? Icons.payments : m == PaymentMethod.bank ? Icons.account_balance : Icons.schedule, size: 16),
                  selected: isSel,
                  onSelected: (v) { if (v) setState(() => _selectedMethod = m); },
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 16),
          CustomCardContainer(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextInputField(
                    label: 'المبلغ',
                    textEditingController: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [DecimalTextInputFormatter()],
                    prefixIcon: const Icon(Icons.attach_money, size: 18),
                  ),
                  if (_selectedMethod == PaymentMethod.bank) ...[
                    const SizedBox(height: 12),
                    if (_loadingBanks)
                      const LinearProgressIndicator()
                    else if (_banks.isNotEmpty)
                      CustomDropdownField<int>(
                        value: _selectedBankId,
                        label: 'البنك',
                        prefixIcon: const Icon(Icons.account_balance, size: 18),
                        items: _banks.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) => setState(() => _selectedBankId = v),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade200)),
                        child: const Text('لا توجد بنوك، أضف من الإعدادات', style: TextStyle(fontSize: 12)),
                      ),
                    const SizedBox(height: 12),
                    TextInputField(
                      label: 'مرجع العملية (اختياري)',
                      textEditingController: _refCtrl,
                      prefixIcon: const Icon(Icons.confirmation_number, size: 18),
                      hint: 'رقم الحوالة أو المرجع',
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: HasibButton(
                      label: 'إضافة دفعة',
                      onPressed: _addPayment,
                      leading: const Icon(Icons.add, size: 18, color: Colors.white),
                      variant: HasibButtonVariant.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_payments.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('الدفعات المضافة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ..._payments.asMap().entries.map((e) {
              final idx = e.key;
              final p = e.value;
              return CustomCardContainer(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  leading: Icon(p.method == PaymentMethod.cash ? Icons.payments : p.method == PaymentMethod.bank ? Icons.account_balance : Icons.schedule, color: AppColors.primary),
                  title: Text(p.method == PaymentMethod.cash ? 'نقدي' : p.method == PaymentMethod.bank ? 'بنكي' : 'آجل', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: p.details?['bank_name'] != null || p.details?['reference'] != null
                      ? Text([if (p.details?['bank_name'] != null) 'البنك: ${p.details!['bank_name']}', if (p.details?['reference'] != null) 'مرجع: ${p.details!['reference']}'].join(' • '), style: const TextStyle(fontSize: 11))
                      : null,
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(NumberFormatter.formatCurrency(p.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _removeAt(idx)),
                  ]),
                ),
              );
            }),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء'))),
            const SizedBox(width: 12),
            Expanded(
              child: HasibButton(
                label: _fullyPaid ? 'تأكيد وعودة' : 'حفظ الدفعات',
                onPressed: _save,
                variant: _fullyPaid ? HasibButtonVariant.success : HasibButtonVariant.primary,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
