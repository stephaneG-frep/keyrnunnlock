class BackupFileInfo {
  const BackupFileInfo({
    required this.name,
    required this.path,
    required this.createdAt,
    required this.sizeBytes,
  });

  final String name;
  final String path;
  final DateTime createdAt;
  final int sizeBytes;
}
