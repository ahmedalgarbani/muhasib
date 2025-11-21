// ============================================================================
// MODELS
// ============================================================================

import 'package:flutter/material.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/core/widgets/responsive/responsive_builder.dart';
import 'package:muhasib/features/accounts/presentation/pages/currencies_manage_page.dart';
import 'package:hasib_lib/form/form_field.dart';

class AccountLimit {
  final String id;
  final String account;
  final String currency;
  final double debitLimit;
  final double creditLimit;
  final double currentDebit;
  final double currentCredit;
  final AccountLimitStatus status;

  AccountLimit({
    required this.id,
    required this.account,
    required this.currency,
    required this.debitLimit,
    required this.creditLimit,
    this.currentDebit = 0,
    this.currentCredit = 0,
    this.status = AccountLimitStatus.active,
  });

  AccountLimit copyWith({
    String? id,
    String? account,
    String? currency,
    double? debitLimit,
    double? creditLimit,
    double? currentDebit,
    double? currentCredit,
    AccountLimitStatus? status,
  }) {
    return AccountLimit(
      id: id ?? this.id,
      account: account ?? this.account,
      currency: currency ?? this.currency,
      debitLimit: debitLimit ?? this.debitLimit,
      creditLimit: creditLimit ?? this.creditLimit,
      currentDebit: currentDebit ?? this.currentDebit,
      currentCredit: currentCredit ?? this.currentCredit,
      status: status ?? this.status,
    );
  }

  double get debitUsagePercentage {
    if (debitLimit == 0) return 0;
    return (currentDebit / debitLimit * 100).clamp(0, 100);
  }

  double get creditUsagePercentage {
    if (creditLimit == 0) return 0;
    return (currentCredit / creditLimit * 100).clamp(0, 100);
  }

  double get maxUsagePercentage {
    return debitUsagePercentage > creditUsagePercentage
        ? debitUsagePercentage
        : creditUsagePercentage;
  }

  UsageLevel get usageLevel {
    final max = maxUsagePercentage;
    if (max >= 90) return UsageLevel.critical;
    if (max >= 70) return UsageLevel.warning;
    return UsageLevel.safe;
  }
}

enum AccountLimitStatus { active, inactive }

enum UsageLevel { safe, warning, critical }

// ============================================================================
// CONSTANTS
// ============================================================================

class AppConstants {
  static const List<String> accounts = [
    ' الالتزامات وحقوق الملكية',
    '   اصول متداولة',
    ' اصول ثابتة ',
    'النقدية',
    'المبيعات',
    'المشتريات',
    'المصروفات',
    'الايرادات',
  ];

  static const List<String> currencies = [
    ' الاساسية',
    'USD',
    'SAR',
    'EGP',
    'EUR',
  ];
}

// ============================================================================
// THEME
// ============================================================================

class AppTheme {
  static const primaryColor = Color(0xFF2563EB);
  static const secondaryColor = Color(0xFF4F46E5);
  static const greenColor = Color(0xFF059669);
  static const redColor = Color(0xFFDC2626);
  static const yellowColor = Color(0xFFD97706);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static Color getUsageColor(UsageLevel level) {
    switch (level) {
      case UsageLevel.critical:
        return redColor;
      case UsageLevel.warning:
        return yellowColor;
      case UsageLevel.safe:
        return greenColor;
    }
  }

  static Color getUsageBackgroundColor(UsageLevel level) {
    switch (level) {
      case UsageLevel.critical:
        return redColor.withOpacity(0.1);
      case UsageLevel.warning:
        return yellowColor.withOpacity(0.1);
      case UsageLevel.safe:
        return greenColor.withOpacity(0.1);
    }
  }
}

// ============================================================================
// REUSABLE WIDGETS
// ============================================================================

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(right: BorderSide(color: color, width: 4)),
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}

class UsageProgressBar extends StatelessWidget {
  final double percentage;
  final Color color;
  final double height;

  const UsageProgressBar({
    Key? key,
    required this.percentage,
    required this.color,
    this.height = 6,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: percentage / 100,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}

class LimitCard extends StatelessWidget {
  final AccountLimit limit;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LimitCard({
    Key? key,
    required this.limit,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final usageLevel = limit.usageLevel;
    final usageColor = AppTheme.getUsageColor(usageLevel);
    final usageBgColor = AppTheme.getUsageBackgroundColor(usageLevel);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ResponsiveBuilder(
          mobile: _buildMobileLayout(usageColor, usageBgColor),
          tablet: _buildTabletLayout(usageColor, usageBgColor),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(Color usageColor, Color usageBgColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                limit.account,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: usageBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${limit.maxUsagePercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: usageColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildActionButtons(),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            limit.currency,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLimitRow(
          ' سقف المدين',
          limit.debitLimit,
          limit.currentDebit,
          limit.debitUsagePercentage,
          AppTheme.greenColor,
        ),
        const SizedBox(height: 12),
        _buildLimitRow(
          ' سقف الدائن ',
          limit.creditLimit,
          limit.currentCredit,
          limit.creditUsagePercentage,
          AppTheme.redColor,
        ),
      ],
    );
  }

  Widget _buildTabletLayout(Color usageColor, Color usageBgColor) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Text(
            ' ${index + 1} ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            limit.account,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Text(
                limit.debitLimit.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.greenColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ' المستخدم: ${limit.currentDebit.toStringAsFixed(0)} ',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              UsageProgressBar(
                percentage: limit.debitUsagePercentage,
                color: AppTheme.greenColor,
                height: 4,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Text(
                limit.creditLimit.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.redColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ' المستخدم: ${limit.currentCredit.toStringAsFixed(0)} ',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              UsageProgressBar(
                percentage: limit.creditUsagePercentage,
                color: AppTheme.redColor,
                height: 4,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                limit.currency,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: usageBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${limit.maxUsagePercentage.toStringAsFixed(0)}% ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: usageColor,
                ),
              ),
            ),
          ),
        ),
        Expanded(flex: 2, child: Center(child: _buildActionButtons())),
      ],
    );
  }

