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
  Map<String, dynamic>? _stats;
  String _selectedPeriod = '7days'; // 7days, 30days, all

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
      final speeches = await ApiService.getUserHistory(
        userId: user.uid,
        limit: 100,
      );
      final stats = await ApiService.getUserStatistics(userId: user.uid);

      setState(() {
        _speeches = speeches;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading progress data: $e');
    }
  }

  List<Map<String, dynamic>> _getFilteredSpeeches() {
    if (_selectedPeriod == 'all') return _speeches;

    final now = DateTime.now();
    final cutoffDate = _selectedPeriod == '7days'
        ? now.subtract(const Duration(days: 7))
        : now.subtract(const Duration(days: 30));

    return _speeches.where((speech) {
      try {
        final timestamp = speech['timestamp'];
        if (timestamp is String) {
          final date = DateTime.parse(timestamp);
          return date.isAfter(cutoffDate);
        }
        return false;
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Progress Dashboard',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _speeches.isEmpty
          ? _buildEmptyState()
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 20),
          _buildOverallStats(),
          const SizedBox(height: 20),
          _buildScoreTrendChart(),
          const SizedBox(height: 20),
          _buildCategoryBreakdown(),
          const SizedBox(height: 20),
          _buildImprovementSuggestions(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No data yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Record more speeches to see your progress',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        _buildPeriodChip('Last 7 Days', '7days'),
        const SizedBox(width: 8),
        _buildPeriodChip('Last 30 Days', '30days'),
        const SizedBox(width: 8),
        _buildPeriodChip('All Time', 'all'),
      ],
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return InkWell(
      onTap: () => setState(() => _selectedPeriod = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildOverallStats() {
    final filteredSpeeches = _getFilteredSpeeches();
    final avgScore = filteredSpeeches.isEmpty
        ? 0.0
        : filteredSpeeches
        .map((s) => (s['overall_score'] ?? 0).toDouble())
        .reduce((a, b) => a + b) /
        filteredSpeeches.length;

    final totalSpeeches = filteredSpeeches.length;
    final bestScore = filteredSpeeches.isEmpty
        ? 0.0
        : filteredSpeeches
        .map((s) => (s['overall_score'] ?? 0).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Speeches',
                  totalSpeeches.toString(),
                  Icons.mic,
                ),
              ),
              Container(width: 1, height: 50, color: Colors.white30),
              Expanded(
                child: _buildStatItem(
                  'Avg Score',
                  avgScore.toStringAsFixed(1),
                  Icons.star,
                ),
              ),
              Container(width: 1, height: 50, color: Colors.white30),
              Expanded(
                child: _buildStatItem(
                  'Best',
                  bestScore.toStringAsFixed(1),
                  Icons.emoji_events,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
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

  Widget _buildScoreTrendChart() {
    final filteredSpeeches = _getFilteredSpeeches();
    if (filteredSpeeches.isEmpty) return const SizedBox();

    // Sort by date
    filteredSpeeches.sort((a, b) {
      try {
        final aDate = DateTime.parse(a['timestamp']);
        final bDate = DateTime.parse(b['timestamp']);
        return aDate.compareTo(bDate);
      } catch (e) {
        return 0;
      }
    });

    final spots = <FlSpot>[];
    for (int i = 0; i < filteredSpeeches.length; i++) {
      final score = (filteredSpeeches[i]['overall_score'] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), score));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Score Trend',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < filteredSpeeches.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${value.toInt() + 1}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
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
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (filteredSpeeches.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: AppTheme.primaryColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Speech Number',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final filteredSpeeches = _getFilteredSpeeches();
    if (filteredSpeeches.isEmpty) return const SizedBox();

    // Calculate average scores for each category
    final categories = {
      'Voice': 0.0,
      'Grammar': 0.0,
      'Structure': 0.0,
      'Proficiency': 0.0,
    };

    for (var speech in filteredSpeeches) {
      final scores = speech['scores'] ?? {};
      categories['Voice'] = (categories['Voice'] ?? 0) +
          ((scores['voice_modulation'] ?? 0) / 20 * 100);
      categories['Grammar'] = (categories['Grammar'] ?? 0) +
          ((scores['vocabulary'] ?? 0) / 50 * 100);
      categories['Structure'] = (categories['Structure'] ?? 0) +
          ((scores['speech_development'] ?? 0) / 20 * 100);
      categories['Proficiency'] = (categories['Proficiency'] ?? 0) +
          ((scores['proficiency'] ?? 0) / 20 * 100);
    }

    categories.updateAll((key, value) => value / filteredSpeeches.length);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Breakdown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...categories.entries.map((entry) {
            return _buildCategoryBar(
              entry.key,
              entry.value,
              _getCategoryIcon(entry.key),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(String label, double score, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                score.toStringAsFixed(1),
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(score / 100),
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementSuggestions() {
    final filteredSpeeches = _getFilteredSpeeches();
    if (filteredSpeeches.length < 2) return const SizedBox();

    // Compare first and last speech
    final firstSpeech = filteredSpeeches.first;
    final lastSpeech = filteredSpeeches.last;

    final firstScore = (firstSpeech['overall_score'] ?? 0).toDouble();
    final lastScore = (lastSpeech['overall_score'] ?? 0).toDouble();
    final improvement = lastScore - firstScore;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                improvement >= 0 ? Icons.trending_up : Icons.trending_down,
                color: improvement >= 0 ? Colors.green : Colors.red,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      improvement >= 0
                          ? 'Great improvement!'
                          : 'Keep practicing!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${improvement >= 0 ? '+' : ''}${improvement.toStringAsFixed(1)} points since first speech',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Voice':
        return Icons.multitrack_audio;
      case 'Grammar':
        return Icons.book;
      case 'Structure':
        return Icons.account_tree;
      case 'Proficiency':
        return Icons.star;
      default:
        return Icons.bar_chart;
    }
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 0.85) return Colors.green;
    if (percentage >= 0.70) return Colors.blue;
    if (percentage >= 0.55) return Colors.orange;
    return Colors.red;
  }
}