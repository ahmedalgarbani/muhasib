// ==================== FILE 1: models/entry_model.dart ====================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muhasib/features/accounts/presentation/pages/currencies_manage_page.dart';
import 'package:hasib_lib/form/form_field.dart';
import 'package:hasib_lib/theme/app_colors.dart';

class EntryModel {
  final String id;
  final String account;
  final String type; // 'مدين' or 'دائن'
  final double amount;

  EntryModel({
    required this.id,
    required this.account,
    required this.type,
    required this.amount,
  });

  EntryModel copyWith({
    String? id,
    String? account,
    String? type,
    double? amount,
  }) {
    return EntryModel(
      id: id ?? this.id,
      account: account ?? this.account,
      type: type ?? this.type,
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'account': account, 'type': type, 'amount': amount};
  }

  factory EntryModel.fromJson(Map<String, dynamic> json) {
    return EntryModel(
      id: json['id'] as String,
      account: json['account'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

// ==================== FILE 2: models/opening_balance_model.dart ====================
class OpeningBalanceModel {
  final String currency;
  final String number;
  final String date;
  final String notes;
  final List<EntryModel> entries;

  OpeningBalanceModel({
    this.currency = 'الأساسية',
    this.number = '1',
    this.date = '17 - 10 - 2025',
    this.notes = '',
    this.entries = const [],
  });

  OpeningBalanceModel copyWith({
    String? currency,
    String? number,
    String? date,
    String? notes,
    List<EntryModel>? entries,
  }) {
    return OpeningBalanceModel(
      currency: currency ?? this.currency,
      number: number ?? this.number,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      entries: entries ?? this.entries,
    );
  }

  double get totalDebit {
    return entries
        .where((e) => e.type == 'مدين')
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get totalCredit {
    return entries
        .where((e) => e.type == 'دائن')
        .fold(0.0, (sum, e) => sum + e.amount);
  }
}

// ==================== FILE 4: constants/app_text_styles.dart ====================

class AppTextStyles {
  // Headings
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.gray800,
    height: 1.2,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.gray800,
    height: 1.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.gray800,
    height: 1.3,
  );

  static const TextStyle heading4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.gray800,
    height: 1.3,
  );

  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.gray700,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.gray700,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.gray600,
    height: 1.4,
  );

  // Labels
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.gray700,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.gray600,
  );

  // Button Text
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.gray500,
  );

  // Special Styles
  static const TextStyle numberBold = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static const TextStyle amountLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.gray800,
  );
}

// ==================== FILE 5: constants/app_dimensions.dart ====================
class AppDimensions {
  // Padding & Margins
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 20.0;
  static const double paddingXLarge = 24.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusXXLarge = 24.0;

  // Border Width
  static const double borderThin = 1.0;
  static const double borderMedium = 2.0;
  static const double borderThick = 3.0;

  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  static const double iconXLarge = 32.0;
  static const double iconXXLarge = 48.0;

  // Input Heights
  static const double inputHeight = 48.0;
  static const double inputHeightLarge = 56.0;

  // Button Heights
  static const double buttonHeight = 48.0;
  static const double buttonHeightLarge = 56.0;

  // Container Sizes
  static const double cardIconSize = 64.0;
  static const double maxWidth = 720.0;

  // Spacing
  static const double spaceXSmall = 4.0;
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 16.0;
  static const double spaceLarge = 24.0;
  static const double spaceXLarge = 32.0;
}

// ==================== FILE 6: widgets/custom_text_field.dart ====================

// ==================== FILE 7: widgets/custom_dropdown.dart ====================

