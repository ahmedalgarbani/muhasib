part of 'sales_cubit.dart';

abstract class SalesState extends Equatable {
  const SalesState();

  @override
  List<Object> get props => [];
}

class SalesInitial extends SalesState {}

class SalesLoading extends SalesState {}

class SalesLoaded extends SalesState {
  final List<InvoiceEntity> invoices;

  const SalesLoaded(this.invoices);

  @override
  List<Object> get props => [invoices];
}

class SalesError extends SalesState {
  final String message;
  const SalesError(this.message);

  @override
  List<Object> get props => [message];
}

class InvoiceCreated extends SalesState {
  final int id;
  const InvoiceCreated(this.id);

  @override
  List<Object> get props => [id];
}

class InvoiceUpdated extends SalesState {}

class InvoiceDeleted extends SalesState {}

// Quotation states
class QuotationsLoaded extends SalesState {
  final List<InvoiceEntity> quotations;
  
  const QuotationsLoaded(this.quotations);
  
  @override
  List<Object> get props => [quotations];
}

class QuotationConverted extends SalesState {
  final int newInvoiceId;
  
  const QuotationConverted(this.newInvoiceId);
  
  @override
  List<Object> get props => [newInvoiceId];
}

// Return invoice states
class ReturnInvoicesLoaded extends SalesState {
  final List<InvoiceEntity> returns;
  
  const ReturnInvoicesLoaded(this.returns);
  
  @override
  List<Object> get props => [returns];
}

class ReturnInvoiceCreated extends SalesState {
  final int returnInvoiceId;
  
  const ReturnInvoiceCreated(this.returnInvoiceId);
  
  @override
  List<Object> get props => [returnInvoiceId];
}
