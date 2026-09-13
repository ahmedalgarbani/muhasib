import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/features/plans/domain/services/license_key_service.dart';

import '../cubit/plans_state.dart';
import 'plan_ui.dart';

/// Gradient card summarising the current subscription and license status.
class PlanStatusCard extends StatelessWidget {
  final PlansLoaded state;
  final VoidCallback? onActivate;

  const PlanStatusCard({super.key, required this.state, this.onActivate});

  @override
  Widget build(BuildContext context) {
    final tier = state.plan.tier;
    final baseColor = state.expired ? AppColors.error : tier.color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            baseColor,
            Color.lerp(baseColor, Colors.black, 0.28) ?? baseColor,
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  state.expired ? Icons.error_outline : tier.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'خطتك الحالية',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            state.plan.nameAr,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (state.trial) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                AppRadius.xl28,
                              ),
                            ),
                            child: const Text(
                              'تجريبي',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _statusText(),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: state.expired
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.95),
            ),
          ),
          if (state.trial && state.daysRemaining != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: LinearProgressIndicator(
                value: (state.daysRemaining! / LicenseKeyService.trialDays)
                    .clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
          if (state.license != null && !state.expired) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.vpn_key_outlined,
                  size: 15,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    state.license!.maskedKey,
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.1,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (onActivate != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onActivate,
                icon: const Icon(Icons.bolt_outlined, size: 18),
                label: Text(
                  state.license == null || state.expired
                      ? 'تفعيل التطبيق'
                      : 'تغيير مفتاح التفعيل',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.7),
                    width: 1.4,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusText() {
    if (state.expired) {
      return 'انتهت صلاحية الترخيص — تم الرجوع إلى الخطة المجانية';
    }
    if (state.trial) {
      final days = state.daysRemaining ?? 0;
      return days == 0
          ? 'ينتهي الاشتراك التجريبي اليوم'
          : 'فترة تجريبية — متبقي $days يوماً';
    }
    final license = state.license;
    if (license == null) return 'لم يتم التفعيل بعد';
    if (license.isPerpetual) return 'ترخيص دائم مفعّل';
    final date = DateFormat('yyyy/MM/dd').format(license.expiresAt!);
    return 'سارية حتى $date';
  }
}
