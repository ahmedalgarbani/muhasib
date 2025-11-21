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
import 'package:muhasib/features/sales/presentation/widgets/components/sales_invoice_screen.dart';
import 'package:muhasib/features/sales/presentation/widgets/sale_page_body.dart';
import 'package:muhasib/features/sales/presentation/pages/quotations_page.dart';
import 'package:muhasib/features/sales/presentation/pages/returns_page.dart';
import 'package:muhasib/features/sales/presentation/pages/return_invoice_form_page.dart';
import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:muhasib/features/purchases/presentation/pages/purchases_list_page.dart';
import 'package:muhasib/features/products/presentation/pages/product_groups_page.dart';
import 'package:muhasib/features/products/presentation/pages/product_units_page.dart';
import 'package:muhasib/features/products/presentation/pages/products_page.dart';
import 'package:muhasib/features/products/presentation/pages/product_sub_units_page.dart';
import 'package:muhasib/features/products/presentation/pages/product_pricing_page.dart';
import 'package:muhasib/features/products/presentation/pages/item_movements_page.dart';
import 'package:muhasib/features/stores/domain/entities/warehouse_entity.dart';
import 'package:muhasib/features/stores/presentation/pages/warehouses_main_page.dart';
import 'package:muhasib/features/stores/presentation/pages/warehouses_list_page.dart';
import 'package:muhasib/features/stores/presentation/pages/warehouse_form_page.dart';
import 'package:muhasib/features/stores/presentation/pages/warehouses_inventory_page.dart';
import 'package:muhasib/features/stores/presentation/pages/stock_adjustment_page.dart';
import 'package:muhasib/features/stores/presentation/pages/stock_transfer_page.dart';

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
      builder: (context, state) => const PlaceholderWidget('Splash Screen'),
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
      builder: (context, state) => const PlaceholderWidget('Settings'),
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
      builder: (context, state) => const PlaceholderWidget('Annual Close'),
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
      builder: (context, state) => const Placeholder(),
      // builder: (context, state) => const TransactionApp(),
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
        ],
        child: const SalesInvoiceScreen(),
      ),
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
      path: '/sales-returns-form',
      name: 'sales-returns-form',
      builder: (context, state) => BlocProvider(
        create: (context) => getIt<SalesCubit>(),
        child: const ReturnInvoiceFormPage(),
      ),
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
      builder: (context, state) => const PlaceholderWidget('Add Purchase Invoice'),
    ),
    GoRoute(
      path: AppRoutes.purchasesList,
      name: AppRoutes.purchasesList,
      builder: (context, state) => const PurchasesListPage(),
    ),
    GoRoute(
      path: AppRoutes.purchasesOrders,
      name: AppRoutes.purchasesOrders,
      builder: (context, state) => const PlaceholderWidget('Purchase Orders'),
    ),
    GoRoute(
      path: AppRoutes.purchasesReturns,
      name: AppRoutes.purchasesReturns,
      builder: (context, state) => const PlaceholderWidget('Purchase Returns'),
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
      builder: (context, state) => const PlaceholderWidget('Categories'),
    ),
    GoRoute(
      path: AppRoutes.settingsBanks,
      name: AppRoutes.settingsBanks,
      builder: (context, state) => const PlaceholderWidget('Banks'),
    ),
    GoRoute(
      path: AppRoutes.settingsCashboxes,
      name: AppRoutes.settingsCashboxes,
      builder: (context, state) => const PlaceholderWidget('Cashboxes'),
    ),
    GoRoute(
      path: AppRoutes.settingsOtherFees,
      name: AppRoutes.settingsOtherFees,
      builder: (context, state) => const PlaceholderWidget('Other Fees'),
    ),
    GoRoute(
      path: AppRoutes.settingsRegions,
      name: AppRoutes.settingsRegions,
      builder: (context, state) => const PlaceholderWidget('Regions'),
    ),

    // ======= التقارير =======
    GoRoute(
      path: AppRoutes.reports,
      name: AppRoutes.reports,
      builder: (context, state) => const PlaceholderWidget('Reports'),
    ),
    GoRoute(
      path: AppRoutes.reportsTransactions,
      name: AppRoutes.reportsTransactions,
      builder: (context, state) =>
          const PlaceholderWidget('Transactions Report'),
    ),
    GoRoute(
      path: AppRoutes.reportsAccountStatement,
      name: AppRoutes.reportsAccountStatement,
      builder: (context, state) => const PlaceholderWidget('Account Statement'),
    ),
    GoRoute(
      path: AppRoutes.reportsMore,
      name: AppRoutes.reportsMore,
      builder: (context, state) => const PlaceholderWidget('More Reports'),
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
