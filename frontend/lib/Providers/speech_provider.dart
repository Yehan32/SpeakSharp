import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Speak_Sharp/models/speech_model.dart';

class SpeechProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<SpeechModel> _speeches = [];
  bool _isLoading = false;

  List<SpeechModel> get speeches => _speeches;
  bool get isLoading => _isLoading;

  Future<void> loadSpeeches() async {
    if (_auth.currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('speeches')
          .orderBy('recordedAt', descending: true)
          .get();

      _speeches = snapshot.docs
          .map((doc) => SpeechModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error loading speeches: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSpeech(SpeechModel speech) async {
    if (_auth.currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('speeches')
          .add(speech.toJson());

      await loadSpeeches();
    } catch (e) {
      debugPrint('Error adding speech: $e');
    }
  }
}
