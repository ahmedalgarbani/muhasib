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

class ValidationFailure extends Failure {
  final List<String> violations;

  ValidationFailure({required String message, this.violations = const []})
    : super(message);

  @override
  String toString() {
    if (violations.isEmpty) return message;
    return '$message:\n${violations.join('\n')}';
  }
}
