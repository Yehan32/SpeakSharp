class ApiConstants {
  static const String RAILWAY_URL = "https://speaksharp-production.up.railway.app";

  // Toggle between local and production
  static const bool USE_RAILWAY = true;  // Set to false for local testing

  static const String LOCAL_URL = "http://10.0.2.2:8000";  // Android Emulator
  // static const String LOCAL_URL = "http://127.0.0.1:8000";  // iOS Simulator

  static String get baseUrl => USE_RAILWAY ? RAILWAY_URL : LOCAL_URL;

  // API Endpoints
  static String get analyzeEndpoint => "$baseUrl/api/v2/analyze";
  static String get quickAnalyzeEndpoint => "$baseUrl/api/v2/quick-analyze";
  static String get historyEndpoint => "$baseUrl/api/v2/history";
  static String get analysisEndpoint => "$baseUrl/api/v2/analysis";
  static String get healthEndpoint => "$baseUrl/health";
  static String get docsEndpoint => "$baseUrl/docs";

  // Analysis Depths
  static const List<String> ANALYSIS_DEPTHS = [
    "basic",
    "standard",
    "advanced",
  ];

  static const Map<String, String> ANALYSIS_DEPTH_DESCRIPTIONS = {
    "basic": "Quick analysis (faster)",
    "standard": "Complete analysis (recommended)",
    "advanced": "Detailed analysis with topic relevance",
  };

  // Gender Options
  static const List<String> GENDER_OPTIONS = [
    "auto",
    "male",
    "female",
  ];

  // Expected Durations
  static const List<String> DURATION_OPTIONS = [
    "1-2 minutes",
    "3-5 minutes",
    "5-7 minutes",
    "7-10 minutes",
    "10-15 minutes",
    "15+ minutes",
  ];

  // Supported Audio Formats
  static const List<String> AUDIO_FORMATS = [
    'mp3',
    'wav',
    'm4a',
    'ogg',
    'flac',
  ];

  // Score Thresholds
  static const double EXCELLENT_SCORE = 85.0;
  static const double GOOD_SCORE = 70.0;
  static const double FAIR_SCORE = 55.0;

  // Pagination
  static const int HISTORY_PAGE_SIZE = 20;
  static const int RECENT_ACTIVITY_LIMIT = 5;

  // Timeouts
  static const Duration API_TIMEOUT = Duration(seconds: 300);
  static const Duration QUICK_ANALYSIS_TIMEOUT = Duration(seconds: 60);

  // Error Messages
  static const String ERROR_NO_INTERNET = "No internet connection";
  static const String ERROR_BACKEND_UNREACHABLE = "Cannot reach server";
  static const String ERROR_INVALID_AUDIO = "Invalid audio file";
  static const String ERROR_UPLOAD_FAILED = "Upload failed";
  static const String ERROR_ANALYSIS_FAILED = "Analysis failed";

  // Helper Methods
  static String getScoreGrade(double score) {
    if (score >= EXCELLENT_SCORE) return "A+";
    if (score >= 80) return "A";
    if (score >= GOOD_SCORE) return "B+";
    if (score >= 65) return "B";
    if (score >= FAIR_SCORE) return "C+";
    if (score >= 50) return "C";
    return "D";
  }

  static String getScoreLabel(double score) {
    if (score >= EXCELLENT_SCORE) return "Excellent";
    if (score >= GOOD_SCORE) return "Good";
    if (score >= FAIR_SCORE) return "Fair";
    return "Needs Improvement";
  }

  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }
}