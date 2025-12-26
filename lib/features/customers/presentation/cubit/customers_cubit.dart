import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/features/customers/domain/repositories/customer_repository.dart';
import 'package:muhasib/features/sales/presentation/widgets/sale_form.dart';

part 'customers_state.dart';

class CustomersCubit extends Cubit<CustomersState> {
  final CustomerRepository _customerRepository;

  CustomersCubit(this._customerRepository) : super(CustomersInitial());

  Future<void> loadCustomers() async {
    emit(CustomersLoading());

    final result = await _customerRepository.getCustomers();
    
    result.fold(
      (failure) => emit(CustomersError('فشل في تحميل العملاء: ${failure.message}')),
      (customersEntities) {
        final customers = customersEntities.map((entity) {
          return Customer(
            id: entity.id.toString(),
            name: entity.name,
            balance: entity.currentBalance,
            creditLimit: entity.creditLimit,
            phone: entity.contact,
            type: entity.type,
          );
        }).toList();
        emit(CustomersLoaded(customers));
      },
    );
  }

  Future<Customer?> addCustomer({
    required String name,
    String? phone,
    String? address,
    int type = 1, // 1=customer, 2=supplier
    double creditLimit = 0.0,
    double openingBalance = 0.0,
  }) async {
    final result = await _customerRepository.addCustomer(
      name: name,
      type: type,
      contact: phone,
      address: address,
      creditLimit: creditLimit,
      openingBalance: openingBalance,
    );

    return result.fold(
      (failure) {
        emit(CustomersError('فشل في إضافة العميل: ${failure.message}'));
        return null;
      },
      (customerEntity) {
        // Reload the correct list based on created party type
        if (customerEntity.type == 2) {
          loadSuppliers();
        } else {
          loadCustomers();
        }
        
        return Customer(
          id: customerEntity.id.toString(),
          name: customerEntity.name,
          balance: customerEntity.currentBalance,
          creditLimit: customerEntity.creditLimit,
          phone: customerEntity.contact,
          type: customerEntity.type,
          address: customerEntity.address,
        );
      },
    );
  }

  Future<void> updateCustomerBalance(
    String customerId,
    double newBalance,
  ) async {
    final result = await _customerRepository.updateCustomerBalance(
      customerId: int.parse(customerId),
      newBalance: newBalance,
    );

    result.fold(
      (failure) => emit(CustomersError('فشل في تحديث رصيد العميل: ${failure.message}')),
      (_) => loadCustomers(),
    );
  }

  Future<void> loadSuppliers() async {
    emit(CustomersLoading());

    final result = await _customerRepository.getSuppliers();
    
    result.fold(
      (failure) => emit(CustomersError('فشل في تحميل الموردين: ${failure.message}')),
      (suppliersEntities) {
        final suppliers = suppliersEntities.map((entity) {
          return Customer(
            id: entity.id.toString(),
            name: entity.name,
            balance: entity.currentBalance,
            creditLimit: entity.creditLimit,
            phone: entity.contact,
            type: entity.type,
          );
        }).toList();
        emit(SuppliersLoaded(suppliers));
      },
    );
  }
}
