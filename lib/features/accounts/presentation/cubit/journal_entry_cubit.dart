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
      final isUpdate = entry.id != null;

      // For updates: validate only the NET delta vs the existing entry to avoid double-counting limits.
      if (validateLimits && entry.lines.isNotEmpty) {
        if (!isUpdate) {
          final validationLines = convertToValidationLines(entry.lines);
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
              await saveEntryAfterValidation(entry, validationLines);
            },
          );
        } else {
          // Update: compute delta lines
          final oldResult = await getJournalEntry.call(params: entry.id!);
          await oldResult.fold(
            (failure) async {
              emit(JournalEntryFailure(failure.message));
              return;
            },
            (oldEntry) async {
              final deltaLines = _computeLimitDeltaLines(
                oldLines: oldEntry.lines,
                newLines: entry.lines,
              );
              // Validate only positive deltas (increases)
              final increases = deltaLines
                  .map((l) => JournalEntryLineValidation(
                        accountId: l.accountId,
                        currencyId: l.currencyId,
                        debitAmount: l.debitAmount > 0 ? l.debitAmount : 0,
                        creditAmount: l.creditAmount > 0 ? l.creditAmount : 0,
                      ))
                  .where((l) => l.debitAmount > 0 || l.creditAmount > 0)
                  .toList();

              if (increases.isNotEmpty) {
                final validationResult = await limitInterceptor.validateJournalEntry(lines: increases);
                final ok = await validationResult.fold(
                  (failure) async {
                    emit(JournalEntryFailure(failure.message));
                    return false;
                  },
                  (isValid) async => isValid,
                );
                if (!ok) return;
              }

              // Proceed with saving; apply delta usage after success
              await saveEntryAfterValidation(entry, deltaLines);
            },
          );
        }
      } else {
        await saveEntryAfterValidation(entry, []);
      }
    } catch (e) {
      emit(JournalEntryFailure('خطأ في حفظ القيد: ${e.toString()}'));
    }
  }

  Future<void> removeEntry(int id) async {
    emit(const JournalEntryActionInProgress());
    try {
      // Reverse limit usage before delete so limits remain correct
      final oldResult = await getJournalEntry.call(params: id);
      final old = await oldResult.fold<Future<JournalEntryEntity?>>(
        (failure) async {
          emit(JournalEntryFailure(failure.message));
          return null;
        },
        (entry) async => entry,
      );
      if (old == null) return;

      final oldLines = convertToValidationLines(old.lines);
      // Apply negative deltas
      final negLines = oldLines
          .map((l) => JournalEntryLineValidation(
                accountId: l.accountId,
                currencyId: l.currencyId,
                debitAmount: -l.debitAmount,
                creditAmount: -l.creditAmount,
              ))
          .toList();
      final usageResult = await limitInterceptor.updateUsageAfterTransaction(lines: negLines);
      if (usageResult.isLeft()) {
        usageResult.fold((failure) => emit(JournalEntryFailure(failure.message)), (_) {});
        return;
      }

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
    } catch (e) {
      emit(JournalEntryFailure('خطأ في حذف القيد: ${e.toString()}'));
    }
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
          // Update account usage after successful update:
          // - validationLines contains NET deltas for updates (can be negative/positive).
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

  /// Compute NET delta lines (new - old) grouped by account_id + currency_id.
  /// Returned lines can have positive or negative debit/credit amounts.
  List<JournalEntryLineValidation> _computeLimitDeltaLines({
    required List<JournalEntryLineEntity> oldLines,
    required List<JournalEntryLineEntity> newLines,
  }) {
    Map<String, JournalEntryLineValidation> toMap(List<JournalEntryLineEntity> lines) {
      final m = <String, JournalEntryLineValidation>{};
      for (final l in lines) {
        if (l.accountId == null || l.currencyId == null) continue;
        final key = '${l.accountId}_${l.currencyId}';
        final prev = m[key];
        if (prev == null) {
          m[key] = JournalEntryLineValidation(
            accountId: l.accountId!,
            currencyId: l.currencyId!,
            debitAmount: l.debit,
            creditAmount: l.credit,
          );
        } else {
          m[key] = JournalEntryLineValidation(
            accountId: prev.accountId,
            currencyId: prev.currencyId,
            debitAmount: prev.debitAmount + l.debit,
            creditAmount: prev.creditAmount + l.credit,
          );
        }
      }
      return m;
    }

    final oldM = toMap(oldLines);
    final newM = toMap(newLines);
    final keys = <String>{...oldM.keys, ...newM.keys};
    final deltas = <JournalEntryLineValidation>[];
    for (final k in keys) {
      final o = oldM[k];
      final n = newM[k];
      final accountId = (n ?? o)!.accountId;
      final currencyId = (n ?? o)!.currencyId;
      final debitDelta = (n?.debitAmount ?? 0.0) - (o?.debitAmount ?? 0.0);
      final creditDelta = (n?.creditAmount ?? 0.0) - (o?.creditAmount ?? 0.0);
      if (debitDelta == 0.0 && creditDelta == 0.0) continue;
      deltas.add(JournalEntryLineValidation(
        accountId: accountId,
        currencyId: currencyId,
        debitAmount: debitDelta,
        creditAmount: creditDelta,
      ));
    }
    return deltas;
  }
}
