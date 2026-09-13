import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/core/widgets/error_state_card.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/text_input_field.dart';

import '../../domain/entities/plan_tier.dart';
import '../../domain/services/license_key_service.dart';
import '../cubit/plans_cubit.dart';
import '../cubit/plans_state.dart';
import '../widgets/device_id_card.dart';
import '../widgets/plan_status_card.dart';
import '../widgets/plan_ui.dart';
import '../widgets/support_whatsapp_card.dart';

/// Enter (or replace) the offline activation key.
class ActivationPage extends StatefulWidget {
  /// When the user arrived from a specific plan card, we show which plan
  /// they are trying to activate.
  final PlanTier? suggestedTier;

  const ActivationPage({super.key, this.suggestedTier});

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final TextEditingController _controller = TextEditingController();
  bool _activating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      AppToast.showWarning(context, 'أدخل مفتاح التفعيل أولاً');
      return;
    }

    setState(() => _activating = true);
    final cubit = context.read<PlansCubit>();
    final error = await cubit.activate(key);
    if (!mounted) return;
    setState(() => _activating = false);

    if (error == null) {
      final plan = cubit.plan;
      _controller.clear();
      FocusScope.of(context).unfocus();
      AppToast.showSuccess(context, 'تم تفعيل الخطة ${plan.nameAr} بنجاح');
    } else {
      AppToast.showError(context, error);
    }
  }

  Future<void> _generateDebugKey(PlanTier tier) async {
    final deviceId = await context.read<PlansCubit>().resolveDeviceId();
    final key = LicenseKeyService.generate(
      tier: tier,
      deviceId: deviceId,
      expiresAt: DateTime.now().add(const Duration(days: 365)),
    );
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('مفتاح ${tier.nameAr} (سنة)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'مفتاح للتجربة فقط، مربوط بمعرّف هذا الجهاز. في الإنتاج '
              'استخدم أداة توليد المفاتيح مع فريق المبيعات.',
              style: TextStyle(fontSize: 12.5, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: SelectableText(
                key,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              await Clipboard.setData(ClipboardData(text: key));
              if (!mounted) return;
              navigator.pop();
              AppToast.showSuccess(context, 'تم نسخ المفتاح، الصقه في الحقل');
            },
            child: const Text('نسخ المفتاح'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetActivation() async {
    await context.read<PlansCubit>().resetActivation();
    if (!mounted) return;
    AppToast.showInfo(context, 'تم إلغاء التفعيل وبدء فترة تجريبية جديدة');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: 'تفعيل التطبيق', showBack: true),
      body: BlocBuilder<PlansCubit, PlansState>(
        builder: (context, state) {
          if (state is PlansLoading || state is PlansInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PlansError) {
            return Center(
              child: ErrorStateCard(
                message: state.message,
                onRetry: () => context.read<PlansCubit>().refresh(),
              ),
            );
          }
          return _ActivationBody(
            state: state as PlansLoaded,
            controller: _controller,
            activating: _activating,
            suggestedTier: widget.suggestedTier,
            onActivate: _activate,
            onGenerateDebugKey: _generateDebugKey,
            onResetActivation: _resetActivation,
          );
        },
      ),
    );
  }
}

class _ActivationBody extends StatelessWidget {
  final PlansLoaded state;
  final TextEditingController controller;
  final bool activating;
  final PlanTier? suggestedTier;
  final VoidCallback onActivate;
  final ValueChanged<PlanTier> onGenerateDebugKey;
  final VoidCallback onResetActivation;

  const _ActivationBody({
    required this.state,
    required this.controller,
    required this.activating,
    required this.suggestedTier,
    required this.onActivate,
    required this.onGenerateDebugKey,
    required this.onResetActivation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggested = suggestedTier;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        PlanStatusCard(state: state),
        if (suggested != null && !state.expired) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: suggested.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(suggested.icon, color: suggested.color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.plan.tier == suggested
                        ? 'خطتك الحالية هي ${suggested.nameAr}.'
                        : 'أنت على وشك تفعيل الخطة ${suggested.nameAr}.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (state.deviceId != null) ...[
          DeviceIdCard(deviceId: state.deviceId!),
          const SizedBox(height: 16),
        ],
        SupportWhatsAppCard(
          deviceId: state.deviceId,
          tier: suggestedTier,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'أدخل مفتاح التفعيل',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'الصق المفتاح الذي استلمته من فريق المبيعات. يتم التحقق منه '
                'محلياً دون الحاجة للإنترنت.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              TextInputField(
                label: 'مفتاح التفعيل',
                hint: 'MHSB-P-20261231-XXXXXX-XXXX-XXXX-XXXX-XXXX',
                controller: controller,
                textAlign: TextAlign.center,
                autofocus: suggested != null,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
                ],
              ),
              const SizedBox(height: 14),
              HasibButton(
                label: 'تفعيل الآن',
                icon: Icons.verified_outlined,
                loading: activating,
                onPressed: activating ? null : onActivate,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'كيف أحصل على مفتاح التفعيل؟',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _step('1', 'اختر الخطة المناسبة من شاشة الخطط والاشتراك.'),
              _step('2', 'انسخ معرّف هذا الجهاز الظاهر بالأعلى وأرسله للمبيعات.'),
              _step('3', 'الصق المفتاح الذي يصل إليك هنا واضغط تفعيل الآن.'),
            ],
          ),
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 16),
          _DebugTools(
            onGenerate: onGenerateDebugKey,
            onReset: onResetActivation,
          ),
        ],
      ],
    );
  }

  Widget _step(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugTools extends StatelessWidget {
  final ValueChanged<PlanTier> onGenerate;
  final VoidCallback onReset;

  const _DebugTools({required this.onGenerate, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amber50,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.amber300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.build_outlined, size: 18, color: AppColors.amber700),
              SizedBox(width: 8),
              Text(
                'أدوات وضع التطوير',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.amber800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'تظهر هذه الأدوات في نسخ التطوير فقط ولا يمكن توليد مفاتيح منها '
            'في نسخة الإنتاج.',
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tier in [
                PlanTier.basic,
                PlanTier.pro,
                PlanTier.enterprise,
              ])
                OutlinedButton(
                  onPressed: () => onGenerate(tier),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.amber800,
                    side: const BorderSide(color: AppColors.amber400),
                  ),
                  child: Text('مفتاح ${tier.nameAr}'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('إلغاء التفعيل وبدء تجربة جديدة'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
        ],
      ),
    );
  }
}
