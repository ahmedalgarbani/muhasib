import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/features/sales/presentation/widgets/sale_form.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/helpers/get_it.dart';

class AddCustomerDialog extends StatefulWidget {
  const AddCustomerDialog({Key? key}) : super(key: key);

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
  
  int _customerType = 1; // 1 = نقدي, 2 = آجل
  bool _isActive = true;
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
      final databaseService = getIt<DatabaseService>();
      final db = await databaseService.database;
      
      // First, find or create the "العملاء" parent account
      final customersParentAccount = await db.query(
        'accounts',
        where: 'name = ? AND is_master = 1',
        whereArgs: ['العملاء'],
        limit: 1,
      );
      
      int customersParentId;
      int customersParentCId;
      
      if (customersParentAccount.isEmpty) {
        // Create العملاء parent account if it doesn't exist
        customersParentId = await db.insert('accounts', {
          'c_id': 120, // Standard code for customers accounts
          'code': '120',
          'name': 'العملاء',
          'is_master': 1,
          'type': 1, // Assets type
          'national': 1,
          'is_active': 1,
          'allow_update_delete': 0,
          'balance': 0.0,
          'local_balance': 0.0,
          'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
        customersParentCId = 120;
      } else {
        customersParentId = customersParentAccount.first['id'] as int;
        customersParentCId = customersParentAccount.first['c_id'] as int;
      }
      
      // Generate a unique code for the customer account
      final lastCustomerAccount = await db.rawQuery(
        'SELECT MAX(CAST(code AS INTEGER)) as max_code FROM accounts WHERE master_id = ?',
        [customersParentId],
      );
      
      int nextCode = 12001; // Start from 12001 for customer accounts
      if (lastCustomerAccount.isNotEmpty && lastCustomerAccount.first['max_code'] != null) {
        nextCode = (lastCustomerAccount.first['max_code'] as int) + 1;
      }
      
      // Create account for the customer
      final accountId = await db.insert('accounts', {
        'c_id': nextCode,
        'code': nextCode.toString(),
        'name': _nameController.text.trim(),
        'is_master': 0,
        'master_id': customersParentId,
        'master_c_id': customersParentCId,
        'type': 1, // Assets type
        'national': 1,
        'statement': 'حساب العميل: ${_nameController.text.trim()}',
        'is_active': _isActive ? 1 : 0,
        'allow_update_delete': 1,
        'balance': double.tryParse(_openingBalanceController.text) ?? 0.0,
        'local_balance': double.tryParse(_openingBalanceController.text) ?? 0.0,
        'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });
      
      // Check if classifications table has data, if not, seed it
      final classificationsCount = await db.rawQuery('SELECT COUNT(*) as count FROM classifications');
      if ((classificationsCount.first['count'] as int) == 0) {
        await db.insert('classifications', {
          'id': 1,
          'name': 'عملاء عاديين',
          'singler_name': 'عميل',
          'order': 1,
          'type': 1,
          'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
      }
      
      // Create the customer record
      final customerId = await db.insert('customers', {
        'name': _nameController.text.trim(),
        'type': _customerType,
        'classification': 1,
        'classification_id': 1,
        'contact': _phoneController.text.trim(),
        'contact_type': 1, // Phone
        'is_active': _isActive ? 1 : 0,
        'account_id': accountId,
        'credit_limit': double.tryParse(_creditLimitController.text) ?? 0.0,
        'current_balance': double.tryParse(_openingBalanceController.text) ?? 0.0,
        'creation_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'last_modification_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });
      
      // Create Customer object to return
      final newCustomer = Customer(
        id: customerId.toString(),
        name: _nameController.text.trim(),
        balance: double.tryParse(_openingBalanceController.text) ?? 0.0,
        creditLimit: double.tryParse(_creditLimitController.text) ?? 0.0,
      );
      
      // Reload accounts in the AccountsCubit
      if (context.mounted) {
        context.read<AccountsCubit>().loadAllAccounts();
        Navigator.of(context).pop(newCustomer);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إضافة العميل "${_nameController.text.trim()}" بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة العميل: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'إضافة عميل جديد',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Customer Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم العميل *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال اسم العميل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone Number
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  
                  // Address
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'العنوان',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  
                  // Customer Type
                  const Text(
                    'نوع العميل',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<int>(
                          title: const Text('نقدي'),
                          value: 1,
                          groupValue: _customerType,
                          onChanged: (value) {
                            setState(() => _customerType = value!);
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<int>(
                          title: const Text('آجل'),
                          value: 2,
                          groupValue: _customerType,
                          onChanged: (value) {
                            setState(() => _customerType = value!);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Credit Limit (only for credit customers)
                  if (_customerType == 2) ...[
                    TextFormField(
                      controller: _creditLimitController,
                      decoration: const InputDecoration(
                        labelText: 'حد الائتمان',
                        prefixIcon: Icon(Icons.credit_card),
                        border: OutlineInputBorder(),
                        suffixText: 'ريال',
                      ),
                      keyboardType: TextInputType.number,
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
                  ],
                  
                  // Opening Balance
                  TextFormField(
                    controller: _openingBalanceController,
                    decoration: const InputDecoration(
                      labelText: 'الرصيد الافتتاحي',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                      border: OutlineInputBorder(),
                      suffixText: 'ريال',
                    ),
                    keyboardType: TextInputType.number,
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
                  
                  // Active Status
                  SwitchListTile(
                    title: const Text('نشط'),
                    subtitle: const Text('يمكن استخدام العميل في الفواتير'),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() => _isActive = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('إلغاء'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveCustomer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('حفظ'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
