import "package:flutter/material.dart";
import 'package:muhasib/core/models/entity.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_text_style.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class CurrencyManagerApp extends StatelessWidget {
  const CurrencyManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إدارة العملات',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const CurrencyListScreen(),
    );
  }
}

// ============================================
// Models
// ============================================

class Currency extends Entity {
  final String id;
  final String name;
  final String code;
  final double rate;
  bool isEnabled;

  Currency({
    required this.id,
    required this.name,
    required this.code,
    required this.rate,
    this.isEnabled = true,
  });

  Currency copyWith({
    String? id,
    String? name,
    String? code,
    double? rate,
    bool? isEnabled,
  }) {
    return Currency(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      rate: rate ?? this.rate,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  String? get route => "UnimplementedError";

  @override
  Map get toJson => throw UnimplementedError();
}

// ============================================
// State Management
// ============================================

class CurrencyController extends ChangeNotifier {
  final List<Currency> _currencies = [
    Currency(
      id: '1',
      name: 'العملة الاساسية',
      code: 'Local',
      rate: 1.0,
      isEnabled: true,
    ),
    Currency(id: '2', name: 'سعودي', code: 'sa', rate: 22.0, isEnabled: true),
  ];

  List<Currency> get currencies => List.unmodifiable(_currencies);

  void addCurrency(Currency currency) {
    _currencies.add(currency);
    notifyListeners();
  }

  void toggleCurrency(String id) {
    final index = _currencies.indexWhere((c) => c.id == id);
    if (index != -1) {
      _currencies[index] = _currencies[index].copyWith(
        isEnabled: !_currencies[index].isEnabled,
      );
      notifyListeners();
    }
  }

  void removeCurrency(String id) {
    _currencies.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}

// ============================================
// Screens
// ============================================

class CurrencyListScreen extends StatefulWidget {
  const CurrencyListScreen({super.key});

  @override
  State<CurrencyListScreen> createState() => _CurrencyListScreenState();
}

class _CurrencyListScreenState extends State<CurrencyListScreen> {
  final CurrencyController _controller = CurrencyController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const CurrencyListHeader(),
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return ListView.builder(
                    padding: AppConstant.defaultPadding,
                    itemCount: _controller.currencies.length,
                    itemBuilder: (context, index) {
                      return CurrencyCard(
                        currency: _controller.currencies[index],
                        index: index + 1,
                        onToggle: () => _controller.toggleCurrency(
                          _controller.currencies[index].id,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            CurrencyListAddButton(
              onPressed: () => _showAddCurrencyModal(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCurrencyModal() {
    showDialog(
      context: context,
      builder: (context) => AddCurrencyModal(
        onAdd: (currency) {
          _controller.addCurrency(currency);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class CurrencyListHeader extends StatelessWidget {
  const CurrencyListHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: AppConstant.defaultPadding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                const Text(
                  'العملات',
                  style: AppTextStyles.heading1,
                ),
              ],
            ),
            Row(
              children: [
                IconButton(icon: const Icon(Icons.search), onPressed: () {}),
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CurrencyListAddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CurrencyListAddButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppConstant.defaultPadding,
      child: HasibButton(
        label: 'إضافة عملة جديدة',
        leading: const Icon(Icons.add, color: Colors.white),
        onPressed: onPressed,
        variant: HasibButtonVariant.primary,
      ),
    );
  }
}

// ============================================
// Widgets
// ============================================

class CurrencyCard extends StatelessWidget {
  final Currency currency;
  final int index;
  final VoidCallback onToggle;

  const CurrencyCard({
    super.key,
    required this.currency,
    required this.index,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () {},
          child: Padding(
            padding: AppConstant.defaultPadding,
            child: Row(
              children: [
                Text(
                  index.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${currency.name} (${currency.code})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currency.rate == 1.0
                            ? 'العملة الافتراضية'
                            : '${currency.rate} سعر الصرف',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                AnimatedToggleSwitch(
                  value: currency.isEnabled,
                  onChanged: (_) => onToggle(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AnimatedToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm14),
          color: value ? AppColors.primary : Colors.grey[300],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddCurrencyModal extends StatefulWidget {
  final Function(Currency) onAdd;

  const AddCurrencyModal({super.key, required this.onAdd});

  @override
  State<AddCurrencyModal> createState() => _AddCurrencyModalState();
}

class _AddCurrencyModalState extends State<AddCurrencyModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _rateController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final currency = Currency(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        code: _codeController.text,
        rate: double.parse(_rateController.text),
      );
      widget.onAdd(currency);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'إضافة عملة',
      icon: Icons.currency_exchange,
      maxWidth: 480,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextInputField(
                    textEditingController: _nameController,
                    label: 'اسم العملة',
                    hint: 'مثال: دولار أمريكي',
                    maxLength: 30,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال اسم العملة';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextInputField(
                    textEditingController: _codeController,
                    label: 'كود العملة',
                    hint: 'مثال: USD',
                    maxLength: 10,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال الكود';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextInputField(
              textEditingController: _rateController,
              label: 'سعر الصرف',
              hint: 'مثال: 3.75',
              inputType: const TextInputType.numberWithOptions(decimal: true),
              suffixIcon: const Icon(Icons.attach_money),
              isRequired: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال سعر الصرف';
                }
                if (double.tryParse(value) == null) {
                  return 'الرجاء إدخال رقم صحيح';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        HasibButton(
          label: 'إلغاء',
          onPressed: () => Navigator.pop(context),
          variant: HasibButtonVariant.secondary,
        ),
        const SizedBox(width: 12),
        HasibButton(
          label: 'حفظ',
          onPressed: _submit,
          variant: HasibButtonVariant.primary,
        ),
      ],
    );
  }
}
