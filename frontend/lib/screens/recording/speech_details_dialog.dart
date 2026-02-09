import 'package:flutter/material.dart';

class SpeechDetailsDialog extends StatelessWidget {
  const SpeechDetailsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Speech Details Dialog'),
          ],
        ),
      ),
    );
  }
}
