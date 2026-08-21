class LocalStorageException implements Exception {
  final String message;
  LocalStorageException(this.message);

  @override
  String toString() => message;
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);

  @override
  String toString() => message;
}

class AccountNotConfiguredException implements Exception {
  final String message;
  final int? connectType;

  AccountNotConfiguredException(this.message, {this.connectType});

  @override
  String toString() => message;
}

class CurrencyNotFoundException implements Exception {
  final String message;
  CurrencyNotFoundException(this.message);
  @override
  String toString() => message;
}

class WarehouseNotFoundException implements Exception {
  final String message;
  WarehouseNotFoundException(this.message);
  @override
  String toString() => message;
}
