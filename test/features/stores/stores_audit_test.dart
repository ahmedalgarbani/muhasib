import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:muhasib/core/database/database_initializer_io.dart';
import 'package:muhasib/core/database/tables/table_schema.dart';
import 'package:muhasib/core/database/tables/accounts_table.dart';
import 'package:muhasib/core/database/tables/account_connects_table.dart';
import 'package:muhasib/core/database/tables/journal_entries_table.dart';
import 'package:muhasib/core/database/tables/journal_entry_lines_table.dart';
import 'package:muhasib/core/database/tables/currencies_table.dart';
import 'package:muhasib/core/database/tables/stocks_table.dart';
import 'package:muhasib/core/database/tables/stock_movements_table.dart';
import 'package:muhasib/core/database/tables/category_movs_table.dart';
import 'package:muhasib/core/database/tables/stock_transfers_table.dart';
import 'package:muhasib/core/database/tables/stock_transfer_lines_table.dart';
import 'package:muhasib/core/database/tables/stock_settlements_table.dart';
import 'package:muhasib/core/database/tables/stock_settlement_lines_table.dart';
import 'package:muhasib/core/database/tables/inventories_table.dart';
import 'package:muhasib/core/database/tables/inventory_lines_table.dart';
import 'package:muhasib/core/database/tables/seeders.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/stores/data/datasources/stock_adjustment_local_datasource.dart';
import 'package:muhasib/features/stores/data/datasources/stock_transfer_local_datasource.dart';
import 'package:muhasib/features/stores/data/datasources/inventory_local_datasource.dart';
import 'package:muhasib/features/stores/data/models/stock_adjustment_model.dart';
import 'package:muhasib/features/stores/data/models/stock_transfer_model.dart';
import 'package:muhasib/features/stores/data/models/inventory_model.dart';
import 'package:muhasib/features/stores/domain/entities/stock_adjustment_entity.dart';
import 'package:muhasib/features/stores/domain/entities/stock_transfer_entity.dart';
import 'package:muhasib/features/stores/domain/entities/inventory_entity.dart';
import 'package:muhasib/features/stores/domain/entities/inventory_line_entity.dart';
import 'package:muhasib/features/stores/domain/enums/stock_enums.dart';

class TestDatabaseService implements DatabaseService {
  final Database _testDb;
  TestDatabaseService(this._testDb);

  @override
  Future<Database> get database async => _testDb;

  @override
  Future<void> close() async {
    await _testDb.close();
  }
}

Future<Database> createFreshTestDatabase() async {
  initializeDatabaseFactory();
  final tables = <TableSchema>[
    CurrenciesTable(),
    AccountsTable(),
    AccountConnectsTable(),
    JournalEntriesTable(),
    JournalEntryLinesTable(),
    StocksTable(),
    StockMovementsTable(),
    WarehouseStocksTable(),
    CategoryMovsTable(),
    StockTransfersTable(),
    StockTransferLinesTable(),
    StockSettlementsTable(),
    StockSettlementLinesTable(),
    InventoriesTable(),
    InventoryLinesTable(),
  ];

  final db = await openDatabase(
    inMemoryDatabasePath,
    version: 1,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = OFF');
    },
    onCreate: (db, version) async {
      for (final table in tables) {
        await db.execute(table.createTable);
        for (final index in table.indexes) {
          try {
            await db.execute(index);
          } catch (_) {}
        }
      }

      await seedDefaultStocks(db);
      await seedDefaultAccounts(db);

      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      // Warehouse #2 for transfers
      await db.insert('stocks', {
        'name': 'المخزن الفرعي',
        'address': 'فرع',
        'is_main_stock': 0,
        'is_active': 1,
        'creation_time': nowSec,
        'last_modification_time': nowSec,
      });
      // Initial stock: product 1 → 10 units @ 50 in warehouse 1
      await db.insert('warehouse_stocks', {
        'product_id': 1,
        'warehouse_id': 1,
        'quantity': 10,
        'avg_cost': 50,
        'last_cost': 50,
        'creation_time': nowSec,
        'last_modification_time': nowSec,
      });
    },
  );

  return db;
}

Future<Map<String, dynamic>> findJournal(
  Database db,
  String referenceType,
  int referenceId,
) async {
  final entries = await db.query(
    'journal_entries',
    where: 'reference_type = ? AND reference_id = ?',
    whereArgs: [referenceType, referenceId],
  );
  expect(entries.length, 1, reason: 'يجب وجود قيد واحد لـ $referenceType/$referenceId');
  return entries.first;
}

