import 'package:flutter/material.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';

class StartupConfigScreen extends StatelessWidget {
  const StartupConfigScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Initial Setup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Customize Your Experience',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 30),
            // Add configuration options here
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/home');
              },
              child: const Text('Complete Setup'),
            ),
          ],
        ),
      ),
    );
  }
}
