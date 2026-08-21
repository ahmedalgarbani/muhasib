import 'package:muhasib/core/enums/account_connect_type.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/features/accounts/domain/repositories/account_connect_repository.dart';
import 'package:muhasib/features/currencies/domain/entities/currency_entity.dart';
import 'package:muhasib/features/currencies/domain/repositories/currency_repository.dart';
import 'package:muhasib/features/stores/data/datasources/warehouse_local_datasource.dart';
import 'package:muhasib/features/stores/data/models/warehouse_model.dart';
import 'package:muhasib/features/settings_entities/data/datasources/cashbox_local_datasource.dart';
import 'package:muhasib/features/settings_entities/data/models/cashbox_model.dart';
import 'package:muhasib/features/setting/data/repositories/settings_repository.dart';
import 'package:muhasib/features/accounts/data/datasources/fiscal_period_datasource.dart';
import 'package:muhasib/features/accounts/data/models/fiscal_period_model.dart';

/// خدمة وصول ذكية ومركزية للبيانات الأساسية المشتركة
/// Central smart lookup service — respects Clean Architecture by delegating
/// to Repositories / DataSources, never querying sqflite directly.
///
/// Provides caching with [refresh()] to invalidate after edits.
/// All queries hit the **live DB** (account_connects, currencies, settings, stocks...),
/// never Seeders, per fix_rules.
class AppLookupService {
  final CurrencyRepository _currencyRepository;
  final AccountConnectRepository _accountConnectRepository;
  final WarehouseLocalDataSource _warehouseDataSource;
  final CashboxLocalDataSource _cashboxDataSource;
  final ISettingsRepository _settingsRepository;
  final FiscalPeriodDataSource _fiscalPeriodDataSource;

  AppLookupService({
    required CurrencyRepository currencyRepository,
    required AccountConnectRepository accountConnectRepository,
    required WarehouseLocalDataSource warehouseDataSource,
    required CashboxLocalDataSource cashboxDataSource,
    required ISettingsRepository settingsRepository,
    required FiscalPeriodDataSource fiscalPeriodDataSource,
  })  : _currencyRepository = currencyRepository,
        _accountConnectRepository = accountConnectRepository,
        _warehouseDataSource = warehouseDataSource,
        _cashboxDataSource = cashboxDataSource,
        _settingsRepository = settingsRepository,
        _fiscalPeriodDataSource = fiscalPeriodDataSource;

  // ---------------------------------------------------------------------------
  // Caches
  // ---------------------------------------------------------------------------
  CurrencyEntity? _cachedLocalCurrency;
  List<CurrencyEntity>? _cachedActiveCurrencies;
  Map<String, dynamic>? _cachedStockSetting;
  Map<String, dynamic>? _cachedOtherSetting;
  Map<AccountConnectType, int>? _cachedAccountConnects;
  WarehouseModel? _cachedMainWarehouse;
  CashboxModel? _cachedMainCashbox;
  FiscalPeriodModel? _cachedCurrentPeriod;
  DateTime? _cacheTimestamp;

  static const _cacheTtl = Duration(minutes: 5);

  bool get _isCacheValid =>
      _cacheTimestamp != null &&
      DateTime.now().difference(_cacheTimestamp!) < _cacheTtl;

  /// Invalidate all caches — call after any edit to settings/accounts/currencies.
  void clearCache() {
    _cachedLocalCurrency = null;
    _cachedActiveCurrencies = null;
    _cachedStockSetting = null;
    _cachedOtherSetting = null;
    _cachedAccountConnects = null;
    _cachedMainWarehouse = null;
    _cachedMainCashbox = null;
    _cachedCurrentPeriod = null;
    _cacheTimestamp = null;
  }

  Future<void> refresh() async {
    clearCache();
    // Optionally pre-warm caches:
    // await Future.wait([getLocalCurrency(), getDefaultWarehouse()]);
  }

  void _touchCache() {
    _cacheTimestamp = DateTime.now();
  }

  // ---------------------------------------------------------------------------
  // Currencies — live DB, WHERE is_local_currency = 1
  // ---------------------------------------------------------------------------

  /// العملة المحلية الأساسية — يقرأ من جدول currencies حيث is_local_currency = 1
  Future<CurrencyEntity> getLocalCurrency() async {
    if (_cachedLocalCurrency != null && _isCacheValid) return _cachedLocalCurrency!;

    final result = await _currencyRepository.getAllCurrencies();
    return result.fold(
      (failure) => throw CurrencyNotFoundException('فشل جلب العملات: ${failure.message}'),
      (currencies) {
        final local = currencies.where((c) => c.isLocalCurrency).toList();
        if (local.isNotEmpty) {
          _cachedLocalCurrency = local.first;
          _touchCache();
          return local.first;
        }
        // Fallback: first active currency
        final active = currencies.where((c) => c.isActive).toList();
        if (active.isNotEmpty) {
          _cachedLocalCurrency = active.first;
          _touchCache();
          return active.first;
        }
        throw CurrencyNotFoundException('لا توجد عملة محلية مهيأة في جدول currencies');
      },
    );
  }

