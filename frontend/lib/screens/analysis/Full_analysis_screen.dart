import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';
import 'package:Speak_Sharp/services/api_service.dart';
import 'package:Speak_Sharp/widgets/card_layout.dart';

class FullAnalysisScreen extends StatefulWidget {
  final Map<String, dynamic> analysisData;

  const FullAnalysisScreen({
    super.key,
    required this.analysisData,
  });

  @override
  State<FullAnalysisScreen> createState() => _FullAnalysisScreenState();
}

class _FullAnalysisScreenState extends State<FullAnalysisScreen> {
  bool _isLoadingFull = false;
  Map<String, dynamic>? _fullAnalysis;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadFullAnalysis();
  }

  Future<void> _loadFullAnalysis() async {
    final analysisId = widget.analysisData['analysis_id'] ?? widget.analysisData['id'];
    if (analysisId == null) {
      setState(() {
        _fullAnalysis = widget.analysisData;
        _isLoadingFull = false;
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoadingFull = true);

    try {
      final analysis = await ApiService.getAnalysis(
        analysisId: analysisId,
        userId: user.uid,
      );
      setState(() {
        _fullAnalysis = analysis;
        _isLoadingFull = false;
      });
    } catch (e) {
      setState(() => _isLoadingFull = false);
      debugPrint('Error loading full analysis: $e');
      // Use provided data as fallback
      _fullAnalysis = widget.analysisData;
    }
  }

  @override
  Widget build(BuildContext context) {
    final overallScore = (widget.analysisData['overall_score'] ?? 0).toDouble();
    final topic = widget.analysisData['topic'] ?? 'Untitled';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              topic,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Score: ${overallScore.toStringAsFixed(1)}/100',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppTheme.textPrimary),
            onPressed: _shareAnalysis,
          ),
        ],
      ),
      body: _isLoadingFull
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Overall Score Card
          _buildOverallScoreCard(overallScore),

          // Tab Bar
          _buildTabBar(),

          // Tab Content
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallScoreCard(double overallScore) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getScoreColor(overallScore),
            _getScoreColor(overallScore).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getScoreColor(overallScore).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Score Circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.3),
              border: Border.all(color: AppTheme.textPrimary, width: 3),
            ),
            child: Center(
              child: Text(
                overallScore.toStringAsFixed(0),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall Performance',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getScoreLabel(overallScore),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getScoreGrade(overallScore),
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTab('Overview', 0),
          _buildTab('Details', 1),
          _buildTab('Transcript', 2),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textTertiary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildDetailsTab();
      case 2:
        return _buildTranscriptTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildOverviewTab() {
    final scores = _fullAnalysis?['scores'] ?? widget.analysisData['scores'] ?? {};

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Score Breakdown',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildScoreItem(
          'Voice Modulation',
          (scores['voice_modulation'] ?? 0).toDouble(),
          20,
          Icons.multitrack_audio,
        ),
        _buildScoreItem(
          'Grammar & Vocabulary',
          (scores['vocabulary'] ?? 0).toDouble(),
          50,
          Icons.book,
        ),
        _buildScoreItem(
          'Speech Structure',
          (scores['speech_development'] ?? 0).toDouble(),
          20,
          Icons.account_tree,
        ),
        _buildScoreItem(
          'Proficiency',
          (scores['proficiency'] ?? 0).toDouble(),
          20,
          Icons.star,
        ),
        _buildScoreItem(
          'Speech Effectiveness',
          (scores['speech_effectiveness'] ?? 0).toDouble(),
          20,
          Icons.trending_up,
        ),
        const SizedBox(height: 24),
        _buildKeyMetrics(),
      ],
    );
  }

  Widget _buildScoreItem(String label, double score, double maxScore, IconData icon) {
    final percentage = (score / maxScore).clamp(0.0, 1.0);
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
              Icon(icon, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${score.toStringAsFixed(1)}/$maxScore',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 15,
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
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(percentage),
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics() {
    final duration = _fullAnalysis?['duration'] ?? widget.analysisData['duration'] ?? {};
    final fillerAnalysis = _fullAnalysis?['filler_analysis'] ??
        widget.analysisData['filler_analysis'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Metrics',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Duration',
                duration['actual'] ?? 'N/A',
                Icons.timer,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Filler Words',
                '${fillerAnalysis['total_filler_words'] ?? 0}',
                Icons.chat_bubble_outline,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    final fillerAnalysis = _fullAnalysis?['filler_analysis'] ??
        widget.analysisData['filler_analysis'] ?? {};
    final pauseAnalysis = _fullAnalysis?['pause_analysis'] ??
        widget.analysisData['pause_analysis'] ?? {};

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        CardLayout(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filler Words Analysis',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Total Filler Words',
                '${fillerAnalysis['total_filler_words'] ?? 0}',
                Icons.chat_bubble_outline,
              ),
              _buildDetailRow(
                'Filler Density',
                '${((fillerAnalysis['filler_density'] ?? 0) * 100).toStringAsFixed(1)}%',
                Icons.pie_chart,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CardLayout(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pause Analysis',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Short Pauses (<1.5s)',
                '${pauseAnalysis['Pauses under 1.5 seconds'] ?? 0}',
                Icons.pause_circle_outline,
              ),
              _buildDetailRow(
                'Long Pauses (>3s)',
                '${pauseAnalysis['Pauses exceeding 3 seconds'] ?? 0}',
                Icons.pause_circle_filled,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptTab() {
    final transcription = _fullAnalysis?['transcription'] ??
        widget.analysisData['transcription'] ??
        'No transcription available';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        CardLayout(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Full Transcription',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: AppTheme.textSecondary),
                    onPressed: () => _copyTranscription(transcription),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SelectableText(
                transcription,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _copyTranscription(String text) {
    // Copy to clipboard functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transcription copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareAnalysis() {
    // Share functionality - will be implemented in share_export_helper
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.blue;
    if (score >= 55) return Colors.orange;
    return Colors.red;
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 0.85) return Colors.green;
    if (percentage >= 0.70) return Colors.blue;
    if (percentage >= 0.55) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(double score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 55) return 'Fair';
    return 'Needs Work';
  }

  String _getScoreGrade(double score) {
    if (score >= 85) return 'Grade: A+';
    if (score >= 80) return 'Grade: A';
    if (score >= 70) return 'Grade: B+';
    if (score >= 65) return 'Grade: B';
    if (score >= 55) return 'Grade: C+';
    return 'Grade: C';
  }
}