import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String baseUrl = "https://speaksharp-production.up.railway.app";

  // API Endpoints
  static const String analyzeEndpoint = "$baseUrl/api/v2/analyze";
  static const String quickAnalyzeEndpoint = "$baseUrl/api/v2/quick-analyze";
  static const String historyEndpoint = "$baseUrl/api/v2/history";
  static const String analysisEndpoint = "$baseUrl/api/v2/analysis";
  static const String healthEndpoint = "$baseUrl/health";

  // Timeout duration
  static const Duration timeout = Duration(seconds: 300);

  /// Health check - Test if backend is running
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse(healthEndpoint),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Health check failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Backend unreachable: $e');
    }
  }

  /// Full speech analysis with all parameters
  static Future<Map<String, dynamic>> analyzeSpeech({
    required File audioFile,
    required String userId,
    String? speechTitle,
    String? topic,
    String expectedDuration = "5-7 minutes",
    String gender = "auto",
    String analysisDepth = "standard",
    Function(double)? onProgress,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(analyzeEndpoint),
      );

      // Add audio file
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio_file',
          audioFile.path,
        ),
      );

      // Add parameters
      request.fields['user_id'] = userId;
      if (speechTitle != null) request.fields['speech_title'] = speechTitle;
      if (topic != null) request.fields['topic'] = topic;
      request.fields['expected_duration'] = expectedDuration;
      request.fields['gender'] = gender;
      request.fields['analysis_depth'] = analysisDepth;

      // Send request
      final streamedResponse = await request.send().timeout(timeout);

      // Simulate progress (actual progress tracking would require backend support)
      if (onProgress != null) {
        for (var i = 0; i <= 100; i += 10) {
          await Future.delayed(const Duration(milliseconds: 300));
          onProgress(i / 100);
        }
      }

      // Get response
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Analysis failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to analyze speech: $e');
    }
  }

  /// Quick analysis (preview mode)
  static Future<Map<String, dynamic>> quickAnalyze({
    required File audioFile,
    Function(double)? onProgress,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(quickAnalyzeEndpoint),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'audio_file',
          audioFile.path,
        ),
      );

      final streamedResponse = await request.send().timeout(timeout);

      if (onProgress != null) {
        for (var i = 0; i <= 100; i += 20) {
          await Future.delayed(const Duration(milliseconds: 200));
          onProgress(i / 100);
        }
      }

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Quick analysis failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to quick analyze: $e');
    }
  }

  /// Get user's speech history
  static Future<List<Map<String, dynamic>>> getUserHistory({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final url = Uri.parse('$historyEndpoint/$userId?limit=$limit&offset=$offset');

      final response = await http.get(url).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['analyses'] ?? []);
      } else {
        throw Exception('Failed to get history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch history: $e');
    }
  }

  /// Get specific analysis by ID
  static Future<Map<String, dynamic>> getAnalysis({
    required String analysisId,
    required String userId,
  }) async {
    try {
      final url = Uri.parse('$analysisEndpoint/$analysisId?user_id=$userId');

      final response = await http.get(url).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Analysis not found');
      } else {
        throw Exception('Failed to get analysis: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch analysis: $e');
    }
  }

  /// Delete analysis
  static Future<bool> deleteAnalysis({
    required String analysisId,
    required String userId,
  }) async {
    try {
      final url = Uri.parse('$analysisEndpoint/$analysisId?user_id=$userId');

      final response = await http.delete(url).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 404) {
        throw Exception('Analysis not found');
      } else {
        throw Exception('Failed to delete: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete analysis: $e');
    }
  }

  /// Get user statistics (from backend or Firebase)
  static Future<Map<String, dynamic>> getUserStatistics({
    required String userId,
  }) async {
    try {
      // First try to get from history
      final history = await getUserHistory(userId: userId, limit: 100);

      if (history.isEmpty) {
        return {
          'total_speeches': 0,
          'average_score': 0.0,
          'best_score': 0.0,
          'total_duration': 0,
        };
      }

      // Calculate statistics
      int totalSpeeches = history.length;
      double totalScore = 0;
      double bestScore = 0;
      int totalDuration = 0;

      for (var analysis in history) {
        double score = (analysis['overall_score'] ?? 0).toDouble();
        totalScore += score;
        if (score > bestScore) bestScore = score;

        // Parse duration if available
        var duration = analysis['duration'];
        if (duration != null && duration['seconds'] != null) {
          totalDuration += (duration['seconds'] as num).toInt();
        }
      }

      double averageScore = totalScore / totalSpeeches;

      return {
        'total_speeches': totalSpeeches,
        'average_score': averageScore,
        'best_score': bestScore,
        'total_duration': totalDuration,
      };
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }

  /// Get current user ID
  static String? getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// Check if user is authenticated
  static bool isAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }
}