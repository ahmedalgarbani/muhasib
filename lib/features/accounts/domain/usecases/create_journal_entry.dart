import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import '../entities/journal_entry_entity.dart';
import '../repositories/journal_repository.dart';

class CreateJournalEntry
    implements Usecase<Either<Failure, int>, JournalEntryEntity> {
  final JournalRepository repository;

  CreateJournalEntry(this.repository);

  @override
  Future<Either<Failure, int>> call({required JournalEntryEntity params}) {
    return repository.createJournalEntry(params);
  }
}
