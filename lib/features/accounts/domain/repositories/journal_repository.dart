import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import '../entities/journal_entry_entity.dart';

abstract class JournalRepository {
  Future<Either<Failure, List<JournalEntryEntity>>> getJournalEntries();
  Future<Either<Failure, JournalEntryEntity>> getJournalEntry(int id);
  Future<Either<Failure, int>> createJournalEntry(JournalEntryEntity entry);
  Future<Either<Failure, void>> updateJournalEntry(JournalEntryEntity entry);
  Future<Either<Failure, void>> deleteJournalEntry(int id);
}