  Future<List<CurrencyEntity>> getActiveCurrencies() async {
    if (_cachedActiveCurrencies != null && _isCacheValid) return _cachedActiveCurrencies!;
    final result = await _currencyRepository.getAllCurrencies();
    return result.fold(
      (failure) => throw CurrencyNotFoundException('فشل جلب العملات: ${failure.message}'),
      (currencies) {
        final active = currencies.where((c) => c.isActive).toList();
        _cachedActiveCurrencies = active;
        _touchCache();
        return active;
      },
    );
  }

  Future<CurrencyEntity?> getCurrencyById(int id) async {
    final result = await _currencyRepository.getCurrencyById(id);
    return result.fold((_) => null, (c) => c);
  }

  // ---------------------------------------------------------------------------
  // Settings — stock_setting, other_setting live from settings table
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _getStockSetting() async {
    if (_cachedStockSetting != null && _isCacheValid) return _cachedStockSetting!;
    final val = await _settingsRepository.getSetting('stock_setting');
    if (val is Map) {
      _cachedStockSetting = Map<String, dynamic>.from(val as Map);
      _touchCache();
      return _cachedStockSetting!;
    }
    // Try decoding if stored as JSON string
    _cachedStockSetting = <String, dynamic>{};
    return _cachedStockSetting!;
  }

  Future<Map<String, dynamic>> _getOtherSetting() async {
    if (_cachedOtherSetting != null && _isCacheValid) return _cachedOtherSetting!;
    final val = await _settingsRepository.getSetting('other_setting');
    if (val is Map) {
      _cachedOtherSetting = Map<String, dynamic>.from(val as Map);
      _touchCache();
      return _cachedOtherSetting!;
    }
    _cachedOtherSetting = <String, dynamic>{};
    return _cachedOtherSetting!;
  }

  /// نسبة الضريبة الافتراضية من stock_setting.default_tax_rate (حية)
  /// المخزنة كـ 15 تعني 15% → نرجع 0.15
  Future<double> getDefaultTaxRate() async {
    final stock = await _getStockSetting();
    final raw = stock['default_tax_rate'];
    if (raw is num) {
      final v = raw.toDouble();
      return v > 1 ? v / 100.0 : v;
    }
    if (raw is String) {
      final v = double.tryParse(raw) ?? 0;
      return v > 1 ? v / 100.0 : v;
    }
    return 0.0;
  }

  /// هل نظام الضرائب مفعّل؟
  Future<bool> isTaxEnabled() async {
    final stock = await _getStockSetting();
    final v = stock['tax_enabled'];
    if (v is bool) return v;
    if (v is int) return v == 1;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    return false;
  }

  Future<String> getDefaultCurrencyCode() async {
    final other = await _getOtherSetting();
    final code = other['default_currency'];
    if (code is String && code.isNotEmpty) return code;
    // fallback to local currency code from DB
    try {
      final local = await getLocalCurrency();
      return local.code;
    } catch (_) {
      return 'SAR';
    }
  }

  // ---------------------------------------------------------------------------
  // Accounts via account_connects — live DB, throws if not configured
  // ---------------------------------------------------------------------------

  /// جلب معرّف الحساب c_id لنوع ربط معيّن — يقرأ مباشرة من account_connects الحية
  /// يرمي [AccountNotConfiguredException] إذا لم يكن الحساب مهيأً.
  Future<int> getAccountId(AccountConnectType type) async {
    // Check bulk cache
    if (_cachedAccountConnects != null && _isCacheValid && _cachedAccountConnects!.containsKey(type)) {
      return _cachedAccountConnects![type]!;
    }

    final result = await _accountConnectRepository.getAccountConnectByType(type.value);
    return result.fold(
      (failure) => throw AccountNotConfiguredException(
        'فشل جلب ربط الحساب ${type.labelAr} (${type.name}): ${failure.message}',
        connectType: type.value,
      ),
      (entity) {
        if (entity == null || entity.cId == null) {
          throw AccountNotConfiguredException(
            'الحساب غير مهيأ لنوع الربط: ${type.labelAr} (${type.name} = ${type.value}). يرجى ضبطه من شاشة ربط الحسابات.',
            connectType: type.value,
          );
        }
        // update cache
        _cachedAccountConnects ??= {};
        _cachedAccountConnects![type] = entity.cId!;
        _touchCache();
        return entity.cId!;
      },
    );
  }

