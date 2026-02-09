import 'package:flutter/material.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';

class ThemeSelectorScreen extends StatefulWidget {
  const ThemeSelectorScreen({Key? key}) : super(key: key);

  @override
  State<ThemeSelectorScreen> createState() => _ThemeSelectorScreenState();
}

class _ThemeSelectorScreenState extends State<ThemeSelectorScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('theme selector')),
      body: const Center(child: Text('Implementation Here')),
    );
  }
}
