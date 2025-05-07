import 'package:flutter/material.dart';
import 'package:humm_error_handler/humm_error_handler.dart';

class ErrorDemoScreen extends StatelessWidget {
  const ErrorDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Demo Screen'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'This screen demonstrates different types of errors',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Create a divide by zero error
                  try {
                    final int result = 42 ~/ 0;
                    debugPrint('Result: $result'); // Never reached
                  } catch (error, stackTrace) {
                    HummErrorHandler().handleError(
                      error,
                      stackTrace,
                      source: 'DivideByZeroDemo',
                      additionalData: {'operation': 'division', 'value': 0},
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Division by zero error handled!'),
                      ),
                    );
                  }
                },
                child: const Text('Trigger Division Error'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Create a null reference error
                  try {
                    const Map<String, dynamic>? map = null;
                    final String value = map!['key'] as String;
                    debugPrint('Value: $value'); // Never reached
                  } catch (error, stackTrace) {
                    HummErrorHandler().handleError(
                      error,
                      stackTrace,
                      source: 'NullReferenceDemo',
                      additionalData: {'attempted_access': 'map["key"]'},
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Null reference error handled!'),
                      ),
                    );
                  }
                },
                child: const Text('Trigger Null Error'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Create a format exception
                  try {
                    const String invalidNumber = 'not-a-number';
                    final int parsedValue = int.parse(invalidNumber);
                    debugPrint('Parsed value: $parsedValue'); // Never reached
                  } catch (error, stackTrace) {
                    HummErrorHandler().handleError(
                      error,
                      stackTrace,
                      source: 'FormatExceptionDemo',
                      additionalData: {'invalid_value': 'not-a-number'},
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Format exception handled!'),
                      ),
                    );
                  }
                },
                child: const Text('Trigger Format Exception'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // View error logs
                  HummCrashlogScreen.show(
                    context,
                    primaryColor: Theme.of(context).colorScheme.primary,
                    secondaryColor: Theme.of(context).colorScheme.onPrimary,
                  );
                },
                child: const Text('View Error Logs'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}