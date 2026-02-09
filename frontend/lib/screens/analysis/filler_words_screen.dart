import 'package:flutter/material.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';
import 'package:Speak_Sharp/widgets/card_layout.dart';

class FillerWordsScreen extends StatelessWidget {
  final Map<String, dynamic> fillerAnalysis;
  final String transcription;

  const FillerWordsScreen({
    Key? key,
    required this.fillerAnalysis,
    required this.transcription,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Filler Words Analysis',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            _buildSummaryCard(),

            const SizedBox(height: 24),

            // Filler Words Per Minute
            _buildFillerPerMinuteCard(),

            const SizedBox(height: 24),

            // Common Filler Words
            _buildCommonFillersCard(),

            const SizedBox(height: 24),

            // Highlighted Transcription
            _buildTranscriptionCard(),

            const SizedBox(height: 24),

            // Tips for Improvement
            _buildTipsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalFillers = fillerAnalysis['total_filler_words'] ?? 0;
    final density = (fillerAnalysis['filler_density'] ?? 0.0) * 100;
    final score = fillerAnalysis['Score'] ?? 0.0;

    return CardLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric(
                  'Total Fillers',
                  totalFillers.toString(),
                  Icons.chat_bubble_outline,
                  _getFillerCountColor(totalFillers),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryMetric(
                  'Density',
                  '${density.toStringAsFixed(1)}%',
                  Icons.percent,
                  _getDensityColor(density),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Score
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getScoreColor(score).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getScoreColor(score).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filler Word Score',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${score.toStringAsFixed(1)}/10',
                  style: TextStyle(
                    color: _getScoreColor(score),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Feedback
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[300],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getFeedbackMessage(density),
                    style: TextStyle(
                      color: Colors.blue[100],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFillerPerMinuteCard() {
    final perMinuteData = fillerAnalysis['filler_per_minute'] ?? {};

    if (perMinuteData.isEmpty) {
      return const SizedBox.shrink();
    }

    return CardLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filler Words Per Minute',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          ...(perMinuteData as Map<String, dynamic>).entries.map((entry) {
            final count = entry.value as int;
            final color = _getPerMinuteColor(count);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: color.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (count > 5)
                    Icon(
                      Icons.warning,
                      color: color,
                      size: 20,
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCommonFillersCard() {
    // Extract common filler words from transcription
    final fillerWords = [
      'um', 'uh', 'ah', 'er', 'like', 'you know',
      'sort of', 'kind of', 'basically', 'actually'
    ];

    final foundFillers = <String, int>{};
    final lowerTranscription = transcription.toLowerCase();

    for (final filler in fillerWords) {
      final count = ' $lowerTranscription '.split(' $filler ').length - 1;
      if (count > 0) {
        foundFillers[filler] = count;
      }
    }

    if (foundFillers.isEmpty) {
      return CardLayout(
        child: Column(
          children: [
            Icon(
              Icons.celebration,
              color: Colors.green,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Excellent!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No common filler words detected',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Sort by frequency
    final sortedFillers = foundFillers.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return CardLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Common Filler Words',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortedFillers.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '"${entry.key}"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${entry.value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptionCard() {
    return CardLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Transcription',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Filler',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text.rich(
              _buildHighlightedTranscription(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _buildHighlightedTranscription() {
    final fillerWords = [
      'um', 'uh', 'ah', 'er', 'like', 'you know',
      'sort of', 'kind of', 'basically', 'actually',
      'literally', 'hmm', 'huh', 'yeah', 'right',
      'okay', 'well', 'kinda', 'gonna', 'wanna'
    ];

    final words = transcription.split(' ');
    final spans = <TextSpan>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[.,!?]'), '');

      if (fillerWords.contains(cleanWord)) {
        // Highlight filler word
        spans.add(
          TextSpan(
            text: '$word ',
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.orange,
            ),
          ),
        );
      } else {
        // Normal word
        spans.add(TextSpan(text: '$word '));
      }
    }

    return TextSpan(children: spans);
  }

  Widget _buildTipsCard() {
    return CardLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.accentColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Tips to Reduce Fillers',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildTipItem(
            '1. Pause Instead',
            'When you feel the urge to say "um", take a brief pause instead. Silence is powerful.',
          ),

          _buildTipItem(
            '2. Practice Awareness',
            'Record yourself regularly to become aware of your filler word patterns.',
          ),

          _buildTipItem(
            '3. Slow Down',
            'Speaking too fast increases filler word usage. Slow your pace slightly.',
          ),

          _buildTipItem(
            '4. Prepare Transitions',
            'Plan transition phrases between ideas to reduce spontaneous fillers.',
          ),

          _buildTipItem(
            '5. Breathe',
            'Take deliberate breaths between sentences. This reduces anxiety-based fillers.',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper functions
  Color _getFillerCountColor(int count) {
    if (count <= 3) return Colors.green;
    if (count <= 8) return Colors.orange;
    return Colors.red;
  }

  Color _getDensityColor(double density) {
    if (density < 5) return Colors.green;
    if (density < 10) return Colors.orange;
    return Colors.red;
  }

  Color _getScoreColor(double score) {
    if (score >= 8) return Colors.green;
    if (score >= 5) return Colors.orange;
    return Colors.red;
  }

  Color _getPerMinuteColor(int count) {
    if (count <= 2) return Colors.green;
    if (count <= 5) return Colors.orange;
    return Colors.red;
  }

  String _getFeedbackMessage(double density) {
    if (density < 3) {
      return 'Excellent! Very minimal filler word usage.';
    } else if (density < 5) {
      return 'Good job! Filler words are well controlled.';
    } else if (density < 10) {
      return 'Moderate usage. Try to reduce filler words further.';
    } else if (density < 15) {
      return 'High usage detected. Focus on pausing instead of using fillers.';
    } else {
      return 'Very high usage. Practice awareness and deliberate pausing.';
    }
  }
}