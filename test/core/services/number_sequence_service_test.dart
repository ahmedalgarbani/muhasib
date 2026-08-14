import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:muhasib/core/services/number_sequence_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late NumberSequenceService service;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    service = NumberSequenceService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('NumberSequenceService Self-Healing & Sequences Tests', () {
    test(
      'getNextNumber auto-creates table and generates sequential invoice numbers',
      () async {
        final inv1 = await service.getNextNumber('sales_invoice');
        expect(inv1, equals('INV-000001'));

        final inv2 = await service.getNextNumber('sales_invoice');
        expect(inv2, equals('INV-000002'));

        final current = await service.getCurrentNumber('sales_invoice');
        expect(current, equals('INV-000002'));

        final val = await service.getCurrentValue('sales_invoice');
        expect(val, equals(2));
      },
    );

    test('getNextNumber works for multiple sequence types', () async {
      final pinv = await service.getNextNumber('purchase_invoice');
      expect(pinv, equals('PINV-000001'));

      final je = await service.getNextNumber('journal_entry');
      expect(je, equals('JE-000001'));

      final rv = await service.getNextNumber('receipt_voucher');
      expect(rv, equals('RV-000001'));

      final pv = await service.getNextNumber('payment_voucher');
      expect(pv, equals('PV-000001'));
    });
  });
}
