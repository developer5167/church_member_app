import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SuccessScreen extends StatelessWidget {
  final String title;
  final String message;

  const SuccessScreen({
    super.key,
    this.title = 'Registration successful',
    this.message = 'Your attendance has been recorded successfully.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Success'),
        automaticallyImplyLeading: false, // Prevents back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Optional: Add an icon for visual feedback
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                // Option 1: Close app
                SystemNavigator.pop();
                // Option 2: Navigate to home if app should stay open
                // Navigator.pushNamedAndRemoveUntil(
                //   context,
                //   '/home',
                //   (route) => false
                // );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Done', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
