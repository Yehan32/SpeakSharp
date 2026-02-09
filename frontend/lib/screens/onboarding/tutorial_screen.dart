import 'package:flutter/material.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutorial'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to Record',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 20),
            // Add tutorial content here
            const Text('Recording tutorial content goes here...'),
          ],
        ),
      ),
    );
  }
}
