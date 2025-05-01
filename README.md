# humm_error_handler

A Flutter library for comprehensive error handling, tracking, and reporting across your applications.

## Features

- ✅ Centralized error handling
- ✅ Error log storage with SharedPreferences
- ✅ Plugin-based architecture for error tracking
- ✅ Integration with Fimber for advanced logging capabilities
- ✅ Zone errors and Flutter errors handling
- ✅ Easily extendable with custom trackers (e.g., Crashlytics, Sentry)

## Usage

### Basic Setup

```dart
import 'package:flutter/material.dart';
import 'package:humm_error_handler/humm_error_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Simple initialization with default options
  await HummErrorHandler.setupErrorHandling(
    appRunner: () => runApp(MyApp()),
    trackers: [FimberTracker()],
  );
}
```

## User-Facing Error Display

You can easily add user-friendly error messages by providing a display callback:

```dart
// Initialize with error display capabilities
await HummErrorHandler.setupErrorHandling(
  appRunner: () => runApp(MyApp()),
  trackers: [FimberTracker()],
  
  // This will be called when errors occur
  errorDisplayCallback: (String message, {Map<String, dynamic>? additionalData}) {
    // Show a toast, dialog, snackbar, etc.
    showToast(message);
  },
  
  // Custom error translation
  errorTranslationCallback: (error, stackTrace, source) {
    // Translate specific errors to user-friendly messages
    if (error.toString().contains('permission')) {
      return 'You don\'t have permission to perform this action';
    }
    
    // Return null to use default error message
    return null;
  },
  
  // Default error message
  defaultErrorMessage: 'Something went wrong',
);
```

You can also update these settings later:

```dart
final errorHandler = HummErrorHandler();

// Set or update display callback
errorHandler.setErrorDisplayCallback((message, {additionalData}) {
  showCustomDialog(message);
});

// Set or update translation function
errorHandler.setErrorTranslationCallback((error, stackTrace, source) {
  // Your translation logic
  return 'User-friendly message';
});

// Update default message
errorHandler.setDefaultErrorMessage('Oops! An error occurred');

// Control which errors are displayed to users
errorHandler.setShouldDisplayErrorCallback((error, stackTrace) {
  // Only show critical errors to users
  return isCriticalError(error);
});
```- ✅ Integration with Fimber for advanced logging capabilities
- ✅ User-facing error display with customizable messages

### Advanced Setup

```dart
import 'package:flutter/material.dart';
import 'package:humm_error_handler/humm_error_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final errorHandler = HummErrorHandler();
  await errorHandler.init(
    storageKey: 'my_custom_errors_key', // Custom key for SharedPreferences
    trackers: [
      FimberTracker(
        logLevel: LogLevel.E,
        includeAdditionalData: true,
      ),
      // Add more trackers as needed
    ],
  );
  
  // Configure Flutter error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    errorHandler.handleError(
      details.exception,
      details.stack ?? StackTrace.empty,
      source: 'Flutter',
    );
  };
  
  // Run the app with Zone error handling
  runZonedGuarded(
    () => runApp(MyApp()),
    (error, stackTrace) {
      errorHandler.handleError(error, stackTrace, source: 'Zone');
    },
  );
}
```

### Manual Error Handling

```dart
void someFunction() {
  try {
    // Your code that might throw
    throw Exception('Something went wrong');
  } catch (e, stackTrace) {
    // Get the singleton instance and handle the error
    HummErrorHandler().handleError(
      e,
      stackTrace,
      source: 'someFunction',
      additionalData: {
        'userId': 'user123',
        'action': 'login',
      },
    );
  }
}
```

## Adding Custom Trackers

### Firebase Crashlytics

First, add Firebase Crashlytics to your project:

```yaml
dependencies:
  firebase_core: ^2.8.0
  firebase_crashlytics: ^3.0.16
```

Then create a Crashlytics tracker:

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:humm_error_handler/humm_error_handler.dart';

class CrashlyticsTracker implements HummErrorTracker {
  final FirebaseCrashlytics _crashlytics;
  
  CrashlyticsTracker({FirebaseCrashlytics? crashlytics}) 
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;
  
  @override
  Future<void> trackError({
    required dynamic error,
    required StackTrace stackTrace,
    String? source,
    Map<String, dynamic>? additionalData,
  }) async {
    // Add custom keys if additional data exists
    if (additionalData != null && additionalData.isNotEmpty) {
      for (final entry in additionalData.entries) {
        await _crashlytics.setCustomKey(entry.key, entry.value.toString());
      }
    }
    
    // Add source as a custom key
    if (source != null) {
      await _crashlytics.setCustomKey('error_source', source);
    }
    
    // Record error to Crashlytics
    await _crashlytics.recordError(
      error,
      stackTrace,
      reason: 'Error from ${source ?? 'unknown'}',
      fatal: false,
    );
  }
}
```

And use it in your app:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Plant a Fimber tree first (required for Fimber to work)
  if (kDebugMode) {
    Fimber.plantTree(DebugTree());
  }
  
  await HummErrorHandler.setupErrorHandling(
    appRunner: () => runApp(MyApp()),
    trackers: [
      FimberTracker(),
      CrashlyticsTracker(),
    ],
  );
}
```

### Sentry

First, add Sentry to your project:

```yaml
dependencies:
  sentry: ^7.1.0
```

Then create a Sentry tracker:

```dart
import 'package:sentry/sentry.dart';
import 'package:humm_error_handler/humm_error_handler.dart';

class SentryTracker implements HummErrorTracker {
  SentryTracker();
  
  @override
  Future<void> trackError({
    required dynamic error,
    required StackTrace stackTrace,
    String? source,
    Map<String, dynamic>? additionalData,
  }) async {
    // Prepare additional context
    final Map<String, dynamic> context = {};
    
    // Add custom data if it exists
    if (additionalData != null && additionalData.isNotEmpty) {
      context.addAll(additionalData);
    }
    
    // Add source as part of context
    if (source != null) {
      context['error_source'] = source;
    }
    
    // Create scope with additional information
    final scope = Scope();
    scope.setContexts('error_context', context);
    
    // Send event to Sentry
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: source != null ? {'source': source} : null,
    );
  }
}
```

And use it in your app:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Sentry
  await Sentry.init(
    (options) {
      options.dsn = 'YOUR_SENTRY_DSN';
      options.tracesSampleRate = 1.0;
    },
    appRunner: () {}, // Empty because we'll use our own error handler
  );
  
  // Plant a Fimber tree
  if (kDebugMode) {
    Fimber.plantTree(DebugTree());
  }
  
  await HummErrorHandler.setupErrorHandling(
    appRunner: () => runApp(MyApp()),
    trackers: [
      FimberTracker(),
      SentryTracker(),
    ],
  );
}
```

## Custom Storage Implementation

You can create your own storage implementation by extending `HummErrorStorage`:

```dart
import 'package:humm_error_handler/humm_error_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class FileErrorStorage extends HummErrorStorage {
  FileErrorStorage({required super.storageKey});
  
  Future<File> get _logFile async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    return File('$path/$storageKey.log');
  }
  
  @override
  Future<String?> getErrorLog() async {
    final file = await _logFile;
    if (await file.exists()) {
      return await file.readAsString();
    }
    return '';
  }
  
  @override
  Future<void> saveErrorLog(String content) async {
    final file = await _logFile;
    await file.writeAsString(content);
  }
}
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.