import 'package:flutter_test/flutter_test.dart';
import 'package:muhasib/features/accounts/domain/entities/account_entity.dart';
import 'package:muhasib/features/accounts/presentation/pages/voucher_form_page.dart';

void main() {
  group('AccountSelectorSheet Classification & Filtering Tests', () {
    final cashAccount = const AccountEntity(
      id: 1,
      cId: 111001,
      code: '100101',
      name: 'الخزينة الرئيسية',
      masterCId: 1110,
      type: 1,
      national: 1,
      statement: 'صندوق الفرع الرئيسي',
    );

    final bankAccount = const AccountEntity(
      id: 2,
      cId: 111002,
      code: '100102',
      name: 'الكريمي إسلامي',
      masterCId: 1110,
      type: 1,
      national: 1,
      statement: 'حساب بنكي الكريمي',
    );

    final customerAccount = const AccountEntity(
      id: 3,
      cId: 112001,
      code: '112001',
      name: 'أحمد صالح محمد', // Does not contain the word 'عميل' in name
      masterCId: 1120,
      type: 1,
      national: 1,
      statement: 'حساب العميل: أحمد صالح محمد',
    );

    final supplierAccount = const AccountEntity(
      id: 4,
      cId: 211001,
      code: '211001',
      name: 'مؤسسة البركة للتجارة', // Does not contain the word 'مورد' in name
      masterCId: 2110,
      type: 2,
      national: 1,
      statement: 'حساب المورد: مؤسسة البركة للتجارة',
    );

    final expenseAccount = const AccountEntity(
      id: 5,
      cId: 3130,
      code: '3003',
      name: 'مصاريف إدارية وعمومية',
      masterCId: 3000,
      type: 3,
      national: 1,
      statement: 'قائمة الدخل',
    );

    final revenueAccount = const AccountEntity(
      id: 6,
      cId: 4110,
      code: '4001',
      name: 'المبيعات العامة',
      masterCId: 4000,
      type: 4,
      national: 1,
      statement: 'قائمة الدخل',
    );

    final allAccounts = [
      cashAccount,
      bankAccount,
      customerAccount,
      supplierAccount,
      expenseAccount,
      revenueAccount,
    ];

    test('All tab matches all 6 accounts', () {
      final matches = allAccounts
          .where((a) => AccountCategoryFilter.all.matches(a))
          .toList();
      expect(matches.length, 6);
    });

    test('Cashboxes tab matches only cash accounts', () {
      final matches = allAccounts
          .where((a) => AccountCategoryFilter.cashboxes.matches(a))
          .toList();
      expect(matches.length, 1);
      expect(matches.first.id, cashAccount.id);
    });

    test(
      'Banks tab matches bank accounts (including by statement or bank name)',
      () {
        final matches = allAccounts
            .where((a) => AccountCategoryFilter.banks.matches(a))
            .toList();
        expect(matches.length, 1);
        expect(matches.first.id, bankAccount.id);
      },
    );

    test(
      'Customers tab matches customer account even without "عميل" in name',
      () {
        final matches = allAccounts
            .where((a) => AccountCategoryFilter.customers.matches(a))
            .toList();
        expect(matches.length, 1);
        expect(matches.first.name, 'أحمد صالح محمد');
        expect(matches.first.id, customerAccount.id);
      },
    );

    test(
      'Suppliers tab matches supplier account even without "مورد" in name',
      () {
        final matches = allAccounts
            .where((a) => AccountCategoryFilter.suppliers.matches(a))
            .toList();
        expect(matches.length, 1);
        expect(matches.first.name, 'مؤسسة البركة للتجارة');
        expect(matches.first.id, supplierAccount.id);
      },
    );

    test('Other accounts tab matches expenses and revenues', () {
      final matches = allAccounts
          .where((a) => AccountCategoryFilter.other.matches(a))
          .toList();
      expect(matches.length, 2);
      expect(matches.map((a) => a.id).toSet(), {
        expenseAccount.id,
        revenueAccount.id,
      });
    });
  });
}
