import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/accounts/presentation/cubit/account_connect_cubit.dart';
import 'package:muhasib/features/accounts/presentation/cubit/account_limits_cubit.dart';
import 'package:muhasib/features/accounts/presentation/pages/account_link_page.dart';
import 'package:muhasib/features/currencies/presentation/pages/currencies_page.dart';
import 'package:muhasib/features/accounts/presentation/pages/open_balance_page.dart';
import 'package:muhasib/features/accounts/presentation/pages/vouchers_page.dart';
import 'package:muhasib/features/accounts/presentation/pages/journal_entry_page.dart';
import 'package:muhasib/features/accounts/presentation/pages/journal_entries_list_page.dart';
import 'package:muhasib/features/accounts/presentation/cubit/journal_entry_cubit.dart';
import 'package:muhasib/features/accounts/presentation/cubit/vouchers_cubit.dart';
import 'package:muhasib/features/main/presentation/pages/home_page_view.dart';
import 'package:muhasib/features/main/presentation/widgets/main_scaffold_shell.dart';
import 'package:muhasib/features/accounts/presentation/pages/accounts_tree_view.dart';
import 'package:muhasib/features/reports/presentation/pages/account_statement_report_page.dart';
import 'package:muhasib/features/reports/presentation/pages/reports_hub_page.dart';
import 'package:muhasib/features/reports/presentation/pages/trial_balance_report_page.dart';
import 'package:muhasib/features/reports/presentation/pages/income_statement_report_page.dart';
import 'package:muhasib/features/reports/presentation/pages/sales_summary_report_page.dart';
import 'package:muhasib/features/reports/presentation/pages/stock_report_page.dart';
import 'package:muhasib/features/reports/presentation/pages/transactions_report_page.dart';
import 'package:muhasib/features/reports/presentation/pages/generic_report_page.dart';
import 'package:muhasib/features/reports/presentation/pages/balance_sheet_report_page.dart';
import 'package:muhasib/features/reports/presentation/pages/journal_report_page.dart';
import 'package:muhasib/features/reports/presentation/pages/general_ledger_report_page.dart';
import 'package:muhasib/features/reports/presentation/pages/invoices_list_report_page.dart';
import 'package:muhasib/features/reports/presentation/pages/sales_aggregates_report_pages.dart';
import 'package:muhasib/features/reports/presentation/pages/inventory_extra_report_pages.dart';
import 'package:muhasib/features/reports/presentation/pages/party_balances_report_pages.dart';
import 'package:muhasib/features/reports/presentation/pages/aged_reports_pages.dart';
import 'package:muhasib/features/reports/presentation/pages/cash_flow_report_page.dart';
import 'package:muhasib/features/reports/presentation/pages/purchase_summary_report_page.dart';
import 'package:muhasib/features/reports/domain/entities/report_item.dart';
import 'package:muhasib/features/sales/presentation/widgets/components/sales_invoice_screen.dart';
import 'package:muhasib/features/sales/presentation/widgets/sale_page_body.dart';
import 'package:muhasib/features/sales/presentation/pages/quotations_page.dart';
import 'package:muhasib/features/sales/presentation/pages/returns_page.dart';
import 'package:muhasib/features/sales/presentation/pages/return_invoice_form_page.dart';
import 'package:muhasib/features/sales/presentation/pages/select_invoice_for_return_page.dart';
import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:muhasib/features/sales/domain/enums/invoice_enums.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/customers/presentation/pages/customers_profile_page.dart';
import 'package:muhasib/features/customers/presentation/pages/suppliers_profile_page.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
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
import 'package:muhasib/features/currencies/presentation/pages/currency_exchange_page_v2.dart';
import 'package:muhasib/features/currencies/presentation/pages/currency_revaluation_page.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:muhasib/features/accounts/presentation/pages/annual_close_page.dart';
import 'package:muhasib/features/accounts/presentation/pages/accounts_limit_page_clean.dart';
import 'package:muhasib/features/settings_entities/settings_entities.dart'
    as settings_entities;

