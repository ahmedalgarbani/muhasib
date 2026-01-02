import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/features/purchases/domain/repositories/purchase_repository.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/purchases/domain/usecases/create_purchase.dart';

part 'purchases_state.dart';


class PurchasesCubit extends Cubit<PurchasesState> {
  final PurchaseRepository repository;
  final CreatePurchase createPurchase;

  PurchasesCubit({
    required this.repository,
    required this.createPurchase,
  }) : super(PurchasesInitial());

  // Load purchase invoices
  Future<void> loadPurchaseInvoices() async {
    emit(PurchasesLoading());
    final result = await repository.getPurchaseInvoices();
    result.fold(
      (failure) => emit(PurchasesError(failure.message)),
      (invoices) => emit(PurchaseInvoicesLoaded(invoices)),
    );
  }

  // Create new purchase invoice
  Future<void> createPurchaseInvoice(InvoiceEntity invoice) async {
    emit(PurchasesLoading());
    final result = await createPurchase(params: invoice);
    result.fold((failure) => emit(PurchasesError(failure.message)), (id) {
      emit(PurchaseInvoiceCreated(id));
      loadPurchaseInvoices();
    });
  }

  // Update purchase invoice
  Future<void> updatePurchaseInvoice(InvoiceEntity invoice) async {
    emit(PurchasesLoading());
    final result = await repository.updatePurchaseInvoice(invoice);
    result.fold((failure) => emit(PurchasesError(failure.message)), (_) {
      emit(PurchaseInvoiceUpdated());
      loadPurchaseInvoices();
    });
  }

  // Delete purchase invoice
  Future<void> deletePurchaseInvoice(int id) async {
    emit(PurchasesLoading());
    final result = await repository.deletePurchaseInvoice(id);
    result.fold((failure) => emit(PurchasesError(failure.message)), (_) {
      emit(PurchaseInvoiceDeleted());
      loadPurchaseInvoices();
    });
  }

  // Load purchase orders
  Future<void> loadPurchaseOrders() async {
    emit(PurchasesLoading());
    final result = await repository.getPurchaseOrders();
    result.fold(
      (failure) => emit(PurchasesError(failure.message)),
      (orders) => emit(PurchaseOrdersLoaded(orders)),
    );
  }

  // Create new purchase order
  Future<void> createPurchaseOrder(InvoiceEntity order) async {
    emit(PurchasesLoading());
    final result = await repository.createPurchaseOrder(order);
    result.fold((failure) => emit(PurchasesError(failure.message)), (id) {
      emit(PurchaseOrderCreated(id));
      loadPurchaseOrders();
    });
  }

  // Convert purchase order to invoice
  Future<void> convertOrderToInvoice(int orderId, InvoiceEntity invoice) async {
    emit(PurchasesLoading());
    final result = await repository.convertOrderToInvoice(orderId, invoice);
    result.fold((failure) => emit(PurchasesError(failure.message)), (
      invoiceId,
    ) {
      emit(PurchaseOrderConverted(invoiceId));
      loadPurchaseOrders();
    });
  }

  // Load purchase returns
  Future<void> loadPurchaseReturns() async {
    emit(PurchasesLoading());
    final result = await repository.getPurchaseReturns();
    result.fold(
      (failure) => emit(PurchasesError(failure.message)),
      (returns) => emit(PurchaseReturnsLoaded(returns)),
    );
  }

  // Create purchase return
  Future<void> createPurchaseReturn(
    InvoiceEntity returnInvoice,
    int parentInvoiceId,
  ) async {
    emit(PurchasesLoading());
    final result = await repository.createPurchaseReturn(
      returnInvoice,
      parentInvoiceId,
    );
    result.fold((failure) => emit(PurchasesError(failure.message)), (id) {
      emit(PurchaseReturnCreated(id));
      loadPurchaseReturns();
    });
  }

  // Search purchases
  Future<void> searchPurchases(String query) async {
    if (query.isEmpty) {
      loadPurchaseInvoices();
      return;
    }
    emit(PurchasesLoading());
    final result = await repository.searchPurchases(query);
    result.fold(
      (failure) => emit(PurchasesError(failure.message)),
      (invoices) => emit(PurchaseInvoicesLoaded(invoices)),
    );
  }
}
