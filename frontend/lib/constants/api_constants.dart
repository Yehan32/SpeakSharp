class ApiConstants {
  // Change this to your backend URL
  // For local testing: 'http://10.0.2.2:8000' (Android Emulator)
  // For local testing: 'http://localhost:8000' (iOS Simulator)
  // For production: 'https://your-backend-url.com'

  static const String baseUrl = 'http://10.0.2.2:8000'; // Android Emulator
  // static const String baseUrl = 'http://localhost:8000'; // iOS Simulator
  // static const String baseUrl = 'https://your-production-url.com';

  // API Endpoints
  static const String analyzeEndpoint = '/api/v2/analyze';
  static const String historyEndpoint = '/api/v2/history';
  static const String healthEndpoint = '/api/v2/health';

  // Timeouts
  static const Duration connectionTimeout = Duration(minutes: 5);
  static const Duration receiveTimeout = Duration(minutes: 5);
}