// ==================== FILE 8: widgets/gradient_button.dart ====================

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double height;
  final List<Color>? gradientColors;
  final Widget? icon;

  const GradientButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.height = AppDimensions.buttonHeightLarge,
    this.gradientColors,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors ?? [AppColors.blue600, AppColors.blue700],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue600.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[icon!, const SizedBox(width: 8)],
                Text(text, style: AppTextStyles.buttonLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== FILE 9: widgets/card_container.dart ====================

class CardContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const CardContainer({
    Key? key,
    required this.child,
    this.backgroundColor = AppColors.white,
    this.borderColor,
    this.padding,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          margin ?? const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      padding: padding ?? const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: AppDimensions.borderThin)
            : Border.all(
                color: AppColors.gray100,
                width: AppDimensions.borderThin,
              ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ==================== FILE 10: widgets/selection_card.dart ====================

class SelectionCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget icon;
  final VoidCallback onTap;

  const SelectionCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
          border: Border.all(color: AppColors.gray200, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.gray200.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: AppDimensions.cardIconSize,
              height: AppDimensions.cardIconSize,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.blue100, AppColors.blue200],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              ),
              child: icon,
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.heading4),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.gray400,
              size: AppDimensions.iconLarge,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== FILE 11: screens/selection_screen.dart ====================

class SelectionScreen extends StatelessWidget {
  final Function(String) onSelect;

  const SelectionScreen({Key? key, required this.onSelect}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.slate50, AppColors.blue50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppDimensions.maxWidth,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(
                          AppDimensions.paddingMedium,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blue600,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusXLarge,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blue600.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          size: AppDimensions.iconXXLarge,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingLarge),
                      Text(
                        'الرصدة الافتتاحية',
                        style: AppTextStyles.heading1,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اختر نوع الإضافة',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.gray600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.paddingXLarge),
                      SelectionCard(
                        title: 'رصيد افتتاحي لحساب واحد',
                        description:
                            'اختر هذا الخيار إذا كان الرصيد مخصصًا لحساب واحد فقط.',
                        icon: const Icon(
                          Icons.calculate,
                          color: AppColors.blue600,
                          size: AppDimensions.iconXLarge,
                        ),
                        onTap: () => onSelect('single'),
                      ),
                      const SizedBox(height: AppDimensions.paddingMedium),
                      SelectionCard(
                        title: 'رصيد افتتاحي لعدة حسابات',
                        description:
                            'اختر هذا الخيار إذا كنت تريد توزيع الرصيد على عدة حسابات.',
                        icon: Stack(
                          children: const [
                            Icon(
                              Icons.calculate,
                              color: AppColors.indigo600,
                              size: AppDimensions.iconXLarge,
                            ),
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Icon(
                                Icons.calculate,
                                color: AppColors.indigo600,
                                size: AppDimensions.iconMedium,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => onSelect('multiple'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== FILE 12: screens/opening_balance_form_screen.dart ====================

class OpeningBalanceFormScreen extends StatefulWidget {
  final String balanceType;

  const OpeningBalanceFormScreen({Key? key, required this.balanceType})
    : super(key: key);

  @override
  State<OpeningBalanceFormScreen> createState() =>
      _OpeningBalanceFormScreenState();
}

class _OpeningBalanceFormScreenState extends State<OpeningBalanceFormScreen> {
  late OpeningBalanceModel _formData;

  final TextEditingController _numberController = TextEditingController(
    text: '1',
  );
  final TextEditingController _dateController = TextEditingController(
    text: '17 - 10 - 2025',
  );
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _formData = OpeningBalanceModel();
    _notesController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _numberController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showAddEntryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEntryModal(
        onSave: (entry) {
          setState(() {
            _formData = _formData.copyWith(
              entries: [..._formData.entries, entry],
            );
          });
        },
      ),
    );
  }

  void _deleteEntry(String id) {
    setState(() {
      _formData = _formData.copyWith(
        entries: _formData.entries.where((e) => e.id != id).toList(),
      );
    });
  }

  void _handleSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ الرصيد الافتتاحي بنجاح'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppDimensions.maxWidth,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(
                          AppDimensions.paddingMedium,
                        ),
                        child: Column(
                          children: [
                            _buildCurrencySection(),
                            _buildNumberAndDateSection(),
                            _buildNotesSection(),
                            _buildEntriesSection(),
                            _buildTotalsSection(),
                            const SizedBox(height: AppDimensions.paddingSmall),
                            GradientButton(text: 'حفظ', onPressed: _handleSave),
                            const SizedBox(height: AppDimensions.paddingLarge),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.gray700),
            onPressed: () => Navigator.pop(context),
          ),
          Text('إضافة رصيد افتتاحي', style: AppTextStyles.heading3),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildCurrencySection() {
    return CardContainer(
      backgroundColor: AppColors.white,
      borderColor: AppColors.blue100,
      child: TextFieldSelect<Currency>(
        hint: 'العملة',
        showHint: true,
        labelIcon: const Icon(
          Icons.account_balance_wallet,
          size: AppDimensions.iconMedium,
          color: AppColors.blue600,
        ),
        isRequired: true,
        // value: _formData.currency,
        items: [],
        onChanged: (value) {
          setState(() {
            _formData = _formData.copyWith(currency: 'value');
          });
        },
        // backgroundColor: const Color(0xFFF0F9FF),
        // borderColor: AppColors.blue200,
      ),
    );
  }

  Widget _buildNumberAndDateSection() {
    return CardContainer(
      child: Row(
        children: [
          Expanded(
            child: TextInputField(
              label: 'الرقم',
              isRequired: true,
              // controller: _numberController,
              textAlign: TextAlign.center,
              borderColor: AppColors.blue300,
              prefixIcon: const Icon(
                Icons.tag,
                color: AppColors.blue600,
                size: AppDimensions.iconSmall,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: TextInputField(
              label: 'تاريخ العملية',
              isRequired: true,
              // controller: _dateController,
              textAlign: TextAlign.center,
              borderColor: AppColors.blue300,
              prefixIcon: const Icon(
                Icons.calendar_today,
                color: AppColors.blue600,
                size: AppDimensions.iconSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return CardContainer(
      child: TextInputField(
        label: 'الملاحظة',
        hint: 'أضف ملاحظة...',
        // controller: _notesController,
        maxLines: 3,
        maxLength: 1000,
        showCharacterCount: true,
        suffixIcon: IconButton(
          icon: const Icon(Icons.mic, color: AppColors.gray400),
          onPressed: () {},
        ),
      ),
    );
  }

  Widget _buildEntriesSection() {
    return CardContainer(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GradientButton(
                text: 'إضافة حساب',
                onPressed: _showAddEntryModal,
                height: AppDimensions.buttonHeight,
                icon: const Icon(Icons.add, color: AppColors.white),
              ),
            ],
          ),
          if (_formData.entries.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildEntriesTable(),
          ],
        ],
      ),
    );
  }

  Widget _buildEntriesTable() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingSmall),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.blue50, AppColors.indigo50],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'الحساب',
                  style: AppTextStyles.label,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'مدين',
                  style: AppTextStyles.label,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'دائن',
                  style: AppTextStyles.label,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        ..._formData.entries.map((entry) => _buildEntryRow(entry)).toList(),
      ],
    );
  }

  Widget _buildEntryRow(EntryModel entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              entry.account,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              entry.type == 'مدين' ? entry.amount.toStringAsFixed(1) : '-',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.green600,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              entry.type == 'دائن' ? entry.amount.toStringAsFixed(1) : '-',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.red500,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.gray400,
              size: AppDimensions.iconMedium,
            ),
            onPressed: () => _deleteEntry(entry.id),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.slate700, AppColors.slate800],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate700.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  'مدين',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formData.totalDebit.toStringAsFixed(1),
                  style: AppTextStyles.numberBold,
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: AppColors.white.withOpacity(0.2),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'دائن',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formData.totalCredit.toStringAsFixed(1),
                  style: AppTextStyles.numberBold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ==================== FILE 13: screens/add_entry_modal.dart ====================

class AddEntryModal extends StatefulWidget {
  final Function(EntryModel) onSave;

  const AddEntryModal({Key? key, required this.onSave}) : super(key: key);

  @override
  State<AddEntryModal> createState() => _AddEntryModalState();
}

class _AddEntryModalState extends State<AddEntryModal> {
  String _selectedAccount = '';
  String _selectedType = 'مدين';
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_selectedAccount.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء ملء جميع الحقول المطلوبة'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final entry = EntryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      account: _selectedAccount,
      type: _selectedType,
      amount: double.tryParse(_amountController.text) ?? 0.0,
    );

    widget.onSave(entry);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppDimensions.radiusXXLarge),
            topRight: Radius.circular(AppDimensions.radiusXXLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAccountDropdown(),
                    const SizedBox(height: AppDimensions.paddingLarge),
                    _buildTypeSelection(),
                    const SizedBox(height: AppDimensions.paddingLarge),
                    _buildAmountField(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppDimensions.paddingSmall),
      width: 48,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.gray300,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLarge,
        vertical: AppDimensions.paddingMedium,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.gray600),
            onPressed: () => Navigator.pop(context),
          ),
          Text('إضافة قيد', style: AppTextStyles.heading3),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildAccountDropdown() {
    return TextFieldSelect(
      showHint: true,
      labelIcon: const Icon(
        Icons.account_balance_wallet,
        size: AppDimensions.iconMedium,
        color: AppColors.blue600,
      ),
      isRequired: true,
      // value: _selectedAccount,
      items: const ['اختر الحساب', 'مصروفات', 'ايرادات', 'أصول', 'خصوم'],
      onChanged: (value) {
        setState(() {
          _selectedAccount = value ?? '';
        });
      },
      hint: 'اختر الحساب',
    );
  }

  Widget _buildTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('نوع الرصيد', style: AppTextStyles.label),
            const SizedBox(width: 4),
            const Text('*', style: TextStyle(color: AppColors.red500)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.blue50,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(color: AppColors.blue200, width: 2),
          ),
          child: Row(
            children: [
              Expanded(child: _buildTypeButton('مدين')),
              const SizedBox(width: AppDimensions.paddingSmall),
              Expanded(child: _buildTypeButton('دائن')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeButton(String type) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue600 : AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.blue600.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          type,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.white : AppColors.gray700,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextInputField(
      label: 'المبلغ',
      isRequired: true,
      hint: '0.00',
      // controller: _amountController,
      inputType: TextInputType.number,
      suffixIcon: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(AppDimensions.paddingSmall),
        decoration: BoxDecoration(
          color: AppColors.blue600,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        child: const Icon(
          Icons.calculate,
          color: AppColors.white,
          size: AppDimensions.iconMedium,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.gray200)),
      ),
      child: GradientButton(text: 'حفظ', onPressed: _handleSave),
    );
  }
}

// ==================== FILE 14: main.dart ====================

class OpeningBalanceApp extends StatelessWidget {
  const OpeningBalanceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Opening Balance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.gray50,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
        ),
        useMaterial3: true,
      ),
      home: const OpeningBalanceNavigator(),
    );
  }
}

class OpeningBalanceNavigator extends StatefulWidget {
  const OpeningBalanceNavigator({Key? key}) : super(key: key);

  @override
  State<OpeningBalanceNavigator> createState() =>
      _OpeningBalanceNavigatorState();
}

class _OpeningBalanceNavigatorState extends State<OpeningBalanceNavigator> {
  String? _selectedBalanceType;

  void _handleSelection(String type) {
    setState(() {
      _selectedBalanceType = type;
    });
  }

  void _handleBack() {
    setState(() {
      _selectedBalanceType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedBalanceType == null) {
      return SelectionScreen(onSelect: _handleSelection);
    }

    return WillPopScope(
      onWillPop: () async {
        _handleBack();
        return false;
      },
      child: OpeningBalanceFormScreen(balanceType: _selectedBalanceType!),
    );
  }
}
