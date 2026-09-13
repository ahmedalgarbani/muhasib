/// Platform-agnostic descriptor for a database backup file.
class BackupFile {
  final String path;
  final String name;
  final DateTime? createdAt;

  const BackupFile({
    required this.path,
    required this.name,
    this.createdAt,
  });
}
