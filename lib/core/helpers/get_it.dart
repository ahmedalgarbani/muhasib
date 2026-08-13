import 'package:get_it/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/core/services/account_config_service.dart';
import 'package:muhasib/core/services/account_validation_service.dart';
import 'package:muhasib/core/services/accounting_setup_validator.dart';
import 'package:muhasib/features/accounts/data/datasources/account_connect_local_datasource.dart';
import 'package:muhasib/features/accounts/data/datasources/account_local_datasource.dart';
import 'package:muhasib/features/accounts/data/datasources/journal_local_datasource.dart';
import 'package:muhasib/features/accounts/data/datasources/voucher_local_datasource.dart';
import 'package:muhasib/features/accounts/presentation/cubit/opening_balance_registration.dart';
import 'package:muhasib/features/accounts/domain/services/account_limit_service.dart';
import 'package:muhasib/features/accounts/data/datasources/account_limit_local_datasource.dart';
import 'package:muhasib/features/accounts/data/services/account_limit_service_impl.dart';
import 'package:muhasib/features/accounts/domain/interceptors/account_limit_interceptor.dart';
import 'package:muhasib/features/accounts/domain/services/account_connect_validator.dart';
import 'package:muhasib/features/accounts/data/repositories/account_connect_repository_impl.dart';
import 'package:muhasib/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:muhasib/features/accounts/data/repositories/journal_repository_impl.dart';
import 'package:muhasib/features/accounts/data/repositories/voucher_repository_impl.dart';
import 'package:muhasib/features/accounts/domain/repositories/account_connect_repository.dart';
import 'package:muhasib/features/accounts/domain/repositories/account_repository.dart';
import 'package:muhasib/features/accounts/domain/repositories/journal_repository.dart';
import 'package:muhasib/features/accounts/domain/repositories/voucher_repository.dart';
import 'package:muhasib/features/accounts/domain/usecases/create_account.dart';
import 'package:muhasib/features/accounts/domain/usecases/create_account_connect.dart';
import 'package:muhasib/features/accounts/domain/usecases/create_journal_entry.dart';
import 'package:muhasib/features/accounts/domain/usecases/delete_account.dart';
import 'package:muhasib/features/accounts/domain/usecases/delete_account_connect.dart';
import 'package:muhasib/features/accounts/domain/usecases/delete_journal_entry.dart';
import 'package:muhasib/features/accounts/domain/usecases/add_voucher.dart';
import 'package:muhasib/features/accounts/domain/usecases/delete_voucher.dart';
import 'package:muhasib/features/accounts/domain/usecases/get_account_connect_by_type.dart';
import 'package:muhasib/features/accounts/domain/usecases/get_all_account_connects.dart';
import 'package:muhasib/features/accounts/domain/usecases/get_all_accounts.dart';
import 'package:muhasib/features/accounts/domain/usecases/get_journal_entries.dart';
import 'package:muhasib/features/accounts/domain/usecases/get_journal_entry.dart';
import 'package:muhasib/features/accounts/domain/usecases/get_voucher_by_id.dart';
import 'package:muhasib/features/accounts/domain/usecases/get_vouchers.dart';
import 'package:muhasib/features/accounts/domain/usecases/get_master_accounts.dart';
import 'package:muhasib/features/accounts/domain/usecases/search_accounts.dart';
import 'package:muhasib/features/accounts/domain/usecases/update_account.dart';
import 'package:muhasib/features/accounts/domain/usecases/update_account_connect.dart';
import 'package:muhasib/features/accounts/domain/usecases/update_journal_entry.dart';
import 'package:muhasib/features/accounts/domain/usecases/update_voucher.dart';
import 'package:muhasib/features/accounts/domain/usecases/generate_voucher_number.dart';
import 'package:muhasib/features/accounts/presentation/cubit/account_connect_cubit.dart';
import 'package:muhasib/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:muhasib/features/accounts/presentation/cubit/journal_entry_cubit.dart';
import 'package:muhasib/features/accounts/presentation/cubit/vouchers_cubit.dart';
import 'package:muhasib/features/accounts/presentation/cubit/account_limits_cubit.dart';
import 'package:muhasib/features/currencies/data/datasources/currency_local_datasource.dart';
import 'package:muhasib/features/currencies/data/repositories/currency_repository_impl.dart';
import 'package:muhasib/features/currencies/domain/repositories/currency_repository.dart';
import 'package:muhasib/features/currencies/domain/usecases/create_currency.dart';
import 'package:muhasib/features/currencies/domain/usecases/delete_currency.dart';
import 'package:muhasib/features/currencies/domain/usecases/get_all_currencies.dart';
import 'package:muhasib/features/currencies/domain/usecases/get_currency_by_code.dart';
import 'package:muhasib/features/currencies/domain/usecases/get_currency_by_id.dart';
import 'package:muhasib/features/currencies/domain/usecases/search_currencies.dart';
import 'package:muhasib/features/currencies/domain/usecases/update_currency.dart';
import 'package:muhasib/features/currencies/presentation/cubit/currencies_cubit.dart';
import 'package:muhasib/features/sales/data/datasources/invoice_local_datasource.dart';
import 'package:muhasib/features/sales/data/repositories/invoice_repository_impl.dart';
import 'package:muhasib/features/sales/domain/repositories/invoice_repository.dart';
import 'package:muhasib/features/sales/domain/usecases/convert_quotation_to_invoice.dart';
import 'package:muhasib/features/sales/domain/usecases/create_invoice.dart';
import 'package:muhasib/features/sales/domain/usecases/create_return_invoice.dart';
import 'package:muhasib/features/sales/domain/usecases/delete_invoice.dart';
import 'package:muhasib/features/sales/domain/usecases/get_invoice.dart';
import 'package:muhasib/features/sales/domain/usecases/get_invoices.dart';
import 'package:muhasib/features/sales/domain/usecases/get_open_quotations.dart';
import 'package:muhasib/features/sales/domain/usecases/get_quotations.dart';
import 'package:muhasib/features/sales/domain/usecases/get_return_invoices.dart';
import 'package:muhasib/features/sales/domain/usecases/get_returns_by_parent_invoice.dart';
import 'package:muhasib/features/sales/domain/usecases/search_invoices.dart';
import 'package:muhasib/features/sales/domain/usecases/update_invoice.dart';
import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:muhasib/features/purchases/domain/repositories/purchase_repository.dart';
import 'package:muhasib/features/purchases/data/repositories/purchase_repository_impl.dart';
import 'package:muhasib/features/purchases/domain/usecases/create_purchase.dart';
import 'package:muhasib/features/purchases/presentation/cubit/purchases_cubit.dart';
import 'package:muhasib/features/products/data/datasources/product_local_datasource.dart';
import 'package:muhasib/features/products/data/datasources/product_group_local_datasource.dart';
import 'package:muhasib/features/products/data/datasources/product_unit_local_datasource.dart';
import 'package:muhasib/features/products/data/repositories/product_repository_impl.dart';
import 'package:muhasib/features/products/data/repositories/product_group_repository_impl.dart';
import 'package:muhasib/features/products/data/repositories/product_unit_repository_impl.dart';
import 'package:muhasib/features/products/domain/repositories/product_repository.dart';
import 'package:muhasib/features/products/domain/repositories/product_group_repository.dart';
import 'package:muhasib/features/products/domain/repositories/product_unit_repository.dart';
import 'package:muhasib/features/products/presentation/cubit/products_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/product_groups_cubit.dart';
import 'package:muhasib/features/products/presentation/cubit/product_units_cubit.dart';
import 'package:muhasib/features/products/data/datasources/product_sub_unit_local_datasource.dart';
import 'package:muhasib/features/products/data/repositories/product_sub_unit_repository_impl.dart';
import 'package:muhasib/features/products/domain/repositories/product_sub_unit_repository.dart';
import 'package:muhasib/features/products/presentation/cubit/product_sub_units_cubit.dart';
import 'package:muhasib/features/products/data/datasources/item_movement_local_datasource.dart';
import 'package:muhasib/features/products/data/repositories/item_movement_repository_impl.dart';
import 'package:muhasib/features/products/domain/repositories/item_movement_repository.dart';
import 'package:muhasib/features/products/presentation/cubit/item_movements_cubit.dart';
import 'package:muhasib/features/products/data/datasources/product_price_local_datasource.dart';
import 'package:muhasib/features/products/data/repositories/product_price_repository_impl.dart';
import 'package:muhasib/features/products/domain/repositories/product_price_repository.dart';
import 'package:muhasib/features/products/presentation/cubit/product_prices_cubit.dart';
import 'package:muhasib/features/initial/data/datasources/initial_local_datasource.dart';
import 'package:muhasib/features/initial/data/repositories/initial_repository_impl.dart';
import 'package:muhasib/features/initial/domain/repositories/initial_repository.dart';
import 'package:muhasib/features/initial/domain/usecases/check_initial_setup_status.dart';
import 'package:muhasib/features/initial/domain/usecases/mark_initial_setup_complete.dart';
import 'package:muhasib/features/initial/domain/usecases/save_opening_balances.dart';
import 'package:muhasib/features/initial/domain/usecases/get_opening_balances.dart';
import 'package:muhasib/features/initial/presentation/cubit/initial_cubit.dart';
import 'package:muhasib/features/setting/data/repositories/settings_repository.dart' as new_settings_repo;
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart' as new_settings_cubit;
import 'package:muhasib/features/stores/data/datasources/warehouse_local_datasource.dart';
import 'package:muhasib/features/stores/data/datasources/stock_transfer_local_datasource.dart';
import 'package:muhasib/features/stores/data/datasources/inventory_local_datasource.dart';
import 'package:muhasib/features/stores/data/datasources/stock_adjustment_local_datasource.dart';
import 'package:muhasib/features/stores/data/repositories/warehouse_repository_impl.dart';
import 'package:muhasib/features/stores/data/repositories/stock_transfer_repository_impl.dart';
import 'package:muhasib/features/stores/data/repositories/inventory_repository_impl.dart';
import 'package:muhasib/features/stores/data/repositories/stock_adjustment_repository_impl.dart';
import 'package:muhasib/features/stores/domain/repositories/warehouse_repository.dart';
import 'package:muhasib/features/stores/domain/repositories/stock_transfer_repository.dart';
import 'package:muhasib/features/stores/domain/repositories/inventory_repository.dart';
import 'package:muhasib/features/stores/domain/repositories/stock_adjustment_repository.dart';
import 'package:muhasib/features/stores/domain/services/warehouse_validation_service.dart';
import 'package:muhasib/features/stores/data/services/warehouse_validation_service_impl.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';
import 'package:muhasib/features/stores/presentation/cubit/stock_transfers_cubit.dart';
import 'package:muhasib/features/stores/presentation/cubit/inventory_cubit.dart';
import 'package:muhasib/features/stores/presentation/cubit/stock_adjustments_cubit.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/customers/data/datasources/customer_data_source.dart';
import 'package:muhasib/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:muhasib/features/customers/domain/repositories/customer_repository.dart';
import 'package:muhasib/features/settings_entities/data/datasources/bank_local_datasource.dart';
import 'package:muhasib/features/settings_entities/data/datasources/cashbox_local_datasource.dart';
import 'package:muhasib/features/settings_entities/data/datasources/other_fee_local_datasource.dart';
import 'package:muhasib/features/settings_entities/data/datasources/region_local_datasource.dart';
import 'package:muhasib/features/settings_entities/data/repositories/bank_repository_impl.dart';
import 'package:muhasib/features/settings_entities/data/repositories/cashbox_repository_impl.dart';
import 'package:muhasib/features/settings_entities/data/repositories/other_fee_repository_impl.dart';
import 'package:muhasib/features/settings_entities/data/repositories/region_repository_impl.dart';
import 'package:muhasib/features/settings_entities/domain/repositories/bank_repository.dart';
import 'package:muhasib/features/settings_entities/domain/repositories/cashbox_repository.dart';
import 'package:muhasib/features/settings_entities/domain/repositories/other_fee_repository.dart';
import 'package:muhasib/features/settings_entities/domain/repositories/region_repository.dart';
import 'package:muhasib/features/settings_entities/presentation/cubit/banks_cubit.dart';
import 'package:muhasib/features/settings_entities/presentation/cubit/cashboxes_cubit.dart';
import 'package:muhasib/features/settings_entities/presentation/cubit/other_fees_cubit.dart';
import 'package:muhasib/features/settings_entities/presentation/cubit/regions_cubit.dart';
import 'package:muhasib/features/reports/data/datasources/transactions_report_data_source.dart';
import 'package:muhasib/features/reports/data/repositories/transactions_report_repository_impl.dart';
import 'package:muhasib/features/reports/domain/repositories/transactions_report_repository.dart';
import 'package:muhasib/features/reports/presentation/cubit/transactions_report_cubit.dart';
import 'package:muhasib/features/reports/data/datasources/trial_balance_datasource.dart';
import 'package:muhasib/features/reports/data/repositories/trial_balance_repository_impl.dart';
import 'package:muhasib/features/reports/domain/repositories/trial_balance_repository.dart';
import 'package:muhasib/features/reports/presentation/cubit/trial_balance_cubit.dart';
import 'package:muhasib/features/reports/data/datasources/income_statement_datasource.dart';
import 'package:muhasib/features/reports/data/repositories/income_statement_repository_impl.dart';
import 'package:muhasib/features/reports/domain/repositories/income_statement_repository.dart';
import 'package:muhasib/features/reports/presentation/cubit/income_statement_cubit.dart';
import 'package:muhasib/features/reports/data/datasources/sales_summary_datasource.dart';
import 'package:muhasib/features/reports/data/repositories/sales_summary_repository_impl.dart';
import 'package:muhasib/features/reports/domain/repositories/sales_summary_repository.dart';
import 'package:muhasib/features/reports/presentation/cubit/sales_summary_cubit.dart';
import 'package:muhasib/features/reports/data/datasources/stock_datasource.dart';
import 'package:muhasib/features/reports/data/repositories/stock_repository_impl.dart';
import 'package:muhasib/features/reports/domain/repositories/stock_repository.dart';
import 'package:muhasib/features/reports/presentation/cubit/stock_cubit.dart';
import 'package:muhasib/features/reports/data/datasources/account_statement_datasource.dart';
import 'package:muhasib/features/reports/data/repositories/account_statement_repository_impl.dart';
import 'package:muhasib/features/reports/domain/repositories/account_statement_repository.dart';
import 'package:muhasib/features/reports/presentation/cubit/account_statement_cubit.dart';
import 'package:muhasib/features/accounts/data/datasources/fiscal_period_datasource.dart';
import 'package:muhasib/core/services/number_sequence_service.dart';
import 'package:muhasib/features/accounts/data/datasources/account_movements_local_datasource.dart';
import 'package:muhasib/features/accounts/data/repositories/account_movements_repository_impl.dart';
import 'package:muhasib/features/accounts/domain/repositories/account_movements_repository.dart';
import 'package:muhasib/features/accounts/domain/usecases/get_account_movements.dart';
import 'package:muhasib/features/accounts/presentation/cubit/account_movements_cubit.dart';
import 'package:muhasib/features/main/presentation/cubit/main_cubit.dart';

