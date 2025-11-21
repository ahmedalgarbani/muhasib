import 'package:get_it/get_it.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/accounts/data/datasources/opening_balance_local_datasource.dart';
import 'package:muhasib/features/accounts/data/repositories/opening_balance_repository_impl.dart';
import 'package:muhasib/features/accounts/domain/repositories/opening_balance_repository.dart';
import 'package:muhasib/features/accounts/domain/usecases/opening_balance_usecases.dart';
import 'package:muhasib/features/accounts/domain/usecases/get_all_accounts.dart';
import 'package:muhasib/features/accounts/presentation/cubit/opening_balance_cubit.dart';

/// Register all opening balance dependencies
/// Call this from GetItHelper.init() after database and account dependencies are registered
void registerOpeningBalanceDependencies(GetIt getIt, DatabaseService databaseService) {
  // Data Source
  getIt.registerLazySingleton<OpeningBalanceLocalDataSource>(
    () => OpeningBalanceLocalDataSourceImpl(databaseService: databaseService),
  );

  // Repository
  getIt.registerLazySingleton<OpeningBalanceRepository>(
    () => OpeningBalanceRepositoryImpl(
      localDataSource: getIt<OpeningBalanceLocalDataSource>(),
    ),
  );

  // Use Cases
  getIt.registerLazySingleton(
    () => GetAllOpeningBalances(repository: getIt<OpeningBalanceRepository>()),
  );
  
  getIt.registerLazySingleton(
    () => GetOpeningBalanceById(repository: getIt<OpeningBalanceRepository>()),
  );
  
  getIt.registerLazySingleton(
    () => CreateOpeningBalance(repository: getIt<OpeningBalanceRepository>()),
  );
  
  getIt.registerLazySingleton(
    () => UpdateOpeningBalance(repository: getIt<OpeningBalanceRepository>()),
  );
  
  getIt.registerLazySingleton(
    () => DeleteOpeningBalance(repository: getIt<OpeningBalanceRepository>()),
  );
  
  getIt.registerLazySingleton(
    () => PostOpeningBalance(repository: getIt<OpeningBalanceRepository>()),
  );
  
  getIt.registerLazySingleton(
    () => GenerateNextOpeningBalanceNumber(repository: getIt<OpeningBalanceRepository>()),
  );

  // Cubit
  getIt.registerFactory(
    () => OpeningBalanceCubit(
      getAllOpeningBalances: getIt<GetAllOpeningBalances>(),
      getOpeningBalanceById: getIt<GetOpeningBalanceById>(),
      createOpeningBalance: getIt<CreateOpeningBalance>(),
      updateOpeningBalance: getIt<UpdateOpeningBalance>(),
      deleteOpeningBalance: getIt<DeleteOpeningBalance>(),
      postOpeningBalance: getIt<PostOpeningBalance>(),
      generateNextNumber: getIt<GenerateNextOpeningBalanceNumber>(),
      getAllAccounts: getIt<GetAllAccounts>(),
    ),
  );
}
