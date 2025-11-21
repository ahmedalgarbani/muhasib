import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import '../entities/journal_entry_entity.dart';
import '../repositories/journal_repository.dart';

class UpdateJournalEntry
    implements Usecase<Either<Failure, void>, JournalEntryEntity> {
  final JournalRepository repository;

  UpdateJournalEntry(this.repository);

  @override
  Future<Either<Failure, void>> call({required JournalEntryEntity params}) {
    return repository.updateJournalEntry(params);
  }
}
