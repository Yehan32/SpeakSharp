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
        
        // Use the factory constructor of SpeechModel to handle data parsing
        // and consistency between local/remote storage formats.
        // If Firestore data uses different keys, we may need a specific mapper.
        
        Map<String, dynamic> jsonData = Map<String, dynamic>.from(data);
        jsonData['id'] = doc.id;
        jsonData['user_id'] = user.uid;
        
        // Map Firestore 'recorded_at' (Timestamp) to JSON string expected by fromJson
        if (data['recorded_at'] is Timestamp) {
          jsonData['created_at'] = (data['recorded_at'] as Timestamp).toDate().toIso8601String();
        }

        return SpeechModel.fromJson(jsonData);
      }).toList();

    } catch (e) {
      debugPrint('Error in getSpeeches: $e');
      return [];
    }
  }
}