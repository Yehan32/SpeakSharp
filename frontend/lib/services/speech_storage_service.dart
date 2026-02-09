import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:Speak_Sharp/models/speech_model.dart';

class SpeechStorageService {
  static const String _storageKey = 'speech_history';

  // Save a speech to history
  static Future<bool> saveSpeech(SpeechModel speech) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Retrieve existing speeches
      final List<SpeechModel> speeches = await getSpeechesFromLocalStorage();

      // Add new speech
      speeches.add(speech);

      // Convert to JSON string and store
      final speechesJson = speeches.map((s) => s.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(speechesJson));

      return true;
    } catch (e) {
      debugPrint('Error saving speech: $e');
      return false;
    }
  }

  // Get all saved speeches from local storage
  static Future<List<SpeechModel>> getSpeechesFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final speechesString = prefs.getString(_storageKey);

      if (speechesString == null) {
        return [];
      }

      final speechesJson = jsonDecode(speechesString) as List;
      return speechesJson.map((json) =>
          SpeechModel.fromJson(json as Map<String, dynamic>)
      ).toList();
    } catch (e) {
      debugPrint('Error retrieving speeches: $e');
      return [];
    }
  }

  static int _parseDurationString(String? durationStr) {
    if (durationStr == null) return 0;
    try {
      final parts = durationStr.split(':');
      if (parts.length == 2) {
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);
        return (minutes * 60 + seconds);
      }
      return 0;
    } catch (e) {
      debugPrint('Error parsing duration: $e');
      return 0;
    }
  }

  // Get all saved speeches from Firestore
  static Future<List<SpeechModel>> getSpeeches() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No user logged in');
        return [];
      }

      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final speechesCollection = userDoc.collection('speeches');

      final QuerySnapshot speechDocs = await speechesCollection
          .orderBy('recorded_at', descending: true)
          .get();

      if (speechDocs.docs.isEmpty) {
        return [];
      }

      return speechDocs.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        try {
          final durationInSeconds = _parseDurationString(data['actual_duration'] as String?);
          final audioUrl = data['audio_url'] as String? ?? '';

          return SpeechModel(
            id: doc.id,
            userId: user.uid,
            topic: data['topic'] ?? 'Untitled Speech',
            speechType: data['speech_type'] ?? 'Prepared Speech',
            recordedAt: (data['recorded_at'] as Timestamp).toDate(),
            duration: durationInSeconds,
            audioUrl: audioUrl,
            overallScore: (data['overall_score'] as num?)?.toDouble() ?? 0.0,
            analysis: AnalysisResult(
              speechDevelopment: (data['speech_development_score'] as num?)?.toDouble() ?? 0.0,
              proficiency: (data['proficiency_score'] as num?)?.toDouble() ?? 0.0,
              voiceAnalysis: (data['voice_analysis_score'] as num?)?.toDouble() ?? 0.0,
              effectiveness: (data['effectiveness_score'] as num?)?.toDouble() ?? 0.0,
              vocabulary: (data['vocabulary_evaluation_score'] as num?)?.toDouble() ?? 0.0,
              transcription: data['transcription'] ?? '',
              fillerWords: [],
              suggestions: [],
              vocalMetrics: VocalMetrics(
                wordsPerMinute: 0,
                pitchRange: 'Moderate',
                volumeVariation: 'Moderate',
                paceChanges: 'Moderate',
                uniqueWordsPercentage: 0.0,
              ),
            ),
          );
        } catch (e) {
          debugPrint('Error creating SpeechModel from document ${doc.id}: $e');
          rethrow;
        }
      }).toList();

    } catch (e) {
      debugPrint('Error in getSpeeches: $e');
      return [];
    }
  }
}
