import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AudioAnalysisService {
  // ✅ HARDCODE THE VALUES (No import needed!)
  static const bool USE_RAILWAY = true;  // Set to false for local testing
  static const String RAILWAY_URL = "https://speaksharp-production.up.railway.app";
  static const String LOCAL_URL = "http://10.0.2.2:8000";  // Android Emulator

  static String get baseUrl => USE_RAILWAY ? RAILWAY_URL : LOCAL_URL;

  /// Uploads audio data and returns the analysis results
  static Future<Map<String, dynamic>> analyzeAudio({
    required Uint8List audioData,
    required String fileName,
    required String topic,
    required String speechType,
    required String expectedDuration,
    required String actualDuration,
    required String userId,
  }) async {
    // ✅ USE CORRECT ENDPOINT
    final uri = Uri.parse('$baseUrl/analyze');  // Changed from /upload/

    final request = http.MultipartRequest('POST', uri)
      ..fields['user_id'] = userId
      ..fields['topic'] = topic
      ..fields['expected_duration'] = expectedDuration
      ..files.add(http.MultipartFile.fromBytes(
        'audio',  // Changed from 'file' to 'audio'
        audioData,
        filename: fileName,
        contentType: MediaType('audio', 'wav'),
      ));

    print('🔵 Uploading to: $uri');
    print('🔵 Topic: $topic');
    print('🔵 User ID: $userId');

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('🔵 Response status: ${response.statusCode}');
    print('🔵 Response body: ${response.body.substring(0, 200)}...');  // First 200 chars

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to analyze audio: ${response.statusCode} - ${response.body}');
    }
  }
}