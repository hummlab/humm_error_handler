import 'package:flutter/material.dart';
import 'package:humm_error_handler/humm_error_handler.dart';
import 'package:humm_error_handler_example/screens/error_demo_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HummErrorHandler Demo'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'This demo shows how to use the HummErrorHandler package',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ErrorDemoScreen(),
                    ),
                  );
                },
                child: const Text('Go to Error Demo'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  HummCrashlogScreen.show(
                    context,
                    primaryColor: Theme.of(context).colorScheme.primary,
                    secondaryColor: Theme.of(context).colorScheme.onPrimary,
                  );
                },
                child: const Text('View Error Logs'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Example of manually handling an error
                  try {
                    throw Exception('This is a test exception from Home Screen');
                  } catch (error, stackTrace) {
                    HummErrorHandler().handleError(
                      error,
                      stackTrace,
                      source: 'HomeScreen',
                      additionalData: {
                        'screen': 'Home',
                        'timestamp': DateTime.now().toString(),
                      },
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error handled! Check the logs.'),
                      ),
                    );
                  }
                },
                child: const Text('Trigger Test Error'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}