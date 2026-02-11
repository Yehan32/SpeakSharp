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
  String? _errorMessage;

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

    setState(() {
      _isLoadingStats = true;
      _errorMessage = null;
    });

    try {
      final stats = await ApiService.getUserStatistics(userId: user.uid);
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
        _errorMessage = 'Failed to load statistics';
      });
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _loadRecentActivity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingRecent = true;
    });

    try {
      final history = await ApiService.getUserHistory(
        userId: user.uid,
        limit: 5,
      );
      setState(() {
        _recentSpeeches = history;
        _isLoadingRecent = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRecent = false;
      });
      debugPrint('Error loading recent activity: $e');
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _startRecording() {
    // Show speech details dialog first
    showDialog(
      context: context,
      builder: (context) => const SpeechDetailsDialog(),
    ).then((details) {
      if (details != null) {
        Navigator.pushNamed(
          context,
          '/recording',
          arguments: details,
        ).then((_) => _refreshData());
      }
    });
  }

  void _uploadRecording() {
    Navigator.pushNamed(context, '/upload-audio').then((_) => _refreshData());
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
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '👋',
                            style: TextStyle(fontSize: 32),
                          ),
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
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        onTap: _startRecording,
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
                        onTap: _uploadRecording,
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // Statistics
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _buildStatistics(),
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
                      const Text(
                        'RECENT ACTIVITY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white54,
                          letterSpacing: 1,
                        ),
                      ),
                      if (_recentSpeeches.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/history');
                          },
                          child: Text(
                            'View All',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),
            TextButton(onPressed: _loadStatistics, child: const Text('Retry')),
          ],
        ),
      );
    }

    final totalSpeeches = _stats?['total_speeches'] ?? 0;
    final avgScore = (_stats?['average_score'] ?? 0.0).toDouble();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.mic,
            value: totalSpeeches.toString(),
            label: 'SPEECHES',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.star,
            value: avgScore.toStringAsFixed(1),
            label: 'AVG SCORE',
            color: Colors.orange,
          ),
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
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_isLoadingRecent) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(),
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
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                Icons.mic_off,
                size: 64,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No speeches yet',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Record or upload your first speech to get started',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getScoreColor(score).withOpacity(0.2),
                  border: Border.all(color: _getScoreColor(score), width: 2),
                ),
                child: Center(
                  child: Text(
                    score.toStringAsFixed(0),
                    style: TextStyle(
                      color: _getScoreColor(score),
                      fontSize: 16,
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
                      style: const TextStyle(
                        color: Colors.white,
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
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.3),
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
            color: Colors.black.withOpacity(0.3),
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
              color: isActive ? AppTheme.primaryColor : Colors.white54,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primaryColor : Colors.white54,
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

  Color _getScoreColor(double score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.blue;
    if (score >= 55) return Colors.orange;
    return Colors.red;
  }
}

// Speech Details Dialog Widget (referenced in _startRecording)
class SpeechDetailsDialog extends StatefulWidget {
  const SpeechDetailsDialog({super.key});

  @override
  State<SpeechDetailsDialog> createState() => _SpeechDetailsDialogState();
}

class _SpeechDetailsDialogState extends State<SpeechDetailsDialog> {
  final _topicController = TextEditingController();
  String _selectedDuration = '5-7 minutes';
  String _selectedDepth = 'standard';
  String _selectedGender = 'auto';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardColor,
      title: const Text(
        'Speech Details',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _topicController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Topic',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'e.g., Climate Change',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDuration,
              dropdownColor: AppTheme.cardColor,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Expected Duration',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              items: ['1-2 minutes', '3-5 minutes', '5-7 minutes', '7-10 minutes']
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedDuration = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDepth,
              dropdownColor: AppTheme.cardColor,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Analysis Depth',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              items: [
                DropdownMenuItem(value: 'basic', child: Text('Basic (Fast)')),
                DropdownMenuItem(value: 'standard', child: Text('Standard (Recommended)')),
                DropdownMenuItem(value: 'advanced', child: Text('Advanced (Detailed)')),
              ],
              onChanged: (v) => setState(() => _selectedDepth = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              dropdownColor: AppTheme.cardColor,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Gender',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              items: [
                DropdownMenuItem(value: 'auto', child: Text('Auto-detect')),
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
              ],
              onChanged: (v) => setState(() => _selectedGender = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'topic': _topicController.text.isEmpty ? 'Untitled' : _topicController.text,
              'expectedDuration': _selectedDuration,
              'analysisDepth': _selectedDepth,
              'gender': _selectedGender,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}