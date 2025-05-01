abstract class HummErrorStorage {
  final String storageKey;

  HummErrorStorage({required this.storageKey});

  Future<String?> getErrorLog();

  Future<void> saveErrorLog(String file);
}
