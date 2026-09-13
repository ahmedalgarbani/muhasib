import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/cubit/local_cubit.dart';
import 'package:muhasib/core/helpers/cubit/theme_cubit.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/helpers/responsive_text.dart';
import 'package:muhasib/core/route/app_router.dart';
import 'package:muhasib/core/services/app_lookup_service.dart';
import 'package:muhasib/core/services/accounting_setup_validator.dart';
import 'package:muhasib/core/services/backup_service.dart';
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:muhasib/core/widgets/root_shell.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:muhasib/features/accounts/presentation/cubit/account_connect_cubit.dart';
import 'package:muhasib/features/accounts/presentation/cubit/account_limits_cubit.dart';
import 'package:muhasib/features/accounts/presentation/cubit/journal_entry_cubit.dart';
import 'package:muhasib/features/currencies/presentation/cubit/currencies_cubit.dart';
import 'package:muhasib/features/purchases/presentation/cubit/purchases_cubit.dart';
import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/product_groups_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/product_units_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/product_sub_units_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/item_movements_cubit.dart';
import 'package:muhasib/features/initial/presentation/cubit/initial_cubit.dart';
import 'package:muhasib/features/main/presentation/cubit/main_cubit.dart';
import 'package:muhasib/features/plans/presentation/cubit/plans_cubit.dart';
import 'package:muhasib/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/features/stores/presentation/cubit/stores_cubit.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:muhasib/core/theme/theme.dart';
import 'package:muhasib/core/widgets/app_lock_gate.dart';
import 'package:muhasib/core/widgets/backup_exit_guard.dart';
import 'package:muhasib/features/accounts/accounts.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:muhasib/core/database/database_initializer.dart';
import 'generated/l10n.dart';

Future<void> _primeDefaultCurrency() async {
  try {
    final lookup = getIt<AppLookupService>();
    final code = await lookup.getDefaultCurrencyCode();
    final active = await lookup.getActiveCurrencies();
    final match = active.where((c) => c.code == code).toList();
    SettingsCache.setDefaultCurrency(
      code: code,
      symbol: match.isEmpty ? null : match.first.symbol,
    );
  } catch (_) {}
}

Future<void> _autoBackupIfDue() async {
  try {
    final path = await getIt<BackupService>().createBackupIfDue();
    if (path != null) {
      await getIt<SettingsCubit>().updateSetting('backup_settings', {
        'deviceSaveTime': DateTime.now().millisecondsSinceEpoch,
      });
    }
  } catch (_) {}
}

/// Runs the accounting configuration check once at startup. Posting itself is
/// already guarded (account resolution throws when nothing is configured), but
/// this surfaces missing/inactive default accounts early in the logs.
Future<void> _validateAccountingSetup() async {
  try {
    final result = await getIt<AccountingSetupValidator>().validateAll();
    if (!result.isValid || result.hasWarnings) {
      debugPrint('⚠️ Accounting setup validation: $result');
    }
  } catch (e) {
    debugPrint('⚠️ Accounting setup validation failed: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database factory for Web/Desktop FFI support
  await initializeDatabaseFactory();

  // Initialize GetIt dependencies
  await GetItHelper.init();

  // Surface missing/inactive default accounting accounts in the logs
  await _validateAccountingSetup();

  // Load app settings into the shared cubit + SettingsCache so every
  // feature reads live values from the DB (formatting, sales rules, print...).
  await getIt<SettingsCubit>().loadSettings();
  await _primeDefaultCurrency();
  await _autoBackupIfDue();

  // Load the subscription license (starts a 14-day trial on first run) and
  // prime PlanCache so gated features know the active entitlements.
  await getIt<PlansCubit>().load();

  final storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await getApplicationSupportDirectory(),
  );
  HydratedBloc.storage = storage;
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<AccountsCubit>()..loadAllAccounts(),
        ),
        BlocProvider(create: (context) => getIt<AccountConnectCubit>()),
        BlocProvider(create: (context) => getIt<AccountLimitsCubit>()),
        BlocProvider(create: (context) => getIt<JournalEntryCubit>()),
        BlocProvider(create: (context) => getIt<CurrenciesCubit>()),
        BlocProvider(create: (context) => getIt<SalesCubit>()),
        BlocProvider(
          create: (context) => getIt<CustomersCubit>()..loadCustomers(),
        ),
        BlocProvider(
          create: (context) => getIt<ProductsCubit>()..loadProducts(),
        ),
        BlocProvider(create: (context) => getIt<ProductGroupsCubit>()),
        BlocProvider(create: (context) => getIt<ProductUnitsCubit>()),
        BlocProvider(create: (context) => getIt<ProductSubUnitsCubit>()),
        BlocProvider(create: (context) => getIt<ItemMovementsCubit>()),
        // Global simple cubits (no external deps)
        BlocProvider(create: (context) => getIt<InitialCubit>()),
        BlocProvider(
          create: (context) => MainCubit(
            customerRepository: getIt(),
            getInvoices: getIt(),
            purchaseRepository: getIt(),
            voucherRepository: getIt(),
          ),
        ),
        BlocProvider(create: (context) => getIt<ReportsCubit>()),
        BlocProvider(create: (context) => StoresCubit()),
        BlocProvider(create: (context) => ThemeCubit()),
        BlocProvider(create: (context) => LocaleCubit()),
        BlocProvider(create: (context) => getIt<PurchasesCubit>()),
        BlocProvider(create: (context) => getIt<SettingsCubit>()),
        BlocProvider(create: (context) => getIt<PlansCubit>()),
        // WarehousesCubit
        BlocProvider(create: (context) => getIt<WarehousesCubit>()),
      ],
      child: MohasebFinanceApp(),
    ),
  );
}

class MohasebFinanceApp extends StatelessWidget {
  const MohasebFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        return BlocBuilder<LocaleCubit, Locale>(
          builder: (context, local) {
            return MaterialApp.router(
              locale: local,
              localizationsDelegates: [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: S.delegate.supportedLocales,
              debugShowCheckedModeBanner: false,
              title: 'محاسب',
              routerConfig: router,
              themeMode: mode,
              theme: appLightTheme,
              darkTheme: appDarkTheme,
              builder: (context, child) => Directionality(
                textDirection: TextDirection.rtl,
                child: ResponsiveTextScale(
                  child: BackupExitGuard(
                    navigatorKey: rootNavigatorKey,
                    child: AppLockGate(child: RootShell(child: child!)),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
