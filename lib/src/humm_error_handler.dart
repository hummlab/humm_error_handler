import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:humm_error_handler/src/consts/storage_key.dart';
import 'package:humm_error_handler/src/error_storage/humm_error_storage.dart';
import 'package:humm_error_handler/src/error_storage/humm_error_storage_impl.dart';
import 'package:humm_error_handler/src/trackers/humm_error_tracker.dart';

/// A callback type for displaying error messages to users
typedef ErrorDisplayCallback = void Function(
  String message, {
  Map<String, dynamic>? additionalData,
});

/// A callback type for handling error translation
typedef ErrorTranslationCallback = String? Function(
  dynamic error,
  StackTrace stackTrace,
  String? source,
);

class HummErrorHandler {
  late HummErrorStorage errorStorage;
  final List<HummErrorTracker> _trackers = [];
  int logSize = 500000; // Default log size

  /// Callback for displaying error messages to users
  ErrorDisplayCallback? _errorDisplayCallback;

  /// Callback for translating errors into user-friendly messages
  ErrorTranslationCallback? _errorTranslationCallback;

  /// Callback for determining if an error should be displayed to users
  bool Function(dynamic error, StackTrace stackTrace)? _shouldDisplayErrorCallback;

  /// Default error message when translation fails
  String _defaultErrorMessage = 'An error occurred';

  static final HummErrorHandler _instance = HummErrorHandler._internal();

  factory HummErrorHandler() => _instance;

  HummErrorHandler._internal();

  /// Initialize the error handler with basic configuration
  Future<void> init({
    String? storageKey,
    HummErrorStorage? errorStorage,
    List<HummErrorTracker>? trackers,
    int? logSize,
    ErrorDisplayCallback? errorDisplayCallback,
    ErrorTranslationCallback? errorTranslationCallback,
    bool Function(dynamic error, StackTrace stackTrace)? shouldDisplayErrorCallback,
    String? defaultErrorMessage,
  }) async {
    this.errorStorage = errorStorage ?? await HummErrorStorageImpl.create(storageKey: storageKey ?? StorageKey.key);

    // Set log size if provided
    if (logSize != null) {
      this.logSize = logSize;
    }

    if (trackers != null && trackers.isNotEmpty) {
      _trackers.addAll(trackers);
    }

    _errorDisplayCallback = errorDisplayCallback;
    _errorTranslationCallback = errorTranslationCallback;
    _shouldDisplayErrorCallback = shouldDisplayErrorCallback;

    if (defaultErrorMessage != null) {
      _defaultErrorMessage = defaultErrorMessage;
    }
  }

  /// Set up standard error handling for Flutter
  void setupFlutterErrorHandling() {
    FlutterError.onError = (FlutterErrorDetails details) {
      handleError(
        details.exception,
        details.stack ?? StackTrace.empty,
        source: 'Flutter',
      );
    };
  }

  /// Configure a Zone for handling uncaught asynchronous errors
  ZoneSpecification createZoneSpecification() {
    return ZoneSpecification(
        handleUncaughtError: (Zone self, ZoneDelegate parent, Zone zone, Object error, StackTrace stackTrace) {
      handleError(error, stackTrace, source: 'Zone');
      // Allow normal Zone processing too
      parent.handleUncaughtError(zone, error, stackTrace);
    });
  }

  /// Run the app in a Zone that catches errors.
  /// This is a simpler version of setupErrorHandling that doesn't create a new zone if we're already in one.
  static void runAppWithErrorHandling(
    Widget app, {
    List<NavigatorObserver>? navigatorObservers,
  }) {
    final handler = HummErrorHandler();

    // Set up Flutter error handling
    handler.setupFlutterErrorHandling();

    // Just run the app - we'll let the caller decide if they want to use runZonedGuarded
    runApp(app);
  }

  /// Set or update the callback for displaying errors to users
  void setErrorDisplayCallback(ErrorDisplayCallback callback) {
    _errorDisplayCallback = callback;
  }

  /// Set or update the callback for translating errors
  void setErrorTranslationCallback(ErrorTranslationCallback callback) {
    _errorTranslationCallback = callback;
  }

  /// Set or update the default error message
  void setDefaultErrorMessage(String message) {
    _defaultErrorMessage = message;
  }

  /// Set the callback that determines if an error should be displayed
  void setShouldDisplayErrorCallback(bool Function(dynamic error, StackTrace stackTrace) callback) {
    _shouldDisplayErrorCallback = callback;
  }

