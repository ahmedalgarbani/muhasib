import 'package:flutter_test/flutter_test.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/initial/data/datasources/initial_local_datasource.dart';
import 'package:muhasib/features/initial/data/repositories/initial_repository_impl.dart';
import 'package:muhasib/features/initial/data/templates/opening_balance_accounting_template.dart';
import 'package:muhasib/features/initial/domain/entities/opening_balance_entity.dart';
import 'package:muhasib/features/initial/domain/usecases/check_initial_setup_status.dart';
import 'package:muhasib/features/initial/domain/usecases/mark_initial_setup_complete.dart';
import 'package:muhasib/features/initial/domain/usecases/save_opening_balances.dart';
import 'package:muhasib/features/initial/domain/usecases/get_opening_balances.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Initial Setup Feature Tests', () {
    late DatabaseService databaseService;
    late InitialLocalDataSource dataSource;
    late InitialRepositoryImpl repository;
    late OpeningBalanceAccountingTemplate accountingTemplate;
    
    setUpAll(() async {
      // Setup test database
      databaseService = DatabaseService();
      await databaseService.database;
      
      // Setup shared preferences for testing
      SharedPreferences.setMockInitialValues({});
      final db = await databaseService.database;
      dataSource = InitialLocalDataSourceImpl(database: db);
      
      // Setup repository
      repository = InitialRepositoryImpl(localDataSource: dataSource);
      accountingTemplate = OpeningBalanceAccountingTemplate(databaseService);
    });
    
    tearDownAll(() async {
      await databaseService.close();
    });
    
    test('Should check initial setup status', () async {
      // Arrange
      final useCase = CheckInitialSetupStatus(repository);
      
      // Act
      final status = await useCase();
      
      // Assert
      expect(status.isComplete, false);
    });
    
    test('Should mark initial setup as complete', () async {
      // Arrange
      final markComplete = MarkInitialSetupComplete(repository);
      final checkStatus = CheckInitialSetupStatus(repository);
      
      // Act
      await markComplete();
      final status = await checkStatus();
      
      // Assert
      expect(status.isComplete, true);
    });
    
    test('Should save and retrieve opening balances', () async {
      // Arrange
      final saveBalances = SaveOpeningBalances(repository);
      final getBalances = GetOpeningBalances(repository);
      
      final testBalances = [
        OpeningBalanceEntity(
          accountId: 1,
          accountName: 'الصندوق',
          accountCode: '1001',
          debitAmount: 10000,
          creditAmount: 0,
          balance: 10000,
          currencyCode: 'SAR',
          exchangeRate: 1.0,
          statement: 'رصيد افتتاحي',
          date: DateTime.now(),
        ),
        OpeningBalanceEntity(
          accountId: 2,
          accountName: 'البنك',
          accountCode: '1002',
          debitAmount: 50000,
          creditAmount: 0,
          balance: 50000,
          currencyCode: 'SAR',
          exchangeRate: 1.0,
          statement: 'رصيد افتتاحي',
          date: DateTime.now(),
        ),
        OpeningBalanceEntity(
          accountId: 3,
          accountName: 'رأس المال',
          accountCode: '3001',
          debitAmount: 0,
          creditAmount: 60000,
          balance: -60000,
          currencyCode: 'SAR',
          exchangeRate: 1.0,
          statement: 'رصيد افتتاحي',
          date: DateTime.now(),
        ),
      ];
      
      // Act
      await saveBalances(testBalances);
      final retrievedBalances = await getBalances();
      
      // Assert
      expect(retrievedBalances.length, greaterThan(0));
    });
    
    test('Should validate opening balances are balanced', () async {
      // Arrange
      final balances = [
        OpeningBalanceEntity(
          accountId: 1,
          accountName: 'الصندوق',
          accountCode: '1001',
          debitAmount: 10000,
          creditAmount: 0,
          balance: 10000,
          date: DateTime.now(),
        ),
        OpeningBalanceEntity(
          accountId: 2,
          accountName: 'رأس المال',
          accountCode: '3001',
          debitAmount: 0,
          creditAmount: 10000,
          balance: -10000,
          date: DateTime.now(),
        ),
      ];
      
      // Act
      final isValid = accountingTemplate.validateOpeningBalances(balances);
      
      // Assert
      expect(isValid, true);
    });
    
    test('Should get opening balance status', () async {
      // Arrange & Act
      final status = await accountingTemplate.getOpeningBalanceStatus();
      
      // Assert
      expect(status, isNotNull);
      expect(status.containsKey('has_opening_balances'), true);
      expect(status.containsKey('total_debits'), true);
      expect(status.containsKey('total_credits'), true);
      expect(status.containsKey('is_balanced'), true);
    });
    
    test('Should check if has opening balances', () async {
      // Act
      final hasBalances = await repository.hasOpeningBalances();
      
      // Assert
      expect(hasBalances, isA<bool>());
    });
    
    test('Should delete opening balances', () async {
      // Arrange
      final saveBalances = SaveOpeningBalances(repository);
      final testBalance = [
        OpeningBalanceEntity(
          accountId: 1,
          accountName: 'Test Account',
          accountCode: '9999',
          debitAmount: 1000,
          creditAmount: 0,
          balance: 1000,
          date: DateTime.now(),
        ),
      ];
      
      // Act
      await saveBalances(testBalance);
      await repository.deleteOpeningBalances();
      final hasBalances = await repository.hasOpeningBalances();
      
      // Assert
      expect(hasBalances, false);
    });
    
    test('Should create journal entries for opening balances', () async {
      // Arrange
      final db = await databaseService.database;
      final testBalances = [
        OpeningBalanceEntity(
          accountId: 1,
          accountName: 'المخزون',
          accountCode: '1201',
          debitAmount: 25000,
          creditAmount: 0,
          balance: 25000,
          date: DateTime.now(),
        ),
        OpeningBalanceEntity(
          accountId: 2,
          accountName: 'الموردون',
          accountCode: '2101',
          debitAmount: 0,
          creditAmount: 25000,
          balance: -25000,
          date: DateTime.now(),
        ),
      ];
      
      // Act
      await accountingTemplate.createOpeningBalanceEntries(
        openingBalances: testBalances,
        date: DateTime.now(),
        statement: 'قيود افتتاحية للاختبار',
      );
      
      // Check journal entries were created
      final journalEntries = await db.query(
        'journal_entries',
        where: 'reference_type = ?',
        whereArgs: ['opening_balance'],
      );
      
      // Assert
      expect(journalEntries.length, greaterThan(0));
    });
  });
}