void main() {
  setUpAll(() {
    initializeDatabaseFactory();
  });

  late Database db;
  late StockAdjustmentLocalDataSourceImpl adjustmentDs;
  late StockTransferLocalDataSourceImpl transferDs;
  late InventoryLocalDataSourceImpl inventoryDs;

  setUp(() async {
    db = await createFreshTestDatabase();
    adjustmentDs = StockAdjustmentLocalDataSourceImpl(
      databaseService: TestDatabaseService(db),
    );
    transferDs = StockTransferLocalDataSourceImpl(database: db);
    inventoryDs = InventoryLocalDataSourceImpl(database: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('التسوية المخزنية', () {
    test('زيادة مخزون → قيد متوازن (مدين مخزون / دائن إيرادات تسوية) + مزج متوسط التكلفة', () async {
      final adjustment = StockAdjustmentModel.fromEntity(
        StockAdjustmentEntity(
          number: 'ADJ-1',
          date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          type: AdjustmentType.increase,
          currencyId: 1,
          statement: 'تسوية زيادة',
          status: TransferStatus.draft,
          stockId: 1,
          lines: [
            StockAdjustmentLineEntity(
              categoryId: 1,
              groupId: 1,
              unitId: 1,
              categorySubUnitId: 1,
              quantity: 4,
              statement: 'منتج',
              amount: 100, // تكلفة وحدة
              totalAmount: 400,
              currencyId: 1,
              stockId: 1,
            ),
          ],
        ),
      );

      final id = await adjustmentDs.createAdjustment(adjustment);
      await adjustmentDs.postAdjustment(id);

      final journal = await findJournal(db, 'stock_adjustment', id);
      expect(journal['is_posted'], 1);
      expect(journal['status'], 2);
      expect(
        (journal['total_debit'] as num).toDouble(),
        closeTo((journal['total_credit'] as num).toDouble(), 0.01),
      );
      expect((journal['total_debit'] as num).toDouble(), closeTo(400, 0.01));

      // خطوط القيد: المخزون مدين 400، إيرادات التسوية دائن 400
      final lines = await db.query(
        'journal_entry_lines',
        where: 'journal_entry_id = ?',
        whereArgs: [journal['id']],
      );
      expect(lines.length, 2);
      final inventoryLine = lines.firstWhere(
        (l) => (l['account_code'] as String) == '1003',
      );
      expect((inventoryLine['debit_amount'] as num).toDouble(), closeTo(400, 0.01));
      final incomeLine = lines.firstWhere(
        (l) => (l['account_code'] as String) == '4200',
      );
      expect((incomeLine['credit_amount'] as num).toDouble(), closeTo(400, 0.01));

      // المخزون: 10 + 4 = 14، متوسط التكلفة = (10*50 + 4*100)/14
      final stock = await db.query(
        'warehouse_stocks',
        where: 'product_id = ? AND warehouse_id = ?',
        whereArgs: [1, 1],
      );
      expect((stock.first['quantity'] as num).toDouble(), closeTo(14, 0.01));
      expect((stock.first['avg_cost'] as num).toDouble(), closeTo(64.2857, 0.1));

      // أرصدة الحسابات تحدثت
      final inventoryAccount = await db.query(
        'accounts',
        where: 'code = ?',
        whereArgs: ['1003'],
      );
      expect((inventoryAccount.first['balance'] as num).toDouble(), closeTo(400, 0.01));

      // ترحيل مزدوج ممنوع
      expect(() => adjustmentDs.postAdjustment(id), throwsException);
    });

    test('نقص مخزون → مدين خسائر تسوية (5200) بتكلفة المتوسط / دائن المخزون', () async {
      final adjustment = StockAdjustmentModel.fromEntity(
        StockAdjustmentEntity(
          number: 'ADJ-2',
          date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          type: AdjustmentType.decrease,
          currencyId: 1,
          statement: 'تسوية نقص',
          status: TransferStatus.draft,
          stockId: 1,
          lines: [
            StockAdjustmentLineEntity(
              categoryId: 1,
              groupId: 1,
              unitId: 1,
              categorySubUnitId: 1,
              quantity: 2,
              statement: 'منتج',
              amount: 0, // يُهمل — يُستخدم متوسط التكلفة
              totalAmount: 0,
              currencyId: 1,
              stockId: 1,
            ),
          ],
        ),
      );

      final id = await adjustmentDs.createAdjustment(adjustment);
      await adjustmentDs.postAdjustment(id);

      final journal = await findJournal(db, 'stock_adjustment', id);
      // القيمة = 2 * متوسط التكلفة 50 = 100
      expect((journal['total_debit'] as num).toDouble(), closeTo(100, 0.01));

      final lossAccount = await db.query(
        'accounts',
        where: 'code = ?',
        whereArgs: ['5200'],
      );
      expect((lossAccount.first['balance'] as num).toDouble(), closeTo(100, 0.01));

      final stock = await db.query(
        'warehouse_stocks',
        where: 'product_id = ? AND warehouse_id = ?',
        whereArgs: [1, 1],
      );
      expect((stock.first['quantity'] as num).toDouble(), closeTo(8, 0.01));
    });
  });

  group('التحويل بين المخازن', () {
    test('تحويل مكتمل → خصم من المصدر وإضافة للوجهة مع حركات صحيحة', () async {
      final transfer = StockTransferModel.fromEntity(
        StockTransferEntity(
          number: 'TRF-1',
          date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          statement: 'تحويل',
          status: TransferStatus.draft,
          fromStockId: 1,
          toStockId: 2,
          lines: [
            StockTransferLineEntity(
              quantity: 3,
              statement: 'منتج',
              costAmount: 50,
              categoryId: 1,
              groupId: 1,
              unitId: 1,
              categorySubUnitId: 1,
            ),
          ],
        ),
      );

      final id = await transferDs.createTransfer(transfer);

      // الأسطر مرتبطة بالتحويل
      final lines = await db.query(
        'stock_transfer_lines',
        where: 'stock_transfer_id = ?',
        whereArgs: [id],
      );
      expect(lines.length, 1);

      await transferDs.updateTransferStatus(id, 'completed');

      final source = await db.query(
        'warehouse_stocks',
        where: 'product_id = ? AND warehouse_id = ?',
        whereArgs: [1, 1],
      );
      expect((source.first['quantity'] as num).toDouble(), closeTo(7, 0.01));

      final dest = await db.query(
        'warehouse_stocks',
        where: 'product_id = ? AND warehouse_id = ?',
        whereArgs: [1, 2],
      );
      expect((dest.first['quantity'] as num).toDouble(), closeTo(3, 0.01));
      expect((dest.first['avg_cost'] as num).toDouble(), closeTo(50, 0.01));

      // إعادة الإكمال ممنوعة
      expect(
        () => transferDs.updateTransferStatus(id, 'completed'),
        throwsException,
      );
    });

    test('كمية أكبر من المتاح → رفض', () async {
      final transfer = StockTransferModel.fromEntity(
        StockTransferEntity(
          number: 'TRF-2',
          date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          statement: 'تحويل',
          status: TransferStatus.draft,
          fromStockId: 1,
          toStockId: 2,
          lines: [
            StockTransferLineEntity(
              quantity: 999,
              statement: 'منتج',
              costAmount: 50,
              categoryId: 1,
              groupId: 1,
              unitId: 1,
              categorySubUnitId: 1,
            ),
          ],
        ),
      );

      final id = await transferDs.createTransfer(transfer);
      expect(
        () => transferDs.updateTransferStatus(id, 'completed'),
        throwsException,
      );
    });
  });

  group('جرد المخزون', () {
    test('ترحيل جرد بفروقات → تسويات + قيود متوازنة + حذف مرحل يعكس كل شيء', () async {
      final inventory = InventoryModel.fromEntity(
        InventoryEntity(
          number: 'INV-1',
          date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          statement: 'جرد',
          inventoryType: InventoryType.spot,
          status: TransferStatus.draft,
          stockId: 1,
          lines: [
            InventoryLineEntity(
              statement: 'منتج',
              quantity: 10,
              actualQuantity: 12, // زيادة 2
              difference: 2,
              costAmount: 50,
              categoryId: 1,
              groupId: 1,
              unitId: 1,
              categorySubUnitId: 1,
              inventoryId: 0,
            ),
          ],
        ),
      );

      final id = await inventoryDs.createInventory(inventory);
      await inventoryDs.postInventory(id);

      // الكمية الفعلية أصبحت 12
      final stock = await db.query(
        'warehouse_stocks',
        where: 'product_id = ? AND warehouse_id = ?',
        whereArgs: [1, 1],
      );
      expect((stock.first['quantity'] as num).toDouble(), closeTo(12, 0.01));

      // قيد الزيادة: 2 * 50 = 100
      final journal = await findJournal(db, 'inventory', id);
      expect((journal['total_debit'] as num).toDouble(), closeTo(100, 0.01));
      expect(journal['is_posted'], 1);

      // إعادة الترحيل ممنوعة
      expect(() => inventoryDs.postInventory(id), throwsException);

      // حذف الجرد المرحّل يعكس القيد والمخزون والتسويات
      await inventoryDs.deleteInventory(id);

      final stockAfter = await db.query(
        'warehouse_stocks',
        where: 'product_id = ? AND warehouse_id = ?',
        whereArgs: [1, 1],
      );
      expect((stockAfter.first['quantity'] as num).toDouble(), closeTo(10, 0.01));

      final remainingEntries = await db.query(
        'journal_entries',
        where: 'reference_type = ? AND reference_id = ?',
        whereArgs: ['inventory', id],
      );
      expect(remainingEntries, isEmpty);

      final remainingSettlements = await db.query(
        'stock_settlements',
        where: 'parent_id = ? AND settlement_reason = ?',
        whereArgs: [id, 'inventory'],
      );
      expect(remainingSettlements, isEmpty);

      // رصيد المخزون رجع صفر
      final inventoryAccount = await db.query(
        'accounts',
        where: 'code = ?',
        whereArgs: ['1003'],
      );
      expect((inventoryAccount.first['balance'] as num).toDouble(), closeTo(0, 0.01));
    });
  });
}
