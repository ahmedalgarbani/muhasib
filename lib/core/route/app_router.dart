import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/features/accounts/presentation/cubit/account_connect_cubit.dart';
import 'package:muhasib/features/accounts/presentation/pages/account_link_page.dart';
import 'package:muhasib/features/accounts/presentation/pages/accounts_limit_page.dart';
import 'package:muhasib/features/currencies/presentation/pages/currencies_page.dart';
import 'package:muhasib/features/accounts/presentation/pages/open_balance_page.dart';
import 'package:muhasib/features/accounts/presentation/pages/voucher_form_screen_page.dart';
import 'package:muhasib/features/accounts/presentation/pages/journal_entry_page.dart';
import 'package:muhasib/features/accounts/presentation/cubit/journal_entry_cubit.dart';
import 'package:muhasib/features/main/presentation/pages/home_page_view.dart';
import 'package:muhasib/features/accounts/presentation/pages/accounts_tree_view.dart';
import 'package:muhasib/features/reports/presentation/pages/account_statement_report_page.dart';
import 'package:muhasib/features/reports/presentation/pages/reports_hub_page.dart';
import 'package:muhasib/features/reports/presentation/pages/trial_balance_report_page.dart';
import 'package:muhasib/features/reports/presentation/pages/income_statement_report_page.dart';
import 'package:muhasib/features/reports/presentation/pages/sales_summary_report_page.dart';
import 'package:muhasib/features/reports/presentation/pages/stock_report_page.dart';
import 'package:muhasib/features/reports/presentation/pages/transactions_report_page.dart';
import 'package:muhasib/features/reports/presentation/pages/generic_report_page.dart';
import 'package:muhasib/features/reports/domain/entities/report_item.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/sales_invoice_screen.dart';
import 'package:muhasib/features/sales/presentation/pages/improved_sales_invoice_screen.dart';
import 'package:muhasib/features/sales/presentation/widgets/sale_page_body.dart';
import 'package:muhasib/features/sales/presentation/pages/quotations_page.dart';
import 'package:muhasib/features/sales/presentation/pages/returns_page.dart';
import 'package:muhasib/features/sales/presentation/pages/return_invoice_form_page.dart';
import 'package:muhasib/features/sales/presentation/pages/select_invoice_for_return_page.dart';
import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/purchases/presentation/pages/purchases_list_page.dart';
import 'package:muhasib/features/purchases/presentation/pages/purchase_form_page.dart';
import 'package:muhasib/features/purchases/presentation/pages/purchase_orders_page.dart';
import 'package:muhasib/features/purchases/presentation/pages/purchase_returns_page.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/products/presentation/pages/product_groups_page.dart';
import 'package:muhasib/features/products/presentation/pages/product_units_page.dart';
import 'package:muhasib/features/products/presentation/pages/products_page.dart';
import 'package:muhasib/features/products/presentation/pages/product_sub_units_page.dart';
import 'package:muhasib/features/products/presentation/pages/product_pricing_page.dart';
import 'package:muhasib/features/products/presentation/pages/item_movements_page.dart';
import 'package:muhasib/features/setting/presentation/cubit/setting_cubit.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/presentation/pages/stock_adjustment_page.dart';
import 'package:muhasib/features/stores/presentation/pages/stock_transfer_page.dart';
import 'package:muhasib/features/stores/presentation/pages/warehouses_inventory_page.dart';
import 'package:muhasib/features/stores/presentation/pages/warehouses_main_page.dart';
import 'package:muhasib/features/stores/presentation/pages/warehouses_list_page.dart';
import 'package:muhasib/features/stores/presentation/pages/warehouse_form_page.dart';
import 'package:muhasib/features/setting/presentation/pages/settings_page.dart'
    as new_settings;
import 'package:muhasib/features/setting/presentation/pages/personal_info_page.dart';
import 'package:muhasib/features/setting/presentation/pages/print_settings_new.dart';
import 'package:muhasib/features/setting/presentation/pages/security_settings_page.dart';
import 'package:muhasib/features/setting/presentation/pages/voucher_settings_page.dart';
import 'package:muhasib/features/setting/presentation/pages/stock_settings_page.dart';
import 'package:muhasib/features/setting/presentation/pages/other_settings_page.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart'
    as new_settings_cubit;
