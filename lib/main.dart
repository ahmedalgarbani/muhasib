import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:muhasib/core/helpers/cubit/local_cubit.dart';
import 'package:muhasib/core/helpers/cubit/theme_cubit.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/helpers/responsive_text.dart';
import 'package:muhasib/core/route/app_router.dart';
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
import 'package:muhasib/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:muhasib/features/setting/presentation/cubit/setting_cubit.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';
import 'package:muhasib/features/stores/presentation/cubit/stores_cubit.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:muhasib/core/theme/theme.dart';
import 'package:muhasib/features/accounts/accounts.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:muhasib/core/database/database_initializer.dart';
import 'generated/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database factory for Web/Desktop FFI support
  await initializeDatabaseFactory();

  // Initialize GetIt dependencies
  await GetItHelper.init();

  // Load app settings into the shared cubit + SettingsCache so every
  // feature reads live values from the DB (formatting, sales rules, print...).
  await getIt<SettingsCubit>().loadSettings();

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
        BlocProvider(create: (context) => getIt<ProductsCubit>()),
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
        BlocProvider(create: (context) => ReportsCubit()),
        BlocProvider(create: (context) => SettingCubit()),
        BlocProvider(create: (context) => StoresCubit()),
        BlocProvider(create: (context) => ThemeCubit()),
        BlocProvider(create: (context) => LocaleCubit()),
        BlocProvider(create: (context) => getIt<PurchasesCubit>()),
        BlocProvider(create: (context) => getIt<SettingsCubit>()),
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
                child: ResponsiveTextScale(child: RootShell(child: child!)),
              ),
            );
          },
        );
      },
    );
  }
}
