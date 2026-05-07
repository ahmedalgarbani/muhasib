import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import 'package:muhasib/features/accounts/domain/interceptors/account_limit_interceptor.dart';

import '../../domain/entities/journal_entry_entity.dart';
import '../../domain/usecases/create_journal_entry.dart';
import '../../domain/usecases/delete_journal_entry.dart';
import '../../domain/usecases/get_journal_entries.dart';
import '../../domain/usecases/get_journal_entry.dart';
import '../../domain/usecases/update_journal_entry.dart';
import '../../domain/usecases/get_all_accounts.dart';
import '../../../currencies/domain/usecases/get_all_currencies.dart';
import '../../domain/entities/account_entity.dart';
import '../../../currencies/domain/entities/currency_entity.dart';

part 'journal_entry_state.dart';

class JournalEntryCubit extends Cubit<JournalEntryState> {
  JournalEntryCubit({
    required this.createJournalEntry,
    required this.updateJournalEntry,
    required this.deleteJournalEntry,
    required this.getJournalEntries,
    required this.getJournalEntry,
    required this.limitInterceptor,
    required this.getAllAccounts,
    required this.getAllCurrencies,
  }) : super(const JournalEntryInitial());

  final CreateJournalEntry createJournalEntry;
  final UpdateJournalEntry updateJournalEntry;
  final DeleteJournalEntry deleteJournalEntry;
  final GetJournalEntries getJournalEntries;
  final GetJournalEntry getJournalEntry;
  final AccountLimitInterceptor limitInterceptor;
  final GetAllAccounts getAllAccounts;
  final GetAllCurrencies getAllCurrencies;

  Future<void> loadEntries() async {
    emit(const JournalEntryLoading());
    final result = await getJournalEntries(params: NoParams());

    result.fold(
      (failure) => emit(JournalEntryFailure(failure.message)),
      (entries) => emit(JournalEntriesLoaded(entries)),
    );
  }

  Future<void> loadFormData() async {
    emit(const JournalEntryLoading());
    
    final accountsResult = await getAllAccounts(params: NoParams());
    final currenciesResult = await getAllCurrencies(params: NoParams());
    
    accountsResult.fold(
      (failure) => emit(JournalEntryFailure(failure.message)),
      (accounts) {
        currenciesResult.fold(
          (failure) => emit(JournalEntryFailure(failure.message)),
          (currencies) => emit(JournalEntryFormDataLoaded(
            accounts: accounts,
            currencies: currencies,
          )),
        );
      },
    );
  }

  Future<void> saveEntry(JournalEntryEntity entry, {bool validateLimits = true}) async {
    emit(const JournalEntryActionInProgress());

    try {
      // 1. التحقق من السقوف المالية باستخدام المعترض الحديث
      if (validateLimits) {
        final validationLines = entry.lines.where((l) => l.accountId != null).map((l) => JournalEntryLineValidation(
          accountId: l.accountId!,
          currencyId: l.currencyId ?? 1,
          debitAmount: l.debit,
          creditAmount: l.credit,
        )).toList();

        final limitResult = await limitInterceptor.validateJournalEntry(lines: validationLines);
        
        bool hasStopped = false;
        limitResult.fold(
          (failure) {
            emit(JournalEntryFailure(failure.message));
            hasStopped = true;
          },
          (_) => null,
        );
        
        if (hasStopped) return;
      }

      final isUpdate = entry.id != null;
      
      if (isUpdate) {
         final updateResult = await updateJournalEntry.call(params: entry);
         updateResult.fold(
          (failure) => emit(JournalEntryFailure(failure.message)),
          (_) => _fetchAndShowSuccess(entry.id!, 'تم تحديث القيد بنجاح'),
        );
      } else {
        final createResult = await createJournalEntry.call(params: entry);
        createResult.fold(
          (failure) => emit(JournalEntryFailure(failure.message)),
          (newId) => _fetchAndShowSuccess(newId, 'تم حفظ القيد بنجاح'),
        );
      }
    } catch (e) {
      emit(JournalEntryFailure('خطأ في تحصيل البيانات أو التحقق: ${e.toString()}'));
    }
  }

  Future<void> _fetchAndShowSuccess(int id, String message) async {
    final fetchResult = await getJournalEntry.call(params: id);
    fetchResult.fold(
      (failure) => emit(JournalEntryFailure(failure.message)),
      (savedEntry) => emit(
        JournalEntryActionSuccess(
          entryId: id,
          entry: savedEntry,
          message: message,
        ),
      ),
    );
  }

  Future<void> removeEntry(int id) async {
    emit(const JournalEntryActionInProgress());
    final result = await deleteJournalEntry.call(params: id);
    result.fold(
      (failure) => emit(JournalEntryFailure(failure.message)),
      (_) => emit(JournalEntryDeleted(entryId: id, message: 'تم حذف القيد بنجاح')),
    );
  }
}
