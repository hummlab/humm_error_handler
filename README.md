# humm_error_handler

A Flutter library for comprehensive error handling, tracking, and reporting across your applications.

## Features

- ✅ Centralized error handling
- ✅ Error log storage with SharedPreferences
- ✅ Plugin-based architecture for error tracking
- ✅ Integration with Fimber for advanced logging capabilities
- ✅ Zone errors and Flutter errors handling
- ✅ Easily extendable with custom trackers (e.g., Crashlytics, Sentry)
- ✅ User-facing error display with customizable messages
- ✅ Built-in error log viewer UI

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  humm_error_handler: ^0.2.0
```

## Usage

### Basic Setup

```dart
import 'package:flutter/material.dart';
import 'package:humm_error_handler/humm_error_handler.dart';
import 'package:fimber/fimber.dart';

void main() {
  // Setup basic logging
  Fimber.plantTree(DebugTree());

  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      
      // Initialize error handler
      await HummErrorHandler.setup(
        trackers: [FimberTracker()],
        errorDisplayCallback: (String message, {Map<String, dynamic>? additionalData}) {
          // Show a toast, dialog, snackbar, etc.
          showToast(message);
        },
      );
      
      runApp(MyApp());
    },
    (Object error, StackTrace stack) async {
      // Delegate zone error handling to HummErrorHandler
      HummErrorHandler().handleError(error, stack, source: 'Zone');
    },
  );
}
```

### Error Display and Translation

You can easily add user-friendly error messages by providing display and translation callbacks:

```dart
await HummErrorHandler.setup(
  trackers: [FimberTracker()],
  
  // This will be called when errors occur
  errorDisplayCallback: (String message, {Map<String, dynamic>? additionalData}) {
    // Show a toast, dialog, snackbar, etc.
    showToast(message);
  },
  
  // Custom error translation
  errorTranslationCallback: (error, stackTrace, source) {
    // Translate specific errors to user-friendly messages
    if (error is FirebaseFunctionsException) {
      return translateFirebaseError(error.message);
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
```

### Integration with Firebase and runZonedGuarded

Here's a complete example showing how to integrate with Firebase in a Flutter app:

```dart
void main() {
  // Setup basic logging
  Fimber.plantTree(DebugTree());

  runZonedGuarded<Future<void>>(
    () async {
      // Flutter initialization
      WidgetsFlutterBinding.ensureInitialized();
      
      // Initialize all app resources
      await _initializeApp();
      
      // Run the app
      final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
        analytics: FirebaseAnalytics.instance
      );
      runApp(MyApp(observer: observer));
    },
    (Object error, StackTrace stack) async {
      // Use HummErrorHandler to handle Zone errors
      HummErrorHandler().handleError(error, stack, source: 'Zone');
    },
  );
}

Future<void> _initializeApp() async {
  // Setup Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Setup other resources
  // ...
  
  // Initialize HummErrorHandler with trackers
  final bool crashlogAgreement = await getUserAgreement() ?? false;
  
  await HummErrorHandler.setup(
    trackers: <HummErrorTracker>[
      FimberTracker(),
      CrashlyticsTracker(
        crashlytics: FirebaseCrashlytics.instance,
        crashlogAgreement: crashlogAgreement,
        shouldReportToCrashlytics: !isDevEnvironment || crashlogAgreement,
      ),
    ],
    errorDisplayCallback: (String message, {Map<String, dynamic>? additionalData}) {
      showErrorMessage(message);
    },
    errorTranslationCallback: (error, stackTrace, source) {
      if (error is FirebaseFunctionsException) {
        return translateFirebaseError(error.message);
      }
      return null;
    },
    defaultErrorMessage: 'Something went wrong',
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

### Firebase Crashlytics Tracker Example

Create a Crashlytics tracker that respects user preferences:

```dart
class CrashlyticsTracker implements HummErrorTracker {
  CrashlyticsTracker({
    FirebaseCrashlytics? crashlytics,
    required this.crashlogAgreement,
    required this.shouldReportToCrashlytics,
  }) : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;
  final bool crashlogAgreement;
  final bool shouldReportToCrashlytics;

  @override
  Future<void> trackError({
    required dynamic error,
    required StackTrace stackTrace,
    String? source,
    Map<String, dynamic>? additionalData,
  }) async {
    // Add additional data as custom keys
    if (additionalData != null && additionalData.isNotEmpty) {
      for (final MapEntry<String, dynamic> entry in additionalData.entries) {
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
      fatal: true,
    );

    // Add a log
    await _crashlytics.log('Error: $error');
  }

  @override
  bool shouldHandleCrashlog() {
    // Only report to Crashlytics if:
    // 1. User has given consent or we're in production
    // 2. Reporting hasn't been explicitly disabled
    return shouldReportToCrashlytics;
  }
}
```

## Migration from runZonedGuarded Direct Implementation

If you're migrating from a direct implementation of `runZonedGuarded` to using the `humm_error_handler` library, follow these steps:

1. Keep your `runZonedGuarded` block, but update the error handler to use `HummErrorHandler().handleError`
2. Move your app initialization to a separate method for clarity
3. Configure `HummErrorHandler` with appropriate trackers

### Before:
```dart
void main() async {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // ... app initialization
      runApp(MyApp());
    },
    (Object error, StackTrace stack) async => handleError(error, stack),
  );
}
```

### After:
```dart
void main() {
  // Basic logging setup
  Fimber.plantTree(DebugTree());

  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      
      // Initialize app resources
      await _initializeApp();
      
      // Run the app
      runApp(MyApp());
    },
    (Object error, StackTrace stack) async {
      // Use HummErrorHandler
      HummErrorHandler().handleError(error, stack, source: 'Zone');
    },
  );
}

Future<void> _initializeApp() async {
  // App initialization
  // ...
  
  // Configure HummErrorHandler
  await HummErrorHandler.setup(
    trackers: [
      FimberTracker(),
      CrashlyticsTracker(),
      // Other trackers
    ],
    // ...
  );
}
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.