final router = GoRouter(
  debugLogDiagnostics: true,
  initialLocation: AppRoutes.splash,
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
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffoldShell(navigationShell: navigationShell);
      },
      branches: [
        // Index 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              name: AppRoutes.home,
              builder: (context, state) => const HomePageView(),
            ),
          ],
        ),
        // Index 1: Sales
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.salesList,
              name: AppRoutes.salesList,
              builder: (context, state) => BlocProvider(
                create: (context) => getIt<SalesCubit>(),
                child: const SalePageBody(),
              ),
            ),
          ],
        ),
        // Index 2: Reports
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.reports,
              name: AppRoutes.reports,
              builder: (context, state) => const ReportsHubPage(),
            ),
          ],
        ),
        // Index 3: Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              name: AppRoutes.settings,
              builder: (context, state) => BlocProvider(
                create: (context) => getIt<new_settings_cubit.SettingsCubit>(),
                child: const new_settings.SettingsPage(),
              ),
            ),
          ],
        ),
      ],
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
        child: const JournalEntriesListPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.accountsJournalAdd,
      name: AppRoutes.accountsJournalAdd,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<JournalEntryCubit>(),
        child: const JournalEntryScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.accountsVouchers,
      name: AppRoutes.accountsVouchers,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<VouchersCubit>(),
        child: const VouchersPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.accountsOpeningBalance,
      name: AppRoutes.accountsOpeningBalance,
      builder: (context, state) => const OpeningBalanceApp(),
    ),
    GoRoute(
      path: AppRoutes.accountsLimits,
      name: AppRoutes.accountsLimits,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<AccountLimitsCubit>()..loadLimits(),
        child: const AccountLimitsScreen(),
      ),
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
      builder: (context, state) => BlocProvider(
        create: (context) => getIt<CurrenciesCubit>(),
        child: const CurrencyExchangePageV2(),
      ),
    ),
    GoRoute(
      path: '/currencies/revaluation',
      name: 'currencies-revaluation',
      builder: (context, state) => const CurrencyRevaluationPage(),
    ),

    // ======= المبيعات =======
    GoRoute(
      path: AppRoutes.sales,
      name: AppRoutes.sales,
      builder: (context, state) => BlocProvider(create: (context) => getIt<SalesCubit>(), child: const SalePageBody()),
    ),
    GoRoute(
      path: AppRoutes.salesAddInvoice,
      name: AppRoutes.salesAddInvoice,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => getIt<SalesCubit>()),
          BlocProvider(create: (context) => getIt<CustomersCubit>()),
          BlocProvider(create: (context) => getIt<ProductsCubit>()),
        ],
        child: const SalesInvoiceScreen(
          invoiceType: InvoiceType.salesInvoice,
        ),
      ),
    ),
    GoRoute(
      path: '/sales/improved-invoice',
      name: 'improved-sales-invoice',
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => getIt<SalesCubit>()),
          BlocProvider(create: (context) => getIt<CustomersCubit>()),
          BlocProvider(create: (context) => getIt<ProductsCubit>()),
        ],
        child: const SalesInvoiceScreen(),
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
      builder: (context, state) => const ProductsPage(),
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
      builder: (context, state) {
        const report = ReportItem(
          id: 'more_reports',
          titleAr: 'تقارير إضافية',
          titleEn: 'More Reports',
          descriptionAr: 'تقارير إضافية سيتم توفيرها قريباً',
          icon: Icons.more_horiz,
          color: AppColors.blueGrey500,
          route: AppRoutes.reportsMore,
          category: ReportCategory.accounting,
        );
        return const GenericReportPage(report: report);
      },
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
      builder: (context, state) => const BalanceSheetReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsCashFlow,
      name: AppRoutes.reportsCashFlow,
      builder: (context, state) => const CashFlowReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsGeneralLedger,
      name: AppRoutes.reportsGeneralLedger,
      builder: (context, state) => const GeneralLedgerReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsJournal,
      name: AppRoutes.reportsJournal,
      builder: (context, state) => const JournalReportPage(),
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
      builder: (context, state) => const SalesByCustomerReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsSalesByProduct,
      name: AppRoutes.reportsSalesByProduct,
      builder: (context, state) => const SalesByProductReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsDailySales,
      name: AppRoutes.reportsDailySales,
      builder: (context, state) => const DailySalesReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsInvoices,
      name: AppRoutes.reportsInvoices,
      builder: (context, state) => const InvoicesListReportPage(
        title: 'تقرير الفواتير',
        icon: Icons.receipt,
        color: AppColors.materialDeepOrange500,
        invoiceTypes: [1, 2],
      ),
    ),
    GoRoute(
      path: AppRoutes.reportsQuotations,
      name: AppRoutes.reportsQuotations,
      builder: (context, state) => const InvoicesListReportPage(
        title: 'تقرير العروض',
        icon: Icons.request_quote,
        color: AppColors.brown500,
        invoiceTypes: [3],
      ),
    ),
    GoRoute(
      path: AppRoutes.reportsSalesReturns,
      name: AppRoutes.reportsSalesReturns,
      builder: (context, state) => const InvoicesListReportPage(
        title: 'مرتجعات المبيعات',
        icon: Icons.assignment_return,
        color: AppColors.materialRed500,
        invoiceTypes: [4],
      ),
    ),

    // تقارير المشتريات
    GoRoute(
      path: AppRoutes.reportsPurchaseSummary,
      name: AppRoutes.reportsPurchaseSummary,
      builder: (context, state) => const PurchaseSummaryReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsPurchaseBySupplier,
      name: AppRoutes.reportsPurchaseBySupplier,
      builder: (context, state) => const PurchaseBySupplierReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsPurchaseByProduct,
      name: AppRoutes.reportsPurchaseByProduct,
      builder: (context, state) => const PurchaseByProductReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsPurchaseReturns,
      name: AppRoutes.reportsPurchaseReturns,
      builder: (context, state) => const InvoicesListReportPage(
        title: 'مرتجعات المشتريات',
        icon: Icons.assignment_return,
        color: AppColors.materialRed500,
        invoiceTypes: [5],
      ),
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
      builder: (context, state) => const StockMovementReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsLowStock,
      name: AppRoutes.reportsLowStock,
      builder: (context, state) => const LowStockReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsStockValuation,
      name: AppRoutes.reportsStockValuation,
      builder: (context, state) => const StockValuationReportPage(),
    ),

    // تقارير العملاء والموردين
    GoRoute(
      path: AppRoutes.reportsCustomerStatement,
      name: AppRoutes.reportsCustomerStatement,
      builder: (context, state) => const AccountStatementReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsCustomerBalances,
      name: AppRoutes.reportsCustomerBalances,
      builder: (context, state) => const CustomerBalancesReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsAgedReceivables,
      name: AppRoutes.reportsAgedReceivables,
      builder: (context, state) => const AgedReceivablesReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsSupplierStatement,
      name: AppRoutes.reportsSupplierStatement,
      builder: (context, state) => const AccountStatementReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsSupplierBalances,
      name: AppRoutes.reportsSupplierBalances,
      builder: (context, state) => const SupplierBalancesReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportsAgedPayables,
      name: AppRoutes.reportsAgedPayables,
      builder: (context, state) => const AgedPayablesReportPage(),
    ),

    // ======= الملفات الشخصية (العملاء والموردين) =======
    GoRoute(
      path: AppRoutes.profiles,
      name: AppRoutes.profiles,
      builder: (context, state) => const CustomersProfilePage(),
    ),
    GoRoute(
      path: AppRoutes.customersProfile,
      name: AppRoutes.customersProfile,
      builder: (context, state) => const CustomersProfilePage(),
    ),
    GoRoute(
      path: AppRoutes.suppliersProfile,
      name: AppRoutes.suppliersProfile,
      builder: (context, state) => const SuppliersProfilePage(),
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
      appBar: CustomAppBar(title: title),
      body: Center(child: Text(title)),
    );
  }
}

class _MainBottomBar extends StatefulWidget {
  const _MainBottomBar();

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
