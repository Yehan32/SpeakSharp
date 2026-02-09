import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';
import 'package:Speak_Sharp/widgets/card_layout.dart';
import 'advanced_analysis_screen.dart';
import '../home/home_screen.dart';

class FeedbackScreen extends StatefulWidget {
  final Map<String, dynamic> analysisResults;
  final String audioPath;

  const FeedbackScreen({
    super.key,
    required this.analysisResults,
    required this.audioPath,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    final overallScore = widget.analysisResults['overall_score'] ?? 0.0;
    final scores = widget.analysisResults['scores'] ?? {};

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
            );
          },
        ),
        title: const Text(
          'Speech Analysis',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (!_isSaved)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.save, color: Colors.white),
              onPressed: _isSaving ? null : _saveToHistory,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Overall Score Card
            _buildOverallScoreCard(overallScore),

            const SizedBox(height: 24),

            // Individual Scores
            _buildScoresSection(scores),

            const SizedBox(height: 24),

            // Quick Insights
            _buildQuickInsights(),

            const SizedBox(height: 24),

            // Transcription Preview
            _buildTranscriptionPreview(),

            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallScoreCard(double score) {
    final grade = _getGrade(score);
    final color = _getScoreColor(score);

    return CardLayout(
      child: Column(
        children: [
          const Text(
            'Overall Performance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 20),

          // Score Circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 12,
                  backgroundColor: AppTheme.cardColor,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                children: [
                  Text(
                    score.toStringAsFixed(1),
                    style: TextStyle(
                      color: color,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '/ 100',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Grade Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color),
            ),
            child: Text(
              grade,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            _getScoreMessage(score),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScoresSection(Map<String, dynamic> scores) {
    final scoreItems = [
      {
        'title': 'Proficiency',
        'score': scores['proficiency'] ?? 0.0,
        'max': 20.0,
        'icon': Icons.speed,
        'description': 'Fluency & pace',
      },
      {
        'title': 'Voice Modulation',
        'score': scores['voice_modulation'] ?? 0.0,
        'max': 20.0,
        'icon': Icons.graphic_eq,
        'description': 'Pitch & emphasis',
      },
      {
        'title': 'Structure',
        'score': scores['speech_development'] ?? 0.0,
        'max': 20.0,
        'icon': Icons.account_tree,
        'description': 'Organization',
      },
      {
        'title': 'Effectiveness',
        'score': scores['speech_effectiveness'] ?? 0.0,
        'max': 20.0,
        'icon': Icons.star,
        'description': 'Impact & clarity',
      },
      {
        'title': 'Vocabulary',
        'score': scores['vocabulary'] ?? 0.0,
        'max': 20.0,
        'icon': Icons.book,
        'description': 'Word choice',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Scores',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        ...scoreItems.map((item) => _buildScoreItem(
          title: item['title'] as String,
          score: item['score'] as double,
          maxScore: item['max'] as double,
          icon: item['icon'] as IconData,
          description: item['description'] as String,
        )),
      ],
    );
  }

  Widget _buildScoreItem({
    required String title,
    required double score,
    required double maxScore,
    required IconData icon,
    required String description,
  }) {
    final percentage = score / maxScore;
    final color = _getScoreColor(score / maxScore * 100);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '${score.toStringAsFixed(1)}/${maxScore.toInt()}',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInsights() {
    final fillerAnalysis = widget.analysisResults['filler_analysis'] ?? {};
    final pauseAnalysis = widget.analysisResults['pause_analysis'] ?? {};
    final duration = widget.analysisResults['duration'] ?? {};

    return CardLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Insights',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          _buildInsightRow(
            Icons.access_time,
            'Duration',
            duration['actual'] ?? 'N/A',
          ),

          _buildInsightRow(
            Icons.chat_bubble_outline,
            'Filler Words',
            '${fillerAnalysis['total_filler_words'] ?? 0}',
          ),

          _buildInsightRow(
            Icons.pause,
            'Significant Pauses',
            '${pauseAnalysis['Pauses exceeding 3 seconds'] ?? 0}',
          ),

          _buildInsightRow(
            Icons.trending_up,
            'Filler Density',
            '${((fillerAnalysis['filler_density'] ?? 0.0) * 100).toStringAsFixed(1)}%',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptionPreview() {
    final transcription = widget.analysisResults['transcription'] ?? '';
    final preview = transcription.length > 200
        ? '${transcription.substring(0, 200)}...'
        : transcription;

    return CardLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transcription',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            preview,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),

          if (transcription.length > 200) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                _showFullTranscription(transcription);
              },
              icon: const Icon(Icons.article),
              label: const Text('Read Full Transcription'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // View Detailed Analysis
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdvancedAnalysisScreen(
                  analysisResults: widget.analysisResults,
                ),
              ),
            );
          },
          icon: const Icon(Icons.analytics),
          label: const Text('View Detailed Analysis'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Return Home
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
            );
          },
          icon: const Icon(Icons.home),
          label: const Text('Return Home'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: const BorderSide(color: Colors.white30),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveToHistory() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Prepare data for Firestore
      final speechData = {
        'user_id': user.uid,
        'topic': widget.analysisResults['topic'] ?? 'Untitled',
        'timestamp': FieldValue.serverTimestamp(),
        'overall_score': widget.analysisResults['overall_score'] ?? 0.0,
        'scores': widget.analysisResults['scores'] ?? {},
        'duration': widget.analysisResults['duration'] ?? {},
        'filler_analysis': widget.analysisResults['filler_analysis'] ?? {},
        'transcription': widget.analysisResults['transcription'] ?? '',
        // Add more fields as needed
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('speeches')
          .add(speechData);

      setState(() {
        _isSaving = false;
        _isSaved = true;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Saved to history'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error saving to history: $e');

      setState(() {
        _isSaving = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFullTranscription(String transcription) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Full Transcription',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Text(
                  transcription,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGrade(double score) {
    if (score >= 90) return 'EXCELLENT';
    if (score >= 80) return 'VERY GOOD';
    if (score >= 70) return 'GOOD';
    if (score >= 60) return 'FAIR';
    return 'NEEDS IMPROVEMENT';
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreMessage(double score) {
    if (score >= 90) return 'Outstanding performance! Keep up the excellent work!';
    if (score >= 80) return 'Great job! You\'re speaking with confidence.';
    if (score >= 70) return 'Good effort! Small improvements will make a big difference.';
    if (score >= 60) return 'You\'re on the right track. Practice will help!';
    return 'Keep practicing! Every speech makes you better.';
  }
}
