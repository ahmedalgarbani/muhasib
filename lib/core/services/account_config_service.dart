import 'package:sqflite/sqflite.dart';

/// Account Connect Types (matching the account_link_page.dart definitions)
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
  static const int inputVAT = 17;  // ضريبة المدخلات (مشتريات)
  static const int outputVAT = 18; // ضريبة المخرجات (مبيعات)
}

/// Default Account IDs (fallback values when no account_connect is configured)
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
  static const int inputVAT = 1170;  // ضريبة مدخلات قابلة للاسترداد
  static const int outputVAT = 2170; // ضريبة مخرجات مستحقة
}

/// Service for retrieving dynamically configured account IDs from account_connects table
class AccountConfigService {
  final Database database;
  
  // Cache for account IDs
  final Map<int, int?> _accountIdCache = {};
  
  AccountConfigService({required this.database});
  
  /// Clear the cache (call when account connects are updated)
  void clearCache() {
    _accountIdCache.clear();
  }
  
  /// Get the configured account c_id for a given connect type
  /// Returns the default account ID if no connection is configured
  Future<int> getAccountId(int connectType, {int? defaultId}) async {
    // Check cache first
    if (_accountIdCache.containsKey(connectType)) {
      final cached = _accountIdCache[connectType];
      if (cached != null) return cached;
      return defaultId ?? _getDefaultForType(connectType);
    }
    
    try {
      final result = await database.query(
        'account_connects',
        where: 'account_connect_type = ?',
        whereArgs: [connectType],
        limit: 1,
      );
      
      if (result.isNotEmpty && result.first['c_id'] != null) {
        final accountCId = result.first['c_id'] as int;
        _accountIdCache[connectType] = accountCId;
        return accountCId;
      }
    } catch (e) {
      // Database error, use default
    }
    
    // No connection found, cache null and return default
    _accountIdCache[connectType] = null;
    return defaultId ?? _getDefaultForType(connectType);
  }
  
  /// Get default account ID for a connect type
  int _getDefaultForType(int connectType) {
    switch (connectType) {
      case AccountConnectTypes.banks:
        return DefaultAccountIds.bank;
      case AccountConnectTypes.cashboxes:
        return DefaultAccountIds.cash;
      case AccountConnectTypes.customers:
        return DefaultAccountIds.customers;
      case AccountConnectTypes.suppliers:
        return DefaultAccountIds.suppliers;
      case AccountConnectTypes.taxes:
        return DefaultAccountIds.tax;
      case AccountConnectTypes.inventory:
        return DefaultAccountIds.inventory;
      case AccountConnectTypes.merchandise:
        return DefaultAccountIds.inventory;
      case AccountConnectTypes.sales:
        return DefaultAccountIds.sales;
      case AccountConnectTypes.discountAllowed:
        return DefaultAccountIds.discountAllowed;
      case AccountConnectTypes.discountEarned:
        return DefaultAccountIds.discountEarned;
      case AccountConnectTypes.purchases:
        return DefaultAccountIds.purchases;
      case AccountConnectTypes.salesReturns:
        return DefaultAccountIds.salesReturns;
      case AccountConnectTypes.purchaseReturns:
        return DefaultAccountIds.purchaseReturns;
      case AccountConnectTypes.costOfGoodsSold:
        return DefaultAccountIds.costOfGoodsSold;
      default:
        return 100; // Fallback
    }
  }
  
  /// Get sales-related account IDs
  Future<SalesAccountConfig> getSalesAccountConfig() async {
    return SalesAccountConfig(
      salesAccountId: await getAccountId(AccountConnectTypes.sales),
      cashAccountId: await getAccountId(AccountConnectTypes.cashboxes),
      bankAccountId: await getAccountId(AccountConnectTypes.banks),
      customersAccountId: await getAccountId(AccountConnectTypes.customers),
      taxAccountId: await getAccountId(AccountConnectTypes.taxes),
      salesReturnsAccountId: await getAccountId(AccountConnectTypes.salesReturns, defaultId: DefaultAccountIds.salesReturns),
      discountAllowedAccountId: await getAccountId(AccountConnectTypes.discountAllowed),
      inventoryAccountId: await getAccountId(AccountConnectTypes.inventory),
      costOfGoodsSoldAccountId: await getAccountId(AccountConnectTypes.costOfGoodsSold, defaultId: DefaultAccountIds.costOfGoodsSold),
    );
  }
  
  /// Get purchase-related account IDs
  Future<PurchaseAccountConfig> getPurchaseAccountConfig() async {
    return PurchaseAccountConfig(
      purchasesAccountId: await getAccountId(AccountConnectTypes.purchases),
      cashAccountId: await getAccountId(AccountConnectTypes.cashboxes),
      bankAccountId: await getAccountId(AccountConnectTypes.banks),
      suppliersAccountId: await getAccountId(AccountConnectTypes.suppliers),
      taxAccountId: await getAccountId(AccountConnectTypes.taxes),
      purchaseReturnsAccountId: await getAccountId(AccountConnectTypes.purchaseReturns, defaultId: DefaultAccountIds.purchaseReturns),
      discountEarnedAccountId: await getAccountId(AccountConnectTypes.discountEarned),
      inventoryAccountId: await getAccountId(AccountConnectTypes.inventory),
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
  
  /// Create default configuration
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
  
  /// Create default configuration
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
