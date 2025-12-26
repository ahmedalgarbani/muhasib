import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/customers/data/datasources/customer_data_source.dart';
import 'package:muhasib/features/customers/domain/entities/customer_entity.dart';
import 'package:muhasib/features/customers/domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerDataSource dataSource;

  CustomerRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<CustomerEntity>>> getCustomers({
    bool includeInactive = false,
  }) async {
    try {
      final customers = await dataSource.getCustomers(
        includeInactive: includeInactive,
      );
      return Right(customers);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to get customers: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CustomerEntity>>> getSuppliers({
    bool includeInactive = false,
  }) async {
    try {
      final suppliers = await dataSource.getSuppliers(
        includeInactive: includeInactive,
      );
      return Right(suppliers);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to get suppliers: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> getCustomerById(int customerId) async {
    try {
      final customer = await dataSource.getCustomerById(customerId);
      return Right(customer);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to get customer: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> addCustomer({
    required String name,
    required int type,
    String? contact,
    String? address,
    double creditLimit = 0.0,
    double openingBalance = 0.0,
  }) async {
    try {
      // Validate input
      if (name.trim().isEmpty) {
        return Left(ValidationFailure(message: 'Customer name cannot be empty'));
      }
      
      if (type != 1 && type != 2) {
        return Left(ValidationFailure(message: 'Invalid customer type'));
      }
      
      if (creditLimit < 0) {
        return Left(ValidationFailure(message: 'Credit limit cannot be negative'));
      }
      
      final customer = await dataSource.addCustomer(
        name: name.trim(),
        type: type,
        contact: contact?.trim(),
        address: address?.trim(),
        creditLimit: creditLimit,
        openingBalance: openingBalance,
      );
      
      return Right(customer);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to add customer: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> updateCustomer({
    required int customerId,
    String? name,
    String? contact,
    String? address,
    double? creditLimit,
    bool? isActive,
  }) async {
    try {
      // Validate input
      if (name != null && name.trim().isEmpty) {
        return Left(ValidationFailure(message: 'Customer name cannot be empty'));
      }
      
      if (creditLimit != null && creditLimit < 0) {
        return Left(ValidationFailure(message: 'Credit limit cannot be negative'));
      }
      
      final customer = await dataSource.updateCustomer(
        customerId: customerId,
        name: name?.trim(),
        contact: contact?.trim(),
        address: address?.trim(),
        creditLimit: creditLimit,
        isActive: isActive,
      );
      
      return Right(customer);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to update customer: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomerBalance({
    required int customerId,
    required double newBalance,
  }) async {
    try {
      await dataSource.updateCustomerBalance(
        customerId: customerId,
        newBalance: newBalance,
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to update customer balance: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(int customerId) async {
    try {
      // Check if customer has transactions
      final summary = await dataSource.getCustomerSummary(customerId);
      final totalTransactions = summary['total_transactions'] as int;
      
      if (totalTransactions > 0) {
        return Left(ValidationFailure(
          message: 'Cannot delete customer with existing transactions'
        ));
      }
      
      await dataSource.deleteCustomer(customerId);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to delete customer: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CustomerEntity>>> searchCustomers({
    required String query,
    int? type,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return const Right([]);
      }
      
      final customers = await dataSource.searchCustomers(
        query: query.trim(),
        type: type,
      );
      return Right(customers);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to search customers: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getCustomerSummary(
    int customerId,
  ) async {
    try {
      final summary = await dataSource.getCustomerSummary(customerId);
      return Right(summary);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to get customer summary: ${e.toString()}'));
    }
  }
}
