import 'package:muhasib/core/enums/account_connect_type.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/features/accounts/domain/repositories/account_connect_repository.dart';

/// @Deprecated: استخدم [AccountConnectType] enum بدلاً من هذه الثوابت
/// Kept for gradual migration — new code must use AccountConnectType enum.
class AccountConnectTypes {
  static const int banks = 0;
  static const int cashboxes = 1;
  static const int customers = 2;
  static const int suppliers = 3;
  static const int taxes = 4;
  static const int inventory = 5;
  static const int merchandise = 6;
  static const int sales = 7;
  static const int discountAllowed = 8;
  static const int discountEarned = 9;
  static const int purchases = 10;
  static const int salesReturns = 11;
  static const int purchaseReturns = 12;
  static const int costOfGoodsSold = 13;
  static const int salesCommissionExpense = 14;
  static const int commissionPayable = 15;
  static const int exchangeGainLoss = 16;
  static const int inputVAT = 17;
  static const int outputVAT = 18;
}

/// @Deprecated: لا تستخدم قيم احتياطية ثابتة — المصدر الوحيد هو account_connects الحي.
/// Kept only for seeding / display, never as runtime fallback.
class DefaultAccountIds {
  static const int sales = 4110;
  static const int cash = 1110;
  static const int bank = 1110;
  static const int customers = 1120;
  static const int suppliers = 2110;
  static const int tax = 2140;
  static const int salesReturns = 4150;
  static const int purchaseReturns = 502;
  static const int discountAllowed = 3150;
  static const int discountEarned = 4140;
  static const int inventory = 1180;
  static const int costOfGoodsSold = 3190;
  static const int purchases = 3110;
  static const int salesCommissionExpense = 3180;
  static const int commissionPayable = 2160;
  static const int exchangeGains = 4160;
  static const int exchangeLosses = 3170;
  static const int inputVAT = 1170;
  static const int outputVAT = 2170;
}

/// Service for retrieving dynamically configured account IDs from account_connects table
/// via Clean Architecture (AccountConnectRepository) — live DB only, no hardcoded fallback.
/// يقرأ حصرياً من جدول account_connects الحي ويرمي [AccountNotConfiguredException] عند عدم الضبط.
class AccountConfigService {
  final AccountConnectRepository _repository;

  // Cache for account IDs by enum value
  final Map<AccountConnectType, int> _cache = {};
  final Map<int, int> _legacyCache = {};

  AccountConfigService({required AccountConnectRepository repository})
      : _repository = repository;

  /// Clear the cache (call when account connects are updated)
  void clearCache() {
    _cache.clear();
    _legacyCache.clear();
  }

  // ---------------------------------------------------------------------------
  // Preferred API — type-safe enum
  // ---------------------------------------------------------------------------

  /// Get the configured account c_id for a given connect type (enum).
  /// Throws [AccountNotConfiguredException] if not configured — no silent fallback.
  Future<int> getAccountIdByType(AccountConnectType type) async {
    if (_cache.containsKey(type)) return _cache[type]!;

    final result = await _repository.getAccountConnectByType(type.value);
    return result.fold(
      (failure) => throw AccountNotConfiguredException(
        'فشل جلب ربط الحساب ${type.labelAr} (${type.name}): ${failure.message}',
        connectType: type.value,
      ),
      (entity) {
        if (entity == null || entity.cId == null) {
          throw AccountNotConfiguredException(
            'الحساب غير مهيأ لنوع الربط: ${type.labelAr} (${type.name}=${type.value}). يرجى ضبطه من شاشة ربط الحسابات.',
            connectType: type.value,
          );
        }
        _cache[type] = entity.cId!;
        return entity.cId!;
      },
    );
  }

  /// Alias for getAccountIdByType — shorter name for callers
  Future<int> getAccountIdForType(AccountConnectType type) => getAccountIdByType(type);

