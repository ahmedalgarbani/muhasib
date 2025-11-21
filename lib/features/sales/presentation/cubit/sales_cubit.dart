import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/usecases/create_invoice.dart';
import 'package:muhasib/features/sales/domain/usecases/delete_invoice.dart';
import 'package:muhasib/features/sales/domain/usecases/get_invoice.dart';
import 'package:muhasib/features/sales/domain/usecases/get_invoices.dart';
import 'package:muhasib/features/sales/domain/usecases/search_invoices.dart';
import 'package:muhasib/features/sales/domain/usecases/update_invoice.dart';
import 'package:muhasib/features/sales/domain/usecases/get_quotations.dart';
import 'package:muhasib/features/sales/domain/usecases/get_open_quotations.dart';
import 'package:muhasib/features/sales/domain/usecases/convert_quotation_to_invoice.dart';
import 'package:muhasib/features/sales/domain/usecases/get_return_invoices.dart';
import 'package:muhasib/features/sales/domain/usecases/create_return_invoice.dart';
import 'package:muhasib/features/sales/domain/usecases/get_returns_by_parent_invoice.dart';

part 'sales_state.dart';

class SalesCubit extends Cubit<SalesState> {
  final GetInvoices getInvoices;
  final GetInvoice getInvoice;
  final CreateInvoice createInvoice;
  final UpdateInvoice updateInvoice;
  final DeleteInvoice deleteInvoice;
  final SearchInvoices searchInvoices;
  
  // Quotation use cases
  final GetQuotations getQuotations;
  final GetOpenQuotations getOpenQuotations;
  final ConvertQuotationToInvoice convertQuotationToInvoice;
  
  // Return invoice use cases
  final GetReturnInvoices getReturnInvoices;
  final CreateReturnInvoice createReturnInvoice;
  final GetReturnsByParentInvoice getReturnsByParentInvoice;

  List<InvoiceEntity>? allInvoices;

  SalesCubit({
    required this.getInvoices,
    required this.getInvoice,
    required this.createInvoice,
    required this.updateInvoice,
    required this.deleteInvoice,
    required this.searchInvoices,
    required this.getQuotations,
    required this.getOpenQuotations,
    required this.convertQuotationToInvoice,
    required this.getReturnInvoices,
    required this.createReturnInvoice,
    required this.getReturnsByParentInvoice,
  }) : super(SalesInitial());

  Future<void> loadInvoices() async {
    emit(SalesLoading());
    final result = await getInvoices(params: NoParams());
    result.fold((failure) => emit(SalesError(failure.message)), (items) {
      allInvoices = items;
      emit(SalesLoaded(items));
    });
  }

  Future<void> addInvoice(InvoiceEntity invoice) async {
    emit(SalesLoading());
    final result = await createInvoice(params: invoice);
    result.fold((failure) => emit(SalesError(failure.message)), (id) {
      emit(InvoiceCreated(id));
      loadInvoices();
    });
  }

  Future<void> modifyInvoice(InvoiceEntity invoice) async {
    emit(SalesLoading());
    final result = await updateInvoice(params: invoice);
    result.fold((failure) => emit(SalesError(failure.message)), (_) {
      emit(InvoiceUpdated());
      loadInvoices();
    });
  }

  Future<void> removeInvoice(int id) async {
    emit(SalesLoading());
    final result = await deleteInvoice(params: id);
    result.fold((failure) => emit(SalesError(failure.message)), (_) {
      emit(InvoiceDeleted());
      loadInvoices();
    });
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      loadInvoices();
      return;
    }
    emit(SalesLoading());
    final result = await searchInvoices(params: query);
    result.fold(
      (failure) => emit(SalesError(failure.message)),
      (items) => emit(SalesLoaded(items)),
    );
  }

  // Quotation methods
  Future<void> loadQuotations() async {
    emit(SalesLoading());
    final result = await getQuotations(params: NoParams());
    result.fold(
      (failure) => emit(SalesError(failure.message)),
      (items) {
        emit(QuotationsLoaded(items));
      },
    );
  }

  Future<void> loadOpenQuotations() async {
    emit(SalesLoading());
    final result = await getOpenQuotations(params: NoParams());
    result.fold(
      (failure) => emit(SalesError(failure.message)),
      (items) {
        emit(QuotationsLoaded(items));
      },
    );
  }

  Future<void> convertQuotation(int quotationId, InvoiceEntity salesInvoice) async {
    emit(SalesLoading());
    final result = await convertQuotationToInvoice(
      params: ConvertQuotationParams(
        quotationId: quotationId,
        salesInvoice: salesInvoice,
      ),
    );
    result.fold(
      (failure) => emit(SalesError(failure.message)),
      (invoiceId) {
        emit(QuotationConverted(invoiceId));
        loadQuotations(); // Refresh quotations list
      },
    );
  }

  // Return invoice methods
  Future<void> loadReturnInvoices() async {
    emit(SalesLoading());
    final result = await getReturnInvoices(params: NoParams());
    result.fold(
      (failure) => emit(SalesError(failure.message)),
      (items) {
        emit(ReturnInvoicesLoaded(items));
      },
    );
  }

  Future<void> loadReturnsByParent(int parentInvoiceId) async {
    emit(SalesLoading());
    final result = await getReturnsByParentInvoice(params: parentInvoiceId);
    result.fold(
      (failure) => emit(SalesError(failure.message)),
      (items) {
        emit(ReturnInvoicesLoaded(items));
      },
    );
  }

  Future<void> createReturn(InvoiceEntity returnInvoice, int parentInvoiceId) async {
    emit(SalesLoading());
    final result = await createReturnInvoice(
      params: CreateReturnParams(
        returnInvoice: returnInvoice,
        parentInvoiceId: parentInvoiceId,
      ),
    );
    result.fold(
      (failure) => emit(SalesError(failure.message)),
      (returnId) {
        emit(ReturnInvoiceCreated(returnId));
        loadReturnInvoices(); // Refresh returns list
      },
    );
  }
}
