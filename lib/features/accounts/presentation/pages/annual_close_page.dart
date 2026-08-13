import 'package:flutter/material.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/features/accounts/presentation/widgets/annual_close_components.dart';
import 'package:muhasib/core/constant/app_constant.dart';

class AnnualClosePage extends StatefulWidget {
  const AnnualClosePage({super.key});

  @override
  State<AnnualClosePage> createState() => _AnnualClosePageState();
}

class _AnnualClosePageState extends State<AnnualClosePage> {
  int selectedYear = DateTime.now().year;
  bool isProcessing = false;
  List<AnnualCloseStep> steps = [];

  @override
  void initState() {
    super.initState();
    _initializeSteps();
  }

  void _initializeSteps() {
    steps = [
      AnnualCloseStep(
        title: 'مراجعة القيود المعلقة',
        description: 'التأكد من عدم وجود قيود معلقة أو غير مرحلة',
        icon: Icons.fact_check,
        status: StepStatus.pending,
      ),
      AnnualCloseStep(
        title: 'ترحيل أرصدة الإيرادات والمصروفات',
        description:
            'نقل أرصدة حسابات الإيرادات والمصروفات إلى حساب ملخص الدخل',
        icon: Icons.swap_horiz,
        status: StepStatus.pending,
      ),
      AnnualCloseStep(
        title: 'إقفال حساب ملخص الدخل',
        description: 'ترحيل صافي الربح أو الخسارة إلى حساب الأرباح المحتجزة',
        icon: Icons.account_balance,
        status: StepStatus.pending,
      ),
      AnnualCloseStep(
        title: 'إنشاء قيد الإقفال',
        description: 'إنشاء قيد يومية لعملية الإقفال السنوي',
        icon: Icons.receipt_long,
        status: StepStatus.pending,
      ),
      AnnualCloseStep(
        title: 'فتح السنة الجديدة',
        description: 'إنشاء الأرصدة الافتتاحية للسنة المالية الجديدة',
        icon: Icons.calendar_month,
        status: StepStatus.pending,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(title: 'الإقفال السنوي'),
        body: SingleChildScrollView(
          padding: AppConstant.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnnualCloseYearSelector(
                year: selectedYear,
                onPrevious: () => setState(() => selectedYear--),
                onNext: selectedYear < DateTime.now().year
                    ? () => setState(() => selectedYear++)
                    : null,
              ),
              const SizedBox(height: 24),
              const AnnualCloseSummaryCards(),
              const SizedBox(height: 24),
              AnnualCloseStepsCard(steps: steps),
              const SizedBox(height: 24),
              AnnualCloseActionButtons(
                processing: isProcessing,
                onPreview: _showPreviewDialog,
                onStart: _startClosingProcess,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPreviewDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: const Text('معاينة الإقفال'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('سيتم إجراء العمليات التالية:'),
            SizedBox(height: 16),
            Text('• ترحيل جميع حسابات الإيرادات'),
            Text('• ترحيل جميع حسابات المصروفات'),
            Text('• إنشاء قيد الإقفال السنوي'),
            Text('• فتح السنة المالية الجديدة'),
            SizedBox(height: 16),
            Text(
              'تحذير: هذه العملية لا يمكن التراجع عنها!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _startClosingProcess() {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: const Text('تأكيد الإقفال'),
        content: Text(
          'هل أنت متأكد من إقفال السنة المالية $selectedYear؟\n\nهذه العملية لا يمكن التراجع عنها.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          HasibButton(
            label: 'تأكيد',
            onPressed: () {
              Navigator.pop(context);
              _performClosing();
            },
            variant: HasibButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  void _performClosing() async {
    setState(() => isProcessing = true);

    for (int i = 0; i < steps.length; i++) {
      setState(() {
        steps[i] = steps[i].copyWith(status: StepStatus.inProgress);
      });

      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        steps[i] = steps[i].copyWith(status: StepStatus.completed);
      });
    }

    setState(() => isProcessing = false);

    if (mounted) {
      AppToast.showSuccess(context, 'تم إقفال السنة المالية بنجاح');
    }
  }
}

enum StepStatus { pending, inProgress, completed, error }

class AnnualCloseStep {
  final String title;
  final String description;
  final IconData icon;
  final StepStatus status;

  AnnualCloseStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.status,
  });

  AnnualCloseStep copyWith({
    String? title,
    String? description,
    IconData? icon,
    StepStatus? status,
  }) {
    return AnnualCloseStep(
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      status: status ?? this.status,
    );
  }
}
