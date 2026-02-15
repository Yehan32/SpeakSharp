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
    double getScore(dynamic value) {
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

    // Get scores from various possible locations
    final scores = json['scores'] ?? {};
    final detailedAnalysis = json['detailed_analysis'] ?? json['detailedAnalysis'] ?? {};

    // Parse category scores - try both formats (with and without _score suffix)
    final grammarScore = getScore(
        scores['grammar'] ??
            scores['grammar_score'] ??
            scores['vocabulary'] ??
            scores['grammar_vocabulary']
    );

    final voiceScore = getScore(
        scores['voice'] ??
            scores['voice_score'] ??
            scores['voice_modulation']
    );

    final structureScore = getScore(
        scores['structure'] ??
            scores['structure_score'] ??
            scores['speech_structure']
    );

    final effectivenessScore = getScore(
        scores['effectiveness'] ??
            scores['effectiveness_score'] ??
            scores['speech_effectiveness']
    );

    final proficiencyScore = getScore(
        scores['proficiency'] ??
            scores['proficiency_score']
    );

    // Calculate overall if not provided (null-safe)
    double calculatedOverall = 0.0;
    int scoreCount = 0;
    double scoreTotal = 0.0;

    // Add non-zero scores (null-safe comparison)
    if ((grammarScore) > 0.0) {
      scoreTotal += grammarScore;
      scoreCount++;
    }
    if ((voiceScore) > 0.0) {
      scoreTotal += voiceScore;
      scoreCount++;
    }
    if ((structureScore) > 0.0) {
      scoreTotal += structureScore;
      scoreCount++;
    }
    if ((effectivenessScore) > 0.0) {
      scoreTotal += effectivenessScore;
      scoreCount++;
    }
    if ((proficiencyScore) > 0.0) {
      scoreTotal += proficiencyScore;
      scoreCount++;
    }

    if (scoreCount > 0) {
      calculatedOverall = (scoreTotal / scoreCount) * 5.0; // Convert 0-20 to 0-100
    }

    // Get overall score from multiple possible locations
    final overallFromJson = json['overall_score'];
    final overallFromJsonCamel = json['overallScore'];
    final overallFromScores = scores['overall_score'];

    double finalOverallScore = calculatedOverall;
    if (overallFromJson != null && overallFromJson is num) {
      finalOverallScore = overallFromJson.toDouble();
    } else if (overallFromJsonCamel != null && overallFromJsonCamel is num) {
      finalOverallScore = overallFromJsonCamel.toDouble();
    } else if (overallFromScores != null && overallFromScores is num) {
      finalOverallScore = overallFromScores.toDouble();
    }

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
      transcription: json['transcription'],

      // Scores
      overallScore: finalOverallScore,
      grammarScore: grammarScore,
      voiceScore: voiceScore,
      structureScore: structureScore,
      effectivenessScore: effectivenessScore,
      proficiencyScore: proficiencyScore,

      // Fluency Metrics - try top level first, then nested
      fillerWordCount: json['filler_word_count'] ?? 0,
      pauseCount: json['pause_count'] ?? 0,
      wordsPerMinute: json['words_per_minute']?.toString() ?? 'N/A',

      // Voice Metrics - try top level first, then nested
      pitchVariation: json['pitch_variation']?.toString() ?? 'N/A',
      volumeControl: json['volume_control']?.toString() ?? 'N/A',
      emphasisScore: json['emphasis']?.toString() ?? 'N/A',

      // Structure Metrics - try top level first, then nested
      hasIntro: json['has_intro'] ?? false,
      hasBody: json['has_body'] ?? false,
      hasConclusion: json['has_conclusion'] ?? false,

      // Vocabulary Metrics - try top level first, then nested
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
}