  void addTracker(HummErrorTracker tracker) {
    _trackers.add(tracker);
  }

  Future<void> handleError(
    dynamic error,
    StackTrace stackTrace, {
    String? source,
    Map<String, dynamic>? additionalData,
    bool displayToUser = true,
  }) async {
    // Log the error
    await _saveErrorToStorage(error, stackTrace, source, additionalData);

    // Send to trackers
    for (final tracker in _trackers) {
      if (tracker.shouldHandleCrashlog()) {
        await tracker.trackError(
          error: error,
          stackTrace: stackTrace,
          source: source,
          additionalData: additionalData,
        );
      }
    }

    // Determine if we should display the error to the user
    final bool shouldDisplay = displayToUser && (_shouldDisplayErrorCallback?.call(error, stackTrace) ?? true);

    // Display the error to the user if needed
    if (shouldDisplay && _errorDisplayCallback != null) {
      String? errorMessage;

      // Try to translate the error
      if (_errorTranslationCallback != null) {
        errorMessage = _errorTranslationCallback!(error, stackTrace, source);
      }

      // Use default error message if translation failed
      errorMessage ??= _defaultErrorMessage;

      // Display the error
      _errorDisplayCallback!(errorMessage, additionalData: additionalData);
    }
  }

  static Future<void> setup({
    List<HummErrorTracker>? trackers,
    String? storageKey,
    HummErrorStorage? errorStorage,
    ErrorDisplayCallback? errorDisplayCallback,
    ErrorTranslationCallback? errorTranslationCallback,
    bool Function(dynamic error, StackTrace stackTrace)? shouldDisplayErrorCallback,
    String? defaultErrorMessage,
    int? logSize,
  }) async {
    final handler = HummErrorHandler();
    await handler.init(
      storageKey: storageKey,
      errorStorage: errorStorage,
      trackers: trackers,
      errorDisplayCallback: errorDisplayCallback,
      errorTranslationCallback: errorTranslationCallback,
      shouldDisplayErrorCallback: shouldDisplayErrorCallback,
      defaultErrorMessage: defaultErrorMessage,
      logSize: logSize,
    );

    // Configure Flutter error handling
    handler.setupFlutterErrorHandling();
  }

  Future<void> _saveErrorToStorage(
    dynamic error,
    StackTrace stackTrace,
    String? source,
    Map<String, dynamic>? additionalData,
  ) async {
    try {
      final String formattedError = _formatErrorForStorage(
        error,
        stackTrace,
        source,
        additionalData,
      );

      String? currentLog = '';
      try {
        currentLog = await errorStorage.getErrorLog();
      } catch (e) {
        currentLog = '';
      }

      currentLog ??= '';

      final String updatedLog = formattedError + (currentLog.isNotEmpty ? '\n\n$currentLog' : '');

      final String trimmedLog = _trimLogIfNeeded(updatedLog);

      await errorStorage.saveErrorLog(trimmedLog);
    } catch (e, s) {
      if (kDebugMode) {
        print('Error while saving to storage: $e');
        print('Stack trace: $s');
      }
    }
  }

  String _formatErrorForStorage(
    dynamic error,
    StackTrace stackTrace,
    String? source,
    Map<String, dynamic>? additionalData,
  ) {
    final StringBuffer buffer = StringBuffer();
    final DateTime now = DateTime.now();

    buffer.writeln('==== ERROR [${now.toIso8601String()}] ====');
    buffer.writeln('Source: ${source ?? 'Unknown'}');
    buffer.writeln('Error: ${error.toString()}');

    if (additionalData != null && additionalData.isNotEmpty) {
      buffer.writeln('\nAdditional Data:');
      additionalData.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }

    buffer.writeln('\nStack Trace:');
    buffer.writeln(stackTrace.toString());

    return buffer.toString();
  }

  String _trimLogIfNeeded(String log) {
    if (log.length <= logSize) {
      return log;
    }

    final List<String> entries = log.split('\n\n');

    final StringBuffer trimmedLog = StringBuffer();
    int currentSize = 0;

    for (final entry in entries) {
      final int newSize = currentSize + entry.length + 2;

      if (newSize > logSize) {
        if (currentSize > 0) {
          trimmedLog.writeln('\n\n[Log trimmed: some older entries were removed]');
        }
        break;
      }

      if (currentSize > 0) {
        trimmedLog.write('\n\n');
      }
      trimmedLog.write(entry);
      currentSize = newSize;
    }

    return trimmedLog.toString();
  }
}
