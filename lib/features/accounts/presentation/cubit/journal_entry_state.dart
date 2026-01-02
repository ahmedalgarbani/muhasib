part of 'journal_entry_cubit.dart';

abstract class JournalEntryState extends Equatable {
  const JournalEntryState();

  @override
  List<Object?> get props => [];
}

class JournalEntryInitial extends JournalEntryState {
  const JournalEntryInitial();
}

class JournalEntryLoading extends JournalEntryState {
  const JournalEntryLoading();
}

class JournalEntriesLoaded extends JournalEntryState {
  final List<JournalEntryEntity> entries;

  const JournalEntriesLoaded(this.entries);

  @override
  List<Object?> get props => [entries];
}

class JournalEntryActionInProgress extends JournalEntryState {
  const JournalEntryActionInProgress();
}

class JournalEntryActionSuccess extends JournalEntryState {
  final int entryId;
  final JournalEntryEntity entry;
  final String message;

  const JournalEntryActionSuccess({
    required this.entryId,
    required this.entry,
    required this.message,
  });

  @override
  List<Object?> get props => [entryId, entry, message];
}

class JournalEntryDeleted extends JournalEntryState {
  final int entryId;
  final String message;

  const JournalEntryDeleted({
    required this.entryId,
    required this.message,
  });

  @override
  List<Object?> get props => [entryId, message];
}

class JournalEntryFormDataLoaded extends JournalEntryState {
  final List<AccountEntity> accounts;
  final List<CurrencyEntity> currencies;

  const JournalEntryFormDataLoaded({
    required this.accounts,
    required this.currencies,
  });

  @override
  List<Object?> get props => [accounts, currencies];
}

class JournalEntryFailure extends JournalEntryState {
  final String message;

  const JournalEntryFailure(this.message);

  @override
  List<Object?> get props => [message];
}
