import 'package:flutter/material.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Hero Section
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                'SS',
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontSize: 32,
                                  color: AppTheme.accentColor,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Title
                          Text(
                            'Welcome to\nSpeak Sharp',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontSize: 36,
                              color: Colors.white,
                            ),
                          ),
                          
                          const SizedBox(height: 15),
                          
                          // Description
                          Text(
                            'Your personal AI-powered speech coach that helps you become a confident speaker',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Curved bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.elliptical(200, 60),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Action Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                // Page Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 25),
                
                // Get Started Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/onboarding/features');
                    },
                    child: const Text('Get Started'),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Skip Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/auth/login');
                    },
                    child: const Text('Skip Tutorial'),
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
