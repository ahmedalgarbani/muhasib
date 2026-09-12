import 'package:equatable/equatable.dart';
import 'plan_feature.dart';
import 'plan_limit.dart';
import 'plan_tier.dart';

/// Immutable description of a subscription plan (pricing + entitlements).
class PlanEntity extends Equatable {
  final PlanTier tier;
  final String nameAr;
  final String nameEn;
  final String taglineAr;

  /// Prices in SAR. `null` means "contact us / not for sale" (e.g. trial).
  final num? priceMonthly;
  final num? priceYearly;

  final Set<PlanFeature> features;
  final Map<PlanLimit, int?> limits;
  final bool isPopular;

  const PlanEntity({
    required this.tier,
    required this.nameAr,
    required this.nameEn,
    required this.taglineAr,
    required this.features,
    required this.limits,
    this.priceMonthly,
    this.priceYearly,
    this.isPopular = false,
  });

  bool hasFeature(PlanFeature feature) => features.contains(feature);

  /// `null` when the limit does not exist or is explicitly unlimited.
  int? limitOf(PlanLimit limit) {
    if (!limits.containsKey(limit)) return null;
    return limits[limit];
  }

  bool isUnlimited(PlanLimit limit) => limitOf(limit) == null;

  String limitLabel(PlanLimit limit) {
    final value = limitOf(limit);
    return value == null ? 'غير محدود' : '$value';
  }

  @override
  List<Object?> get props => [
        tier,
        nameAr,
        nameEn,
        taglineAr,
        priceMonthly,
        priceYearly,
        features,
        limits,
        isPopular,
      ];
}
