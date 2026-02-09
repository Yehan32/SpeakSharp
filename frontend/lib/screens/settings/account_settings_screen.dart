import 'package:flutter/material.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('account settings')),
      body: const Center(child: Text('Implementation Here')),
    );
  }
}