  Widget _buildLimitRow(
    String label,
    double limit,
    double current,
    double percentage,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              limit.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          ' المستخدم: ${current.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 6),
        UsageProgressBar(percentage: percentage, color: color),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, size: 20),
          color: AppTheme.primaryColor,
          onPressed: onEdit,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.delete, size: 20),
          color: AppTheme.redColor,
          onPressed: onDelete,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

// ============================================================================
// ADD/EDIT MODAL
// ============================================================================

class AddEditLimitModal extends StatefulWidget {
  final AccountLimit? editLimit;
  final Function(AccountLimit) onSave;

  const AddEditLimitModal({Key? key, this.editLimit, required this.onSave})
    : super(key: key);

  @override
  State<AddEditLimitModal> createState() => _AddEditLimitModalState();
}

class _AddEditLimitModalState extends State<AddEditLimitModal> {
  late TextEditingController _debitController;
  late TextEditingController _creditController;

  String? _selectedAccount;
  String? _selectedCurrency;

  @override
  void initState() {
    super.initState();
    if (widget.editLimit != null) {
      _selectedAccount = widget.editLimit!.account;
      _selectedCurrency = widget.editLimit!.currency;
      _debitController = TextEditingController(
        text: widget.editLimit!.debitLimit.toString(),
      );
      _creditController = TextEditingController(
        text: widget.editLimit!.creditLimit.toString(),
      );
    } else {
      _debitController = TextEditingController(text: '0');
      _creditController = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _debitController.dispose();
    _creditController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_selectedAccount == null || _selectedCurrency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' يرجى اختيار الحساب والعملة '),
          backgroundColor: AppTheme.redColor,
        ),
      );
      return;
    }

    final limit = AccountLimit(
      id:
          widget.editLimit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      account: _selectedAccount!,
      currency: _selectedCurrency!,
      debitLimit: double.tryParse(_debitController.text) ?? 0,
      creditLimit: double.tryParse(_creditController.text) ?? 0,
      currentDebit: widget.editLimit?.currentDebit ?? 0,
      currentCredit: widget.editLimit?.currentCredit ?? 0,
    );

    widget.onSave(limit);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.editLimit != null
                          ? ' تعديل السقف المالي'
                          : ' إضافة سقف مالي جديد ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFieldSelect<Currency>(
                      hint: 'الحساب',
                      showHint: true,

                      isRequired: true,
                      // selectedValue: _selectedAccount,
                      items: [],
                      onChanged: (value) =>
                          setState(() => _selectedAccount = 'value'),
                      // prefixIcon: const Icon(Icons.account_balance, size: 20),
                    ),
                    const SizedBox(height: 16),
                    TextFieldSelect<Currency>(
                      hint: 'العملة',
                      isRequired: true,
                      // selectedValue: _selectedCurrency,
                      items: [],
                      onChanged: (value) =>
                          setState(() => _selectedCurrency = 'value'),
                      // prefixIcon: const Icon(Icons.attach_money, size: 20),
                    ),
                    const SizedBox(height: 16),
                    TextInputField(
                      label: ' السقف الأقصى للمدين ',
                      // controller: _debitController,
                      inputType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      hint: '0.00 ',
                      // fillColor: AppTheme.greenColor.withOpacity(0.05),
                      borderColor: AppTheme.greenColor.withOpacity(0.3),
                      prefixIcon: const Icon(
                        Icons.arrow_upward,
                        color: AppTheme.greenColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextInputField(
                      label: ' السقف الأقصى للدائن ',
                      // controller: _creditController,
                      inputType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      hint: '0.00',
                      fillColor: AppTheme.redColor.withOpacity(0.05),
                      borderColor: AppTheme.redColor.withOpacity(0.3),
                      prefixIcon: const Icon(
                        Icons.arrow_downward,
                        color: AppTheme.redColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ' سيتم تنبيهك تلقائياً عند وصول المبلغ إلى 70% من السقف المحدد ',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleSave,
                      icon: const Icon(Icons.save),
                      label: Text(
                        widget.editLimit != null
                            ? ' حفظ التعديلات '
                            : 'حفظ السقف ',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.greenColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('إلغاء'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// MAIN SCREEN
// ============================================================================

class AccountLimitsScreen extends StatefulWidget {
  const AccountLimitsScreen({Key? key}) : super(key: key);

  @override
  State<AccountLimitsScreen> createState() => _AccountLimitsScreenState();
}

class _AccountLimitsScreenState extends State<AccountLimitsScreen> {
  List<AccountLimit> _limits = [];

  @override
  void initState() {
    super.initState();
    _limits = [
      AccountLimit(
        id: '1',
        account: 'النقدية',
        currency: 'الاساسية',
        debitLimit: 10000,
        creditLimit: 5000,
        currentDebit: 600,
        currentCredit: 600,
      ),
      AccountLimit(
        id: '2',
        account: 'المبيعات',
        currency: 'USD',
        debitLimit: 50000,
        creditLimit: 25000,
        currentDebit: 45000,
        currentCredit: 1200,
      ),
    ];
  }

  void _addLimit(AccountLimit limit) {
    setState(() {
      _limits.add(limit);
    });
    _showSuccessMessage('تم إضافة السقف بنجاح');
  }

  void _updateLimit(AccountLimit limit) {
    setState(() {
      final index = _limits.indexWhere((l) => l.id == limit.id);
      if (index != -1) {
        _limits[index] = limit;
      }
    });
    _showSuccessMessage('تم تحديث السقف بنجاح ');
  }

  void _deleteLimit(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(' تأكيد الحذف'),
        content: const Text(' هل أنت متأكد من حذف هذا السقف المالي؟ '),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _limits.removeWhere((l) => l.id == id);
              });
              Navigator.of(context).pop();
              _showSuccessMessage(' تم حذف السقف بنجاح');
            },
            child: const Text(
              'حذف',
              style: TextStyle(color: AppTheme.redColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppTheme.greenColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _exportToPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.white),
            SizedBox(width: 12),
            Text(" جاري تصدير تقرير الأسقف المالية..."),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  int get _activeAccountsCount {
    return _limits.where((l) => l.status == AccountLimitStatus.active).length;
  }

  int get _warningAccountsCount {
    return _limits
        .where(
          (l) =>
              l.usageLevel == UsageLevel.critical ||
              l.usageLevel == UsageLevel.warning,
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: const Text(
            '  تحديد أسقف الحسابات المالية ',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {},
          ),
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              onPressed: _exportToPDF,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.white, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ' إدارة الأسقف المالية',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            " تحديد الحدود القصوى للمدين والدائن لكل حساب ",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),

              // Statistics Cards
              ResponsiveBuilder(
                mobile: Column(
                  children: [
                    StatCard(
                      title: ' إجمالي الحسابات',
                      value: _limits.length.toString(),
                      icon: Icons.account_balance,
                      color: AppTheme.primaryColor,
                    ),
                    StatCard(
                      title: ' الحسابات النشطة ',
                      value: _activeAccountsCount.toString(),
                      icon: Icons.check_circle,
                      color: AppTheme.greenColor,
                    ),
                    StatCard(
                      title: ' تحذيرات السقف',
                      value: _warningAccountsCount.toString(),
                      icon: Icons.warning,
                      color: AppTheme.redColor,
                    ),
                  ],
                ),
                tablet: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: ' إجمالي الحسابات',
                        value: _limits.length.toString(),
                        icon: Icons.account_balance,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: ' الحسابات النشطة',
                        value: _activeAccountsCount.toString(),
                        icon: Icons.check_circle,
                        color: AppTheme.greenColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: ' تحذيرات السقف',
                        value: _warningAccountsCount.toString(),
                        icon: Icons.warning,
                        color: AppTheme.redColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Add New Button
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AddEditLimitModal(onSave: _addLimit),
                  );
                },
                icon: const Icon(Icons.add, size: 22, color: Colors.white),
                label: const Text(
                  " إضافة سقف مالي جديد ",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),

              // Table Header (Tablet/Desktop only)
              ResponsiveBuilder(
                mobile: const SizedBox.shrink(),
                tablet: Card(
                  margin: EdgeInsets.zero,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.1),
                          AppTheme.secondaryColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            '#',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'الحساب',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            ' سقف المدين',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            ' سقف الدائن',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'العملة',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'الحالة',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'إجراءات',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Limits List
              if (_limits.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          ' لا توجد أسقف محددة بعد ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ' ابدأ بإضافة سقف مالي جديد',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._limits.asMap().entries.map((entry) {
                  final index = entry.key;
                  final limit = entry.value;
                  return LimitCard(
                    limit: limit,
                    index: index,
                    onEdit: () {
                      showDialog(
                        context: context,
                        builder: (context) => AddEditLimitModal(
                          editLimit: limit,
                          onSave: _updateLimit,
                        ),
                      );
                    },
                    onDelete: () => _deleteLimit(limit.id),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MAIN APP
// ============================================================================
