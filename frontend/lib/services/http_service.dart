import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/api_constants.dart';

class HttpService {
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;
  HttpService._internal();

  Future<Map<String, dynamic>> uploadAndAnalyze({
    required File audioFile,
    required String userId,
    required String topic,
    required String expectedDuration,
    String? speechTitle,
    String gender = 'auto',
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.analyzeEndpoint}');

      final request = http.MultipartRequest('POST', uri);

      // Add audio file
      final audioStream = http.ByteStream(audioFile.openRead());
      final audioLength = await audioFile.length();

      final multipartFile = http.MultipartFile(
        'audio_file',
        audioStream,
        audioLength,
        filename: audioFile.path.split('/').last,
        contentType: MediaType('audio', 'wav'),
      );

      request.files.add(multipartFile);

      // Add form fields
      request.fields['user_id'] = userId;
      request.fields['topic'] = topic;
      request.fields['expected_duration'] = expectedDuration;
      request.fields['gender'] = gender;

      if (speechTitle != null) {
        request.fields['speech_title'] = speechTitle;
      }

      // Send request
      print('🚀 Sending analysis request to backend...');
      final streamedResponse = await request.send().timeout(
        ApiConstants.connectionTimeout,
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Analysis successful!');
        return data;
      } else {
        print('Analysis failed: ${response.body}');
        throw Exception('Analysis failed: ${response.statusCode}');
      }

    } catch (e) {
      print('HTTP Error: $e');
      rethrow;
    }
  }

  Future<bool> checkBackendHealth() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.healthEndpoint}'),
      ).timeout(Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Backend health check failed: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserHistory(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.historyEndpoint}/$userId'),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['analyses'] ?? []);
      } else {
        throw Exception('Failed to load history');
      }
    } catch (e) {
      print('Error loading history: $e');
      return [];
    }
  }
}