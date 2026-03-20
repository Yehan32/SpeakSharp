import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({Key? key}) : super(key: key);

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Load recent speeches as activity notifications
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('speeches')
          .orderBy('recorded_at', descending: true)
          .limit(20)
          .get();

      final activityNotifs = snapshot.docs.map((doc) {
        final data = doc.data();
        final score = (data['overall_score'] ?? 0).toDouble();
        final topic = data['topic'] ?? 'Untitled';
        final ts = data['recorded_at'];
        String time = 'Recently';
        if (ts is Timestamp) {
          time = _formatDate(ts.toDate());
        }
        return {
          'id': doc.id,
          'type': 'analysis',
          'title': 'Speech Analysis Complete',
          'body': '"$topic" — Score: ${score.toStringAsFixed(1)}/100',
          'time': time,
          'score': score,
          'read': true,
          'icon': Icons.analytics_outlined,
          'color': AppTheme.getScoreColor(score),
        };
      }).toList();

      // Add static tip notifications
      final tips = [
        {
          'id': 'tip_1',
          'type': 'tip',
          'title': 'Speaking Tip',
          'body': 'Practice pausing instead of using filler words like "um" and "uh".',
          'time': 'Today',
          'read': false,
          'icon': Icons.lightbulb_outline,
          'color': AppTheme.proficiencyColor,
        },
        {
          'id': 'tip_2',
          'type': 'tip',
          'title': 'Improve Your Score',
          'body': 'A clear introduction and conclusion can boost your Structure score significantly.',
          'time': 'Yesterday',
          'read': false,
          'icon': Icons.trending_up,
          'color': AppTheme.successColor,
        },
      ];

      if (mounted) {
        setState(() {
          _notifications = [...tips, ...activityNotifs];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading notifications: $e');
    }
  }

  void _markAllRead() {
    setState(() {
      for (var n in _notifications) {
        n['read'] = true;
      }
    });
  }

  int get _unreadCount =>
      _notifications.where((n) => n['read'] == false).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadNotifications,
        color: AppTheme.accentColor,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _notifications.length,
          itemBuilder: (context, index) =>
              _buildNotificationCard(_notifications[index]),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['read'] as bool;
    final color = notification['color'] as Color;
    final icon = notification['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: isRead
              ? AppTheme.textTertiary.withOpacity(0.1)
              : color.withOpacity(0.3),
          width: isRead ? 1 : 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() => notification['read'] = true);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'],
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['body'],
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification['time'],
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentColor.withOpacity(0.1),
            ),
            child: Icon(Icons.notifications_none,
                size: 56, color: AppTheme.accentColor),
          ),
          const SizedBox(height: 20),
          Text(
            'No notifications yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your speech activity will appear here',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays == 0) return 'Today ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}