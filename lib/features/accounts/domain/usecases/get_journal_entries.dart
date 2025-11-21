import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import '../entities/journal_entry_entity.dart';
import '../repositories/journal_repository.dart';

class GetJournalEntries
    implements Usecase<Either<Failure, List<JournalEntryEntity>>, NoParams> {
  final JournalRepository repository;

  GetJournalEntries(this.repository);

  @override
  Future<Either<Failure, List<JournalEntryEntity>>> call({
    required NoParams params,
  }) {
    return repository.getJournalEntries();
  }
}
