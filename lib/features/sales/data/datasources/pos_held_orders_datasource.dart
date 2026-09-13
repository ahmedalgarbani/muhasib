import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:muhasib/core/services/database_service.dart';

class HeldOrderItem {
  final int productId;
  final String name;
  final double quantity;
  final double unitPrice;
  final double discount;
  final int? unitId;
  final int? subUnitId;

  const HeldOrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0,
    this.unitId,
    this.subUnitId,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'discount': discount,
        'unitId': unitId,
        'subUnitId': subUnitId,
      };

  factory HeldOrderItem.fromJson(Map<String, dynamic> json) => HeldOrderItem(
        productId: (json['productId'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        discount: (json['discount'] as num?)?.toDouble() ?? 0,
        unitId: (json['unitId'] as num?)?.toInt(),
        subUnitId: (json['subUnitId'] as num?)?.toInt(),
      );
}

class HeldOrder {
  final int? id;
  final DateTime createdAt;
  final int? customerId;
  final String? customerName;
  final String? note;
  final List<HeldOrderItem> items;

  const HeldOrder({
    this.id,
    required this.createdAt,
    this.customerId,
    this.customerName,
    this.note,
    required this.items,
  });

  double get total => items.fold(
        0.0,
        (sum, item) => sum + item.unitPrice * item.quantity - item.discount,
      );

  int get itemCount => items.length;
}

class PosHeldOrdersDataSource {
  final DatabaseService _databaseService;

  PosHeldOrdersDataSource(this._databaseService);

  Future<Database> get _db async {
    final db = await _databaseService.database;
    await _ensureTable(db);
    return db;
  }

  /// Safety net for databases created before this table existed.
  Future<void> _ensureTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_held_orders (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        creator_id INTEGER NULL DEFAULT 1,
        creation_time INTEGER NOT NULL,
        last_modification_time INTEGER NOT NULL,
        customer_id INTEGER NULL,
        customer_name TEXT NULL,
        note TEXT NULL,
        items_json TEXT NOT NULL
      )
    ''');
  }

  Future<int> insert({
    int? customerId,
    String? customerName,
    String? note,
    required List<HeldOrderItem> items,
  }) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.insert('pos_held_orders', {
      'creation_time': now,
      'last_modification_time': now,
      'customer_id': customerId,
      'customer_name': customerName,
      'note': note,
      'items_json': jsonEncode(items.map((e) => e.toJson()).toList()),
    });
  }

  Future<List<HeldOrder>> getAll() async {
    final db = await _db;
    final rows = await db.query(
      'pos_held_orders',
      orderBy: 'creation_time DESC',
    );
    return rows.map((row) {
      final items = <HeldOrderItem>[];
      try {
        final decoded = jsonDecode(row['items_json'] as String) as List;
        for (final item in decoded) {
          items.add(HeldOrderItem.fromJson(Map<String, dynamic>.from(item)));
        }
      } catch (_) {}
      return HeldOrder(
        id: row['id'] as int?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (row['creation_time'] as num).toInt(),
        ),
        customerId: row['customer_id'] as int?,
        customerName: row['customer_name'] as String?,
        note: row['note'] as String?,
        items: items,
      );
    }).toList();
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('pos_held_orders', where: 'id = ?', whereArgs: [id]);
  }
}
