class LocalStorageException implements Exception {
  final String message;
  LocalStorageException(this.message);
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}
