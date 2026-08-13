import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/accounts/domain/entities/voucher_entity.dart';
import 'package:muhasib/features/accounts/domain/repositories/voucher_repository.dart';
import 'package:muhasib/features/customers/domain/entities/customer_entity.dart';
import 'package:muhasib/features/customers/domain/repositories/customer_repository.dart';
import 'package:muhasib/features/main/presentation/cubit/main_cubit.dart';
import 'package:muhasib/features/purchases/domain/repositories/purchase_repository.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/repositories/invoice_repository.dart';
import 'package:muhasib/features/sales/domain/usecases/get_invoices.dart';

class FakeCustomerRepository implements CustomerRepository {
  final List<CustomerEntity> customers;
  final List<CustomerEntity> suppliers;

  FakeCustomerRepository({
    this.customers = const [],
    this.suppliers = const [],
  });

  @override
  Future<Either<Failure, List<CustomerEntity>>> getCustomers({
    bool includeInactive = false,
  }) async {
    return Right(customers);
  }

  @override
  Future<Either<Failure, List<CustomerEntity>>> getSuppliers({
    bool includeInactive = false,
  }) async {
    return Right(suppliers);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeInvoiceRepository implements InvoiceRepository {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePurchaseRepository implements PurchaseRepository {
  final List<InvoiceEntity> purchases;

  FakePurchaseRepository({this.purchases = const []});

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getPurchaseInvoices() async {
    return Right(purchases);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVoucherRepository implements VoucherRepository {
  final List<VoucherEntity> vouchers;

  FakeVoucherRepository({this.vouchers = const []});

  @override
  Future<Either<Failure, List<VoucherEntity>>> getVouchers({
    VoucherType? type,
  }) async {
    return Right(vouchers);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGetInvoices extends GetInvoices {
  final List<InvoiceEntity> salesInvoices;

  FakeGetInvoices({this.salesInvoices = const []})
    : super(FakeInvoiceRepository());

  @override
  Future<Either<Failure, List<InvoiceEntity>>> call({
    required NoParams params,
  }) async {
    return Right(salesInvoices);
  }
}

void main() {
  test(
    'MainCubit emits MainDashboardLoaded with correct stats and transaction data',
    () async {
      final customerRepo = FakeCustomerRepository(
        customers: [
          const CustomerEntity(id: 1, name: 'عميل 1', type: 1),
          const CustomerEntity(id: 2, name: 'عميل 2', type: 1),
        ],
        suppliers: [const CustomerEntity(id: 3, name: 'مورد 1', type: 2)],
      );

      final getInvoices = FakeGetInvoices(
        salesInvoices: [
          InvoiceEntity(
            id: 101,
            number: '1001',
            date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            amount: 1500.0,
            totalAmount: 1500.0,
            invoiceType: 1,
            stockId: 1,
            customerId: 1,
            invoiceTransType: 1,
          ),
        ],
      );

      final purchaseRepo = FakePurchaseRepository(purchases: []);
      final voucherRepo = FakeVoucherRepository(vouchers: []);

      final cubit = MainCubit(
        customerRepository: customerRepo,
        getInvoices: getInvoices,
        purchaseRepository: purchaseRepo,
        voucherRepository: voucherRepo,
      );

      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<MainLoading>(),
          isA<MainDashboardLoaded>()
              .having((s) => s.customersCount, 'customersCount', 2)
              .having((s) => s.suppliersCount, 'suppliersCount', 1)
              .having(
                (s) => s.recentTransactions.length,
                'recentTransactions length',
                1,
              ),
        ]),
      );

      await cubit.loadDashboardData();
    },
  );
}
