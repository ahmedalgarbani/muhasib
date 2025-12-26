import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/core/usecase/usecases.dart';

import '../../domain/entities/journal_entry_entity.dart';
import '../../domain/usecases/create_journal_entry.dart';
import '../../domain/usecases/delete_journal_entry.dart';
import '../../domain/usecases/get_journal_entries.dart';
import '../../domain/usecases/get_journal_entry.dart';
import '../../domain/usecases/update_journal_entry.dart';
import '../../domain/interceptors/account_limit_interceptor.dart';

part 'journal_entry_state.dart';

class JournalEntryCubit extends Cubit<JournalEntryState> {
  JournalEntryCubit({
    required this.createJournalEntry,
    required this.updateJournalEntry,
    required this.deleteJournalEntry,
    required this.getJournalEntries,
    required this.getJournalEntry,
    required this.limitInterceptor,
  }) : super(const JournalEntryInitial());

  final CreateJournalEntry createJournalEntry;
  final UpdateJournalEntry updateJournalEntry;
  final DeleteJournalEntry deleteJournalEntry;
  final GetJournalEntries getJournalEntries;
  final GetJournalEntry getJournalEntry;
  final AccountLimitInterceptor limitInterceptor;

  Future<void> loadEntries() async {
    emit(const JournalEntryLoading());
    final result = await getJournalEntries(params: NoParams());

    result.fold(
      (failure) => emit(JournalEntryFailure(failure.message)),
      (entries) => emit(JournalEntriesLoaded(entries)),
    );
  }

  Future<void> saveEntry(JournalEntryEntity entry, {bool validateLimits = true}) async {
    emit(const JournalEntryActionInProgress());

    try {
      // Validate account limits if enabled
      if (validateLimits && entry.lines.isNotEmpty) {
        // Convert journal entry lines to validation format
        final validationLines = convertToValidationLines(entry.lines);
        
        // Use limit interceptor directly (without mixin to avoid BuildContext dependency)
        final validationResult = await limitInterceptor.validateJournalEntry(lines: validationLines);
        
        await validationResult.fold(
          (failure) async {
            emit(JournalEntryFailure(failure.message));
            return;
          },
          (isValid) async {
            if (!isValid) {
              emit(const JournalEntryFailure('فشل التحقق من حدود الحسابات'));
              return;
            }
            
            // Proceed with saving the entry
            await saveEntryAfterValidation(entry, validationLines);
          },
        );
      } else {
        // No validation needed, proceed directly
        await saveEntryAfterValidation(entry, []);
      }
    } catch (e) {
      emit(JournalEntryFailure('خطأ في حفظ القيد: ${e.toString()}'));
    }
  }

  Future<void> removeEntry(int id) async {
    emit(const JournalEntryActionInProgress());
    final result = await deleteJournalEntry.call(params: id);

    result.fold(
      (failure) => emit(JournalEntryFailure(failure.message)),
      (_) => emit(
        JournalEntryDeleted(
          entryId: id,
          message: 'تم حذف القيد المحاسبي بنجاح',
        ),
      ),
    );
  }

  /// Helper method to save entry after validation
  Future<void> saveEntryAfterValidation(JournalEntryEntity entry, List<JournalEntryLineValidation> validationLines) async {
    if (entry.id == null) {
      // Creating new entry
      final createResult = await createJournalEntry.call(
        params: entry.copyWith(id: null),
      );

      await createResult.fold(
        (failure) async => emit(JournalEntryFailure(failure.message)),
        (entryId) async {
          // Update account usage after successful creation
          if (validationLines.isNotEmpty) {
            await limitInterceptor.updateUsageAfterTransaction(lines: validationLines);
          }
          
          final fetchResult = await getJournalEntry.call(params: entryId);
          fetchResult.fold(
            (failure) => emit(JournalEntryFailure(failure.message)),
            (savedEntry) => emit(
              JournalEntryActionSuccess(
                entryId: entryId,
                entry: savedEntry,
                message: 'تم حفظ القيد المحاسبي بنجاح',
              ),
            ),
          );
        },
      );
    } else {
      // Updating existing entry
      final updateResult = await updateJournalEntry.call(params: entry);

      await updateResult.fold(
        (failure) async => emit(JournalEntryFailure(failure.message)),
        (_) async {
          // Update account usage after successful update
          if (validationLines.isNotEmpty) {
            await limitInterceptor.updateUsageAfterTransaction(lines: validationLines);
          }
          
          final fetchResult = await getJournalEntry.call(params: entry.id!);
          fetchResult.fold(
            (failure) => emit(JournalEntryFailure(failure.message)),
            (savedEntry) => emit(
              JournalEntryActionSuccess(
                entryId: savedEntry.id!,
                entry: savedEntry,
                message: 'تم تحديث القيد المحاسبي بنجاح',
              ),
            ),
          );
        },
      );
    }
  }

  /// Convert journal entry lines to account limit validation format
  List<JournalEntryLineValidation> convertToValidationLines(List<JournalEntryLineEntity> entryLines) {
    return entryLines
        .where((line) => line.accountId != null && line.currencyId != null)
        .map((line) => JournalEntryLineValidation(
              accountId: line.accountId!,
              currencyId: line.currencyId!,
              debitAmount: line.debit,
              creditAmount: line.credit,
            ))
        .toList();
  }
}