import 'package:muhasib/features/initial/presentation/cubit/initial_cubit.dart';
import 'package:muhasib/features/initial/presentation/pages/initial_gate_page.dart';
import 'package:muhasib/features/initial/presentation/pages/initial_setup_page.dart';
import 'package:muhasib/features/currencies/presentation/cubit/currencies_cubit.dart';
import 'package:muhasib/features/currencies/presentation/pages/currency_exchange_page.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:muhasib/features/accounts/presentation/pages/annual_close_page.dart';
import 'package:muhasib/features/settings_entities/settings_entities.dart'
    as settings_entities;

final router = GoRouter(
  debugLogDiagnostics: true,
  initialLocation: AppRoutes.home,
  redirect: (context, state) {
    // final authService = locator<AuthService>();
    // final isLoggedIn = authService.isLoggedIn;
    // final loggingIn = state.matchedLocation == AppRoutes.login;

    // if (!isLoggedIn && !loggingIn) {
    //   return AppRoutes.login;
    // } else if (isLoggedIn && loggingIn) {
    //   return AppRoutes.dashboard;
    // }
    return null;
  },
  routes: [
    // ======= Core Screens =======
    GoRoute(
      path: AppRoutes.splash,
      name: AppRoutes.splash,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<InitialCubit>(),
        child: const InitialGatePage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.initialSetup,
      name: AppRoutes.initialSetup,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => getIt<SettingCubit>()),
          BlocProvider(create: (context) => getIt<CurrenciesCubit>()),
          BlocProvider(create: (context) => getIt<WarehousesCubit>()),
          BlocProvider(create: (context) => getIt<InitialCubit>()),
        ],
        child: const InitialSetupPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: AppRoutes.home,
      builder: (context, state) => const HomePageView(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: AppRoutes.login,
      builder: (context, state) => const PlaceholderWidget('Login'),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      name: AppRoutes.dashboard,
      builder: (context, state) => const PlaceholderWidget('Dashboard'),
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: AppRoutes.settings,
      builder: (context, state) => BlocProvider(
        create: (context) => getIt<new_settings_cubit.SettingsCubit>(),
        child: const new_settings.SettingsPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.profile,
      name: AppRoutes.profile,
      builder: (context, state) => const PlaceholderWidget('Profile'),
    ),

    // ======= Header =======
    GoRoute(
      path: AppRoutes.usersSync,
      name: AppRoutes.usersSync,
      builder: (context, state) => const PlaceholderWidget('Users & Sync'),
    ),

    // ======= الحسابات =======
    GoRoute(
      path: AppRoutes.accountsGuide,
      name: AppRoutes.accountsGuide,
      builder: (context, state) => const AccountsTreeScreen(),
    ),
    GoRoute(
      path: AppRoutes.accountsLink,
      name: AppRoutes.accountsLink,
      builder: (context, state) => BlocProvider(
        create: (context) =>
            getIt<AccountConnectCubit>()..loadAllAccountConnects(),
        child: AccountLinkingScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.accountsJournal,
      name: AppRoutes.accountsJournal,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<JournalEntryCubit>(),
        child: const JournalEntryScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.accountsVouchers,
      name: AppRoutes.accountsVouchers,
      builder: (context, state) => const VoucherFormScreen(),
    ),
    GoRoute(
      path: AppRoutes.accountsOpeningBalance,
      name: AppRoutes.accountsOpeningBalance,
      builder: (context, state) => const OpeningBalanceApp(),
    ),
    GoRoute(
      path: AppRoutes.accountsLimits,
      name: AppRoutes.accountsLimits,
      builder: (context, state) => AccountLimitsScreen(),
    ),
    GoRoute(
      path: AppRoutes.accountsAnnualClose,
      name: AppRoutes.accountsAnnualClose,
      builder: (context, state) => const AnnualClosePage(),
    ),

    // ======= العملات =======
    GoRoute(
      path: AppRoutes.currenciesManage,
      name: AppRoutes.currenciesManage,
      builder: (context, state) => const CurrenciesPage(),
    ),
    GoRoute(
      path: AppRoutes.currenciesExchange,
      name: AppRoutes.currenciesExchange,
      builder: (context, state) => const CurrencyExchangePage(),
    ),

    // ======= المبيعات =======
    GoRoute(
      path: AppRoutes.sales,
      name: AppRoutes.sales,
      builder: (context, state) => const PlaceholderWidget(""),
    ),
    GoRoute(
      path: AppRoutes.salesAddInvoice,
      name: AppRoutes.salesAddInvoice,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => getIt<SalesCubit>()),
          BlocProvider(create: (context) => getIt<AccountsCubit>()),
          BlocProvider(create: (context) => getIt<CustomersCubit>()),
        ],
        child: const SalesInvoiceScreen(),
      ),
    ),
    GoRoute(
      path: '/sales/improved-invoice',
      name: 'improved-sales-invoice',
      builder: (context, state) => const ImprovedSalesInvoiceScreen(),
    ),
    GoRoute(
      path: AppRoutes.salesList,
      name: AppRoutes.salesList,
      builder: (context, state) => BlocProvider(
        create: (context) => getIt<SalesCubit>(),
        child: const SalePageBody(),
      ),
    ),
    GoRoute(
      path: AppRoutes.salesQuotes,
      name: AppRoutes.salesQuotes,
      builder: (context, state) => BlocProvider(
        create: (context) => getIt<SalesCubit>(),
        child: const QuotationsPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.salesReturns,
      name: AppRoutes.salesReturns,
      builder: (context, state) => BlocProvider(
        create: (context) => getIt<SalesCubit>(),
        child: const ReturnsPage(),
      ),
    ),
    GoRoute(
      path: '/select-invoice-for-return',
      name: 'select-invoice-for-return',
      builder: (context, state) => BlocProvider(
        create: (context) => getIt<SalesCubit>(),
        child: const SelectInvoiceForReturnPage(),
      ),
    ),
    GoRoute(
      path: '/sales-returns-form',
      name: 'sales-returns-form',
      builder: (context, state) {
        final invoiceId = state.uri.queryParameters['invoiceId'];
        return BlocProvider(
          create: (context) => getIt<SalesCubit>(),
          child: ReturnInvoiceFormPage(
            originalInvoiceId: invoiceId != null
                ? int.tryParse(invoiceId)
                : null,
          ),
        );
      },
    ),

    // ======= المشتريات =======
    GoRoute(
      path: AppRoutes.purchases,
      name: AppRoutes.purchases,
      builder: (context, state) => const PurchasesListPage(),
    ),
    GoRoute(
      path: AppRoutes.purchasesAddInvoice,
      name: AppRoutes.purchasesAddInvoice,
      builder: (context, state) {
        final invoice = state.extra as InvoiceEntity?;
        return PurchaseFormPage(invoice: invoice);
      },
    ),
    GoRoute(
      path: AppRoutes.purchasesList,
      name: AppRoutes.purchasesList,
      builder: (context, state) => const PurchasesListPage(),
    ),
    GoRoute(
      path: AppRoutes.purchasesOrders,
      name: AppRoutes.purchasesOrders,
      builder: (context, state) => const PurchaseOrdersPage(),
    ),
    GoRoute(
      path: AppRoutes.purchasesReturns,
      name: AppRoutes.purchasesReturns,
      builder: (context, state) => const PurchaseReturnsPage(),
    ),

    // ======= الأصناف =======
    GoRoute(
      path: AppRoutes.items,
      name: AppRoutes.items,
      builder: (context, state) => const PlaceholderWidget('Items'),
    ),
    GoRoute(
      path: AppRoutes.itemsGroups,
      name: AppRoutes.itemsGroups,
      builder: (context, state) => const ProductGroupsPage(),
    ),
    GoRoute(
      path: AppRoutes.itemsUnits,
      name: AppRoutes.itemsUnits,
      builder: (context, state) => const ProductUnitsPage(),
    ),
    GoRoute(
      path: AppRoutes.itemsManage,
      name: AppRoutes.itemsManage,
      builder: (context, state) => const ProductsPage(),
    ),
    GoRoute(
      path: AppRoutes.itemsSubUnits,
      name: AppRoutes.itemsSubUnits,
      builder: (context, state) => const ProductSubUnitsPage(),
    ),
    GoRoute(
      path: AppRoutes.itemsPricing,
      name: AppRoutes.itemsPricing,
      builder: (context, state) => const ProductPricingPage(),
    ),
    GoRoute(
      path: AppRoutes.itemsMovements,
      name: AppRoutes.itemsMovements,
      builder: (context, state) => const ItemMovementsPage(),
    ),

    // ======= المخازن =======
    GoRoute(
      path: AppRoutes.warehouses,
      name: AppRoutes.warehouses,
      builder: (context, state) => const WarehousesMainPage(),
    ),

    // ======= الإعدادات =======
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const new_settings.SettingsPage(),
    ),
    GoRoute(
      path: AppRoutes.warehousesList,
      name: AppRoutes.warehousesList,
      builder: (context, state) => const WarehousesListPage(),
    ),
    GoRoute(
      path: AppRoutes.warehouseForm,
      name: AppRoutes.warehouseForm,
      builder: (context, state) {
        final warehouse = state.extra as WarehouseEntity?;
        return WarehouseFormPage(warehouse: warehouse);
      },
    ),
    GoRoute(
      path: AppRoutes.warehousesInventory,
      name: AppRoutes.warehousesInventory,
      builder: (context, state) => const WarehousesInventoryPage(),
    ),
    GoRoute(
      path: AppRoutes.warehousesAdjustment,
      name: AppRoutes.warehousesAdjustment,
      builder: (context, state) => const StockAdjustmentPage(),
    ),
    GoRoute(
      path: AppRoutes.warehousesTransfer,
      name: AppRoutes.warehousesTransfer,
      builder: (context, state) => const StockTransferPage(),
    ),

    // ======= التهيئات =======
    GoRoute(
      path: AppRoutes.settingsCategories,
      name: AppRoutes.settingsCategories,
      builder: (context, state) => const ProductGroupsPage(),
    ),
    GoRoute(
      path: AppRoutes.settingsBanks,
      name: AppRoutes.settingsBanks,
      builder: (context, state) => const settings_entities.BanksPage(),
    ),
    GoRoute(
      path: AppRoutes.settingsCashboxes,
      name: AppRoutes.settingsCashboxes,
      builder: (context, state) => const settings_entities.CashboxesPage(),
    ),
    GoRoute(
      path: AppRoutes.settingsOtherFees,
      name: AppRoutes.settingsOtherFees,
      builder: (context, state) => const settings_entities.OtherFeesPage(),
    ),
    GoRoute(
      path: AppRoutes.settingsRegions,
      name: AppRoutes.settingsRegions,
      builder: (context, state) => const settings_entities.RegionsPage(),
    ),

    // ======= إعدادات النظام الجديدة =======
    GoRoute(
      path: AppRoutes.settingsPersonal,
      name: AppRoutes.settingsPersonal,
      builder: (context, state) => BlocProvider(
        create: (context) => getIt<new_settings_cubit.SettingsCubit>(),
        child: const PersonalInfoPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.settingsPrint,
      name: AppRoutes.settingsPrint,
      builder: (context, state) => BlocProvider(
        create: (context) => getIt<new_settings_cubit.SettingsCubit>(),
        child: const PrintSettingsPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.settingsSecurity,
      name: AppRoutes.settingsSecurity,
      builder: (context, state) => BlocProvider(
        create: (context) => getIt<new_settings_cubit.SettingsCubit>(),
        child: const SecuritySettingsPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.settingsVoucher,
      name: AppRoutes.settingsVoucher,
      builder: (context, state) => BlocProvider(
        create: (context) => getIt<new_settings_cubit.SettingsCubit>(),
        child: const VoucherSettingsPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.settingsStock,
      name: AppRoutes.settingsStock,
      builder: (context, state) => BlocProvider(
        create: (context) => getIt<new_settings_cubit.SettingsCubit>(),
        child: const StockSettingsPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.settingsOther,
      name: AppRoutes.settingsOther,
      builder: (context, state) => BlocProvider(
        create: (context) => getIt<new_settings_cubit.SettingsCubit>(),
        child: const OtherSettingsPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.settingsMaintenance,
      name: AppRoutes.settingsMaintenance,
      builder: (context, state) => const PlaceholderWidget('Maintenance'),
    ),
    GoRoute(
      path: AppRoutes.settingsActivation,
      name: AppRoutes.settingsActivation,
      builder: (context, state) => const PlaceholderWidget('Activation'),
    ),

    // ======= التقارير =======
    GoRoute(
      path: AppRoutes.reports,
      name: AppRoutes.reports,
      builder: (context, state) => const ReportsHubPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsTransactions,
      name: AppRoutes.reportsTransactions,
      builder: (context, state) => const TransactionsReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsAccountStatement,
      name: AppRoutes.reportsAccountStatement,
      builder: (context, state) => const AccountStatementReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsMore,
      name: AppRoutes.reportsMore,
      builder: (context, state) => const PlaceholderWidget('More Reports'),
    ),

    // تقارير المحاسبة
    GoRoute(
      path: AppRoutes.reportsTrialBalance,
      name: AppRoutes.reportsTrialBalance,
      builder: (context, state) => const TrialBalanceReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsIncomeStatement,
      name: AppRoutes.reportsIncomeStatement,
      builder: (context, state) => const IncomeStatementReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsBalanceSheet,
      name: AppRoutes.reportsBalanceSheet,
      builder: (context, state) {
        const report = ReportItem(
          id: 'balance_sheet',
          titleAr: 'الميزانية العمومية',
          titleEn: 'Balance Sheet',
          descriptionAr: 'الأصول والخصوم وحقوق الملكية',
          icon: Icons.account_balance,
          color: Color(0xFF7B1FA2),
          route: AppRoutes.reportsBalanceSheet,
          category: ReportCategory.accounting,
        );
        return const GenericReportPage(report: report);
      },
    ),
    GoRoute(
      path: AppRoutes.reportsCashFlow,
      name: AppRoutes.reportsCashFlow,
      builder: (context, state) {
        const report = ReportItem(
          id: 'cash_flow',
          titleAr: 'التدفقات النقدية',
          titleEn: 'Cash Flow',
          descriptionAr: 'حركة النقد الداخل والخارج',
          icon: Icons.water_drop,
          color: Color(0xFF00ACC1),
          route: AppRoutes.reportsCashFlow,
          category: ReportCategory.accounting,
        );
        return const GenericReportPage(report: report);
      },
    ),
    GoRoute(
      path: AppRoutes.reportsGeneralLedger,
      name: AppRoutes.reportsGeneralLedger,
      builder: (context, state) {
        const report = ReportItem(
          id: 'general_ledger',
          titleAr: 'دفتر الأستاذ العام',
          titleEn: 'General Ledger',
          descriptionAr: 'جميع القيود والحركات المحاسبية',
          icon: Icons.menu_book,
          color: Color(0xFF5D4037),
          route: AppRoutes.reportsGeneralLedger,
          category: ReportCategory.accounting,
        );
        return const GenericReportPage(report: report);
      },
    ),
    GoRoute(
      path: AppRoutes.reportsJournal,
      name: AppRoutes.reportsJournal,
      builder: (context, state) {
        const report = ReportItem(
          id: 'journal',
          titleAr: 'تقرير اليومية',
          titleEn: 'Journal Report',
          descriptionAr: 'قيود اليومية والحركات اليومية',
          icon: Icons.event_note,
          color: Color(0xFF607D8B),
          route: AppRoutes.reportsJournal,
          category: ReportCategory.accounting,
        );
        return const GenericReportPage(report: report);
      },
    ),

    // تقارير المبيعات
    GoRoute(
      path: AppRoutes.reportsSalesSummary,
      name: AppRoutes.reportsSalesSummary,
      builder: (context, state) => const SalesSummaryReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsSalesByCustomer,
      name: AppRoutes.reportsSalesByCustomer,
      builder: (context, state) {
        const report = ReportItem(
          id: 'sales_by_customer',
          titleAr: 'مبيعات حسب العميل',
          titleEn: 'Sales by Customer',
          descriptionAr: 'تحليل المبيعات لكل عميل',
          icon: Icons.people,
          color: Color(0xFF388E3C),
          route: AppRoutes.reportsSalesByCustomer,
          category: ReportCategory.sales,
        );
        return const GenericReportPage(report: report);
      },
    ),
    GoRoute(
      path: AppRoutes.reportsSalesByProduct,
      name: AppRoutes.reportsSalesByProduct,
      builder: (context, state) {
        const report = ReportItem(
          id: 'sales_by_product',
          titleAr: 'مبيعات حسب المنتج',
          titleEn: 'Sales by Product',
          descriptionAr: 'تحليل المبيعات لكل منتج',
          icon: Icons.inventory_2,
          color: Color(0xFF7B1FA2),
          route: AppRoutes.reportsSalesByProduct,
          category: ReportCategory.sales,
        );
        return const GenericReportPage(report: report);
      },
    ),
    GoRoute(
      path: AppRoutes.reportsDailySales,
      name: AppRoutes.reportsDailySales,
      builder: (context, state) {
        const report = ReportItem(
          id: 'daily_sales',
          titleAr: 'المبيعات اليومية',
          titleEn: 'Daily Sales',
          descriptionAr: 'تقرير المبيعات اليومي',
          icon: Icons.today,
          color: Color(0xFF00ACC1),
          route: AppRoutes.reportsDailySales,
          category: ReportCategory.sales,
        );
        return const GenericReportPage(report: report);
      },
    ),
    GoRoute(
      path: AppRoutes.reportsInvoices,
      name: AppRoutes.reportsInvoices,
      builder: (context, state) {
        const report = ReportItem(
          id: 'invoices',
          titleAr: 'تقرير الفواتير',
          titleEn: 'Invoices Report',
          descriptionAr: 'قائمة جميع فواتير المبيعات',
          icon: Icons.receipt,
          color: Color(0xFFFF5722),
          route: AppRoutes.reportsInvoices,
          category: ReportCategory.sales,
        );
        return const GenericReportPage(report: report);
      },
    ),
    GoRoute(
      path: AppRoutes.reportsQuotations,
      name: AppRoutes.reportsQuotations,
      builder: (context, state) {
        const report = ReportItem(
          id: 'quotations',
          titleAr: 'تقرير العروض',
          titleEn: 'Quotations Report',
          descriptionAr: 'عروض الأسعار وحالتها',
          icon: Icons.request_quote,
          color: Color(0xFF795548),
          route: AppRoutes.reportsQuotations,
          category: ReportCategory.sales,
        );
        return const GenericReportPage(report: report);
      },
    ),
    GoRoute(
      path: AppRoutes.reportsSalesReturns,
      name: AppRoutes.reportsSalesReturns,
      builder: (context, state) {
        const report = ReportItem(
          id: 'sales_returns',
          titleAr: 'مرتجعات المبيعات',
          titleEn: 'Sales Returns',
          descriptionAr: 'تقرير مرتجعات المبيعات',
          icon: Icons.assignment_return,
          color: Color(0xFFF44336),
          route: AppRoutes.reportsSalesReturns,
          category: ReportCategory.sales,
        );
        return const GenericReportPage(report: report);
      },
    ),

    // تقارير المشتريات
    GoRoute(
      path: AppRoutes.reportsPurchaseSummary,
      name: AppRoutes.reportsPurchaseSummary,
      builder: (context, state) {
        const report = ReportItem(
          id: 'purchase_summary',
          titleAr: 'ملخص المشتريات',
          titleEn: 'Purchase Summary',
          descriptionAr: 'إجمالي المشتريات والتكاليف',
          icon: Icons.shopping_cart,
          color: Color(0xFF1976D2),
          route: AppRoutes.reportsPurchaseSummary,
          category: ReportCategory.purchases,
        );
        return const GenericReportPage(report: report);
      },
    ),
    GoRoute(
      path: AppRoutes.reportsPurchaseBySupplier,
      name: AppRoutes.reportsPurchaseBySupplier,
      builder: (context, state) {
        const report = ReportItem(
          id: 'purchase_by_supplier',
          titleAr: 'مشتريات حسب المورد',
          titleEn: 'Purchase by Supplier',
          descriptionAr: 'تحليل المشتريات لكل مورد',
          icon: Icons.local_shipping,
          color: Color(0xFF388E3C),
          route: AppRoutes.reportsPurchaseBySupplier,
          category: ReportCategory.purchases,
        );
        return const GenericReportPage(report: report);
      },
    ),
    GoRoute(
      path: AppRoutes.reportsPurchaseByProduct,
      name: AppRoutes.reportsPurchaseByProduct,
      builder: (context, state) {
        const report = ReportItem(
          id: 'purchase_by_product',
          titleAr: 'مشتريات حسب المنتج',
          titleEn: 'Purchase by Product',
          descriptionAr: 'تحليل المشتريات لكل منتج',
          icon: Icons.category,
          color: Color(0xFF7B1FA2),
          route: AppRoutes.reportsPurchaseByProduct,
          category: ReportCategory.purchases,
        );
        return const GenericReportPage(report: report);
      },
    ),
    GoRoute(
      path: AppRoutes.reportsPurchaseReturns,
      name: AppRoutes.reportsPurchaseReturns,
      builder: (context, state) {
        const report = ReportItem(
          id: 'purchase_returns',
          titleAr: 'مرتجعات المشتريات',
          titleEn: 'Purchase Returns',
          descriptionAr: 'تقرير مرتجعات المشتريات',
          icon: Icons.assignment_return,
          color: Color(0xFFF44336),
          route: AppRoutes.reportsPurchaseReturns,
          category: ReportCategory.purchases,
        );
        return const GenericReportPage(report: report);
      },
    ),

    // تقارير المخزون
    GoRoute(
      path: AppRoutes.reportsStock,
      name: AppRoutes.reportsStock,
      builder: (context, state) => const StockReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsStockMovement,
      name: AppRoutes.reportsStockMovement,
      builder: (context, state) {
        const report = ReportItem(
          id: 'stock_movement',
          titleAr: 'حركة المخزون',
          titleEn: 'Stock Movement',
          descriptionAr: 'تتبع حركة الأصناف',
          icon: Icons.swap_horiz,
          color: Color(0xFF388E3C),
          route: AppRoutes.reportsStockMovement,
          category: ReportCategory.inventory,
        );
        return const GenericReportPage(report: report);
      },
    ),
    GoRoute(
      path: AppRoutes.reportsLowStock,
      name: AppRoutes.reportsLowStock,
      builder: (context, state) {
        const report = ReportItem(
          id: 'low_stock',
          titleAr: 'تنبيه نقص المخزون',
          titleEn: 'Low Stock Alert',
          descriptionAr: 'الأصناف التي وصلت للحد الأدنى',
          icon: Icons.warning,
          color: Color(0xFFFF9800),
          route: AppRoutes.reportsLowStock,
          category: ReportCategory.inventory,
        );
        return const GenericReportPage(report: report);
      },
    ),
    GoRoute(
      path: AppRoutes.reportsStockValuation,
      name: AppRoutes.reportsStockValuation,
      builder: (context, state) {
        const report = ReportItem(
          id: 'stock_valuation',
          titleAr: 'تقييم المخزون',
          titleEn: 'Stock Valuation',
          descriptionAr: 'قيمة المخزون بالتكلفة وسعر البيع',
          icon: Icons.monetization_on,
          color: Color(0xFF7B1FA2),
          route: AppRoutes.reportsStockValuation,
          category: ReportCategory.inventory,
        );
        return const GenericReportPage(report: report);
      },
    ),

    // تقارير العملاء والموردين
    GoRoute(
      path: AppRoutes.reportsCustomerStatement,
      name: AppRoutes.reportsCustomerStatement,
      builder: (context, state) {
        const report = ReportItem(
          id: 'customer_statement',
          titleAr: 'كشف حساب عميل',
          titleEn: 'Customer Statement',
          descriptionAr: 'تفاصيل حركة حساب العميل',
          icon: Icons.person,
          color: Color(0xFF1976D2),
          route: AppRoutes.reportsCustomerStatement,
          category: ReportCategory.customers,
        );
        return const GenericReportPage(report: report);
      },
    ),
    GoRoute(
      path: AppRoutes.reportsCustomerBalances,
      name: AppRoutes.reportsCustomerBalances,
      builder: (context, state) {
        const report = ReportItem(
          id: 'customer_balances',
          titleAr: 'أرصدة العملاء',
          titleEn: 'Customer Balances',
          descriptionAr: 'أرصدة جميع العملاء',
          icon: Icons.account_balance_wallet,
          color: Color(0xFF388E3C),
          route: AppRoutes.reportsCustomerBalances,
          category: ReportCategory.customers,
        );
        return const GenericReportPage(report: report);
      },
    ),
    GoRoute(
      path: AppRoutes.reportsAgedReceivables,
      name: AppRoutes.reportsAgedReceivables,
      builder: (context, state) {
        const report = ReportItem(
          id: 'aged_receivables',
          titleAr: 'أعمار الديون',
          titleEn: 'Aged Receivables',
          descriptionAr: 'تحليل عمر ديون العملاء',
          icon: Icons.schedule,
          color: Color(0xFFFF5722),
          route: AppRoutes.reportsAgedReceivables,
          category: ReportCategory.customers,
        );
        return const GenericReportPage(report: report);
      },
    ),
    GoRoute(
      path: AppRoutes.reportsSupplierStatement,
      name: AppRoutes.reportsSupplierStatement,
      builder: (context, state) {
        const report = ReportItem(
          id: 'supplier_statement',
          titleAr: 'كشف حساب مورد',
          titleEn: 'Supplier Statement',
          descriptionAr: 'تفاصيل حركة حساب المورد',
          icon: Icons.local_shipping,
          color: Color(0xFF7B1FA2),
          route: AppRoutes.reportsSupplierStatement,
          category: ReportCategory.customers,
        );
        return const GenericReportPage(report: report);
      },
    ),
    GoRoute(
      path: AppRoutes.reportsSupplierBalances,
      name: AppRoutes.reportsSupplierBalances,
      builder: (context, state) {
        const report = ReportItem(
          id: 'supplier_balances',
          titleAr: 'أرصدة الموردين',
          titleEn: 'Supplier Balances',
          descriptionAr: 'أرصدة جميع الموردين',
          icon: Icons.account_balance,
          color: Color(0xFF00ACC1),
          route: AppRoutes.reportsSupplierBalances,
          category: ReportCategory.customers,
        );
        return const GenericReportPage(report: report);
      },
    ),
    GoRoute(
      path: AppRoutes.reportsAgedPayables,
      name: AppRoutes.reportsAgedPayables,
      builder: (context, state) {
        const report = ReportItem(
          id: 'aged_payables',
          titleAr: 'أعمار المستحقات',
          titleEn: 'Aged Payables',
          descriptionAr: 'تحليل عمر المستحقات للموردين',
          icon: Icons.history,
          color: Color(0xFFF44336),
          route: AppRoutes.reportsAgedPayables,
          category: ReportCategory.customers,
        );
        return const GenericReportPage(report: report);
      },
    ),

    // ======= عن التطبيق =======
    GoRoute(
      path: AppRoutes.about,
      name: AppRoutes.about,
      builder: (context, state) => const PlaceholderWidget('About App'),
    ),
    GoRoute(
      path: AppRoutes.aboutYoutube,
      name: AppRoutes.aboutYoutube,
      builder: (context, state) => const PlaceholderWidget('About Youtube'),
    ),
    GoRoute(
      path: AppRoutes.aboutShare,
      name: AppRoutes.aboutShare,
      builder: (context, state) => const PlaceholderWidget('Share App'),
    ),
    GoRoute(
      path: AppRoutes.aboutRate,
      name: AppRoutes.aboutRate,
      builder: (context, state) => const PlaceholderWidget('Rate App'),
    ),
    GoRoute(
      path: AppRoutes.aboutHelp,
      name: AppRoutes.aboutHelp,
      builder: (context, state) => const PlaceholderWidget('Help'),
    ),
    GoRoute(
      path: AppRoutes.aboutPrivacy,
      name: AppRoutes.aboutPrivacy,
      builder: (context, state) => const PlaceholderWidget('Privacy Policy'),
    ),
    GoRoute(
      path: AppRoutes.aboutTerms,
      name: AppRoutes.aboutTerms,
      builder: (context, state) => const PlaceholderWidget('Terms of Service'),
    ),
  ],
);

class PlaceholderWidget extends StatelessWidget {
  final String title;
  const PlaceholderWidget(this.title, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}

class _MainBottomBar extends StatefulWidget {
  const _MainBottomBar({super.key});

  @override
  State<_MainBottomBar> createState() => _MainBottomBarState();
}

class _MainBottomBarState extends State<_MainBottomBar> {
  int _index = 0;
  final List<String> _tabs = [
    AppRoutes.dashboard,
    AppRoutes.settings,
    AppRoutes.profile,
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _index,
      onTap: (i) {
        setState(() => _index = i);
        context.go(_tabs[i]);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
