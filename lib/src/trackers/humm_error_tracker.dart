abstract class HummErrorTracker {
  Future<void> trackError({
    required dynamic error,
    required StackTrace stackTrace,
    String? source,
    Map<String, dynamic>? additionalData,
  });
}
