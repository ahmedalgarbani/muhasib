import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecase/usecases.dart';
import '../repositories/journal_repository.dart';

class DeleteJournalEntry implements Usecase<Either<Failure, void>, int> {
  final JournalRepository repository;

  DeleteJournalEntry(this.repository);

  @override
  Future<Either<Failure, void>> call({required int params}) {
    return repository.deleteJournalEntry(params);
  }
}
