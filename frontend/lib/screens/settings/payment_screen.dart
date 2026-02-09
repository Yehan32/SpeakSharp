import 'package:flutter/material.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('payment')),
      body: const Center(child: Text('Implementation Here')),
    );
  }
}
