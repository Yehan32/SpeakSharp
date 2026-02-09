import 'package:flutter/material.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ProgressDashboardScreen> createState() => _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: const Center(child: Text('Progress Dashboard')),
    );
  }
}
