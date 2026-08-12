import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/custom_confirm_dialog.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/custom_switch_tile.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import '../cubit/currencies_cubit.dart';
import '../../domain/entities/currency_entity.dart';

class CurrenciesPage extends StatelessWidget {
  const CurrenciesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CurrenciesCubit>()..loadAllCurrencies(),
      child: const _CurrenciesView(),
    );
  }
}

class _CurrenciesView extends StatelessWidget {
  const _CurrenciesView();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'إدارة العملات',
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _showSearchDialog(context),
              tooltip: 'بحث',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<CurrenciesCubit>().loadAllCurrencies(),
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: BlocBuilder<CurrenciesCubit, CurrenciesState>(
          builder: (context, state) {
            if (state is CurrenciesLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CurrenciesLoaded) {
              return _buildCurrenciesList(context, state.currencies);
            } else if (state is CurrenciesError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('خطأ: ${state.message}', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    HasibButton(
                      label: 'إعادة المحاولة',
                      onPressed: () => context.read<CurrenciesCubit>().loadAllCurrencies(),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text('لا توجد عملات'));
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddEditCurrencyDialog(context),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('إضافة عملة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildCurrenciesList(BuildContext context, List<CurrencyEntity> currencies) {
    if (currencies.isEmpty) {
      return const Center(child: Text('لا توجد عملات مضافة'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: currencies.length,
      itemBuilder: (context, index) {
        final currency = currencies[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: currency.isLocalCurrency
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.gray200,
              child: Text(
                currency.symbol ?? currency.code,
                style: TextStyle(
                  color: currency.isLocalCurrency ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Text(currency.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (currency.isLocalCurrency) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: const Text(
                      'محلية',
                      style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text('الكود: ${currency.code} | سعر الصرف: ${currency.exchangeRate}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () => _showAddEditCurrencyDialog(context, currency: currency),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmation(context, currency),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSearchDialog(BuildContext context) {
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => CustomDialog(
        title: 'البحث عن عملة',
        icon: Icons.search,
        content: TextInputField(
          label: 'اسم أو كود العملة',
          hint: 'أدخل اسم أو كود العملة',
          textEditingController: searchController,
          prefixIcon: const Icon(Icons.search),
        ),
        actions: [
          HasibButton(
            label: 'إلغاء',
            variant: HasibButtonVariant.secondary,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          const SizedBox(width: 12),
          HasibButton(
            label: 'بحث',
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (searchController.text.isNotEmpty) {
                context.read<CurrenciesCubit>().search(searchController.text);
              }
            },
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
        builder: (context, setState) => CustomDialog(
          title: isEdit ? 'تعديل العملة' : 'إضافة عملة جديدة',
          icon: isEdit ? Icons.edit : Icons.add_circle,
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextInputField(
                  label: 'اسم العملة',
                  hint: 'مثال: دولار أمريكي',
                  isRequired: true,
                  textEditingController: nameController,
                  prefixIcon: const Icon(Icons.text_fields),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'الرجاء إدخال اسم العملة' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextInputField(
                        label: 'كود العملة',
                        hint: 'USD',
                        isRequired: true,
                        textEditingController: codeController,
                        prefixIcon: const Icon(Icons.code),
                        maxLength: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'الرجاء إدخال الكود';
                          if (value.length != 3) return 'الكود يجب أن يكون 3 أحرف';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextInputField(
                        label: 'الرمز',
                        hint: '\$',
                        textEditingController: symbolController,
                        prefixIcon: const Icon(Icons.attach_money),
                        maxLength: 5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextInputField(
                  label: 'سعر الصرف',
                  hint: '3.75',
                  isRequired: true,
                  textEditingController: rateController,
                  inputType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: const Icon(Icons.trending_up),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'الرجاء إدخال سعر الصرف';
                    final rate = double.tryParse(value);
                    if (rate == null || rate <= 0) return 'الرجاء إدخال رقم صحيح';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomSwitchTile(
                  title: 'العملة المحلية',
                  subtitle: 'تعيين كعملة رئيسية للنظام',
                  value: isLocalCurrency,
                  onChanged: (value) => setState(() => isLocalCurrency = value),
                ),
                CustomSwitchTile(
                  title: 'الحالة',
                  subtitle: 'تفعيل أو تعطيل التعامل بالعملة',
                  value: isActive,
                  onChanged: (value) => setState(() => isActive = value),
                ),
              ],
            ),
          ),
          actions: [
            HasibButton(
              label: 'إلغاء',
              variant: HasibButtonVariant.secondary,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            const SizedBox(width: 12),
            HasibButton(
              label: isEdit ? 'حفظ التغييرات' : 'إضافة',
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
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, CurrencyEntity currency) {
    showDialog(
      context: context,
      builder: (dialogContext) => CustomConfirmDialog(
        title: 'تأكيد الحذف',
        message: 'هل أنت متأكد من حذف العملة "${currency.name}"؟',
        confirmLabel: 'حذف',
        isDanger: true,
        onConfirm: () {
          context.read<CurrenciesCubit>().removeCurrency(currency.id!);
        },
      ),
    );
  }
}