  /// Safe variant — returns null instead of throwing
  Future<int?> getAccountIdOrNull(AccountConnectType type) async {
    try {
      return await getAccountIdByType(type);
    } on AccountNotConfiguredException {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Legacy int-based API — deprecated, delegates to enum version
  // ---------------------------------------------------------------------------

  /// @Deprecated Use [getAccountIdByType] with [AccountConnectType]
  /// If [defaultId] is supplied, it is returned as fallback for gradual migration.
  /// Otherwise throws [AccountNotConfiguredException].
  Future<int> getAccountId(int connectType, {int? defaultId}) async {
    if (_legacyCache.containsKey(connectType)) return _legacyCache[connectType]!;

    final type = AccountConnectType.tryFromValue(connectType);
    if (type != null) {
      try {
        final id = await getAccountIdByType(type);
        _legacyCache[connectType] = id;
        return id;
      } on AccountNotConfiguredException {
        if (defaultId != null) {
          _legacyCache[connectType] = defaultId;
          return defaultId;
        }
        rethrow;
      }
    }

    // Unknown connectType — fallback only if caller provided defaultId
    if (defaultId != null) {
      _legacyCache[connectType] = defaultId;
      return defaultId;
    }

    throw AccountNotConfiguredException(
      'نوع ربط حساب غير معروف: $connectType — لا يمكن الرجوع لقيمة افتراضية ثابتة.',
      connectType: connectType,
    );
  }

  // ---------------------------------------------------------------------------
  // Batch configs — now throw if any required account missing
  // ---------------------------------------------------------------------------

  /// Get sales-related account IDs — all from live account_connects
  Future<SalesAccountConfig> getSalesAccountConfig() async {
    // Use try variants for optional accounts that may legitimately be missing?
    // Per spec, throw if not configured — caller should handle.
    return SalesAccountConfig(
      salesAccountId: await getAccountIdByType(AccountConnectType.sales),
      cashAccountId: await getAccountIdByType(AccountConnectType.cashboxes),
      bankAccountId: await getAccountIdByType(AccountConnectType.banks),
      customersAccountId: await getAccountIdByType(AccountConnectType.customers),
      taxAccountId: await getAccountIdOrNull(AccountConnectType.taxes) ??
          await getAccountIdOrNull(AccountConnectType.outputVAT) ??
          (throw AccountNotConfiguredException('حساب الضريبة غير مهيأ', connectType: AccountConnectType.taxes.value)),
      salesReturnsAccountId: await getAccountIdByType(AccountConnectType.salesReturns),
      discountAllowedAccountId: await getAccountIdByType(AccountConnectType.discountAllowed),
      inventoryAccountId: await getAccountIdByType(AccountConnectType.inventory),
      costOfGoodsSoldAccountId: await getAccountIdByType(AccountConnectType.costOfGoodsSold),
    );
  }

  /// Get purchase-related account IDs
  Future<PurchaseAccountConfig> getPurchaseAccountConfig() async {
    return PurchaseAccountConfig(
      purchasesAccountId: await getAccountIdByType(AccountConnectType.purchases),
      cashAccountId: await getAccountIdByType(AccountConnectType.cashboxes),
      bankAccountId: await getAccountIdByType(AccountConnectType.banks),
      suppliersAccountId: await getAccountIdByType(AccountConnectType.suppliers),
      taxAccountId: await getAccountIdOrNull(AccountConnectType.taxes) ??
          await getAccountIdOrNull(AccountConnectType.inputVAT) ??
          (throw AccountNotConfiguredException('حساب الضريبة غير مهيأ', connectType: AccountConnectType.taxes.value)),
      purchaseReturnsAccountId: await getAccountIdByType(AccountConnectType.purchaseReturns),
      discountEarnedAccountId: await getAccountIdByType(AccountConnectType.discountEarned),
      inventoryAccountId: await getAccountIdByType(AccountConnectType.inventory),
    );
  }
}

/// Configuration class for sales-related accounts
class SalesAccountConfig {
  final int salesAccountId;
  final int cashAccountId;
  final int bankAccountId;
  final int customersAccountId;
  final int taxAccountId;
  final int salesReturnsAccountId;
  final int discountAllowedAccountId;
  final int inventoryAccountId;
  final int costOfGoodsSoldAccountId;

  const SalesAccountConfig({
    required this.salesAccountId,
    required this.cashAccountId,
    required this.bankAccountId,
    required this.customersAccountId,
    required this.taxAccountId,
    required this.salesReturnsAccountId,
    required this.discountAllowedAccountId,
    required this.inventoryAccountId,
    required this.costOfGoodsSoldAccountId,
  });

  /// @Deprecated — do not use hardcoded defaults; fetch via AccountConfigService
  static const SalesAccountConfig defaults = SalesAccountConfig(
    salesAccountId: DefaultAccountIds.sales,
    cashAccountId: DefaultAccountIds.cash,
    bankAccountId: DefaultAccountIds.bank,
    customersAccountId: DefaultAccountIds.customers,
    taxAccountId: DefaultAccountIds.tax,
    salesReturnsAccountId: DefaultAccountIds.salesReturns,
    discountAllowedAccountId: DefaultAccountIds.discountAllowed,
    inventoryAccountId: DefaultAccountIds.inventory,
    costOfGoodsSoldAccountId: DefaultAccountIds.costOfGoodsSold,
  );
}

/// Configuration class for purchase-related accounts
class PurchaseAccountConfig {
  final int purchasesAccountId;
  final int cashAccountId;
  final int bankAccountId;
  final int suppliersAccountId;
  final int taxAccountId;
  final int purchaseReturnsAccountId;
  final int discountEarnedAccountId;
  final int inventoryAccountId;

  const PurchaseAccountConfig({
    required this.purchasesAccountId,
    required this.cashAccountId,
    required this.bankAccountId,
    required this.suppliersAccountId,
    required this.taxAccountId,
    required this.purchaseReturnsAccountId,
    required this.discountEarnedAccountId,
    required this.inventoryAccountId,
  });

  /// @Deprecated — do not use hardcoded defaults
  static const PurchaseAccountConfig defaults = PurchaseAccountConfig(
    purchasesAccountId: DefaultAccountIds.purchases,
    cashAccountId: DefaultAccountIds.cash,
    bankAccountId: DefaultAccountIds.bank,
    suppliersAccountId: DefaultAccountIds.suppliers,
    taxAccountId: DefaultAccountIds.tax,
    purchaseReturnsAccountId: DefaultAccountIds.purchaseReturns,
    discountEarnedAccountId: DefaultAccountIds.discountEarned,
    inventoryAccountId: DefaultAccountIds.inventory,
  );
}
