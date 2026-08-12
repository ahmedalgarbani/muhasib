import "package:flutter/material.dart";
import "package:muhasib/core/models/entity.dart";
import "package:muhasib/core/widgets/text_input_field.dart";
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/theme/app_text_style.dart';

class CurrencyManagerApp extends StatelessWidget {
  const CurrencyManagerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: ' إدارة العملات',
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
  // TODO: implement route
  String? get route => "UnimplementedError";

  @override
  // TODO: implement toJson
  Map get toJson => throw UnimplementedError();
}

// ============================================
// State Management (Simple Provider Pattern)
// ============================================

class CurrencyController extends ChangeNotifier {
  final List<Currency> _currencies = [
    Currency(
      id: '1',
      name: ' العملة الاساسية',
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
  const CurrencyListScreen({Key? key}) : super(key: key);

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
            _buildHeader(),
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
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
            _buildAddButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
        padding: const EdgeInsets.all(16),
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

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AppButton(
        text: ' إضافة عملة جديدة ',
        icon: Icons.add,
        onPressed: () => _showAddCurrencyModal(),
      ),
    );
  }

  void _showAddCurrencyModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddCurrencyModal(
        onAdd: (currency) {
          _controller.addCurrency(currency);
          Navigator.pop(context);
        },
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
    Key? key,
    required this.currency,
    required this.index,
    required this.onToggle,
  }) : super(key: key);

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
            padding: const EdgeInsets.all(16),
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
                        '${currency.name} (${currency.code}) ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currency.rate == 1.0
                            ? ' العملة الافتراضية '
                            : ' ${currency.rate} سعر الصرف ',
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
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

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
          color: value ? Colors.blue : Colors.grey[300],
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

class AppButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;

  const AppButton({
    Key? key,
    required this.text,
    this.icon,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class AddCurrencyModal extends StatefulWidget {
  final Function(Currency) onAdd;

  const AddCurrencyModal({Key? key, required this.onAdd}) : super(key: key);

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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_buildHeader(), _buildForm()],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            ' إضافة عملة',
            style: AppTextStyles.heading1,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextInputField(
                    // controller: _nameController,
                    label: ' اسم العملة',
                    hint: ' مثال: دولار أمريكي ',
                    maxLength: 30,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return ' الرجاء إدخال اسم العملة';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextInputField(
                    // controller: _codeController,
                    label: ' كود العملة',
                    hint: ' مثال: USD',
                    maxLength: 10,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return ' الرجاء إدخال الكود';
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
              label: ' سعر الصرف',
              hint: ' مثال: 3.75',
              inputType: TextInputType.numberWithOptions(decimal: true),
              suffixIcon: Icon(Icons.attach_money),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return ' الرجاء إدخال سعر الصرف ';
                }
                if (double.tryParse(value) == null) {
                  return ' الرجاء إدخال رقم صحيح ';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            AppButton(text: 'حفظ', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int? maxLength;
  final TextInputType? keyboardType;
  final IconData? suffixIcon;
  final String? Function(String?)? validator;

  const AppTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLength,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            children: [
              TextSpan(text: label),
              const TextSpan(
                text: '*',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
            counterText: maxLength != null ? "" : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        if (maxLength != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                return Text(
                  '${value.text.length}/$maxLength',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                );
              },
            ),
          ),
      ],
    );
  }
}
