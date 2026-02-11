import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:Speak_Sharp/providers/auth_provider.dart';
import 'package:Speak_Sharp/providers/speech_provider.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';
import 'package:Speak_Sharp/screens/splash_screen.dart';
import 'package:Speak_Sharp/screens/upload_audio_screen.dart';
import 'package:Speak_Sharp/screens/onboarding/welcome_screen.dart';
import 'package:Speak_Sharp/screens/onboarding/features_screen.dart';
import 'package:Speak_Sharp/screens/onboarding/ready_screen.dart';
import 'package:Speak_Sharp/screens/onboarding/tutorial_screen.dart';
import 'package:Speak_Sharp/screens/onboarding/startup_config_screen.dart';
import 'package:Speak_Sharp/screens/auth/login_screen.dart';
import 'package:Speak_Sharp/screens/auth/register_screen.dart';
import 'package:Speak_Sharp/screens/home/home_screen.dart';
import 'package:Speak_Sharp/screens/recording/speech_details_dialog.dart';
import 'package:Speak_Sharp/screens/recording/recording_screen.dart';
import 'package:Speak_Sharp/screens/recording/playback_screen.dart';
import 'package:Speak_Sharp/screens/analysis/feedback_screen.dart';
import 'package:Speak_Sharp/screens/analysis/filler_words_screen.dart';
import 'package:Speak_Sharp/screens/analysis/advanced_analysis_screen.dart';
import 'package:Speak_Sharp/screens/history/history_screen.dart';
import 'package:Speak_Sharp/screens/history/search_screen.dart';
import 'package:Speak_Sharp/screens/profile/profile_screen.dart';
import 'package:Speak_Sharp/screens/profile/progress_dashboard_screen.dart';
import 'package:Speak_Sharp/screens/settings/settings_screen.dart';
import 'package:Speak_Sharp/screens/settings/notification_center_screen.dart';
import 'package:Speak_Sharp/screens/settings/payment_screen.dart';
import 'package:Speak_Sharp/screens/analysis/Full_analysis_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SpeechProvider()),
      ],
      child: MaterialApp(
        title: 'Speak Sharp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/splash',
        onGenerateRoute: (settings) {
          if (settings.name == '/recording') {
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => RecordingScreen(
                topic: args?['topic'] ?? 'Untitled',
                expectedDuration: args?['expectedDuration'] ?? '1-2 minutes',
              ),
            );
          }
          if (settings.name == '/playback') {
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => PlaybackScreen(
                audioPath: args?['audioPath'] ?? '',
                topic: args?['topic'] ?? 'Untitled',
                expectedDuration: args?['expectedDuration'] ?? '1-2 minutes',
                recordingDuration: args?['recordingDuration'] ?? 0,
              ),
            );
          }
          if (settings.name == '/feedback') {
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => FeedbackScreen(
                analysisResults: args?['analysisResults'] ?? {},
                audioPath: args?['audioPath'] ?? '',
              ),
            );
          }
          if (settings.name == '/filler-words') {
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => FillerWordsScreen(
                fillerAnalysis: args?['fillerAnalysis'] ?? {},
                transcription: args?['transcription'] ?? '',
              ),
            );
          }
          if (settings.name == '/advanced-analysis') {
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => AdvancedAnalysisScreen(
                analysisResults: args?['analysisResults'] ?? {},
              ),
            );
          }
          return null;
        },
        routes: {
          '/upload-audio': (context) => const UploadAudioScreen(),
          '/splash': (context) => const SplashScreen(),
          '/onboarding/welcome': (context) => const WelcomeScreen(),
          '/onboarding/features': (context) => const FeaturesScreen(),
          '/onboarding/ready': (context) => const ReadyScreen(),
          '/onboarding/tutorial': (context) => const TutorialScreen(),
          '/onboarding/startup': (context) => const StartupConfigScreen(),
          '/auth/login': (context) => const LoginScreen(),
          '/auth/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/history': (context) => const HistoryScreen(),
          '/search': (context) => const SearchScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/progress': (context) => const ProgressDashboardScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/notifications': (context) => const NotificationCenterScreen(),
          '/payment': (context) => const PaymentScreen(),
          '/full-analysis': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return FullAnalysisScreen(analysisData: args);
          },
        },
      ),
    );
  }
}
