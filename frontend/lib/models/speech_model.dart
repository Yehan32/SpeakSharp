class SpeechModel {
  final String id;
  final String userId;
  final String topic;
  final String speechType; // Ice Breaker, Prepared, Evaluation, Table Topics
  final DateTime recordedAt;
  final int duration; // in seconds
  final String audioUrl;
  final double overallScore;
  final AnalysisResult? analysis;

  SpeechModel({
    required this.id,
    required this.userId,
    required this.topic,
    required this.speechType,
    required this.recordedAt,
    required this.duration,
    required this.audioUrl,
    required this.overallScore,
    this.analysis,
  });

  factory SpeechModel.fromJson(Map<String, dynamic> json) {
    return SpeechModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      topic: json['topic'] ?? '',
      speechType: json['speechType'] ?? '',
      recordedAt: DateTime.parse(json['recordedAt']),
      duration: json['duration'] ?? 0,
      audioUrl: json['audioUrl'] ?? '',
      overallScore: (json['overallScore'] ?? 0).toDouble(),
      analysis: json['analysis'] != null
          ? AnalysisResult.fromJson(json['analysis'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'topic': topic,
      'speechType': speechType,
      'recordedAt': recordedAt.toIso8601String(),
      'duration': duration,
      'audioUrl': audioUrl,
      'overallScore': overallScore,
      'analysis': analysis?.toJson(),
    };
  }

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get speechTypeShort {
    switch (speechType) {
      case 'Ice Breaker Speech':
        return 'Ice Breaker';
      case 'Prepared Speech':
        return 'Prepared';
      case 'Evaluation Speech':
        return 'Evaluation';
      case 'Table Topics':
        return 'Topics';
      default:
        return speechType;
    }
  }
}

class AnalysisResult {
  final double speechDevelopment;
  final double proficiency;
  final double voiceAnalysis;
  final double effectiveness;
  final double vocabulary;
  final String transcription;
  final List<FillerWord> fillerWords;
  final VocalMetrics vocalMetrics;
  final List<String> suggestions;

  AnalysisResult({
    required this.speechDevelopment,
    required this.proficiency,
    required this.voiceAnalysis,
    required this.effectiveness,
    required this.vocabulary,
    required this.transcription,
    required this.fillerWords,
    required this.vocalMetrics,
    required this.suggestions,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      speechDevelopment: (json['speechDevelopment'] ?? 0).toDouble(),
      proficiency: (json['proficiency'] ?? 0).toDouble(),
      voiceAnalysis: (json['voiceAnalysis'] ?? 0).toDouble(),
      effectiveness: (json['effectiveness'] ?? 0).toDouble(),
      vocabulary: (json['vocabulary'] ?? 0).toDouble(),
      transcription: json['transcription'] ?? '',
      fillerWords: (json['fillerWords'] as List<dynamic>?)
          ?.map((e) => FillerWord.fromJson(e))
          .toList() ??
          [],
      vocalMetrics: VocalMetrics.fromJson(json['vocalMetrics'] ?? {}),
      suggestions: List<String>.from(json['suggestions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'speechDevelopment': speechDevelopment,
      'proficiency': proficiency,
      'voiceAnalysis': voiceAnalysis,
      'effectiveness': effectiveness,
      'vocabulary': vocabulary,
      'transcription': transcription,
      'fillerWords': fillerWords.map((e) => e.toJson()).toList(),
      'vocalMetrics': vocalMetrics.toJson(),
      'suggestions': suggestions,
    };
  }

  double get averageScore {
    return (speechDevelopment + proficiency + voiceAnalysis + effectiveness + vocabulary) / 5;
  }
}

class FillerWord {
  final String word;
  final int count;
  final List<int> timestamps; // in seconds

  FillerWord({
    required this.word,
    required this.count,
    required this.timestamps,
  });

  factory FillerWord.fromJson(Map<String, dynamic> json) {
    return FillerWord(
      word: json['word'] ?? '',
      count: json['count'] ?? 0,
      timestamps: List<int>.from(json['timestamps'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'count': count,
      'timestamps': timestamps,
    };
  }
}

class VocalMetrics {
  final int wordsPerMinute;
  final String pitchRange; // Good, Moderate, Needs Improvement
  final String volumeVariation;
  final String paceChanges;
  final double uniqueWordsPercentage;

  VocalMetrics({
    required this.wordsPerMinute,
    required this.pitchRange,
    required this.volumeVariation,
    required this.paceChanges,
    required this.uniqueWordsPercentage,
  });

  factory VocalMetrics.fromJson(Map<String, dynamic> json) {
    return VocalMetrics(
      wordsPerMinute: json['wordsPerMinute'] ?? 0,
      pitchRange: json['pitchRange'] ?? 'Moderate',
      volumeVariation: json['volumeVariation'] ?? 'Moderate',
      paceChanges: json['paceChanges'] ?? 'Moderate',
      uniqueWordsPercentage: (json['uniqueWordsPercentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wordsPerMinute': wordsPerMinute,
      'pitchRange': pitchRange,
      'volumeVariation': volumeVariation,
      'paceChanges': paceChanges,
      'uniqueWordsPercentage': uniqueWordsPercentage,
    };
  }

  bool get isOptimalSpeakingRate {
    return wordsPerMinute >= 130 && wordsPerMinute <= 160;
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final int totalSpeeches;
  final double averageScore;
  final String? photoUrl;
  final bool isPremium;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.totalSpeeches = 0,
    this.averageScore = 0.0,
    this.photoUrl,
    this.isPremium = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      totalSpeeches: json['totalSpeeches'] ?? 0,
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      photoUrl: json['photoUrl'],
      isPremium: json['isPremium'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'totalSpeeches': totalSpeeches,
      'averageScore': averageScore,
      'photoUrl': photoUrl,
      'isPremium': isPremium,
    };
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  int get memberDays {
    return DateTime.now().difference(createdAt).inDays;
  }
}
