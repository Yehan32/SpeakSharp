class SpeechModel {
  final String? id;
  final String? userId;
  final String? title;
  final String? topic;
  final String? duration;
  final DateTime? createdAt;
  final String? audioUrl;
  final String? transcription;

  // Overall Score (0-100)
  final double? overallScore;

  // Category Scores (0-20 each)
  final double? grammarScore;
  final double? voiceScore;
  final double? structureScore;
  final double? effectivenessScore;
  final double? proficiencyScore;

  // Detailed Metrics - Fluency
  final int? fillerWordCount;
  final int? pauseCount;
  final String? wordsPerMinute;

  // Detailed Metrics - Voice
  final String? pitchVariation;
  final String? volumeControl;
  final String? emphasisScore;

  // Detailed Metrics - Structure
  final bool? hasIntro;
  final bool? hasBody;
  final bool? hasConclusion;

  // Detailed Metrics - Vocabulary
  final int? uniqueWordCount;
  final int? totalWords;
  final String? vocabularyRichness;

  // Additional fields
  final Map<String, dynamic>? detailedAnalysis;
  final List<String>? suggestions;
  final String? status;

  SpeechModel({
    this.id,
    this.userId,
    this.title,
    this.topic,
    this.duration,
    this.createdAt,
    this.audioUrl,
    this.transcription,
    this.overallScore,
    this.grammarScore,
    this.voiceScore,
    this.structureScore,
    this.effectivenessScore,
    this.proficiencyScore,
    this.fillerWordCount,
    this.pauseCount,
    this.wordsPerMinute,
    this.pitchVariation,
    this.volumeControl,
    this.emphasisScore,
    this.hasIntro,
    this.hasBody,
    this.hasConclusion,
    this.uniqueWordCount,
    this.totalWords,
    this.vocabularyRichness,
    this.detailedAnalysis,
    this.suggestions,
    this.status,
  });

  factory SpeechModel.fromJson(Map<String, dynamic> json) {
    // Helper to safely get scores from nested structures
    double? getScore(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is Map) {
        // Check for score field in nested object
        if (value.containsKey('score')) {
          final score = value['score'];
          if (score is num) return score.toDouble();
        }
        // Check for value field
        if (value.containsKey('value')) {
          final val = value['value'];
          if (val is num) return val.toDouble();
        }
      }
      return 0.0;
    }

    // Helper to get nested value
    dynamic getNestedValue(Map<String, dynamic> json, List<String> keys,
        {dynamic defaultValue}) {
      dynamic current = json;
      for (var key in keys) {
        if (current is Map && current.containsKey(key)) {
          current = current[key];
        } else {
          return defaultValue;
        }
      }
      return current ?? defaultValue;
    }

    // Get scores from various possible locations
    final scores = json['scores'] ?? {};
    final detailedAnalysis = json['detailed_analysis'] ?? json['detailedAnalysis'] ?? {};

    return SpeechModel(
      id: json['id'] ?? json['analysis_id'],
      userId: json['user_id'] ?? json['userId'],
      title: json['speech_title'] ?? json['title'],
      topic: json['topic'],
      duration: json['duration'] ?? json['expected_duration'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now()),
      audioUrl: json['audio_url'] ?? json['audioUrl'],
      transcription: json['transcription'] ?? detailedAnalysis['transcription'],

      // Overall Score - calculate from category scores if not provided
      overallScore: json['overall_score']?.toDouble() ??
          json['overallScore']?.toDouble() ??
          _calculateOverallScore(scores),

      // Category Scores (0-20 each)
      grammarScore: getScore(scores['grammar_score'] ?? scores['vocabulary'] ?? scores['grammar_vocabulary']),
      voiceScore: getScore(scores['voice_score'] ?? scores['voice_modulation']),
      structureScore: getScore(scores['structure_score'] ?? scores['speech_structure']),
      effectivenessScore: getScore(scores['effectiveness_score'] ?? scores['speech_effectiveness']),
      proficiencyScore: getScore(scores['proficiency_score']),

      // Fluency Metrics - ✅ READ FROM TOP LEVEL
      fillerWordCount: json['filler_word_count'] ?? 0,
      pauseCount: json['pause_count'] ?? 0,
      wordsPerMinute: json['words_per_minute']?.toString() ?? 'N/A',

      // Voice Metrics - ✅ READ FROM TOP LEVEL
      pitchVariation: json['pitch_variation']?.toString() ?? 'N/A',
      volumeControl: json['volume_control']?.toString() ?? 'N/A',
      emphasisScore: json['emphasis']?.toString() ?? 'N/A',

      // Structure Metrics - ✅ READ FROM TOP LEVEL
      hasIntro: json['has_intro'] ?? false,
      hasBody: json['has_body'] ?? false,
      hasConclusion: json['has_conclusion'] ?? false,

      // Vocabulary Metrics - ✅ READ FROM TOP LEVEL
      uniqueWordCount: json['unique_word_count'] ?? 0,
      totalWords: json['total_words'] ?? 0,
      vocabularyRichness: json['vocabulary_richness']?.toString() ?? 'N/A',

      detailedAnalysis: detailedAnalysis,
      suggestions: (json['suggestions'] as List?)?.cast<String>(),
      status: json['status'] ?? 'completed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'speech_title': title,
      'topic': topic,
      'duration': duration,
      'created_at': createdAt?.toIso8601String(),
      'audio_url': audioUrl,
      'transcription': transcription,
      'overall_score': overallScore,
      'scores': {
        'grammar': grammarScore,
        'voice': voiceScore,
        'structure': structureScore,
        'effectiveness': effectivenessScore,
        'proficiency': proficiencyScore,
      },
      'detailed_analysis': detailedAnalysis,
      'suggestions': suggestions,
      'status': status,
    };
  }

  // Calculate overall score from category scores
  static double _calculateOverallScore(Map<String, dynamic> scores) {
    if (scores.isEmpty) return 0.0;

    double total = 0.0;
    int count = 0;

    // Extract scores
    final grammarScore = _extractScore(scores['grammar'] ?? scores['vocabulary']);
    final voiceScore = _extractScore(scores['voice'] ?? scores['voice_modulation']);
    final structureScore = _extractScore(scores['structure'] ?? scores['speech_structure']);
    final effectivenessScore = _extractScore(scores['effectiveness'] ?? scores['speech_effectiveness']);
    final proficiencyScore = _extractScore(scores['proficiency']);

    if (grammarScore > 0) {
      total += grammarScore;
      count++;
    }
    if (voiceScore > 0) {
      total += voiceScore;
      count++;
    }
    if (structureScore > 0) {
      total += structureScore;
      count++;
    }
    if (effectivenessScore > 0) {
      total += effectivenessScore;
      count++;
    }
    if (proficiencyScore > 0) {
      total += proficiencyScore;
      count++;
    }

    if (count == 0) return 0.0;

    // Convert to 0-100 scale (each score is 0-20, so multiply by 5)
    return (total / count) * 5;
  }

  static double _extractScore(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is Map) {
      if (value.containsKey('score')) {
        final score = value['score'];
        if (score is num) return score.toDouble();
      }
      if (value.containsKey('value')) {
        final val = value['value'];
        if (val is num) return val.toDouble();
      }
    }
    return 0.0;
  }
}