import 'package:flutter_test/flutter_test.dart';
import 'package:muhasib/features/plans/domain/entities/plan_feature.dart';
import 'package:muhasib/features/plans/domain/entities/plan_limit.dart';
import 'package:muhasib/features/plans/domain/entities/plan_tier.dart';
import 'package:muhasib/features/plans/domain/plans_catalog.dart';
import 'package:muhasib/features/plans/domain/services/plan_cache.dart';
import 'package:muhasib/features/plans/domain/services/plan_limit_guard.dart';

void main() {
  group('PlansCatalog', () {
    test('every purchasable plan includes the POS baseline', () {
      for (final plan in PlansCatalog.purchasablePlans) {
        expect(plan.hasFeature(PlanFeature.pointOfSale), isTrue);
        expect(plan.hasFeature(PlanFeature.salesInvoices), isTrue);
        expect(plan.nameAr, isNotEmpty);
      }
    });

    test('tiers are cumulative', () {
      for (var i = 1; i < PlansCatalog.purchasablePlans.length; i++) {
        final lower = PlansCatalog.purchasablePlans[i - 1];
        final higher = PlansCatalog.purchasablePlans[i];
        for (final feature in lower.features) {
          expect(
            higher.hasFeature(feature),
            isTrue,
            reason: '${higher.tier.name} should include ${feature.name}',
          );
        }
      }
    });

    test('premium features are locked on the free plan', () {
      final free = PlansCatalog.free;
      expect(free.hasFeature(PlanFeature.accounting), isFalse);
      expect(free.hasFeature(PlanFeature.multiCurrency), isFalse);
      expect(free.hasFeature(PlanFeature.reportsAdvanced), isFalse);
      expect(free.hasFeature(PlanFeature.warehouses), isFalse);
    });

    test('enterprise is unlimited', () {
      final enterprise = PlansCatalog.enterprise;
      for (final limit in PlanLimit.values) {
        expect(enterprise.isUnlimited(limit), isTrue);
      }
    });

    test('expired licenses fall back to free', () {
      expect(
        PlansCatalog.effectivePlanFor(PlanTier.enterprise, expired: true).tier,
        PlanTier.free,
      );
      expect(
        PlansCatalog.effectivePlanFor(PlanTier.enterprise, expired: false).tier,
        PlanTier.enterprise,
      );
    });
  });

  group('PlanCache & PlanLimitGuard', () {
    tearDown(PlanCache.reset);

    test('reflects the active plan entitlements', () {
      PlanCache.update(plan: PlansCatalog.pro);

      expect(PlanCache.isEnabled(PlanFeature.accounting), isTrue);
      expect(PlanCache.isUnlimited(PlanLimit.maxMonthlyInvoices), isTrue);
      expect(PlanCache.canAdd(PlanLimit.maxProducts, 19999), isTrue);
      expect(PlanCache.canAdd(PlanLimit.maxProducts, 20000), isFalse);
    });

    test('guard explains the blocked limit in Arabic', () {
      PlanCache.update(plan: PlansCatalog.free);

      final error = PlanLimitGuard.check(PlanLimit.maxProducts, 300);

      expect(error, isNotNull);
      expect(error, contains('الأصناف'));
      expect(error, contains('المجانية'));
      expect(PlanLimitGuard.check(PlanLimit.maxProducts, 299), isNull);
    });

    test('resets to the free plan', () {
      PlanCache.update(plan: PlansCatalog.enterprise);
      PlanCache.reset();

      expect(PlanCache.plan.tier, PlanTier.free);
      expect(PlanCache.license, isNull);
    });
  });
}
