import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/customers/domain/entities/customer_entity.dart';

abstract class CustomerRepository {
  // Get all customers
  Future<Either<Failure, List<CustomerEntity>>> getCustomers({
    bool includeInactive = false,
  });

  // Get all suppliers
  Future<Either<Failure, List<CustomerEntity>>> getSuppliers({
    bool includeInactive = false,
  });

  // Get customer by ID
  Future<Either<Failure, CustomerEntity>> getCustomerById(int customerId);

  // Add new customer
  Future<Either<Failure, CustomerEntity>> addCustomer({
    required String name,
    required int type, // 1=customer, 2=supplier
    String? contact,
    String? address,
    double creditLimit,
    double openingBalance,
  });

  // Update customer
  Future<Either<Failure, CustomerEntity>> updateCustomer({
    required int customerId,
    String? name,
    String? contact,
    String? address,
    double? creditLimit,
    bool? isActive,
  });

  // Update customer balance
  Future<Either<Failure, void>> updateCustomerBalance({
    required int customerId,
    required double newBalance,
  });

  // Delete customer (soft delete)
  Future<Either<Failure, void>> deleteCustomer(int customerId);

  // Search customers
  Future<Either<Failure, List<CustomerEntity>>> searchCustomers({
    required String query,
    int? type,
  });

  // Get customer transactions summary
  Future<Either<Failure, Map<String, dynamic>>> getCustomerSummary(int customerId);
}
