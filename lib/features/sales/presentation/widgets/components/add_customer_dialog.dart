import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/features/customers/presentation/widgets/party_profile_widgets.dart';

class AddCustomerDialog extends StatefulWidget {
  /// partyType: 1 = customer, 2 = supplier
  final int partyType;

  const AddCustomerDialog({
    super.key,
    this.partyType = 1,
  });

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _creditLimitController = TextEditingController(text: '0');
  final _openingBalanceController = TextEditingController(text: '0');
  
  bool _isLoading = false;

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
      final customer = await cubit.addCustomer(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        type: widget.partyType, // 1=customer, 2=supplier
        creditLimit: double.tryParse(_creditLimitController.text) ?? 0.0,
        openingBalance: double.tryParse(_openingBalanceController.text) ?? 0.0,
      );
      
      if (customer != null && context.mounted) {
        Navigator.of(context).pop(customer);
        AppToast.showSuccess(
          context,
          widget.partyType == 2
              ? 'تم إضافة المورد "${customer.name}" بنجاح'
              : 'تم إضافة العميل "${customer.name}" بنجاح',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'خطأ في إضافة العميل: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSupplier = widget.partyType == 2;
    return CustomDialog(
      title: isSupplier ? 'إضافة مورد جديد' : 'إضافة عميل جديد',
      icon: isSupplier ? Icons.business : Icons.person_add,
      maxWidth: 500,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextInputField(
              label: isSupplier ? 'اسم المورد' : 'اسم العميل',
              textEditingController: _nameController,
              prefixIcon: Icon(isSupplier ? Icons.business : Icons.person),
              isRequired: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return isSupplier ? 'يرجى إدخال اسم المورد' : 'يرجى إدخال اسم العميل';
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
            const SizedBox(height: 16),
            TextInputField(
              label: 'الرصيد الافتتاحي',
              textEditingController: _openingBalanceController,
              inputType: TextInputType.number,
              prefixIcon: const Icon(Icons.account_balance_wallet),
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
            const SizedBox(height: 12),
            PartyAccountNotice(isSupplier: isSupplier),
          ],
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
          label: 'حفظ',
          loading: _isLoading,
          onPressed: _isLoading ? null : _saveCustomer,
          variant: HasibButtonVariant.primary,
        ),
      ],
    );
  }
}
