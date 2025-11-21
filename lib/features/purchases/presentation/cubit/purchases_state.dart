part of 'purchases_cubit.dart';

abstract class PurchasesState extends Equatable {
  const PurchasesState();

  @override
  List<Object> get props => [];
}

class PurchasesInitial extends PurchasesState {}

class PurchasesLoading extends PurchasesState {}

class PurchasesError extends PurchasesState {
  final String message;
  
  const PurchasesError(this.message);
  
  @override
  List<Object> get props => [message];
}

// Purchase Invoice States
class PurchaseInvoicesLoaded extends PurchasesState {
  final List<InvoiceEntity> invoices;
  
  const PurchaseInvoicesLoaded(this.invoices);
  
  @override
  List<Object> get props => [invoices];
}

class PurchaseInvoiceCreated extends PurchasesState {
  final int invoiceId;
  
  const PurchaseInvoiceCreated(this.invoiceId);
  
  @override
  List<Object> get props => [invoiceId];
}

class PurchaseInvoiceUpdated extends PurchasesState {}

class PurchaseInvoiceDeleted extends PurchasesState {}

// Purchase Order States
class PurchaseOrdersLoaded extends PurchasesState {
  final List<InvoiceEntity> orders;
  
  const PurchaseOrdersLoaded(this.orders);
  
  @override
  List<Object> get props => [orders];
}

class PurchaseOrderCreated extends PurchasesState {
  final int orderId;
  
  const PurchaseOrderCreated(this.orderId);
  
  @override
  List<Object> get props => [orderId];
}

class PurchaseOrderConverted extends PurchasesState {
  final int invoiceId;
  
  const PurchaseOrderConverted(this.invoiceId);
  
  @override
  List<Object> get props => [invoiceId];
}

// Purchase Return States
class PurchaseReturnsLoaded extends PurchasesState {
  final List<InvoiceEntity> returns;
  
  const PurchaseReturnsLoaded(this.returns);
  
  @override
  List<Object> get props => [returns];
}

class PurchaseReturnCreated extends PurchasesState {
  final int returnId;
  
  const PurchaseReturnCreated(this.returnId);
  
  @override
  List<Object> get props => [returnId];
}
