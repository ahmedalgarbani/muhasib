import 'package:flutter/material.dart';

class AnnualClosePage extends StatefulWidget {
  const AnnualClosePage({Key? key}) : super(key: key);

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
        description: 'نقل أرصدة حسابات الإيرادات والمصروفات إلى حساب ملخص الدخل',
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
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'الإقفال السنوي',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildYearSelector(),
              const SizedBox(height: 24),
              _buildSummaryCards(),
              const SizedBox(height: 24),
              _buildStepsCard(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearSelector() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.date_range, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'السنة المالية',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$selectedYear',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => selectedYear--),
                  icon: const Icon(Icons.chevron_right),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: selectedYear < DateTime.now().year
                      ? () => setState(() => selectedYear++)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'إجمالي الإيرادات',
            '0.00',
            Icons.trending_up,
            const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'إجمالي المصروفات',
            '0.00',
            Icons.trending_down,
            const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'صافي الربح/الخسارة',
            '0.00',
            Icons.account_balance_wallet,
            const Color(0xFF6366F1),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'خطوات الإقفال',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              return _buildStepItem(step, index, index == steps.length - 1);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(AnnualCloseStep step, int index, bool isLast) {
    Color statusColor;
    IconData statusIcon;

    switch (step.status) {
      case StepStatus.completed:
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle;
        break;
      case StepStatus.inProgress:
        statusColor = const Color(0xFF6366F1);
        statusIcon = Icons.sync;
        break;
      case StepStatus.error:
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.circle_outlined;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor, width: 2),
              ),
              child: Icon(step.icon, color: statusColor, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: statusColor.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      step.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    Icon(statusIcon, color: statusColor, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showPreviewDialog(),
            icon: const Icon(Icons.preview),
            label: const Text('معاينة'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: isProcessing ? null : () => _startClosingProcess(),
            icon: isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(isProcessing ? 'جاري الإقفال...' : 'بدء الإقفال'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPreviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الإقفال'),
        content: Text(
          'هل أنت متأكد من إقفال السنة المالية $selectedYear؟\n\nهذه العملية لا يمكن التراجع عنها.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performClosing();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            child: const Text('تأكيد'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إقفال السنة المالية بنجاح'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
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

