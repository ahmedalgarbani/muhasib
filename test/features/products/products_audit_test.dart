import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:muhasib/core/database/database_initializer_io.dart';
import 'package:muhasib/core/database/tables/table_schema.dart';
import 'package:muhasib/core/database/tables/accounts_table.dart';
import 'package:muhasib/core/database/tables/account_connects_table.dart';
import 'package:muhasib/core/database/tables/journal_entries_table.dart';
import 'package:muhasib/core/database/tables/journal_entry_lines_table.dart';
import 'package:muhasib/core/database/tables/stocks_table.dart';
import 'package:muhasib/core/database/tables/categories_table.dart';
import 'package:muhasib/core/database/tables/stock_movements_table.dart';
import 'package:muhasib/core/database/tables/invoice_lines_table.dart';
import 'package:muhasib/core/database/tables/seeders.dart';
import 'package:muhasib/features/products/data/datasources/product_local_datasource.dart';
import 'package:muhasib/features/products/data/models/product_model.dart';
import 'package:muhasib/features/products/domain/entities/product_entity.dart';

Future<Database> createFreshTestDatabase() async {
  initializeDatabaseFactory();
  final tables = <TableSchema>[
    AccountsTable(),
    AccountConnectsTable(),
    JournalEntriesTable(),
    JournalEntryLinesTable(),
    StocksTable(),
    CategoriesTable(),
    WarehouseStocksTable(),
    StockMovementsTable(),
    InvoiceLinesTable(),
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
    },
  );
  return db;
}

ProductModel buildProduct({
  int? id,
  String barcode = 'TEST-001',
  double quantity = 0,
  double cost = 50,
}) {
  return ProductModel(
    id: id,
    name: 'منتج اختبار',
    statement: 'وصف',
    barcodeNo: barcode,
    costAmount: cost,
    sellAmount: 100,
    quantity: quantity,
    groupId: null,
    unitId: null,
    stockId: 1,
  );
}

void main() {
  setUpAll(() {
    initializeDatabaseFactory();
  });

  late Database db;
  late ProductLocalDataSourceImpl dataSource;

  setUp(() async {
    db = await createFreshTestDatabase();
    dataSource = ProductLocalDataSourceImpl(database: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('منتج بكمية افتتاحية → صف مخزون + حركة + قيد افتتاحي متوازن', () async {
    final id = await dataSource.insertProduct(
      buildProduct(quantity: 5, cost: 50),
    );

    // صف المخزون
    final stock = await db.query(
      'warehouse_stocks',
      where: 'product_id = ? AND warehouse_id = ?',
      whereArgs: [id, 1],
    );
    expect(stock.length, 1);
    expect((stock.first['quantity'] as num).toDouble(), closeTo(5, 0.01));
    expect((stock.first['avg_cost'] as num).toDouble(), closeTo(50, 0.01));

    // حركة مخزون
    final movements = await db.query(
      'stock_movements',
      where: 'reference_type = ? AND reference_id = ?',
      whereArgs: ['product_creation', id],
    );
    expect(movements.length, 1);

    // قيد افتتاحي: مدين مخزون 250 / دائن أرصدة افتتاحية 250
    final entries = await db.query(
      'journal_entries',
      where: 'reference_type = ? AND reference_id = ?',
      whereArgs: ['opening_balance', id],
    );
    expect(entries.length, 1);
    final entry = entries.first;
    expect(entry['is_posted'], 1);
    expect(
      (entry['total_debit'] as num).toDouble(),
      closeTo((entry['total_credit'] as num).toDouble(), 0.01),
    );
    expect((entry['total_debit'] as num).toDouble(), closeTo(250, 0.01));

    // أرصدة الحسابات
    final inventoryAccount = await db.query(
      'accounts',
      where: 'code = ?',
      whereArgs: ['1003'],
    );
    expect((inventoryAccount.first['balance'] as num).toDouble(), closeTo(250, 0.01));
    final obAccount = await db.query(
      'accounts',
      where: 'code = ?',
      whereArgs: ['3100'],
    );
    expect((obAccount.first['balance'] as num).toDouble(), closeTo(-250, 0.01));
  });

  test('الكمية المعروضة تعكس رصيد المخزن الفعلي وليس حقل المنتج القديم', () async {
    final id = await dataSource.insertProduct(buildProduct(quantity: 2, cost: 50));

    // محاكاة عملية بيع: خصم وحدة من المخزن بدون لمس categories.quantity
    await db.update(
      'warehouse_stocks',
      {'quantity': 1},
      where: 'product_id = ? AND warehouse_id = ?',
      whereArgs: [id, 1],
    );

    final products = await dataSource.getProducts();
    expect(products.first.quantity, closeTo(1, 0.01));

    final single = await dataSource.getProductById(id);
    expect(single.quantity, closeTo(1, 0.01));
  });

  test('تعديل المنتج لا يغير كمية المخزون', () async {
    final id = await dataSource.insertProduct(buildProduct(quantity: 5, cost: 50));

    // النموذج يرسل quantity قديمة خاطئة (كما في السلوك القديم) — يجب تجاهلها
    final updated = buildProduct(id: id, quantity: 999, cost: 60);
    await dataSource.updateProduct(updated);

    final stock = await db.query(
      'warehouse_stocks',
      where: 'product_id = ? AND warehouse_id = ?',
      whereArgs: [id, 1],
    );
    expect((stock.first['quantity'] as num).toDouble(), closeTo(5, 0.01));

    // التكلفة تحدثت
    final product = await dataSource.getProductById(id);
    expect(product.costAmount, closeTo(60, 0.01));
  });

  test('حذف منتج بكمية في المخزن مرفوض', () async {
    final id = await dataSource.insertProduct(buildProduct(quantity: 3, cost: 50));

    expect(() => dataSource.deleteProduct(id), throwsException);

    // بعد تصفير الكمية يُحذف (soft delete)
    await db.update(
      'warehouse_stocks',
      {'quantity': 0},
      where: 'product_id = ?',
      whereArgs: [id],
    );
    await dataSource.deleteProduct(id);
    final deleted = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    expect(deleted.first['is_deleted'], 1);
  });

  test('حذف منتج مستخدم في فواتير مرفوض', () async {
    final id = await dataSource.insertProduct(buildProduct(quantity: 0));

    await db.insert('invoice_lines', {
      'invoice_id': 1,
      'category_id': id,
      'quantity': 1,
    });

    expect(() => dataSource.deleteProduct(id), throwsException);
  });
}
