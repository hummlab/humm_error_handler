import 'package:fimber/fimber.dart';
import 'package:humm_error_handler/src/trackers/humm_error_tracker.dart';

/// A tracker that logs errors using the Fimber logging library
///
/// This tracker leverages Fimber's powerful logging capabilities
/// to produce well-formatted, filterable logs for debugging.
class FimberTracker implements HummErrorTracker {
  final bool _includeAdditionalData;
  final LogLevel _logLevel;

  /// Creates a new Fimber tracker
  ///
  /// [tag] - Tag for categorizing logs (appears in log output)
  /// [includeAdditionalData] - Whether to include additional data in logs
  /// [logLevel] - Fimber log level to use
  FimberTracker({
    bool includeAdditionalData = true,
    LogLevel logLevel = LogLevel.E,
  })  : _includeAdditionalData = includeAdditionalData,
        _logLevel = logLevel;

  @override
  Future<void> trackError({
    required dynamic error,
    required StackTrace stackTrace,
    String? source,
    Map<String, dynamic>? additionalData,
  }) async {
    // Build the log message
    final StringBuffer buffer = StringBuffer();

    // Add source if available
    if (source != null) {
      buffer.write('[$source] ');
    }

    // Add error message
    buffer.write(error.toString());

    // Add additional data if requested and available
    if (_includeAdditionalData && additionalData != null && additionalData.isNotEmpty) {
      buffer.write('\nAdditional Data:');
      additionalData.forEach((key, value) {
        buffer.write('\n  $key: $value');
      });
    }

    // Use Fimber to log the error with the appropriate level
    switch (_logLevel) {
      case LogLevel.V:
        Fimber.v(buffer.toString(), ex: error, stacktrace: stackTrace);
        break;
      case LogLevel.D:
        Fimber.d(buffer.toString(), ex: error, stacktrace: stackTrace);
        break;
      case LogLevel.I:
        Fimber.i(buffer.toString(), ex: error, stacktrace: stackTrace);
        break;
      case LogLevel.W:
        Fimber.w(buffer.toString(), ex: error, stacktrace: stackTrace);
        break;
      case LogLevel.E:
        Fimber.e(buffer.toString(), ex: error, stacktrace: stackTrace);
        break;
    }
  }
}

/// Log levels for the FimberTracker
enum LogLevel {
  /// Verbose: for very detailed logs
  V,

  /// Debug: for debugging information
  D,

  /// Info: for general information
  I,

  /// Warning: for warnings
  W,

  /// Error: for errors (default)
  E,
}
