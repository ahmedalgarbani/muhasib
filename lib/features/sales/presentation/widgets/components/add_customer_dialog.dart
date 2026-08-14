import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/features/sales/presentation/models/sale_invoice_models.dart';
import 'package:muhasib/features/customers/presentation/widgets/party_profile_widgets.dart';

enum BalanceDirection {
  debit, // عليه (مدين)
  credit, // له (دائن)
}

class AddCustomerDialog extends StatefulWidget {
  /// partyType: 1 = customer, 2 = supplier
  final int partyType;
  final Customer? initialCustomer;

  const AddCustomerDialog({
    super.key,
    this.partyType = 1,
    this.initialCustomer,
  });

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _creditLimitController;
  late final TextEditingController _openingBalanceController;

  late BalanceDirection _balanceDirection;
  bool _isLoading = false;

  bool get _isEditing => widget.initialCustomer != null;
  bool get _isSupplier => (widget.initialCustomer?.type ?? widget.partyType) == 2;

  @override
  void initState() {
    super.initState();
    final customer = widget.initialCustomer;
    _nameController = TextEditingController(text: customer?.name ?? '');
    _phoneController = TextEditingController(text: customer?.phone ?? '');
    _addressController = TextEditingController(text: customer?.address ?? '');
    _creditLimitController = TextEditingController(
      text: customer != null ? customer.creditLimit.toStringAsFixed(0) : '0',
    );
    _openingBalanceController = TextEditingController(text: '0');

    // Default direction:
    // Customer (1): default is debit (عليه / مدين)
    // Supplier (2): default is credit (له / دائن)
    if (_isSupplier) {
      _balanceDirection = BalanceDirection.credit;
    } else {
      _balanceDirection = BalanceDirection.debit;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _creditLimitController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cubit = context.read<CustomersCubit>();
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
      final address = _addressController.text.trim().isEmpty ? null : _addressController.text.trim();
      final creditLimit = double.tryParse(_creditLimitController.text.trim()) ?? 0.0;

      if (_isEditing) {
        final partyId = int.tryParse(widget.initialCustomer!.id);
        if (partyId == null) {
          throw Exception('معرف العميل غير صالح');
        }

        final success = await cubit.updateCustomer(
          id: partyId,
          name: name,
          phone: phone,
          address: address,
          creditLimit: creditLimit,
          type: _isSupplier ? 2 : 1,
        );

        if (success && mounted) {
          final updatedCustomer = widget.initialCustomer!.copyWith(
            name: name,
            phone: phone,
            address: address,
            creditLimit: creditLimit,
          );
          Navigator.of(context).pop(updatedCustomer);
          AppToast.showSuccess(
            context,
            _isSupplier
                ? 'تم تحديث بيانات المورد "$name" بنجاح'
                : 'تم تحديث بيانات العميل "$name" بنجاح',
          );
        }
      } else {
        // Calculate signed opening balance
        final rawAmount = double.tryParse(_openingBalanceController.text.trim()) ?? 0.0;
        final absAmount = rawAmount.abs();

        double signedOpeningBalance = 0.0;
        if (absAmount > 0) {
          if (!_isSupplier) {
            // Customer:
            // debit ("عليه") => positive (+)
            // credit ("له") => negative (-)
            signedOpeningBalance = _balanceDirection == BalanceDirection.debit ? absAmount : -absAmount;
          } else {
            // Supplier:
            // credit ("له") => positive (+)
            // debit ("عليه") => negative (-)
            signedOpeningBalance = _balanceDirection == BalanceDirection.credit ? absAmount : -absAmount;
          }
        }

        final customer = await cubit.addCustomer(
          name: name,
          phone: phone,
          address: address,
          type: _isSupplier ? 2 : 1,
          creditLimit: creditLimit,
          openingBalance: signedOpeningBalance,
        );

        if (customer != null && mounted) {
          Navigator.of(context).pop(customer);
          AppToast.showSuccess(
            context,
            _isSupplier
                ? 'تم إضافة المورد "${customer.name}" بنجاح'
                : 'تم إضافة العميل "${customer.name}" بنجاح',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          'خطأ أثناء الحفظ: ${e.toString().replaceAll("Exception: ", "")}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dialogTitle = _isEditing
        ? (_isSupplier ? 'تعديل بيانات المورد' : 'تعديل بيانات العميل')
        : (_isSupplier ? 'إضافة مورد جديد' : 'إضافة عميل جديد');

    return CustomDialog(
      title: dialogTitle,
      icon: _isSupplier ? Icons.business : Icons.person_add,
      maxWidth: 540,
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextInputField(
                label: _isSupplier ? 'اسم المورد' : 'اسم العميل',
                textEditingController: _nameController,
                prefixIcon: Icon(_isSupplier ? Icons.business : Icons.person),
                isRequired: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return _isSupplier ? 'يرجى إدخال اسم المورد' : 'يرجى إدخال اسم العميل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextInputField(
                label: 'رقم الهاتف',
                textEditingController: _phoneController,
                inputType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone),
              ),
              const SizedBox(height: 16),
              TextInputField(
                label: 'العنوان',
                textEditingController: _addressController,
                maxLines: 2,
                prefixIcon: const Icon(Icons.location_on),
              ),
              const SizedBox(height: 16),
              TextInputField(
                label: 'حد الائتمان (اختياري)',
                textEditingController: _creditLimitController,
                inputType: TextInputType.number,
                prefixIcon: const Icon(Icons.credit_card),
                suffixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('ريال'),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'يرجى إدخال رقم صحيح';
                    }
                  }
                  return null;
                },
              ),
              if (!_isEditing) ...[
                const SizedBox(height: 16),
                _buildOpeningBalanceSection(colorScheme),
                const SizedBox(height: 12),
                PartyAccountNotice(isSupplier: _isSupplier),
              ],
            ],
          ),
        ),
      ),
      actions: [
        HasibButton(
          label: 'إلغاء',
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          variant: HasibButtonVariant.secondary,
        ),
        const SizedBox(width: 12),
        HasibButton(
          label: _isEditing ? 'حفظ التعديلات' : 'حفظ',
          loading: _isLoading,
          onPressed: _isLoading ? null : _saveCustomer,
          variant: HasibButtonVariant.primary,
        ),
      ],
    );
  }

  Widget _buildOpeningBalanceSection(ColorScheme colorScheme) {
    final double? currentEnteredAmount = double.tryParse(_openingBalanceController.text.trim());
    final hasAmount = currentEnteredAmount != null && currentEnteredAmount > 0;

    String explanationText;
    if (!_isSupplier) {
      // Customer
      if (_balanceDirection == BalanceDirection.debit) {
        explanationText = 'المبلغ دين مستحق على العميل لصالح المنشأة (مدين / عليه).';
      } else {
        explanationText = 'المبلغ رصيد دائن للعميل أو دفعة سددها مقدماً للمنشأة (دائن / له).';
      }
    } else {
      // Supplier
      if (_balanceDirection == BalanceDirection.credit) {
        explanationText = 'المبلغ مستحق للمورد على المنشأة مقابل بضاعة سابقة (دائن / له).';
      } else {
        explanationText = 'المبلغ دفعة مسددة مقدماً للمورد أو رصيد مسترد للمنشأة (مدين / عليه).';
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                'الرصيد الافتتاحي',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextInputField(
            label: 'مبلغ الرصيد الافتتاحي',
            textEditingController: _openingBalanceController,
            inputType: TextInputType.number,
            prefixIcon: const Icon(Icons.money),
            suffixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('ريال'),
            ),
            onChanged: (val) {
              setState(() {});
            },
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (double.tryParse(value) == null) {
                  return 'يرجى إدخال رقم صحيح';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'طبيعة الرصيد الافتتاحي:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDirectionOption(
                  title: !_isSupplier ? 'عليه (مدين)' : 'عليه (دفعة مقدمة)',
                  subtitle: !_isSupplier ? 'مستحق على العميل' : 'مدفوع له مقدماً',
                  isSelected: _balanceDirection == BalanceDirection.debit,
                  selectedColor: !_isSupplier ? Colors.red : Colors.green,
                  onTap: () {
                    setState(() => _balanceDirection = BalanceDirection.debit);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDirectionOption(
                  title: !_isSupplier ? 'له (دائن / رصيد)' : 'له (دائن / مستحق)',
                  subtitle: !_isSupplier ? 'رصيد لصالحه' : 'مستحق للمورد',
                  isSelected: _balanceDirection == BalanceDirection.credit,
                  selectedColor: !_isSupplier ? Colors.green : Colors.orange.shade800,
                  onTap: () {
                    setState(() => _balanceDirection = BalanceDirection.credit);
                  },
                ),
              ),
            ],
          ),
          if (hasAmount) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: (_balanceDirection == BalanceDirection.debit
                        ? (!_isSupplier ? Colors.red : Colors.green)
                        : (!_isSupplier ? Colors.green : Colors.orange.shade800))
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: _balanceDirection == BalanceDirection.debit
                        ? (!_isSupplier ? Colors.red : Colors.green)
                        : (!_isSupplier ? Colors.green : Colors.orange.shade800),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      explanationText,
                      style: TextStyle(
                        fontSize: 11,
                        color: _balanceDirection == BalanceDirection.debit
                            ? (!_isSupplier ? Colors.red.shade900 : Colors.green.shade900)
                            : (!_isSupplier ? Colors.green.shade900 : Colors.orange.shade900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDirectionOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(
            color: isSelected ? selectedColor : Colors.grey.shade400,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 16,
                  color: isSelected ? selectedColor : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? selectedColor : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? selectedColor : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

