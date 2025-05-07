import 'dart:async';

import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:humm_error_handler/humm_error_handler.dart';
import 'package:humm_error_handler_example/screens/home_screen.dart';
import 'package:humm_error_handler_example/trackers/custom_tracker.dart';


void main() {
  // Plant a debug tree for Fimber
  Fimber.plantTree(DebugTree());

  // Run the app with error handling
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize the error handler
      await _initializeErrorHandler();

      // Run the app
      runApp(const MyApp());
    },
    (Object error, StackTrace stack) async {
      // Use HummErrorHandler to handle Zone errors
      HummErrorHandler().handleError(error, stack, source: 'Zone');
    },
  );
}

Future<void> _initializeErrorHandler() async {
  await HummErrorHandler.setup(
    // Add trackers
    trackers: [
      FimberTracker(),
      CustomTracker(enabled: true),
    ],
    // Display errors to the user
    errorDisplayCallback: (String message, {Map<String, dynamic>? additionalData}) {
      Fimber.i('Displaying error to user: $message');
      // In a real app, you would show a snackbar, dialog, etc.
    },
    // Translate errors to user-friendly messages
    errorTranslationCallback: (dynamic error, StackTrace stackTrace, String? source) {
      if (error is FormatException) {
        return 'Invalid format: ${error.message}';
      }
      return null; // Use default message for other errors
    },
    // Default error message
    defaultErrorMessage: 'Something went wrong',
    // Maximum log size
    logSize: 1000000,
  );

  // Setup Flutter error handling
  HummErrorHandler().setupFlutterErrorHandling();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HummErrorHandler Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}