import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import '../entities/journal_entry_entity.dart';
import '../repositories/journal_repository.dart';

class GetJournalEntry
    implements Usecase<Either<Failure, JournalEntryEntity>, int> {
  final JournalRepository repository;

  GetJournalEntry(this.repository);

  @override
  Future<Either<Failure, JournalEntryEntity>> call({required int params}) {
    return repository.getJournalEntry(params);
  }
}
