import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muhasib/core/usecase/usecases.dart';

import '../../domain/entities/journal_entry_entity.dart';
import '../../domain/usecases/create_journal_entry.dart';
import '../../domain/usecases/delete_journal_entry.dart';
import '../../domain/usecases/get_journal_entries.dart';
import '../../domain/usecases/get_journal_entry.dart';
import '../../domain/usecases/update_journal_entry.dart';

part 'journal_entry_state.dart';

class JournalEntryCubit extends Cubit<JournalEntryState> {
  JournalEntryCubit({
    required this.createJournalEntry,
    required this.updateJournalEntry,
    required this.deleteJournalEntry,
    required this.getJournalEntries,
    required this.getJournalEntry,
  }) : super(const JournalEntryInitial());

  final CreateJournalEntry createJournalEntry;
  final UpdateJournalEntry updateJournalEntry;
  final DeleteJournalEntry deleteJournalEntry;
  final GetJournalEntries getJournalEntries;
  final GetJournalEntry getJournalEntry;

  Future<void> loadEntries() async {
    emit(const JournalEntryLoading());
    final result = await getJournalEntries(params: NoParams());

    result.fold(
      (failure) => emit(JournalEntryFailure(failure.message)),
      (entries) => emit(JournalEntriesLoaded(entries)),
    );
  }

  Future<void> saveEntry(JournalEntryEntity entry) async {
    emit(const JournalEntryActionInProgress());

    if (entry.id == null) {
      final createResult = await createJournalEntry.call(
        params: entry.copyWith(id: null),
      );

      await createResult.fold(
        (failure) async => emit(JournalEntryFailure(failure.message)),
        (entryId) async {
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
      final updateResult = await updateJournalEntry.call(params: entry);

      await updateResult.fold(
        (failure) async => emit(JournalEntryFailure(failure.message)),
        (_) async {
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
}