  /// نسخة آمنة تُرجع null بدلاً من الرمي
  Future<int?> getAccountIdOrNull(AccountConnectType type) async {
    try {
      return await getAccountId(type);
    } on AccountNotConfiguredException {
      return null;
    }
  }

  /// جلب جميع روابط الحسابات مرة واحدة (للواجهات)
  Future<Map<AccountConnectType, int>> getAllAccountConnects() async {
    if (_cachedAccountConnects != null && _isCacheValid) return _cachedAccountConnects!;
    final result = await _accountConnectRepository.getAllAccountConnects();
    return result.fold(
      (failure) => throw AccountNotConfiguredException('فشل جلب روابط الحسابات: ${failure.message}'),
      (list) {
        final map = <AccountConnectType, int>{};
        for (final e in list) {
          final rawType = e.accountConnectType;
          if (rawType == null) continue;
          final t = AccountConnectType.tryFromValue(rawType);
          if (t != null && e.cId != null) map[t] = e.cId!;
        }
        _cachedAccountConnects = map;
        _touchCache();
        return map;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Warehouse / CashBox — live DB, default from settings or is_main flag
  // ---------------------------------------------------------------------------

  /// المستودع الافتراضي — من settings.stock_setting.default_warehouse أو is_main_stock
  Future<WarehouseModel> getDefaultWarehouse() async {
    if (_cachedMainWarehouse != null && _isCacheValid) return _cachedMainWarehouse!;

    // 1) Try settings
    try {
      final stock = await _getStockSetting();
      final wareId = stock['default_warehouse'];
      int? id;
      if (wareId is int) id = wareId;
      if (wareId is String) id = int.tryParse(wareId);
      if (id != null && id > 0) {
        try {
          final w = await _warehouseDataSource.getWarehouseById(id);
          _cachedMainWarehouse = w;
          _touchCache();
          return w;
        } catch (_) {
          // fall through to is_main
        }
      }
    } catch (_) {}

    // 2) Fallback to is_main_stock = 1
    final main = await _warehouseDataSource.getMainWarehouse();
    if (main != null) {
      _cachedMainWarehouse = main;
      _touchCache();
      return main;
    }

    // 3) First active
    final actives = await _warehouseDataSource.getActiveWarehouses();
    if (actives.isNotEmpty) {
      _cachedMainWarehouse = actives.first;
      _touchCache();
      return actives.first;
    }

    throw WarehouseNotFoundException('لا يوجد مستودع افتراضي مهيأ — يرجى إنشاء مستودع وتحديده كرئيسي');
  }

  Future<int> getDefaultWarehouseId() async {
    final w = await getDefaultWarehouse();
    final id = w.id;
    if (id == null) throw WarehouseNotFoundException('تعذر قراءة معرّف المستودع الافتراضي');
    return id;
  }

  /// الصندوق الافتراضي — من is_main_fund = 1
  Future<CashboxModel> getDefaultCashBox() async {
    if (_cachedMainCashbox != null && _isCacheValid) return _cachedMainCashbox!;
    final main = await _cashboxDataSource.getMainCashbox();
    if (main != null) {
      _cachedMainCashbox = main;
      _touchCache();
      return main;
    }
    final actives = await _cashboxDataSource.getActiveCashboxes();
    if (actives.isNotEmpty) {
      _cachedMainCashbox = actives.first;
      _touchCache();
      return actives.first;
    }
    throw WarehouseNotFoundException('لا يوجد صندوق افتراضي مهيأ');
  }

  Future<int> getDefaultCashBoxId() async {
    final b = await getDefaultCashBox();
    final id = b.id;
    if (id == null) throw WarehouseNotFoundException('تعذر قراءة معرّف الصندوق الافتراضي');
    return id;
  }

  // ---------------------------------------------------------------------------
  // Fiscal Period
  // ---------------------------------------------------------------------------

  Future<FiscalPeriodModel?> getCurrentFiscalPeriod() async {
    if (_cachedCurrentPeriod != null && _isCacheValid) return _cachedCurrentPeriod;
    final period = await _fiscalPeriodDataSource.getPeriodForDate(DateTime.now());
    _cachedCurrentPeriod = period;
    _touchCache();
    return period;
  }

  // ---------------------------------------------------------------------------
  // Convenience helpers for invoice / accounting services
  // ---------------------------------------------------------------------------

  /// إعدادات المبيعات/المشتريات من account_connects (تغليف لـ getAccountId)
  Future<Map<String, int>> getSalesAccountIds() async {
    return {
      'sales': await getAccountId(AccountConnectType.sales),
      'cash': await getAccountId(AccountConnectType.cashboxes),
      'customers': await getAccountId(AccountConnectType.customers),
      'tax': await getAccountIdOrNull(AccountConnectType.taxes) ?? await getAccountIdOrNull(AccountConnectType.outputVAT) ?? 0,
    };
  }
}
