import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';
import '../recording/recording_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _userName = 'User';
  int _totalSpeeches = 0;
  double _averageScore = 0.0;
  List<Map<String, dynamic>> _recentSpeeches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get user name
      setState(() {
        _userName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
      });

      // Get user's speeches
      final speechesSnapshot = await FirebaseFirestore.instance
          .collection('speeches')
          .where('user_id', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      if (speechesSnapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _totalSpeeches = 0;
          _averageScore = 0.0;
          _recentSpeeches = [];
        });
        return;
      }

      // Calculate statistics
      double totalScore = 0;
      List<Map<String, dynamic>> speeches = [];

      for (var doc in speechesSnapshot.docs) {
        final data = doc.data();
        totalScore += (data['overall_score'] ?? 0.0) as double;

        speeches.add({
          'id': doc.id,
          'topic': data['topic'] ?? 'Untitled',
          'score': data['overall_score'] ?? 0.0,
          'timestamp': data['timestamp'] as Timestamp?,
          'duration': data['duration']?['actual'] ?? 'N/A',
        });
      }

      setState(() {
        _totalSpeeches = speechesSnapshot.docs.length;
        _averageScore = totalScore / speechesSnapshot.docs.length;
        _recentSpeeches = speeches;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(25),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getGreeting()},',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$_userName 👋',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadUserData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Big Action Button
                      InkWell(
                        onTap: () {
                          _showRecordingDialog(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentColor.withOpacity(0.3),
                                blurRadius: 40,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Icon(
                                  Icons.mic,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 15),
                              const Text(
                                'Start Recording',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Begin a new speech session',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Metrics Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              _totalSpeeches.toString(),
                              'Speeches',
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildMetricCard(
                              _averageScore.toStringAsFixed(1),
                              'Avg Score',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // Section Title
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'RECENT ACTIVITY',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Speech Cards
                      if (_recentSpeeches.isEmpty)
                        _buildEmptyState()
                      else
                        ..._recentSpeeches.map((speech) {
                          final timestamp = speech['timestamp'] as Timestamp?;
                          final date = timestamp?.toDate();
                          final daysAgo = date != null
                              ? DateTime.now().difference(date).inDays
                              : 0;
                          final timeAgo = daysAgo == 0
                              ? 'Today'
                              : daysAgo == 1
                              ? '1 day ago'
                              : '$daysAgo days ago';

                          return _buildSpeechCard(
                            speech['topic'] as String,
                            '$timeAgo • ${speech['duration']}',
                            (speech['score'] as double).toStringAsFixed(1),
                            speech['id'] as String,
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Navigation
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 15,
                bottom: 25,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home, 'Home', 0),
                  _buildNavItem(Icons.history, 'History', 1),
                  _buildNavItem(Icons.person, 'Profile', 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechCard(String title, String meta, String score, String id) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to speech details
            Navigator.of(context).pushNamed('/history');
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppTheme.warningGradient,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  score,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.mic_none,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No speeches yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Record your first speech to get started',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isActive = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (index == 1) {
          Navigator.of(context).pushNamed('/history');
        } else if (index == 2) {
          Navigator.of(context).pushNamed('/profile');
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppTheme.accentColor : AppTheme.textTertiary,
            size: 24,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? AppTheme.accentColor : AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  void _showRecordingDialog(BuildContext context) {
    final topicController = TextEditingController();
    String selectedDuration = '5-7 minutes';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'New Speech',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: topicController,
              decoration: const InputDecoration(
                labelText: 'Speech Topic',
                hintText: 'Enter your topic',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedDuration,
              decoration: const InputDecoration(
                labelText: 'Expected Duration',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: '1-2 minutes', child: Text('1-2 minutes')),
                DropdownMenuItem(value: '2-3 minutes', child: Text('2-3 minutes')),
                DropdownMenuItem(value: '5-7 minutes', child: Text('5-7 minutes')),
                DropdownMenuItem(value: '10-15 minutes', child: Text('10-15 minutes')),
              ],
              onChanged: (value) {
                if (value != null) selectedDuration = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final topic = topicController.text.trim();
              if (topic.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a topic'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecordingScreen(
                    topic: topic,
                    expectedDuration: selectedDuration,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
            ),
            child: const Text('Start Recording'),
          ),
        ],
      ),
    );
  }
}