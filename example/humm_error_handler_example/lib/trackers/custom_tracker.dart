import 'package:humm_error_handler/humm_error_handler.dart';
import 'package:fimber/fimber.dart';

/// A simple custom tracker example
class CustomTracker implements HummErrorTracker {
  final bool enabled;
  
  /// Constructor with option to enable/disable
  CustomTracker({required this.enabled});

  @override
  Future<void> trackError({
    required dynamic error,
    required StackTrace stackTrace,
    String? source,
    Map<String, dynamic>? additionalData,
  }) async {
    final StringBuffer buffer = StringBuffer();
    
    buffer.writeln('=== CUSTOM TRACKER ERROR ===');
    buffer.writeln('Timestamp: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Source: ${source ?? 'Unknown'}');
    buffer.writeln('Error: $error');
    
    if (additionalData != null && additionalData.isNotEmpty) {
      buffer.writeln('Additional Data:');
      additionalData.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    
    buffer.writeln('Stack Trace:');
    buffer.writeln(stackTrace);
    buffer.writeln('=== END CUSTOM TRACKER ===');
    
    // Log using Fimber
    Fimber.e(buffer.toString());
    
    // In a real implementation, you might:
    // - Send to a custom analytics service
    // - Log to a file
    // - Send to a remote server
    // - Etc.
  }

  @override
  bool shouldHandleCrashlog() {
    return enabled;
  }
}