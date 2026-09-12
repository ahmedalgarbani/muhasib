import 'entities/plan_entity.dart';
import 'entities/plan_feature.dart';
import 'entities/plan_limit.dart';
import 'entities/plan_tier.dart';

/// Single source of truth for what each plan offers and costs.
/// Edit this file to tune pricing, features and limits — nothing else.
class PlansCatalog {
  static const PlanEntity free = PlanEntity(
    tier: PlanTier.free,
    nameAr: 'المجانية',
    nameEn: 'Free',
    taglineAr: 'ابدأ البيع وإدارة أصنافك بدون أي تكلفة',
    priceMonthly: 0,
    priceYearly: 0,
    features: {
      PlanFeature.pointOfSale,
      PlanFeature.salesInvoices,
      PlanFeature.products,
      PlanFeature.customers,
      PlanFeature.suppliers,
      PlanFeature.reportsBasic,
    },
    limits: {
      PlanLimit.maxProducts: 300,
      PlanLimit.maxWarehouses: 1,
      PlanLimit.maxUsers: 1,
      PlanLimit.maxCurrencies: 1,
      PlanLimit.maxMonthlyInvoices: 300,
    },
  );

  static const PlanEntity basic = PlanEntity(
    tier: PlanTier.basic,
    nameAr: 'الأساسية',
    nameEn: 'Basic',
    taglineAr: 'للمتاجر الصغيرة التي تحتاج المخزون والمشتريات',
    priceMonthly: 99,
    priceYearly: 990,
    features: {
      PlanFeature.pointOfSale,
      PlanFeature.salesInvoices,
      PlanFeature.salesReturns,
      PlanFeature.quotations,
      PlanFeature.purchases,
      PlanFeature.purchaseReturns,
      PlanFeature.products,
      PlanFeature.multiUnit,
      PlanFeature.customers,
      PlanFeature.suppliers,
      PlanFeature.stockOperations,
      PlanFeature.reportsBasic,
    },
    limits: {
      PlanLimit.maxProducts: 3000,
      PlanLimit.maxWarehouses: 1,
      PlanLimit.maxUsers: 3,
      PlanLimit.maxCurrencies: 1,
      PlanLimit.maxMonthlyInvoices: 3000,
    },
  );

  static const PlanEntity pro = PlanEntity(
    tier: PlanTier.pro,
    nameAr: 'الاحترافية',
    nameEn: 'Professional',
    taglineAr: 'محاسبة كاملة، مخازن متعددة وعملات متعددة',
    priceMonthly: 199,
    priceYearly: 1990,
    isPopular: true,
    features: {
      PlanFeature.pointOfSale,
      PlanFeature.salesInvoices,
      PlanFeature.salesReturns,
      PlanFeature.quotations,
      PlanFeature.purchases,
      PlanFeature.purchaseReturns,
      PlanFeature.purchaseOrders,
      PlanFeature.products,
      PlanFeature.multiUnit,
      PlanFeature.customers,
      PlanFeature.suppliers,
      PlanFeature.stockOperations,
      PlanFeature.warehouses,
      PlanFeature.accounting,
      PlanFeature.multiCurrency,
      PlanFeature.reportsBasic,
      PlanFeature.reportsAdvanced,
      PlanFeature.barcodeScanning,
      PlanFeature.backup,
      PlanFeature.users,
    },
    limits: {
      PlanLimit.maxProducts: 20000,
      PlanLimit.maxWarehouses: 5,
      PlanLimit.maxUsers: 10,
      PlanLimit.maxCurrencies: 10,
      PlanLimit.maxMonthlyInvoices: null,
    },
  );

  static const PlanEntity enterprise = PlanEntity(
    tier: PlanTier.enterprise,
    nameAr: 'الأعمال',
    nameEn: 'Enterprise',
    taglineAr: 'بلا حدود، مع دعم ذو أولوية لفريقك',
    priceMonthly: 399,
    priceYearly: 3990,
    features: {
      PlanFeature.pointOfSale,
      PlanFeature.salesInvoices,
      PlanFeature.salesReturns,
      PlanFeature.quotations,
      PlanFeature.purchases,
      PlanFeature.purchaseReturns,
      PlanFeature.purchaseOrders,
      PlanFeature.products,
      PlanFeature.multiUnit,
      PlanFeature.customers,
      PlanFeature.suppliers,
      PlanFeature.stockOperations,
      PlanFeature.warehouses,
      PlanFeature.accounting,
      PlanFeature.multiCurrency,
      PlanFeature.reportsBasic,
      PlanFeature.reportsAdvanced,
      PlanFeature.barcodeScanning,
      PlanFeature.backup,
      PlanFeature.users,
      PlanFeature.prioritySupport,
    },
    limits: {
      PlanLimit.maxProducts: null,
      PlanLimit.maxWarehouses: null,
      PlanLimit.maxUsers: null,
      PlanLimit.maxCurrencies: null,
      PlanLimit.maxMonthlyInvoices: null,
    },
  );

  /// 30-day evaluation license with Professional-level entitlements.
  static const PlanEntity trial = PlanEntity(
    tier: PlanTier.trial,
    nameAr: 'التجريبية',
    nameEn: 'Trial',
    taglineAr: 'جرّب كل مميزات الخطة الاحترافية لمدة 30 يوماً',
    priceMonthly: null,
    priceYearly: null,
    features: {
      PlanFeature.pointOfSale,
      PlanFeature.salesInvoices,
      PlanFeature.salesReturns,
      PlanFeature.quotations,
      PlanFeature.purchases,
      PlanFeature.purchaseReturns,
      PlanFeature.purchaseOrders,
      PlanFeature.products,
      PlanFeature.multiUnit,
      PlanFeature.customers,
      PlanFeature.suppliers,
      PlanFeature.stockOperations,
      PlanFeature.warehouses,
      PlanFeature.accounting,
      PlanFeature.multiCurrency,
      PlanFeature.reportsBasic,
      PlanFeature.reportsAdvanced,
      PlanFeature.barcodeScanning,
      PlanFeature.backup,
      PlanFeature.users,
    },
    limits: {
      PlanLimit.maxProducts: 20000,
      PlanLimit.maxWarehouses: 5,
      PlanLimit.maxUsers: 10,
      PlanLimit.maxCurrencies: 10,
      PlanLimit.maxMonthlyInvoices: null,
    },
  );

  /// Purchasable plans shown on the upgrade screen (trial excluded).
  static const List<PlanEntity> purchasablePlans = [free, basic, pro, enterprise];

  static const List<PlanEntity> all = [free, basic, pro, enterprise, trial];

  static PlanEntity planFor(PlanTier tier) {
    switch (tier) {
      case PlanTier.free:
        return free;
      case PlanTier.basic:
        return basic;
      case PlanTier.pro:
        return pro;
      case PlanTier.enterprise:
        return enterprise;
      case PlanTier.trial:
        return trial;
    }
  }

  /// Returns the plan entitled by a valid, non-expired license.
  /// Expired licenses fall back to [free].
  static PlanEntity effectivePlanFor(PlanTier tier, {required bool expired}) {
    if (expired) return free;
    return planFor(tier);
  }
}
