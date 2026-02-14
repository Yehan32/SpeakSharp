import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';
import 'package:Speak_Sharp/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() => _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _speeches = [];
  String _selectedPeriod = '7'; // 7, 30, all

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final history = await ApiService.getUserHistory(
        userId: user.uid,
        limit: 100,
      );

      if (mounted) {
        setState(() {
          _speeches = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error loading progress data: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredSpeeches {
    if (_selectedPeriod == 'all') return _speeches;

    final days = int.parse(_selectedPeriod);
    final cutoff = DateTime.now().subtract(Duration(days: days));

    return _speeches.where((speech) {
      final timestamp = speech['timestamp'];
      if (timestamp == null) return false;

      try {
        final date = DateTime.parse(timestamp.toString());
        return date.isAfter(cutoff);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        title: Text(
          'Progress Dashboard',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(color: AppTheme.accentColor),
      )
          : _speeches.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.accentColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Selector
              _buildPeriodSelector(),

              const SizedBox(height: 24),

              // Overall Stats
              _buildOverallStats(),

              const SizedBox(height: 24),

              // Score Chart
              _buildScoreChart(),

              const SizedBox(height: 24),

              // Category Breakdown
              _buildCategoryBreakdown(),

              const SizedBox(height: 24),

              // Improvement Tracker
              _buildImprovementTracker(),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          _buildPeriodButton('Last 7 Days', '7'),
          _buildPeriodButton('Last 30 Days', '30'),
          _buildPeriodButton('All Time', 'all'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPeriod = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.primaryGradient : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverallStats() {
    final speeches = _filteredSpeeches;
    final totalSpeeches = speeches.length;

    if (totalSpeeches == 0) {
      return const SizedBox.shrink();
    }

    final avgScore = speeches.fold<double>(
      0,
          (sum, speech) => sum + ((speech['overall_score'] ?? 0).toDouble()),
    ) / totalSpeeches;

    final bestScore = speeches.fold<double>(
      0,
          (max, speech) {
        final score = (speech['overall_score'] ?? 0).toDouble();
        return score > max ? score : max;
      },
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        children: [
          Text(
            'OVERALL PERFORMANCE',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildOverallStatItem(
                  Icons.mic,
                  totalSpeeches.toString(),
                  'Speeches',
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildOverallStatItem(
                  Icons.star,
                  avgScore.toStringAsFixed(1),
                  'Avg Score',
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildOverallStatItem(
                  Icons.emoji_events,
                  bestScore.toStringAsFixed(1),
                  'Best',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreChart() {
    final speeches = _filteredSpeeches;

    if (speeches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SCORE TREND',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textTertiary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.textTertiary.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '#${value.toInt() + 1}',
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (speeches.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: speeches
                        .asMap()
                        .entries
                        .map((entry) => FlSpot(
                      entry.key.toDouble(),
                      (entry.value['overall_score'] ?? 0).toDouble(),
                    ))
                        .toList(),
                    isCurved: true,
                    gradient: AppTheme.primaryGradient,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: AppTheme.accentColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accentColor.withOpacity(0.2),
                          AppTheme.accentColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final speeches = _filteredSpeeches;

    if (speeches.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate average scores for each category
    final categories = {
      'Voice': {'color': AppTheme.voiceColor, 'icon': Icons.record_voice_over},
      'Grammar': {'color': AppTheme.grammarColor, 'icon': Icons.abc},
      'Structure': {'color': AppTheme.structureColor, 'icon': Icons.architecture},
      'Proficiency': {'color': AppTheme.proficiencyColor, 'icon': Icons.lightbulb},
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CATEGORY BREAKDOWN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textTertiary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          ...categories.entries.map((entry) {
            // For demo, generate random scores. In real app, calculate from actual data
            final score = 70.0 + (entry.key.hashCode % 20);
            return _buildCategoryItem(
              entry.key,
              score,
              entry.value['color'] as Color,
              entry.value['icon'] as IconData,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String name, double score, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${score.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementTracker() {
    final speeches = _filteredSpeeches;

    if (speeches.length < 2) {
      return const SizedBox.shrink();
    }

    final firstScore = (speeches.last['overall_score'] ?? 0).toDouble();
    final latestScore = (speeches.first['overall_score'] ?? 0).toDouble();
    final improvement = latestScore - firstScore;
    final isImproving = improvement > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isImproving ? AppTheme.successGradient : AppTheme.warningGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        children: [
          Icon(
            isImproving ? Icons.trending_up : Icons.trending_flat,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            isImproving ? 'Great Progress!' : 'Keep Practicing!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isImproving
                ? 'You\'ve improved by ${improvement.toStringAsFixed(1)} points!'
                : 'Try focusing on your weak areas to improve',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentColor.withOpacity(0.2),
                    AppTheme.secondaryAccent.withOpacity(0.2),
                  ],
                ),
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 64,
                color: AppTheme.accentColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No data yet',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Record more speeches to see your progress',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.mic),
              label: const Text('Start Recording'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}