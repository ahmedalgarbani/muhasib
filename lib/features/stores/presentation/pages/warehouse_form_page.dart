import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/widgets/custom_text_field.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

class WarehouseFormPage extends StatefulWidget {
  final WarehouseEntity? warehouse;

  const WarehouseFormPage({super.key, this.warehouse});

  @override
  State<WarehouseFormPage> createState() => _WarehouseFormPageState();
}

class _WarehouseFormPageState extends State<WarehouseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _managerController = TextEditingController();
  final _capacityController = TextEditingController();

  bool _isActive = true;
  bool _isMainStock = false;
  int? _selectedAccountId;
  List<AccountEntity> _accounts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    if (widget.warehouse != null) {
      _populateFields();
    }
  }

  void _loadAccounts() async {
    // Load inventory accounts for linking
    context.read<AccountsCubit>().loadAllAccounts();
  }

  void _populateFields() {
    final warehouse = widget.warehouse!;
    _nameController.text = warehouse.name;
    _addressController.text = warehouse.address;
    _contactController.text = warehouse.contact ?? '';
    _managerController.text = warehouse.managerName ?? '';
    _capacityController.text = warehouse.capacity?.toString() ?? '';
    _isActive = warehouse.isActive;
    _isMainStock = warehouse.isMainStock;
    _selectedAccountId = warehouse.accountId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _managerController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _saveWarehouse() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final warehouse = WarehouseEntity(
      id: widget.warehouse?.id,
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      contact: _contactController.text.trim().isEmpty
          ? null
          : _contactController.text.trim(),
      managerName: _managerController.text.trim().isEmpty
          ? null
          : _managerController.text.trim(),
      accountId: _selectedAccountId,
      isActive: _isActive,
      isMainStock: _isMainStock,
      capacity: _capacityController.text.isEmpty
          ? null
          : double.tryParse(_capacityController.text),
    );

    if (widget.warehouse == null) {
      context.read<WarehousesCubit>().createWarehouse(warehouse);
    } else {
      context.read<WarehousesCubit>().updateWarehouse(warehouse);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.warehouse != null;
    final colorScheme = Theme.of(context).colorScheme;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<AccountsCubit>()..loadAllAccounts(),
        ),
      ],
      child: BlocListener<WarehousesCubit, WarehousesState>(
        listener: (context, state) {
          if (state is WarehouseCreated || state is WarehouseUpdated) {
            AppToast.showSuccess(
              context,
              state is WarehouseCreated
                  ? 'تم إضافة المخزن بنجاح'
                  : 'تم تحديث المخزن بنجاح',
            );
            context.pop(true);
          } else if (state is WarehousesError) {
            setState(() => _isLoading = false);
            AppToast.showError(context, state.message);
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.neutral100,
          appBar: CustomAppBar(
            title: isEditing ? 'تعديل المخزن' : 'إضافة مخزن جديد',
            actions: [
              if (isEditing)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _showDeleteDialog(context),
                  tooltip: 'حذف المخزن',
                ),
            ],
          ),
          body: BlocBuilder<AccountsCubit, AccountsState>(
            builder: (context, accountsState) {
              if (accountsState is AccountsLoaded) {
                _accounts = accountsState.accounts
                    .where(
                      (account) =>
                          account.name.toLowerCase().contains('مخزون') ||
                          account.name.toLowerCase().contains('بضاعة'),
                      // || account.accountType == 'inventory'
                    )
                    .toList();
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Basic Information Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'معلومات أساسية',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _nameController,
                                label: 'اسم المخزن',
                                hint: 'أدخل اسم المخزن',
                                prefixIcon: Icons.store,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'اسم المخزن مطلوب';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _addressController,
                                label: 'العنوان',
                                hint: 'أدخل عنوان المخزن',
                                prefixIcon: Icons.location_on,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: SwitchListTile(
                                      title: const Text('نشط'),
                                      value: _isActive,
                                      onChanged: (value) {
                                        setState(() => _isActive = value);
                                      },
                                      activeThumbColor: colorScheme.primary,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  Expanded(
                                    child: SwitchListTile(
                                      title: const Text('المخزن الرئيسي'),
                                      value: _isMainStock,
                                      onChanged: (value) {
                                        setState(() => _isMainStock = value);
                                      },
                                      activeThumbColor: colorScheme.primary,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Contact Information Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.contact_phone_outlined,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'معلومات الاتصال',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _contactController,
                                label: 'معلومات الاتصال',
                                hint: 'أدخل رقم الهاتف أو البريد الإلكتروني',
                                prefixIcon: Icons.phone,
                                keyboardType: TextInputType.text,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _managerController,
                                label: 'اسم المسؤول',
                                hint: 'أدخل اسم مسؤول المخزن',
                                prefixIcon: Icons.person,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Additional Information Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.settings_outlined,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'معلومات إضافية',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _capacityController,
                                label: 'السعة التخزينية',
                                hint: 'أدخل السعة التخزينية',
                                prefixIcon: Icons.inventory,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<int>(
                                initialValue: _selectedAccountId,
                                decoration: InputDecoration(
                                  labelText: 'الحساب المرتبط',
                                  prefixIcon: const Icon(Icons.account_balance),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                items: _accounts.map((account) {
                                  return DropdownMenuItem<int>(
                                    value: account.id,
                                    child: Text(account.name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedAccountId = value);
                                },
                                hint: const Text('اختر الحساب المرتبط'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveWarehouse,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      isEditing
                                          ? 'حفظ التغييرات'
                                          : 'إضافة المخزن',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => context.pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                side: BorderSide(color: colorScheme.primary),
                              ),
                              child: const Text(
                                'إلغاء',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف المخزن'),
        content: const Text('هل أنت متأكد من حذف هذا المخزن؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<WarehousesCubit>().deleteWarehouse(
                widget.warehouse!.id!,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
