import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/core/usecases/usecase.dart';
import 'package:muhasib/features/accounts/domain/entities/opening_balance_entity.dart';
import 'package:muhasib/features/accounts/domain/repositories/opening_balance_repository.dart';

// Get all opening balances
class GetAllOpeningBalances extends UseCase<List<OpeningBalanceEntity>, NoParams> {
  final OpeningBalanceRepository repository;

  GetAllOpeningBalances({required this.repository});

  @override
  Future<Either<Failure, List<OpeningBalanceEntity>>> call({required NoParams params}) async {
    return await repository.getAllOpeningBalances();
  }
}

// Get opening balance by ID
class GetOpeningBalanceById extends UseCase<OpeningBalanceEntity, int> {
  final OpeningBalanceRepository repository;

  GetOpeningBalanceById({required this.repository});

  @override
  Future<Either<Failure, OpeningBalanceEntity>> call({required int params}) async {
    return await repository.getOpeningBalanceById(params);
  }
}

// Create opening balance
class CreateOpeningBalance extends UseCase<int, OpeningBalanceEntity> {
  final OpeningBalanceRepository repository;

  CreateOpeningBalance({required this.repository});

  @override
  Future<Either<Failure, int>> call({required OpeningBalanceEntity params}) async {
    return await repository.createOpeningBalance(params);
  }
}

// Update opening balance
class UpdateOpeningBalance extends UseCase<void, OpeningBalanceEntity> {
  final OpeningBalanceRepository repository;

  UpdateOpeningBalance({required this.repository});

  @override
  Future<Either<Failure, void>> call({required OpeningBalanceEntity params}) async {
    return await repository.updateOpeningBalance(params);
  }
}

// Delete opening balance
class DeleteOpeningBalance extends UseCase<void, int> {
  final OpeningBalanceRepository repository;

  DeleteOpeningBalance({required this.repository});

  @override
  Future<Either<Failure, void>> call({required int params}) async {
    return await repository.deleteOpeningBalance(params);
  }
}

// Post opening balance
class PostOpeningBalance extends UseCase<void, int> {
  final OpeningBalanceRepository repository;

  PostOpeningBalance({required this.repository});

  @override
  Future<Either<Failure, void>> call({required int params}) async {
    return await repository.postOpeningBalance(params);
  }
}

// Generate next number
class GenerateNextOpeningBalanceNumber extends UseCase<String, NoParams> {
  final OpeningBalanceRepository repository;

  GenerateNextOpeningBalanceNumber({required this.repository});

  @override
  Future<Either<Failure, String>> call({required NoParams params}) async {
    return await repository.generateNextNumber();
  }
}
