// lib/core/route/route_names.dart
class AppRoutes {
  // ======= Core Screens =======
  static const String splash = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';
  static const String profile = '/profile';

  // ======= Initial Setup =======
  static const String initialSetup = '/initial/setup';

  // ======= Header =======
  static const String usersSync = '/users-sync';

  // ======= الحسابات =======
  static const String accounts = '/accounts';
  static const String accountsGuide = '/accounts/guide';
  static const String accountsLink = '/accounts/link';
  static const String accountsJournal = '/accounts/journal';
  static const String accountsJournalAdd = '/accounts/journal/add';
  static const String accountsVouchers = '/accounts/vouchers';
  static const String accountsOpeningBalance = '/accounts/opening-balance';
  static const String accountsLimits = '/accounts/limits';
  static const String accountsAnnualClose = '/accounts/annual-close';

  // ======= العملات =======
  static const String currencies = '/currencies';
  static const String currenciesManage = '/currencies/manage';
  static const String currenciesExchange = '/currencies/exchange';
  static const String currenciesRevaluation = '/currencies/revaluation';

  // ======= المبيعات =======
  static const String sales = '/sales';
  static const String salesAddInvoice = '/sales/add-invoice';
  static const String salesImprovedInvoice = '/sales/improved-invoice';
  static const String salesList = '/sales/list';
  static const String salesQuotes = '/sales/quotes';
  static const String salesReturns = '/sales/returns';
  static const String salesReturnsForm = '/sales-returns-form';
  static const String selectInvoiceForReturn =
      '/sales/select-invoice-for-return';

  // ======= المشتريات =======
  static const String purchases = '/purchases';
  static const String purchasesAddInvoice = '/purchases/add-invoice';
  static const String purchasesDetail = '/purchases/detail';
  static const String purchasesList = '/purchases/list';
  static const String purchasesOrders = '/purchases/orders';
  static const String purchasesReturns = '/purchases/returns';

  // ======= الأصناف =======
  static const String items = '/items';
  static const String itemsGroups = '/items/groups';
  static const String itemsUnits = '/items/units';
  static const String itemsManage = '/items/manage';
  static const String itemsSubUnits = '/items/sub-units';
  static const String itemsPricing = '/items/pricing';
  static const String itemsMovements = '/items/movements';

  // ======= المخازن =======
  static const String warehouses = '/warehouses';
  static const String warehousesList = '/warehouses/list';
  static const String warehouseForm = '/warehouses/form';
  static const String warehousesInventory = '/warehouses/inventory';
  static const String warehousesAdjustment = '/warehouses/adjustment';
  static const String warehousesTransfer = '/warehouses/transfer';

  // ======= التهيئات =======
  static const String settingsCategories = '/settings/categories';
  static const String settingsBanks = '/settings/banks';
  static const String settingsCashboxes = '/settings/cashboxes';
  static const String settingsOtherFees = '/settings/other-fees';
  static const String settingsRegions = '/settings/regions';

  // ======= إعدادات النظام =======
  static const String settingsPersonal = '/settings/personal';
  static const String settingsPrint = '/settings/print';
  static const String settingsSecurity = '/settings/security';
  static const String settingsVoucher = '/settings/voucher';
  static const String settingsStock = '/settings/stock';
  static const String settingsOther = '/settings/other';
  static const String settingsMaintenance = '/settings/maintenance';
  static const String settingsActivation = '/settings/activation';

  // ======= التقارير =======
  static const String reports = '/reports';
  static const String reportsTransactions = '/reports/transactions';
  static const String reportsAccountStatement = '/reports/account-statement';
  static const String reportsMore = '/reports/more';

  // تقارير المحاسبة
  static const String reportsTrialBalance = '/reports/trial-balance';
  static const String reportsIncomeStatement = '/reports/income-statement';
  static const String reportsBalanceSheet = '/reports/balance-sheet';
  static const String reportsCashFlow = '/reports/cash-flow';
  static const String reportsGeneralLedger = '/reports/general-ledger';
  static const String reportsJournal = '/reports/journal';

  // تقارير المبيعات
  static const String reportsSalesSummary = '/reports/sales-summary';
  static const String reportsSalesByCustomer = '/reports/sales-by-customer';
  static const String reportsSalesByProduct = '/reports/sales-by-product';
  static const String reportsDailySales = '/reports/daily-sales';
  static const String reportsInvoices = '/reports/invoices';
  static const String reportsQuotations = '/reports/quotations';
  static const String reportsSalesReturns = '/reports/sales-returns';

  // تقارير المشتريات
  static const String reportsPurchaseSummary = '/reports/purchase-summary';
  static const String reportsPurchaseBySupplier =
      '/reports/purchase-by-supplier';
  static const String reportsPurchaseByProduct = '/reports/purchase-by-product';
  static const String reportsPurchaseReturns = '/reports/purchase-returns';

  // تقارير المخزون
  static const String reportsStock = '/reports/stock';
  static const String reportsStockMovement = '/reports/stock-movement';
  static const String reportsLowStock = '/reports/low-stock';
  static const String reportsStockValuation = '/reports/stock-valuation';

  // تقارير العملاء والموردين
  static const String reportsCustomerStatement = '/reports/customer-statement';
  static const String reportsCustomerBalances = '/reports/customer-balances';
  static const String reportsAgedReceivables = '/reports/aged-receivables';
  static const String reportsSupplierStatement = '/reports/supplier-statement';
  static const String reportsSupplierBalances = '/reports/supplier-balances';
  static const String reportsAgedPayables = '/reports/aged-payables';

  // ======= الملفات الشخصية (العملاء والموردين) =======
  static const String profiles = '/profiles';
  static const String customersProfile = '/profiles/customers';
  static const String suppliersProfile = '/profiles/suppliers';
  static const String customerDetails = '/profiles/customers/details';
  static const String supplierDetails = '/profiles/suppliers/details';

  // ======= عن التطبيق =======
  static const String about = '/about';
  static const String aboutYoutube = '/about/youtube';
  static const String aboutShare = '/about/share';
  static const String aboutRate = '/about/rate';
  static const String aboutHelp = '/about/help';
  static const String aboutPrivacy = '/about/privacy';
  static const String aboutTerms = '/about/terms';
}