final getIt = GetIt.instance;
final sl = getIt; // Alias for backward compatibility

class GetItHelper {
  static Future<void> init() async {
    // Database Service
    final databaseService = DatabaseService();
    final database = await databaseService.database;

    getIt.registerLazySingleton<IDatabaseService>(() => databaseService);
    getIt.registerLazySingleton<DatabaseService>(() => databaseService);
    
    // Account Config Service (dynamic account ID lookup)
    getIt.registerLazySingleton<AccountConfigService>(
      () => AccountConfigService(database: database),
    );
    
    // Account Validation Service (prevent deletion of accounts used in journal entries)
    getIt.registerLazySingleton<AccountValidationService>(
      () => AccountValidationService(
        database: database,
        journalRepository: null, // Will be set after JournalRepository is registered
      ),
    );
    
    // Accounting Setup Validator (validate default accounts at startup)
    getIt.registerLazySingleton<AccountingSetupValidator>(
      () => AccountingSetupValidator(
        database: database,
        accountConfigService: getIt<AccountConfigService>(),
      ),
    );

    // ==================== New Accounting Services ====================
    // Fiscal Period DataSource
    getIt.registerLazySingleton<FiscalPeriodDataSource>(
      () => FiscalPeriodDataSourceImpl(database: database),
    );

    // Number Sequence Service
    getIt.registerLazySingleton<NumberSequenceService>(
      () => NumberSequenceService(database),
    );

    // ==================== Initial Feature ====================
    getIt.registerLazySingleton<InitialLocalDataSource>(
      () => InitialLocalDataSourceImpl(database: database),
    );
    getIt.registerLazySingleton<InitialRepository>(
      () => InitialRepositoryImpl(
        localDataSource: getIt<InitialLocalDataSource>(),
        databaseService: getIt<DatabaseService>(),
      ),
    );
    getIt.registerLazySingleton(
      () => CheckInitialSetupStatus(getIt<InitialRepository>()),
    );
    getIt.registerLazySingleton(
      () => MarkInitialSetupComplete(getIt<InitialRepository>()),
    );
    getIt.registerLazySingleton(
      () => SaveOpeningBalances(getIt<InitialRepository>()),
    );
    getIt.registerLazySingleton(
      () => GetOpeningBalances(getIt<InitialRepository>()),
    );
    getIt.registerFactory(
      () => InitialCubit(
        checkInitialSetupStatus: getIt<CheckInitialSetupStatus>(),
        markInitialSetupComplete: getIt<MarkInitialSetupComplete>(),
        saveOpeningBalancesUseCase: getIt<SaveOpeningBalances>(),
        getOpeningBalancesUseCase: getIt<GetOpeningBalances>(),
      ),
    );

    // ==================== Accounts Feature ====================

    // Data Sources
    getIt.registerLazySingleton<AccountLocalDataSource>(
      () => AccountLocalDataSourceImpl(database),
    );
    getIt.registerLazySingleton<AccountConnectLocalDataSource>(
      () => AccountConnectLocalDataSourceImpl(database: database),
    );
    getIt.registerLazySingleton<JournalLocalDataSource>(
      () => JournalLocalDataSourceImpl(database: database),
    );
    getIt.registerLazySingleton<VoucherLocalDataSource>(
      () => VoucherLocalDataSourceImpl(database: database),
    );

    // Repositories
    getIt.registerLazySingleton<AccountRepository>(
      () => AccountRepositoryImpl(
        getIt<AccountLocalDataSource>(),
        validationService: getIt<AccountValidationService>(),
      ),
    );
    getIt.registerLazySingleton<AccountConnectRepository>(
      () => AccountConnectRepositoryImpl(
        localDataSource: getIt<AccountConnectLocalDataSource>(),
      ),
    );
    getIt.registerLazySingleton<JournalRepository>(
      () => JournalRepositoryImpl(
        localDataSource: getIt<JournalLocalDataSource>(),
      ),
    );
    getIt.registerLazySingleton<VoucherRepository>(
      () => VoucherRepositoryImpl(
        localDataSource: getIt<VoucherLocalDataSource>(),
      ),
    );

    // ==================== Currencies Feature ====================
    // Data Source
    getIt.registerLazySingleton<CurrencyLocalDataSource>(
      () => CurrencyLocalDataSourceImpl(database),
    );
    // Repository
    getIt.registerLazySingleton<CurrencyRepository>(
      () => CurrencyRepositoryImpl(getIt<CurrencyLocalDataSource>()),
    );
    // Use Cases
    getIt.registerLazySingleton(
      () => GetAllCurrencies(getIt<CurrencyRepository>()),
    );
    getIt.registerLazySingleton(
      () => GetCurrencyById(getIt<CurrencyRepository>()),
    );
    getIt.registerLazySingleton(
      () => GetCurrencyByCode(getIt<CurrencyRepository>()),
    );
    getIt.registerLazySingleton(
      () => CreateCurrency(getIt<CurrencyRepository>()),
    );
    getIt.registerLazySingleton(
      () => UpdateCurrency(getIt<CurrencyRepository>()),
    );
    getIt.registerLazySingleton(
      () => DeleteCurrency(getIt<CurrencyRepository>()),
    );
    getIt.registerLazySingleton(
      () => SearchCurrencies(getIt<CurrencyRepository>()),
    );

    // Use Cases
    getIt.registerLazySingleton(
      () => GetAllAccounts(getIt<AccountRepository>()),
    );
    getIt.registerLazySingleton(
      () => GetMasterAccounts(getIt<AccountRepository>()),
    );
    getIt.registerLazySingleton(
      () => CreateAccount(getIt<AccountRepository>()),
    );
    getIt.registerLazySingleton(
      () => UpdateAccount(getIt<AccountRepository>()),
    );
    getIt.registerLazySingleton(
      () => DeleteAccount(getIt<AccountRepository>()),
    );
    getIt.registerLazySingleton(
      () => SearchAccounts(getIt<AccountRepository>()),
    );

    getIt.registerLazySingleton(
      () => GetAccountConnectByType(getIt<AccountConnectRepository>()),
    );
    getIt.registerLazySingleton(
      () => DeleteAccountConnect(getIt<AccountConnectRepository>()),
    );
    getIt.registerLazySingleton(
      () => UpdateAccountConnect(getIt<AccountConnectRepository>()),
    );
    getIt.registerLazySingleton(
      () => CreateAccountConnect(getIt<AccountConnectRepository>()),
    );
    getIt.registerLazySingleton(
      () => GetAllAccountConnects(getIt<AccountConnectRepository>()),
    );
    getIt.registerLazySingleton(
      () => GetJournalEntries(getIt<JournalRepository>()),
    );
    getIt.registerLazySingleton(
      () => GetJournalEntry(getIt<JournalRepository>()),
    );
    getIt.registerLazySingleton(
      () => CreateJournalEntry(getIt<JournalRepository>()),
    );
    getIt.registerLazySingleton(
      () => UpdateJournalEntry(getIt<JournalRepository>()),
    );
    getIt.registerLazySingleton(
      () => DeleteJournalEntry(getIt<JournalRepository>()),
    );
    getIt.registerLazySingleton(
      () => GetVouchersUseCase(getIt<VoucherRepository>()),
    );
    getIt.registerLazySingleton(
      () => GetVoucherByIdUseCase(getIt<VoucherRepository>()),
    );
    getIt.registerLazySingleton(
      () => AddVoucherUseCase(
        getIt<VoucherRepository>(),
      ),
    );
    getIt.registerLazySingleton(
      () => UpdateVoucherUseCase(getIt<VoucherRepository>()),
    );
    getIt.registerLazySingleton(
      () => DeleteVoucherUseCase(getIt<VoucherRepository>()),
    );
    getIt.registerLazySingleton(
      () => GenerateVoucherNumberUseCase(getIt<VoucherRepository>()),
    );

    // Register Opening Balance dependencies
    registerOpeningBalanceDependencies(getIt, databaseService);

    // Account Limits datasource + service
    getIt.registerLazySingleton<AccountLimitLocalDataSource>(
      () => AccountLimitLocalDataSourceImpl(databaseService: databaseService),
    );
    getIt.registerLazySingleton<AccountLimitService>(
      () => AccountLimitServiceImpl(localDataSource: getIt<AccountLimitLocalDataSource>()),
    );
    
    // Register Account Limit Interceptor
    getIt.registerLazySingleton<AccountLimitInterceptor>(
      () => AccountLimitInterceptor(limitService: getIt<AccountLimitService>()),
    );
    
    // Register Account Connect Validator
    getIt.registerLazySingleton<AccountConnectValidator>(
      () => AccountConnectValidator(repository: getIt<AccountConnectRepository>()),
    );

    // ==================== Sales Feature ====================
    // Data Source
    getIt.registerLazySingleton<InvoiceLocalDataSource>(
      () => InvoiceLocalDataSourceImpl(database: database),
    );
    // Repository (with accounting services for double-entry)
    getIt.registerLazySingleton<InvoiceRepository>(
      () => InvoiceRepositoryImpl(
        localDataSource: getIt<InvoiceLocalDataSource>(),
        journalRepository: getIt<JournalRepository>(),
        accountConfigService: getIt<AccountConfigService>(),
        numberSequenceService: getIt<NumberSequenceService>(),
      ),
    );
    // Use Cases
    getIt.registerLazySingleton(() => GetInvoices(getIt<InvoiceRepository>()));
    getIt.registerLazySingleton(() => GetInvoice(getIt<InvoiceRepository>()));
    getIt.registerLazySingleton(
      () => CreateInvoice(getIt<InvoiceRepository>()),
    );
    getIt.registerLazySingleton(
      () => UpdateInvoice(getIt<InvoiceRepository>()),
    );
    getIt.registerLazySingleton(
      () => DeleteInvoice(getIt<InvoiceRepository>()),
    );
    getIt.registerLazySingleton(
      () => SearchInvoices(getIt<InvoiceRepository>()),
    );
    getIt.registerLazySingleton(
      () => GetQuotations(getIt<InvoiceRepository>()),
    );
    getIt.registerLazySingleton(
      () => GetOpenQuotations(getIt<InvoiceRepository>()),
    );
    getIt.registerLazySingleton(
      () => ConvertQuotationToInvoice(getIt<InvoiceRepository>()),
    );
    getIt.registerLazySingleton(
      () => GetReturnInvoices(getIt<InvoiceRepository>()),
    );
    getIt.registerLazySingleton(
      () => CreateReturnInvoice(
        getIt<InvoiceRepository>(),
      ),
    );
    getIt.registerLazySingleton(
      () => GetReturnsByParentInvoice(getIt<InvoiceRepository>()),
    );

    // Cubit
    getIt.registerFactory(
      () => AccountsCubit(
        getAllAccounts: getIt<GetAllAccounts>(),
        getMasterAccounts: getIt<GetMasterAccounts>(),
        createAccount: getIt<CreateAccount>(),
        updateAccount: getIt<UpdateAccount>(),
        deleteAccount: getIt<DeleteAccount>(),
        searchAccounts: getIt<SearchAccounts>(),
      ),
    );
    getIt.registerFactory(
      () => AccountConnectCubit(
        createAccountConnect: getIt<CreateAccountConnect>(),
        deleteAccountConnect: getIt<DeleteAccountConnect>(),
        getAccountConnectByType: getIt<GetAccountConnectByType>(),
        getAllAccountConnects: getIt<GetAllAccountConnects>(),
        updateAccountConnect: getIt<UpdateAccountConnect>(),
      ),
    );
    getIt.registerFactory(
      () => AccountLimitsCubit(
        limitService: getIt<AccountLimitService>(),
      ),
    );
    getIt.registerFactory(
      () => JournalEntryCubit(
        createJournalEntry: getIt<CreateJournalEntry>(),
        updateJournalEntry: getIt<UpdateJournalEntry>(),
        deleteJournalEntry: getIt<DeleteJournalEntry>(),
        getJournalEntries: getIt<GetJournalEntries>(),
        getJournalEntry: getIt<GetJournalEntry>(),
        limitInterceptor: getIt<AccountLimitInterceptor>(),
        getAllAccounts: getIt<GetAllAccounts>(),
        getAllCurrencies: getIt<GetAllCurrencies>(),
      ),
    );
    getIt.registerFactory(
      () => VouchersCubit(
        getVouchersUseCase: getIt<GetVouchersUseCase>(),
        getVoucherByIdUseCase: getIt<GetVoucherByIdUseCase>(),
        addVoucherUseCase: getIt<AddVoucherUseCase>(),
        updateVoucherUseCase: getIt<UpdateVoucherUseCase>(),
        deleteVoucherUseCase: getIt<DeleteVoucherUseCase>(),
        generateVoucherNumberUseCase: getIt<GenerateVoucherNumberUseCase>(),
        limitInterceptor: getIt<AccountLimitInterceptor>(),
      ),
    );
    getIt.registerFactory(
      () => CurrenciesCubit(
        getAllCurrencies: getIt<GetAllCurrencies>(),
        getCurrencyById: getIt<GetCurrencyById>(),
        getCurrencyByCode: getIt<GetCurrencyByCode>(),
        createCurrency: getIt<CreateCurrency>(),
        updateCurrency: getIt<UpdateCurrency>(),
        deleteCurrency: getIt<DeleteCurrency>(),
        searchCurrencies: getIt<SearchCurrencies>(),
      ),
    );
    getIt.registerFactory(
      () => SalesCubit(
        getInvoices: getIt<GetInvoices>(),
        getInvoice: getIt<GetInvoice>(),
        createInvoice: getIt<CreateInvoice>(),
        updateInvoice: getIt<UpdateInvoice>(),
        deleteInvoice: getIt<DeleteInvoice>(),
        searchInvoices: getIt<SearchInvoices>(),
        getQuotations: getIt<GetQuotations>(),
        getOpenQuotations: getIt<GetOpenQuotations>(),
        convertQuotationToInvoice: getIt<ConvertQuotationToInvoice>(),
        getReturnInvoices: getIt<GetReturnInvoices>(),
        createReturnInvoice: getIt<CreateReturnInvoice>(),
        getReturnsByParentInvoice: getIt<GetReturnsByParentInvoice>(),
        limitInterceptor: getIt<AccountLimitInterceptor>(),
      ),
    );

    // ==================== Purchases Feature ====================
    // Repository (reuses Invoice data source + accounting services)
    getIt.registerLazySingleton<PurchaseRepository>(
      () => PurchaseRepositoryImpl(
        localDataSource: getIt<InvoiceLocalDataSource>(),
        journalRepository: getIt<JournalRepository>(),
        accountConfigService: getIt<AccountConfigService>(),
      ),
    );
    
    // Use Cases
    getIt.registerLazySingleton(
      () => CreatePurchase(
        getIt<PurchaseRepository>(),
      ),
    );
    
    // Cubit
    getIt.registerFactory(
      () => PurchasesCubit(
        repository: getIt<PurchaseRepository>(),
        createPurchase: getIt<CreatePurchase>(),
        limitInterceptor: getIt<AccountLimitInterceptor>(),
      ),
    );
    
    // ==================== Products Feature ====================
    // Data Sources
    getIt.registerLazySingleton<ProductLocalDataSource>(
      () => ProductLocalDataSourceImpl(database: database),
    );
    getIt.registerLazySingleton<ProductGroupLocalDataSource>(
      () => ProductGroupLocalDataSourceImpl(database: database),
    );
    getIt.registerLazySingleton<ProductUnitLocalDataSource>(
      () => ProductUnitLocalDataSourceImpl(database: database),
    );
    getIt.registerLazySingleton<ProductSubUnitLocalDataSource>(
      () => ProductSubUnitLocalDataSourceImpl(database: database),
    );
    getIt.registerLazySingleton<ItemMovementLocalDataSource>(
      () => ItemMovementLocalDataSourceImpl(database: database),
    );
    
    // Repositories
    getIt.registerLazySingleton<ProductRepository>(
      () => ProductRepositoryImpl(getIt<ProductLocalDataSource>()),
    );
    getIt.registerLazySingleton<ProductGroupRepository>(
      () => ProductGroupRepositoryImpl(getIt<ProductGroupLocalDataSource>()),
    );
    getIt.registerLazySingleton<ProductUnitRepository>(
      () => ProductUnitRepositoryImpl(getIt<ProductUnitLocalDataSource>()),
    );
    getIt.registerLazySingleton<ProductSubUnitRepository>(
      () => ProductSubUnitRepositoryImpl(getIt<ProductSubUnitLocalDataSource>()),
    );
    getIt.registerLazySingleton<ItemMovementRepository>(
      () => ItemMovementRepositoryImpl(getIt<ItemMovementLocalDataSource>()),
    );
    
    // Cubits
    getIt.registerFactory(
      () => ProductsCubit(getIt<ProductRepository>()),
    );
    getIt.registerFactory(
      () => ProductGroupsCubit(getIt<ProductGroupRepository>()),
    );
    getIt.registerFactory(
      () => ProductUnitsCubit(getIt<ProductUnitRepository>()),
    );
    getIt.registerFactory(
      () => ProductSubUnitsCubit(getIt<ProductSubUnitRepository>()),
    );
    getIt.registerFactory(
      () => ItemMovementsCubit(getIt<ItemMovementRepository>()),
    );
    
    // Product Prices
    getIt.registerLazySingleton<ProductPriceLocalDataSource>(
      () => ProductPriceLocalDataSourceImpl(database: database),
    );
    getIt.registerLazySingleton<ProductPriceRepository>(
      () => ProductPriceRepositoryImpl(getIt<ProductPriceLocalDataSource>()),
    );
    getIt.registerFactory(
      () => ProductPricesCubit(getIt<ProductPriceRepository>()),
    );
    
    // ==================== Stores/Warehouses Feature ====================
    // Data Sources
    getIt.registerLazySingleton<WarehouseLocalDataSource>(
      () => WarehouseLocalDataSourceImpl(database: database),
    );
    getIt.registerLazySingleton<StockTransferLocalDataSource>(
      () => StockTransferLocalDataSourceImpl(database: database),
    );
    getIt.registerLazySingleton<InventoryLocalDataSource>(
      () => InventoryLocalDataSourceImpl(database: database),
    );
    getIt.registerLazySingleton<StockAdjustmentLocalDataSource>(
      () => StockAdjustmentLocalDataSourceImpl(databaseService: getIt<DatabaseService>()),
    );
    
    // Services
    getIt.registerLazySingleton<WarehouseValidationService>(
      () => WarehouseValidationServiceImpl(databaseService: getIt<DatabaseService>()),
    );
    
    // Repositories
    getIt.registerLazySingleton<WarehouseRepository>(
      () => WarehouseRepositoryImpl(
        getIt<WarehouseLocalDataSource>(),
        validationService: getIt<WarehouseValidationService>(),
      ),
    );
    getIt.registerLazySingleton<StockTransferRepository>(
      () => StockTransferRepositoryImpl(getIt<StockTransferLocalDataSource>()),
    );
    getIt.registerLazySingleton<InventoryRepository>(
      () => InventoryRepositoryImpl(getIt<InventoryLocalDataSource>()),
    );
    getIt.registerLazySingleton<StockAdjustmentRepository>(
      () => StockAdjustmentRepositoryImpl(getIt<StockAdjustmentLocalDataSource>()),
    );
    
    // Cubits
    getIt.registerFactory(
      () => WarehousesCubit(getIt<WarehouseRepository>()),
    );
    getIt.registerFactory(
      () => StockTransfersCubit(getIt<StockTransferRepository>()),
    );
    getIt.registerFactory(
      () => InventoryCubit(getIt<InventoryRepository>()),
    );
    getIt.registerFactory(
      () => StockAdjustmentsCubit(getIt<StockAdjustmentRepository>()),
    );
    
    // ==================== Customers Feature ====================
    // Data Source
    getIt.registerLazySingleton<CustomerDataSource>(
      () => CustomerDataSourceImpl(databaseService: getIt<DatabaseService>()),
    );
    
    // Repository
    getIt.registerLazySingleton<CustomerRepository>(
      () => CustomerRepositoryImpl(dataSource: getIt<CustomerDataSource>()),
    );
    
    // Cubit
    getIt.registerFactory(
      () => CustomersCubit(getIt<CustomerRepository>()),
    );
    
    // ==================== Settings Feature ====================
    // Repository
    getIt.registerLazySingleton<new_settings_repo.ISettingsRepository>(
      () => new_settings_repo.SettingsRepository(database: database),
    );
    
    // Cubit
    getIt.registerLazySingleton(
      () => new_settings_cubit.SettingsCubit(
        repository: getIt<new_settings_repo.ISettingsRepository>(),
      ),
    );

    // ==================== Settings Entities Feature ====================
    // Data Sources
    getIt.registerLazySingleton<BankLocalDataSource>(
      () => BankLocalDataSourceImpl(database: database),
    );
    getIt.registerLazySingleton<CashboxLocalDataSource>(
      () => CashboxLocalDataSourceImpl(database: database),
    );
    getIt.registerLazySingleton<OtherFeeLocalDataSource>(
      () => OtherFeeLocalDataSourceImpl(database: database),
    );
    getIt.registerLazySingleton<RegionLocalDataSource>(
      () => RegionLocalDataSourceImpl(database: database),
    );

    // Repositories
    getIt.registerLazySingleton<BankRepository>(
      () => BankRepositoryImpl(getIt<BankLocalDataSource>()),
    );
    getIt.registerLazySingleton<CashboxRepository>(
      () => CashboxRepositoryImpl(getIt<CashboxLocalDataSource>()),
    );
    getIt.registerLazySingleton<OtherFeeRepository>(
      () => OtherFeeRepositoryImpl(getIt<OtherFeeLocalDataSource>()),
    );
    getIt.registerLazySingleton<RegionRepository>(
      () => RegionRepositoryImpl(getIt<RegionLocalDataSource>()),
    );

    // Cubits
    getIt.registerFactory(
      () => BanksCubit(getIt<BankRepository>()),
    );
    getIt.registerFactory(
      () => CashboxesCubit(getIt<CashboxRepository>()),
    );
    getIt.registerFactory(
      () => OtherFeesCubit(getIt<OtherFeeRepository>()),
    );
    getIt.registerFactory(
      () => RegionsCubit(getIt<RegionRepository>()),
    );

    // Transactions Report
    getIt.registerLazySingleton<TransactionsReportDataSource>(
      () => TransactionsReportDataSourceImpl(getIt<DatabaseService>()),
    );
    getIt.registerLazySingleton<TransactionsReportRepository>(
      () => TransactionsReportRepositoryImpl(getIt<TransactionsReportDataSource>()),
    );
    getIt.registerFactory(
      () => TransactionsReportCubit(getIt<TransactionsReportRepository>()),
    );

    // Trial Balance Report
    getIt.registerLazySingleton<TrialBalanceDataSource>(
      () => TrialBalanceDataSourceImpl(databaseService: getIt<DatabaseService>()),
    );
    getIt.registerLazySingleton<TrialBalanceRepository>(
      () => TrialBalanceRepositoryImpl(dataSource: getIt<TrialBalanceDataSource>()),
    );
    getIt.registerFactory(
      () => TrialBalanceCubit(repository: getIt<TrialBalanceRepository>()),
    );

    // Income Statement Report
    getIt.registerLazySingleton<IncomeStatementDataSource>(
      () => IncomeStatementDataSourceImpl(databaseService: getIt<DatabaseService>()),
    );
    getIt.registerLazySingleton<IncomeStatementRepository>(
      () => IncomeStatementRepositoryImpl(dataSource: getIt<IncomeStatementDataSource>()),
    );
    getIt.registerFactory(
      () => IncomeStatementCubit(repository: getIt<IncomeStatementRepository>()),
    );

    // Sales Summary Report
    getIt.registerLazySingleton<SalesSummaryDataSource>(
      () => SalesSummaryDataSourceImpl(databaseService: getIt<DatabaseService>()),
    );
    getIt.registerLazySingleton<SalesSummaryRepository>(
      () => SalesSummaryRepositoryImpl(dataSource: getIt<SalesSummaryDataSource>()),
    );
    getIt.registerFactory(
      () => SalesSummaryCubit(repository: getIt<SalesSummaryRepository>()),
    );

    // Stock Report
    getIt.registerLazySingleton<StockDataSource>(
      () => StockDataSourceImpl(databaseService: getIt<DatabaseService>()),
    );
    getIt.registerLazySingleton<StockRepository>(
      () => StockRepositoryImpl(dataSource: getIt<StockDataSource>()),
    );
    getIt.registerFactory(
      () => StockCubit(repository: getIt<StockRepository>()),
    );

    // Account Statement Report
    getIt.registerLazySingleton<AccountStatementDataSource>(
      () => AccountStatementDataSourceImpl(databaseService: getIt<DatabaseService>()),
    );
    getIt.registerLazySingleton<AccountStatementRepository>(
      () => AccountStatementRepositoryImpl(dataSource: getIt<AccountStatementDataSource>()),
    );
    getIt.registerFactory(
      () => AccountStatementCubit(repository: getIt<AccountStatementRepository>()),
    );

    // Account Movements Feature
    getIt.registerLazySingleton<AccountMovementsLocalDataSource>(
      () => AccountMovementsLocalDataSourceImpl(database: database),
    );
    getIt.registerLazySingleton<AccountMovementsRepository>(
      () => AccountMovementsRepositoryImpl(localDataSource: getIt<AccountMovementsLocalDataSource>()),
    );
    getIt.registerLazySingleton(
      () => GetAccountMovements(getIt<AccountMovementsRepository>()),
    );
    getIt.registerLazySingleton(
      () => GetAccountMovementsSummary(getIt<AccountMovementsRepository>()),
    );
    getIt.registerFactory(
      () => AccountMovementsCubit(
        getAccountMovements: getIt<GetAccountMovements>(),
        getAccountMovementsSummary: getIt<GetAccountMovementsSummary>(),
      ),
    );
    getIt.registerFactory(
      () => MainCubit(
        customerRepository: getIt<CustomerRepository>(),
        getInvoices: getIt<GetInvoices>(),
        purchaseRepository: getIt<PurchaseRepository>(),
        voucherRepository: getIt<VoucherRepository>(),
      ),
    );
  }

  static Future<void> reset() async {
    await getIt.reset();
  }
}
