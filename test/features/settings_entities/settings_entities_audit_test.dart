import 'package:flutter_test/flutter_test.dart';
import 'package:muhasib/core/database/tables/banks_table.dart';
import 'package:muhasib/core/database/tables/funds_table.dart';
import 'package:muhasib/core/database/tables/other_tools_table.dart';
import 'package:muhasib/core/database/tables/regions_table.dart';
import 'package:muhasib/core/database/tables/accounts_table.dart';
import 'package:muhasib/core/database/tables/currencies_table.dart';
import 'package:muhasib/features/settings_entities/data/datasources/bank_local_datasource.dart';
import 'package:muhasib/features/settings_entities/data/datasources/cashbox_local_datasource.dart';
import 'package:muhasib/features/settings_entities/data/datasources/other_fee_local_datasource.dart';
import 'package:muhasib/features/settings_entities/data/datasources/region_local_datasource.dart';
import 'package:muhasib/features/settings_entities/data/models/bank_model.dart';
import 'package:muhasib/features/settings_entities/data/models/cashbox_model.dart';
import 'package:muhasib/features/settings_entities/data/models/other_fee_model.dart';
import 'package:muhasib/features/settings_entities/data/models/region_model.dart';
import 'package:muhasib/features/settings_entities/data/repositories/bank_repository_impl.dart';
import 'package:muhasib/features/settings_entities/data/repositories/cashbox_repository_impl.dart';
import 'package:muhasib/features/settings_entities/data/repositories/other_fee_repository_impl.dart';
import 'package:muhasib/features/settings_entities/data/repositories/region_repository_impl.dart';
import 'package:muhasib/features/settings_entities/domain/entities/bank_entity.dart';
import 'package:muhasib/features/settings_entities/domain/entities/cashbox_entity.dart';
import 'package:muhasib/features/settings_entities/domain/entities/other_fee_entity.dart';
import 'package:muhasib/features/settings_entities/domain/entities/region_entity.dart';
import 'package:muhasib/features/settings_entities/presentation/cubit/banks_cubit.dart';
import 'package:muhasib/features/settings_entities/presentation/cubit/cashboxes_cubit.dart';
import 'package:muhasib/features/settings_entities/presentation/cubit/other_fees_cubit.dart';
import 'package:muhasib/features/settings_entities/presentation/cubit/regions_cubit.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);

    // Create required tables
    await db.execute(AccountsTable().createTable);
    await db.execute(CurrenciesTable().createTable);
    await db.execute(BanksTable().createTable);
    await db.execute(FundsTable().createTable);
    await db.execute(OtherToolsTable().createTable);
    await db.execute(RegionsTable().createTable);

    // Insert dummy currency & account for foreign key integrity
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await db.insert('currencies', {
      'id': 1,
      'name': 'ريال يمني',
      'code': 'YER',
      'symbol': 'ر.ي',
      'min_exchange_rate': 1.0,
      'max_exchange_rate': 1.0,
      'exchange_rate': 1.0,
      'is_local_currency': 1,
      'is_active': 1,
      'decimal_places': 2,
      'creation_time': now,
      'last_modification_time': now,
    });

    await db.insert('accounts', {
      'id': 1,
      'c_id': 1110,
      'code': '1001',
      'name': 'النقدية والبنوك',
      'is_master': 1,
      'type': 1,
      'national': 1,
      'is_active': 1,
      'allow_update_delete': 0,
      'balance': 0.0,
      'local_balance': 0.0,
      'creation_time': now,
      'last_modification_time': now,
    });
  });

  tearDown(() async {
    await db.close();
  });

  group('Banks - Local DataSource & Repository & Cubit Audit', () {
    test('Bank CRUD operations & Search & Active filtering', () async {
      final dataSource = BankLocalDataSourceImpl(database: db);
      final repo = BankRepositoryImpl(dataSource);
      final cubit = BanksCubit(repo);

      // 1. Create Bank 1 (Active)
      final bank1 = const BankEntity(
        name: 'بنك الكريمي',
        contact: '777000111',
        contactType: 0,
        bankCode: 'KRE',
        branchName: 'فرع حدة',
        accountNumber: '12345678',
        isActive: true,
        accountId: 1,
      );
      final createRes1 = await repo.createBank(bank1);
      expect(createRes1.isRight(), true);
      final bank1Id = createRes1.getOrElse(() => 0);
      expect(bank1Id, isNonZero);

      // 2. Create Bank 2 (Inactive)
      final bank2 = const BankEntity(
        name: 'بنك التضامن',
        contact: '777222333',
        contactType: 0,
        bankCode: 'TDB',
        branchName: 'فرع الزبيري',
        accountNumber: '87654321',
        isActive: false,
      );
      final createRes2 = await repo.createBank(bank2);
      expect(createRes2.isRight(), true);

      // 3. Get All Banks
      final allBanksRes = await repo.getBanks();
      expect(allBanksRes.isRight(), true);
      allBanksRes.fold((f) => fail(f.message), (banks) {
        expect(banks.length, 2);
      });

      // 4. Get Active Banks Only
      final activeBanksRes = await repo.getActiveBanks();
      expect(activeBanksRes.isRight(), true);
      activeBanksRes.fold((f) => fail(f.message), (banks) {
        expect(banks.length, 1);
        expect(banks.first.name, 'بنك الكريمي');
      });

      // 5. Search Banks by Name and Branch
      final searchRes1 = await repo.searchBanks('الكريمي');
      expect(searchRes1.isRight(), true);
      searchRes1.fold((f) => fail(f.message), (banks) {
        expect(banks.length, 1);
      });

      final searchRes2 = await repo.searchBanks('الزبيري');
      expect(searchRes2.isRight(), true);
      searchRes2.fold((f) => fail(f.message), (banks) {
        expect(banks.length, 1);
        expect(banks.first.name, 'بنك التضامن');
      });

      // 6. Update Bank (and verify clearing nullable branch name)
      final updatedBank = BankEntity(
        id: bank1Id,
        name: 'بنك الكريمي الإسلامي',
        contact: bank1.contact,
        contactType: bank1.contactType,
        branchName: null, // Cleared
        bankCode: 'KRE-NEW',
        isActive: true,
      );
      final updateRes = await repo.updateBank(updatedBank);
      expect(updateRes.isRight(), true);

      final getByIdRes = await repo.getBankById(bank1Id);
      expect(getByIdRes.isRight(), true);
      getByIdRes.fold((f) => fail(f.message), (b) {
        expect(b.name, 'بنك الكريمي الإسلامي');
        expect(b.branchName, isNull);
        expect(b.bankCode, 'KRE-NEW');
      });

      // 7. Cubit flow
      await cubit.loadBanks();
      expect(cubit.state, isA<BanksLoaded>());
      expect((cubit.state as BanksLoaded).banks.length, 2);

      // 8. Delete Bank
      final deleteRes = await repo.deleteBank(bank1Id);
      expect(deleteRes.isRight(), true);

      final remainingBanks = await repo.getBanks();
      remainingBanks.fold((f) => fail(f.message), (banks) {
        expect(banks.length, 1);
      });
    });
  });

  group('Cashboxes (Funds) - Local DataSource & Repository & Cubit Audit', () {
    test('Cashbox CRUD & Main Cashbox Invariant on insert & update', () async {
      final dataSource = CashboxLocalDataSourceImpl(database: db);
      final repo = CashboxRepositoryImpl(dataSource);
      final cubit = CashboxesCubit(repo);

      // 1. Create Main Cashbox
      final box1 = const CashboxEntity(
        name: 'الصندوق الرئيسي',
        isActive: true,
        isMainFund: true,
        currentBalance: 50000.0,
        currencyId: 1,
        accountId: 1,
      );
      final res1 = await repo.createCashbox(box1);
      expect(res1.isRight(), true);
      final box1Id = res1.getOrElse(() => 0);

      // 2. Create Branch Cashbox with isMainFund = true (should automatically unset box1)
      final box2 = const CashboxEntity(
        name: 'صندوق فرع 1',
        isActive: true,
        isMainFund: true,
        currentBalance: 10000.0,
      );
      final res2 = await repo.createCashbox(box2);
      expect(res2.isRight(), true);
      final box2Id = res2.getOrElse(() => 0);

      // 3. Verify only box2 is now main fund
      final mainRes = await repo.getMainCashbox();
      expect(mainRes.isRight(), true);
      mainRes.fold((f) => fail(f.message), (box) {
        expect(box, isNotNull);
        expect(box!.id, box2Id);
        expect(box.name, 'صندوق فرع 1');
      });

      final oldBox1Res = await repo.getCashboxById(box1Id);
      oldBox1Res.fold((f) => fail(f.message), (box) {
        expect(box.isMainFund, false);
      });

      // 4. Update box1 back to isMainFund = true
      final updateBox1 = (await repo.getCashboxById(box1Id)).getOrElse(() => box1).copyWith(
        isMainFund: true,
      );
      await repo.updateCashbox(updateBox1);

      // Verify box1 is main and box2 is not
      final newMain = (await repo.getMainCashbox()).getOrElse(() => null);
      expect(newMain?.id, box1Id);

      final box2Check = (await repo.getCashboxById(box2Id)).getOrElse(() => box2);
      expect(box2Check.isMainFund, false);

      // 5. Cubit tests
      await cubit.loadCashboxes();
      expect(cubit.state, isA<CashboxesLoaded>());
      expect((cubit.state as CashboxesLoaded).cashboxes.length, 2);
    });
  });

  group('Other Fees (Other Tools) - Audit', () {
    test('Other fees CRUD & Tool Type segregation Audit', () async {
      final dataSource = OtherFeeLocalDataSourceImpl(database: db);
      final repo = OtherFeeRepositoryImpl(dataSource);
      final cubit = OtherFeesCubit(repo);

      // 1. Create Expense Fee (toolType: 0)
      final fee1 = const OtherFeeEntity(
        name: 'أجور نقل وشحن',
        isActive: true,
        toolType: 0, // Expense
        accountId: 1,
      );
      final res1 = await repo.createOtherFee(fee1);
      expect(res1.isRight(), true);
      final fee1Id = res1.getOrElse(() => 0);

      // 2. Create Revenue Fee (toolType: 1)
      final fee2 = const OtherFeeEntity(
        name: 'خدمة توصيل سريع',
        isActive: true,
        toolType: 1, // Revenue
      );
      final res2 = await repo.createOtherFee(fee2);
      expect(res2.isRight(), true);

      // 3. Get by Type
      final expenseFeesRes = await repo.getOtherFeesByType(0);
      expenseFeesRes.fold((f) => fail(f.message), (fees) {
        expect(fees.length, 1);
        expect(fees.first.name, 'أجور نقل وشحن');
      });

      final revenueFeesRes = await repo.getOtherFeesByType(1);
      revenueFeesRes.fold((f) => fail(f.message), (fees) {
        expect(fees.length, 1);
        expect(fees.first.name, 'خدمة توصيل سريع');
      });

      // 4. Update
      final updated = fee1.copyWith(id: fee1Id, name: 'رسوم شحن وتغليف');
      await repo.updateOtherFee(updated);

      final fetched = await repo.getOtherFeeById(fee1Id);
      fetched.fold((f) => fail(f.message), (f) {
        expect(f.name, 'رسوم شحن وتغليف');
      });

      // 5. Delete
      await repo.deleteOtherFee(fee1Id);
      final all = await repo.getOtherFees();
      all.fold((f) => fail(f.message), (fees) {
        expect(fees.length, 1);
      });
    });
  });

  group('Regions - Audit', () {
    test('Regions CRUD & Search & Hierarchy Audit', () async {
      final dataSource = RegionLocalDataSourceImpl(database: db);
      final repo = RegionRepositoryImpl(dataSource);
      final cubit = RegionsCubit(repo);

      // 1. Create Country/Parent Region
      final r1 = const RegionEntity(
        name: 'صنعاء',
        code: 'SAN',
        country: 'اليمن',
        description: 'أمانة العاصمة',
        isActive: true,
      );
      final res1 = await repo.createRegion(r1);
      expect(res1.isRight(), true);
      final r1Id = res1.getOrElse(() => 0);

      // 2. Create Sub-region
      final r2 = RegionEntity(
        name: 'حدة',
        code: 'SAN-HDD',
        country: 'اليمن',
        parentRegionId: r1Id,
        isActive: true,
      );
      final res2 = await repo.createRegion(r2);
      expect(res2.isRight(), true);

      // 3. Search by Code ('SAN') - matches both SAN and SAN-HDD
      final searchRes = await repo.searchRegions('SAN');
      searchRes.fold((f) => fail(f.message), (regions) {
        expect(regions.length, 2);
      });

      // 4. Search by Name ('حدة')
      final searchNameRes = await repo.searchRegions('حدة');
      searchNameRes.fold((f) => fail(f.message), (regions) {
        expect(regions.length, 1);
        expect(regions.first.name, 'حدة');
      });

      // 5. Delete
      await repo.deleteRegion(r1Id);
      final all = await repo.getRegions();
      all.fold((f) => fail(f.message), (r) {
        expect(r.length, 1);
      });
    });
  });
}
