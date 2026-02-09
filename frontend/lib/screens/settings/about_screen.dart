import 'package:flutter/material.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('about')),
      body: const Center(child: Text('Implementation Here')),
    );
  }
}
