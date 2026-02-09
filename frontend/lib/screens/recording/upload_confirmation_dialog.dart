import 'package:flutter/material.dart';

class UploadConfirmationDialog extends StatelessWidget {
  const UploadConfirmationDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Upload Confirmation'),
          ],
        ),
      ),
    );
  }
}
