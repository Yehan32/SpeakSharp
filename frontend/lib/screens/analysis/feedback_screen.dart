import 'package:flutter/material.dart';
import '../../models/speech_model.dart';
import '../../utils/app_theme.dart';

class FeedbackScreen extends StatefulWidget {
  final SpeechModel speech;

  const FeedbackScreen({Key? key, required this.speech}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
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
    final theme = Theme.of(context);
    final overallScore = widget.speech.overallScore ?? 0.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Speech Analysis',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: AppTheme.textPrimary),
            onPressed: () {
              // Save to favorites or export
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Analysis saved!')),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Overall Score Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildOverallScoreCard(overallScore),
            ),
          ),

          // Score Breakdown
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Detailed Scores',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildScoreCard(
                  'Grammar & Vocabulary',
                  widget.speech.grammarScore ?? 0,
                  20,
                  Icons.spellcheck,
                  AppTheme.grammarColor,
                  'Word choice and sentence structure',
                ),
                const SizedBox(height: 12),
                _buildScoreCard(
                  'Voice Modulation',
                  widget.speech.voiceScore ?? 0,
                  20,
                  Icons.graphic_eq,
                  AppTheme.voiceColor,
                  'Pitch, tone, and vocal variety',
                ),
                const SizedBox(height: 12),
                _buildScoreCard(
                  'Structure & Organization',
                  widget.speech.structureScore ?? 0,
                  20,
                  Icons.account_tree,
                  AppTheme.structureColor,
                  'Speech flow and organization',
                ),
                const SizedBox(height: 12),
                _buildScoreCard(
                  'Speech Effectiveness',
                  widget.speech.effectivenessScore ?? 0,
                  20,
                  Icons.star,
                  AppTheme.proficiencyColor,
                  'Overall impact and delivery',
                ),
                const SizedBox(height: 12),
                _buildScoreCard(
                  'Proficiency',
                  widget.speech.proficiencyScore ?? 0,
                  20,
                  Icons.bookmark,
                  AppTheme.accentColor,
                  'Speaking fluency and confidence',
                ),
              ]),
            ),
          ),

          // Tabs for detailed analysis
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: AppTheme.textSecondary,
                  indicatorColor: AppTheme.primaryColor,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Fluency'),
                    Tab(text: 'Voice'),
                    Tab(text: 'Structure'),
                    Tab(text: 'Vocabulary'),
                  ],
                ),
              ),
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildFluencyTab(),
                _buildVoiceTab(),
                _buildStructureTab(),
                _buildVocabularyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallScoreCard(double score) {
    final percentage = (score / 100 * 100).clamp(0, 100);
    final color = AppTheme.getScoreColor(score);
    final label = score >= 80
        ? 'EXCELLENT'
        : score >= 60
        ? 'GOOD'
        : score >= 40
        ? 'FAIR'
        : 'NEEDS IMPROVEMENT';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          // Circular progress indicator
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      '/100',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(
      String title,
      double score,
      double maxScore,
      IconData icon,
      Color color,
      String description,
      ) {
    final percentage = (score / maxScore * 100).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: AppTheme.getColoredShadow(color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${score.toStringAsFixed(1)}/$maxScore',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            'Speech Information',
            Icons.info_outline,
            AppTheme.primaryColor,
            [
              _buildInfoRow('Topic', widget.speech.topic ?? 'Not specified'),
              _buildInfoRow('Duration', widget.speech.duration ?? 'Unknown'),
              _buildInfoRow(
                  'Date', widget.speech.createdAt?.toString() ?? 'Unknown'),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Key Insights',
            Icons.lightbulb_outline,
            AppTheme.proficiencyColor,
            [
              _buildInsight(
                'Overall Performance',
                (widget.speech.overallScore ?? 0) >= 70
                    ? 'Great job! Your speech was well-delivered.'
                    : 'Good effort! Focus on the areas below to improve.',
                (widget.speech.overallScore ?? 0) >= 70
                    ? Icons.check_circle
                    : Icons.info,
              ),
              _buildInsight(
                'Strengths',
                (widget.speech.grammarScore ?? 0) > 15
                    ? 'Excellent grammar and vocabulary'
                    : 'Work on grammar and word choice',
                Icons.trending_up,
              ),
              _buildInsight(
                'Areas to Improve',
                (widget.speech.structureScore ?? 0) < 10
                    ? 'Focus on speech structure and organization'
                    : 'Continue refining your delivery',
                Icons.flag,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFluencyTab() {
    final fillerWords = widget.speech.fillerWordCount ?? 0;
    final pauseCount = widget.speech.pauseCount ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSectionCard(
            'Fluency Metrics',
            Icons.speed,
            AppTheme.voiceColor,
            [
              _buildMetricRow('Filler Words (um, uh, like)', '$fillerWords'),
              _buildMetricRow('Long Pauses (>2s)', '$pauseCount'),
              _buildMetricRow(
                  'Words Per Minute', widget.speech.wordsPerMinute ?? 'N/A'),
              _buildMetricRow('Fluency Score',
                  '${widget.speech.proficiencyScore ?? 0}/20'),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Recommendations',
            Icons.lightbulb,
            AppTheme.proficiencyColor,
            [
              _buildRecommendation(
                fillerWords > 10
                    ? 'Try to reduce filler words by pausing briefly instead'
                    : 'Good control of filler words!',
              ),
              _buildRecommendation(
                pauseCount > 5
                    ? 'Practice to reduce long pauses and maintain flow'
                    : 'Nice speech rhythm!',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSectionCard(
            'Voice Analysis',
            Icons.mic,
            AppTheme.voiceColor,
            [
              _buildMetricRow(
                  'Pitch Variation', widget.speech.pitchVariation ?? 'N/A'),
              _buildMetricRow(
                  'Volume Control', widget.speech.volumeControl ?? 'N/A'),
              _buildMetricRow(
                  'Emphasis', widget.speech.emphasisScore ?? 'N/A'),
              _buildMetricRow('Voice Score',
                  '${widget.speech.voiceScore ?? 0}/20'),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Voice Tips',
            Icons.tips_and_updates,
            AppTheme.proficiencyColor,
            [
              _buildRecommendation(
                'Use vocal variety to emphasize key points',
              ),
              _buildRecommendation(
                'Maintain consistent volume throughout',
              ),
              _buildRecommendation(
                'Practice breathing exercises for better control',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStructureTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSectionCard(
            'Speech Structure',
            Icons.account_tree,
            AppTheme.structureColor,
            [
              _buildMetricRow('Introduction', widget.speech.hasIntro ?? false ? 'Present' : 'Missing'),
              _buildMetricRow('Body/Content', widget.speech.hasBody ?? false ? 'Well-developed' : 'Needs work'),
              _buildMetricRow('Conclusion', widget.speech.hasConclusion ?? false ? 'Strong' : 'Weak'),
              _buildMetricRow('Structure Score',
                  '${widget.speech.structureScore ?? 0}/20'),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Structure Tips',
            Icons.architecture,
            AppTheme.proficiencyColor,
            [
              _buildRecommendation(
                widget.speech.hasIntro ?? false
                    ? 'Good opening! Continue with strong hooks'
                    : 'Start with a clear introduction to engage audience',
              ),
              _buildRecommendation(
                widget.speech.hasConclusion ?? false
                    ? 'Nice conclusion! Summarize key points'
                    : 'End with a memorable conclusion',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSectionCard(
            'Vocabulary Metrics',
            Icons.book,
            AppTheme.grammarColor,
            [
              _buildMetricRow(
                  'Unique Words', '${widget.speech.uniqueWordCount ?? 0}'),
              _buildMetricRow(
                  'Total Words', '${widget.speech.totalWords ?? 0}'),
              _buildMetricRow('Vocabulary Richness',
                  widget.speech.vocabularyRichness ?? 'N/A'),
              _buildMetricRow('Grammar Score',
                  '${widget.speech.grammarScore ?? 0}/20'),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Vocabulary Tips',
            Icons.school,
            AppTheme.proficiencyColor,
            [
              _buildRecommendation(
                'Expand vocabulary by reading diverse materials',
              ),
              _buildRecommendation(
                'Use specific words instead of general terms',
              ),
              _buildRecommendation(
                'Practice using transition words for better flow',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      String title,
      IconData icon,
      Color color,
      List<Widget> children,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: AppTheme.getColoredShadow(color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsight(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.proficiencyColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: AppTheme.successColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}