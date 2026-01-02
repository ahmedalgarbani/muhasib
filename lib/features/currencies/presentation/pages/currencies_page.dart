import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_entity.dart';
import 'package:muhasib/features/currencies/presentation/cubit/currencies_cubit.dart';

class CurrenciesPage extends StatefulWidget {
  const CurrenciesPage({Key? key}) : super(key: key);

  @override
  State<CurrenciesPage> createState() => _CurrenciesPageState();
}

class _CurrenciesPageState extends State<CurrenciesPage> {
  @override
  void initState() {
    super.initState();
    context.read<CurrenciesCubit>().loadAllCurrencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CustomAppBar(
        title: 'إدارة العملات',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<CurrenciesCubit, CurrenciesState>(
        builder: (context, state) {
          if (state is CurrenciesLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CurrenciesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<CurrenciesCubit>().loadAllCurrencies(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          } else if (state is CurrenciesLoaded) {
            if (state.currencies.isEmpty) {
              return _buildEmptyState();
            }
            return _buildCurrenciesList(state.currencies);
          }
          return _buildEmptyState();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditCurrencyDialog(context),
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('إضافة عملة'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.monetization_on_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد عملات مسجلة',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على زر الإضافة لتسجيل عملة جديدة',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrenciesList(List<CurrencyEntity> currencies) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: currencies.length,
      itemBuilder: (context, index) {
        final currency = currencies[index];
        return _buildCurrencyCard(currency, index + 1);
      },
    );
  }

  Widget _buildCurrencyCard(CurrencyEntity currency, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCurrencyDetails(context, currency),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    index.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          currency.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            currency.code,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'سعر الصرف: ${currency.exchangeRate.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (currency.isLocalCurrency == true) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'العملة المحلية',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showAddEditCurrencyDialog(context, currency: currency);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(context, currency);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('تعديل'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    enabled: currency.isLocalCurrency != true,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          size: 20,
                          color: currency.isLocalCurrency == true
                              ? Colors.grey
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'حذف',
                          style: TextStyle(
                            color: currency.isLocalCurrency == true
                                ? Colors.grey
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCurrencyDetails(BuildContext context, CurrencyEntity currency) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(currency.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('الكود', currency.code),
            _buildDetailRow('الرمز', currency.symbol ?? '-'),
            _buildDetailRow('سعر الصرف', currency.exchangeRate.toString()),
            _buildDetailRow(
              'العملة المحلية',
              currency.isLocalCurrency == true ? 'نعم' : 'لا',
            ),
            _buildDetailRow('نشط', currency.isActive == true ? 'نعم' : 'لا'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _showAddEditCurrencyDialog(context, currency: currency);
            },
            child: const Text('تعديل'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('البحث عن عملة'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'أدخل اسم أو كود العملة',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (searchController.text.isNotEmpty) {
                context.read<CurrenciesCubit>().search(searchController.text);
              }
            },
            child: const Text('بحث'),
          ),
        ],
      ),
    );
  }

  void _showAddEditCurrencyDialog(
    BuildContext context, {
    CurrencyEntity? currency,
  }) {
    final isEdit = currency != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: currency?.name);
    final codeController = TextEditingController(text: currency?.code);
    final symbolController = TextEditingController(text: currency?.symbol);
    final rateController = TextEditingController(
      text: currency != null ? currency.exchangeRate.toString() : '1.00',
    );
    bool isLocalCurrency = currency?.isLocalCurrency ?? false;
    bool isActive = currency?.isActive ?? true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'تعديل العملة' : 'إضافة عملة جديدة'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم العملة',
                      hintText: 'مثال: دولار أمريكي',
                      prefixIcon: Icon(Icons.text_fields),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال اسم العملة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: codeController,
                          decoration: const InputDecoration(
                            labelText: 'كود العملة',
                            hintText: 'USD',
                            prefixIcon: Icon(Icons.code),
                          ),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(3),
                            FilteringTextInputFormatter.allow(RegExp('[A-Z]')),
                          ],
                          textCapitalization: TextCapitalization.characters,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال الكود';
                            }
                            if (value.length != 3) {
                              return 'الكود يجب أن يكون 3 أحرف';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: symbolController,
                          decoration: const InputDecoration(
                            labelText: 'الرمز',
                            hintText: '\$',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(5),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: rateController,
                    decoration: const InputDecoration(
                      labelText: 'سعر الصرف',
                      hintText: '3.75',
                      prefixIcon: Icon(Icons.trending_up),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال سعر الصرف';
                      }
                      final rate = double.tryParse(value);
                      if (rate == null || rate <= 0) {
                        return 'الرجاء إدخال رقم صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('العملة المحلية'),
                    value: isLocalCurrency,
                    onChanged: (value) {
                      setState(() => isLocalCurrency = value);
                    },
                    dense: true,
                  ),
                  SwitchListTile(
                    title: const Text('نشط'),
                    value: isActive,
                    onChanged: (value) {
                      setState(() => isActive = value);
                    },
                    dense: true,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newCurrency = CurrencyEntity(
                    id: currency?.id,
                    name: nameController.text.trim(),
                    code: codeController.text.trim(),
                    symbol: symbolController.text.trim().isEmpty 
                        ? null 
                        : symbolController.text.trim(),
                    exchangeRate: double.parse(rateController.text),
                    minExchangeRate: double.parse(rateController.text) * 0.5,
                    maxExchangeRate: double.parse(rateController.text) * 2,
                    decimalPlaces: 2,
                    isLocalCurrency: isLocalCurrency,
                    isActive: isActive,
                  );

                  if (isEdit) {
                    context.read<CurrenciesCubit>().modifyCurrency(newCurrency);
                  } else {
                    context.read<CurrenciesCubit>().addCurrency(newCurrency);
                  }
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Text(isEdit ? 'حفظ التغييرات' : 'إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, CurrencyEntity currency) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف العملة "${currency.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CurrenciesCubit>().removeCurrency(currency.id!);
              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
