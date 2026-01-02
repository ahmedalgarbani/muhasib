import 'package:sqflite/sqflite.dart';

/// Service to validate currency operations
class CurrencyValidationService {
  final Database database;

  CurrencyValidationService(this.database);

  /// Check if currency is the local/base currency
  Future<bool> isLocalCurrency(int currencyId) async {
    final result = await database.query(
      'currencies',
      where: 'id = ? AND is_local_currency = 1',
      whereArgs: [currencyId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Check if currency is used in invoices
  Future<int> getInvoiceCountForCurrency(int currencyId) async {
    final result = await database.rawQuery('''
      SELECT COUNT(*) as count FROM invoices WHERE currency_id = ?
    ''', [currencyId]);
    return (result.first['count'] as int?) ?? 0;
  }

  /// Check if currency is used in vouchers
  Future<int> getVoucherCountForCurrency(int currencyId) async {
    final result = await database.rawQuery('''
      SELECT COUNT(*) as count FROM vouchers WHERE currency_id = ?
    ''', [currencyId]);
    return (result.first['count'] as int?) ?? 0;
  }

  /// Check if currency is used in currency exchanges
  Future<int> getExchangeCountForCurrency(int currencyId) async {
    final result = await database.rawQuery('''
      SELECT COUNT(*) as count FROM currency_exchanges 
      WHERE credit_currency_id = ? OR debit_currency_id = ?
    ''', [currencyId, currencyId]);
    return (result.first['count'] as int?) ?? 0;
  }

  /// Check if currency is used in journal entry lines
  Future<int> getJournalLineCountForCurrency(int currencyId) async {
    final result = await database.rawQuery('''
      SELECT COUNT(*) as count FROM journal_entry_lines WHERE currency_id = ?
    ''', [currencyId]);
    return (result.first['count'] as int?) ?? 0;
  }

  /// Check if currency is used in opening entries
  Future<int> getOpeningEntryCountForCurrency(int currencyId) async {
    final result = await database.rawQuery('''
      SELECT COUNT(*) as count FROM opening_entries WHERE currency_id = ?
    ''', [currencyId]);
    return (result.first['count'] as int?) ?? 0;
  }

  /// Validate if a currency can be deleted
  /// Returns null if can be deleted, or an error message if not
  Future<String?> canDeleteCurrency(int currencyId) async {
    // Check if it's the local currency
    if (await isLocalCurrency(currencyId)) {
      return 'لا يمكن حذف العملة المحلية الأساسية';
    }

    // Check usage in invoices
    final invoiceCount = await getInvoiceCountForCurrency(currencyId);
    if (invoiceCount > 0) {
      return 'لا يمكن حذف العملة لوجود $invoiceCount فاتورة/فواتير مرتبطة بها';
    }

    // Check usage in vouchers
    final voucherCount = await getVoucherCountForCurrency(currencyId);
    if (voucherCount > 0) {
      return 'لا يمكن حذف العملة لوجود $voucherCount سند/سندات مرتبطة بها';
    }

    // Check usage in currency exchanges
    final exchangeCount = await getExchangeCountForCurrency(currencyId);
    if (exchangeCount > 0) {
      return 'لا يمكن حذف العملة لوجود $exchangeCount عملية صرف مرتبطة بها';
    }

    // Check usage in journal entries
    final journalCount = await getJournalLineCountForCurrency(currencyId);
    if (journalCount > 0) {
      return 'لا يمكن حذف العملة لوجود $journalCount قيد/قيود محاسبية مرتبطة بها';
    }

    // Check usage in opening entries
    final openingCount = await getOpeningEntryCountForCurrency(currencyId);
    if (openingCount > 0) {
      return 'لا يمكن حذف العملة لوجود $openingCount أرصدة افتتاحية مرتبطة بها';
    }

    return null; // Can be deleted
  }

  /// Validate if a currency can be modified
  /// Returns null if can be modified, or an error message if not
  Future<String?> canModifyCurrency(int currencyId, {bool isChangingLocalStatus = false}) async {
    // Prevent changing the local currency flag if it's the only local currency
    if (isChangingLocalStatus) {
      final localCurrencies = await database.query(
        'currencies',
        where: 'is_local_currency = 1',
      );
      
      if (localCurrencies.length == 1 && localCurrencies.first['id'] == currencyId) {
        return 'لا يمكن تغيير حالة العملة المحلية الوحيدة';
      }
    }

    return null; // Can be modified
  }

  /// Get total usage count for a currency
  Future<int> getTotalUsageCount(int currencyId) async {
    int total = 0;
    total += await getInvoiceCountForCurrency(currencyId);
    total += await getVoucherCountForCurrency(currencyId);
    total += await getExchangeCountForCurrency(currencyId);
    total += await getJournalLineCountForCurrency(currencyId);
    total += await getOpeningEntryCountForCurrency(currencyId);
    return total;
  }
}
