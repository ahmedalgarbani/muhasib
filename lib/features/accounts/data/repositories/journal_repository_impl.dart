import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/exceptions.dart';
import 'package:muhasib/core/errors/failure.dart';

import '../../domain/entities/journal_entry_entity.dart';
import '../../domain/repositories/journal_repository.dart';
import '../datasources/journal_local_datasource.dart';
import '../models/journal_entry_model.dart';

class JournalRepositoryImpl implements JournalRepository {
  final JournalLocalDataSource localDataSource;

  JournalRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, int>> createJournalEntry(
    JournalEntryEntity entry,
  ) async {
    try {
      final id = await localDataSource.insertJournalEntry(
        JournalEntryModel.fromEntity(entry),
      );
      return Right(id);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteJournalEntry(int id) async {
    try {
      await localDataSource.deleteJournalEntry(id);
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, JournalEntryEntity>> getJournalEntry(int id) async {
    try {
      final entry = await localDataSource.getJournalEntry(id);
      return Right(entry);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<JournalEntryEntity>>> getJournalEntries() async {
    try {
      final entries = await localDataSource.getJournalEntries();
      return Right(entries);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateJournalEntry(
    JournalEntryEntity entry,
  ) async {
    try {
      await localDataSource.updateJournalEntry(
        JournalEntryModel.fromEntity(entry),
      );
      return const Right(null);
    } on LocalStorageException catch (e) {
      return Left(LocalStorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
