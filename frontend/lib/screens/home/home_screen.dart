import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';
import 'package:Speak_Sharp/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoadingStats = true;
  bool _isLoadingRecent = true;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _recentSpeeches = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadStatistics(),
      _loadRecentActivity(),
    ]);
  }

  Future<void> _loadStatistics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoadingStats = true);

    try {
      final stats = await ApiService.getUserStatistics(userId: user.uid);
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _loadRecentActivity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoadingRecent = true);

    try {
      final history = await ApiService.getUserHistory(
        userId: user.uid,
        limit: 5,
      );
      if (mounted) {
        setState(() {
          _recentSpeeches = history;
          _isLoadingRecent = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRecent = false);
      }
      debugPrint('Error loading recent activity: $e');
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName?.split(' ')[0] ?? 'User';
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppTheme.accentColor,
          child: CustomScrollView(
            slivers: [
              // Header with greeting
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting
                      Text(
                        greeting,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('👋', style: TextStyle(fontSize: 32)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      // Start Recording Button
                      _buildActionButton(
                        icon: Icons.mic,
                        title: 'Start Recording',
                        subtitle: 'Begin a new speech session',
                        gradient: AppTheme.primaryGradient,
                        onTap: () => Navigator.pushNamed(context, '/recording'),
                      ),

                      const SizedBox(height: 16),

                      // Upload Recording Button
                      _buildActionButton(
                        icon: Icons.upload_file,
                        title: 'Upload Recording',
                        subtitle: 'Analyze an existing audio file',
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade400,
                            Colors.deepPurple.shade600,
                          ],
                        ),
                        onTap: () => Navigator.pushNamed(context, '/upload-audio'),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // Statistics Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR PROGRESS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textTertiary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatistics(),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // Recent Activity Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RECENT ACTIVITY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textTertiary,
                          letterSpacing: 1,
                        ),
                      ),
                      if (_recentSpeeches.isNotEmpty)
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/history'),
                          child: Text(
                            'View All',
                            style: TextStyle(
                              color: AppTheme.accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Recent Speeches List
              _buildRecentActivity(),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    if (_isLoadingStats) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.accentColor),
        ),
      );
    }

    if (_stats == null) {
      return _buildEmptyStats();
    }

    final totalSpeeches = _stats!['total_speeches'] as int;
    final avgScore = (_stats!['average_score'] as num).toDouble();
    final bestScore = (_stats!['best_score'] as num).toDouble();
    final totalDuration = _stats!['total_duration'] as int;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.mic,
                value: totalSpeeches.toString(),
                label: 'Speeches',
                color: AppTheme.voiceColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.star,
                value: avgScore.toStringAsFixed(1),
                label: 'Avg Score',
                color: AppTheme.grammarColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.emoji_events,
                value: bestScore.toStringAsFixed(1),
                label: 'Best Score',
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.access_time,
                value: _formatDuration(totalDuration),
                label: 'Total Time',
                color: AppTheme.proficiencyColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.getColoredShadow(color),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
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
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStats() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 48,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No statistics yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Record or upload your first speech to see your progress',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_isLoadingRecent) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.accentColor),
          ),
        ),
      );
    }

    if (_recentSpeeches.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mic_off,
                  size: 48,
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No speeches yet',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Record or upload your first speech to get started',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) => _buildSpeechCard(_recentSpeeches[index]),
        childCount: _recentSpeeches.length,
      ),
    );
  }

  Widget _buildSpeechCard(Map<String, dynamic> speech) {
    final topic = speech['topic'] ?? 'Untitled';
    final score = (speech['overall_score'] ?? 0).toDouble();
    final timestamp = speech['timestamp'];
    final date = timestamp != null ? _formatDate(timestamp) : 'Recently';

    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/full-analysis',
            arguments: speech,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
            border: Border.all(
              color: AppTheme.getScoreColor(score).withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.getScoreColor(score),
                      AppTheme.getScoreColor(score).withOpacity(0.7),
                    ],
                  ),
                  boxShadow: AppTheme.getColoredShadow(AppTheme.getScoreColor(score)),
                ),
                child: Center(
                  child: Text(
                    score.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textTertiary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', true, () {}),
              _buildNavItem(
                Icons.history,
                'History',
                false,
                    () => Navigator.pushNamed(context, '/history'),
              ),
              _buildNavItem(
                Icons.person,
                'Profile',
                false,
                    () => Navigator.pushNamed(context, '/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon,
      String label,
      bool isActive,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.accentColor : AppTheme.textTertiary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.accentColor : AppTheme.textTertiary,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  String _formatDate(dynamic timestamp) {
    try {
      DateTime date;
      if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Recently';
      }

      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) return 'Today';
      if (difference.inDays == 1) return 'Yesterday';
      if (difference.inDays < 7) return '${difference.inDays} days ago';

      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Recently';
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${seconds}s';
    }
  }
}