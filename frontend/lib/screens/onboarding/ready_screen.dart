import 'package:flutter/material.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';

class ReadyScreen extends StatelessWidget {
  const ReadyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.successGradient,
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '🚀',
                        style: TextStyle(fontSize: 120),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "You're All Set!",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          "Ready to start your speaking improvement journey? Let's record your first speech!",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/auth/login');
                    },
                    child: const Text('Start Recording'),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/auth/login');
                    },
                    child: const Text('Explore Features'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
