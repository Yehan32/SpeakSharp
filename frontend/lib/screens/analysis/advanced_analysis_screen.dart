import 'package:flutter/material.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';
import 'package:Speak_Sharp/widgets/card_layout.dart';
import 'filler_words_screen.dart';

class AdvancedAnalysisScreen extends StatefulWidget {
  final Map<String, dynamic> analysisResults;

  const AdvancedAnalysisScreen({
    super.key,
    required this.analysisResults,
  });

  @override
  State<AdvancedAnalysisScreen> createState() => _AdvancedAnalysisScreenState();
}

class _AdvancedAnalysisScreenState extends State<AdvancedAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          'Detailed Analysis',
          style: TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Fluency'),
            Tab(text: 'Voice'),
            Tab(text: 'Structure'),
            Tab(text: 'Vocabulary'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildFluencyTab(),
          _buildVoiceTab(),
          _buildStructureTab(),
          _buildVocabularyTab(),
        ],
      ),
    );
  }

  // ==================== OVERVIEW TAB ====================
  Widget _buildOverviewTab() {
    final scores = widget.analysisResults['scores'] ?? {};
    final overallScore = widget.analysisResults['overall_score'] ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Score
          CardLayout(
            child: Column(
              children: [
                const Text(
                  'Overall Performance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  overallScore.toStringAsFixed(1),
                  style: TextStyle(
                    color: _getScoreColor(overallScore),
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'out of 100',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Score Breakdown
          const Text(
            'Score Breakdown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          _buildScoreCard(
            'Proficiency (Fluency)',
            scores['proficiency'] ?? 0.0,
            20,
            Icons.speed,
            'How smoothly you speak without hesitations',
          ),

          _buildScoreCard(
            'Voice Modulation',
            scores['voice_modulation'] ?? 0.0,
            20,
            Icons.graphic_eq,
            'Variation in pitch, volume, and emphasis',
          ),

          _buildScoreCard(
            'Speech Development',
            scores['speech_development'] ?? 0.0,
            20,
            Icons.account_tree,
            'Organization and time management',
          ),

          _buildScoreCard(
            'Speech Effectiveness',
            scores['speech_effectiveness'] ?? 0.0,
            20,
            Icons.star,
            'Purpose clarity and audience engagement',
          ),

          _buildScoreCard(
            'Vocabulary',
            scores['vocabulary'] ?? 0.0,
            20,
            Icons.book,
            'Grammar and word choice quality',
          ),
        ],
      ),
    );
  }

  // ==================== FLUENCY TAB ====================
  Widget _buildFluencyTab() {
    final fillerAnalysis = widget.analysisResults['filler_analysis'] ?? {};
    final pauseAnalysis = widget.analysisResults['pause_analysis'] ?? {};
    final proficiencyDetails = widget.analysisResults['proficiency_details'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filler Words Section
          CardLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filler Words',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FillerWordsScreen(
                              fillerAnalysis: fillerAnalysis,
                              transcription: widget.analysisResults['transcription'] ?? '',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Details'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildMetricRow(
                  'Total Filler Words',
                  '${fillerAnalysis['total_filler_words'] ?? 0}',
                  Icons.chat_bubble_outline,
                ),

                _buildMetricRow(
                  'Filler Density',
                  '${((fillerAnalysis['filler_density'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                  Icons.percent,
                ),

                const SizedBox(height: 16),

                // Filler words per minute
                if (fillerAnalysis['filler_per_minute'] != null) ...[
                  const Text(
                    'Filler Words Per Minute:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(fillerAnalysis['filler_per_minute'] as Map<String, dynamic>)
                      .entries
                      .map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${entry.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Pause Analysis
          CardLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pause Analysis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                _buildMetricRow(
                  'Pauses under 1.5s',
                  '${pauseAnalysis['Pauses under 1.5 seconds'] ?? 0}',
                  Icons.timer,
                  subtitle: 'Natural pauses',
                ),

                _buildMetricRow(
                  'Pauses 1.5-3s',
                  '${pauseAnalysis['Pauses between 1.5-3 seconds'] ?? 0}',
                  Icons.timer_outlined,
                  subtitle: 'Noticeable pauses',
                ),

                _buildMetricRow(
                  'Pauses over 3s',
                  '${pauseAnalysis['Pauses exceeding 3 seconds'] ?? 0}',
                  Icons.timer_off,
                  subtitle: 'Significant pauses',
                  isWarning: (pauseAnalysis['Pauses exceeding 3 seconds'] ?? 0) > 2,
                ),

                _buildMetricRow(
                  'Pauses over 5s',
                  '${pauseAnalysis['Pauses exceeding 5 seconds'] ?? 0}',
                  Icons.error_outline,
                  subtitle: 'Critical pauses',
                  isWarning: (pauseAnalysis['Pauses exceeding 5 seconds'] ?? 0) > 0,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Proficiency Score Details
          CardLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Proficiency Breakdown',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                _buildScoreBreakdown(
                  'Filler Score',
                  proficiencyDetails['filler_score'] ?? 0.0,
                  10,
                ),

                _buildScoreBreakdown(
                  'Pause Score',
                  proficiencyDetails['pause_score'] ?? 0.0,
                  10,
                ),

                _buildScoreBreakdown(
                  'Overall Proficiency',
                  proficiencyDetails['final_score'] ?? 0.0,
                  20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== VOICE TAB ====================
  Widget _buildVoiceTab() {
    final voiceDetails = widget.analysisResults['voice_modulation_details'] ?? {};
    final pitchAnalysis = voiceDetails['pitch_analysis'] ?? {};
    final volumeAnalysis = voiceDetails['volume_analysis'] ?? {};
    final emphasisAnalysis = voiceDetails['emphasis_analysis'] ?? {};
    final scores = voiceDetails['scores'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pitch Analysis
          CardLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pitch Analysis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                _buildMetricRow(
                  'Average Pitch',
                  '${(pitchAnalysis['mean_pitch'] ?? 0.0).toStringAsFixed(1)} Hz',
                  Icons.graphic_eq,
                ),

                _buildMetricRow(
                  'Pitch Range',
                  '${(pitchAnalysis['pitch_range'] ?? 0.0).toStringAsFixed(1)} Hz',
                  Icons.tune,
                  subtitle: _getPitchRangeFeedback(pitchAnalysis['pitch_range'] ?? 0.0),
                ),

                _buildMetricRow(
                  'Pitch Variation',
                  '${(pitchAnalysis['pitch_variation'] ?? 0.0).toStringAsFixed(1)} Hz',
                  Icons.show_chart,
                  subtitle: _getPitchVariationFeedback(pitchAnalysis['pitch_variation'] ?? 0.0),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Volume Analysis
          CardLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Volume Analysis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                _buildMetricRow(
                  'Average Intensity',
                  '${(volumeAnalysis['mean_intensity'] ?? 0.0).toStringAsFixed(1)} dB',
                  Icons.volume_up,
                ),

                _buildMetricRow(
                  'Intensity Range',
                  '${(volumeAnalysis['intensity_range'] ?? 0.0).toStringAsFixed(1)} dB',
                  Icons.equalizer,
                  subtitle: _getIntensityRangeFeedback(volumeAnalysis['intensity_range'] ?? 0.0),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Emphasis Analysis
          CardLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Emphasis Analysis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                _buildMetricRow(
                  'Emphasis Points',
                  '${emphasisAnalysis['emphasis_points_count'] ?? 0}',
                  Icons.star,
                  subtitle: _getEmphasisFeedback(emphasisAnalysis['emphasis_points_count'] ?? 0),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Voice Scores
          CardLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Voice Modulation Scores',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                _buildScoreBreakdown(
                  'Pitch & Volume',
                  scores['pitch_and_volume_score'] ?? 0.0,
                  10,
                ),

                _buildScoreBreakdown(
                  'Emphasis',
                  scores['emphasis_score'] ?? 0.0,
                  10,
                ),

                _buildScoreBreakdown(
                  'Total Voice Modulation',
                  scores['total_score'] ?? 0.0,
                  20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STRUCTURE TAB ====================
  Widget _buildStructureTab() {
    final developmentDetails = widget.analysisResults['speech_development_details'] ?? {};
    final structure = developmentDetails['structure'] ?? {};
    final timeUtilization = developmentDetails['time_utilization'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Structure Quality
          CardLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Speech Structure',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                _buildQualityIndicator(
                  'Introduction',
                  structure['introduction_quality'] ?? 'N/A',
                ),

                _buildQualityIndicator(
                  'Body Development',
                  structure['body_development'] ?? 'N/A',
                ),

                _buildQualityIndicator(
                  'Conclusion',
                  structure['conclusion_quality'] ?? 'N/A',
                ),

                const Divider(height: 32, color: Colors.white24),

                _buildMetricRow(
                  'Structure Score',
                  '${structure['score'] ?? 0}/14',
                  Icons.account_tree,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Time Utilization
          CardLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Time Utilization',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                _buildMetricRow(
                  'Total Time',
                  timeUtilization['total_time']?.toString() ?? 'N/A',
                  Icons.access_time,
                ),

                _buildMetricRow(
                  'Introduction Time',
                  '${timeUtilization['intro_time'] ?? 0}s (~20%)',
                  Icons.start,
                ),

                _buildMetricRow(
                  'Body Time',
                  '${timeUtilization['body_time'] ?? 0}s (~60%)',
                  Icons.article,
                ),

                _buildMetricRow(
                  'Conclusion Time',
                  '${timeUtilization['conclusion_time'] ?? 0}s (~20%)',
                  Icons.flag,
                ),

                const Divider(height: 32, color: Colors.white24),

                _buildMetricRow(
                  'Time Score',
                  '${timeUtilization['score'] ?? 0}/6',
                  Icons.timer,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Feedback
          if (structure['feedback'] != null && (structure['feedback'] as List).isNotEmpty)
            CardLayout(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recommendations',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(structure['feedback'] as List).map(
                        (feedback) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: AppTheme.accentColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feedback.toString(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
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

  // ==================== VOCABULARY TAB ====================
  Widget _buildVocabularyTab() {
    final vocabDetails = widget.analysisResults['vocabulary_details'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lexical Diversity
          CardLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lexical Diversity',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                _buildMetricRow(
                  'Unique Words',
                  '${vocabDetails['unique_words'] ?? 0}',
                  Icons.category,
                ),

                _buildMetricRow(
                  'Diversity Ratio',
                  '${((vocabDetails['lexical_diversity'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                  Icons.pie_chart,
                  subtitle: _getLexicalDiversityFeedback(vocabDetails['lexical_diversity'] ?? 0.0),
                ),

                _buildMetricRow(
                  'Advanced Vocabulary',
                  '${vocabDetails['advanced_vocab_count'] ?? 0} words',
                  Icons.school,
                  subtitle: _getAdvancedVocabFeedback(vocabDetails['advanced_vocab_count'] ?? 0),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Feedback
          if (vocabDetails['feedback'] != null && (vocabDetails['feedback'] as List).isNotEmpty)
            CardLayout(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vocabulary Feedback',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(vocabDetails['feedback'] as List).map(
                        (feedback) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feedback.toString(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
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

  // ==================== HELPER WIDGETS ====================

  Widget _buildScoreCard(
      String title,
      double score,
      int maxScore,
      IconData icon,
      String description,
      ) {
    final percentage = score / maxScore;
    final color = _getScoreColor(percentage * 100);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
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
                '${score.toStringAsFixed(1)}/$maxScore',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
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

  Widget _buildMetricRow(
      String label,
      String value,
      IconData icon, {
        String? subtitle,
        bool isWarning = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: isWarning ? Colors.orange : AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isWarning ? Colors.orange : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown(String label, double score, int maxScore) {
    final percentage = score / maxScore;
    final color = _getScoreColor(percentage * 100);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Text(
                '${score.toStringAsFixed(1)}/$maxScore',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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

  Widget _buildQualityIndicator(String label, String quality) {
    final color = _getQualityColor(quality);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color),
            ),
            child: Text(
              quality,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPER FUNCTIONS ====================

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getQualityColor(String quality) {
    switch (quality.toLowerCase()) {
      case 'excellent':
      case 'very good':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'weak':
      case 'poor':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getPitchRangeFeedback(double range) {
    if (range > 200) return 'Excellent variation';
    if (range > 100) return 'Good variation';
    if (range > 50) return 'Moderate variation';
    return 'Limited variation';
  }

  String _getPitchVariationFeedback(double variation) {
    if (variation > 50) return 'Very dynamic';
    if (variation > 30) return 'Good dynamics';
    if (variation > 15) return 'Moderate dynamics';
    return 'Monotone';
  }

  String _getIntensityRangeFeedback(double range) {
    if (range > 40) return 'Excellent volume control';
    if (range > 25) return 'Good volume control';
    if (range > 15) return 'Moderate control';
    return 'Limited control';
  }

  String _getEmphasisFeedback(int count) {
    if (count > 15) return 'Excellent use of emphasis';
    if (count > 8) return 'Good emphasis';
    if (count > 3) return 'Some emphasis';
    return 'Limited emphasis';
  }

  String _getLexicalDiversityFeedback(double ratio) {
    if (ratio > 0.7) return 'Excellent diversity';
    if (ratio > 0.5) return 'Good diversity';
    if (ratio > 0.3) return 'Moderate diversity';
    return 'Limited diversity';
  }

  String _getAdvancedVocabFeedback(int count) {
    if (count > 20) return 'Excellent vocabulary';
    if (count > 10) return 'Good vocabulary';
    if (count > 5) return 'Moderate vocabulary';
    return 'Basic vocabulary';
  }
}
