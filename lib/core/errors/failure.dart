abstract class Failure {
  final String message;
  Failure(this.message);
}

class LocalStorageFailure extends Failure {
  LocalStorageFailure(super.message);
}

class NetworkFailure extends Failure {
  NetworkFailure(super.message);
}

class UnknownFailure extends Failure {
  UnknownFailure(super.message);
}

class CacheFailure extends Failure {
  CacheFailure(super.message);
}

class DatabaseFailure extends Failure {
  DatabaseFailure({required String message}) : super(message);
}
