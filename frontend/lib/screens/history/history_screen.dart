import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';
import 'package:Speak_Sharp/services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _allSpeeches = [];
  List<Map<String, dynamic>> _filteredSpeeches = [];
  String _sortBy = 'newest'; // newest, oldest, highest, lowest

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
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
          _allSpeeches = history;
          _filteredSpeeches = history;
          _isLoading = false;
          _applySorting();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error loading history: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load history: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _filterSpeeches(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSpeeches = _allSpeeches;
      } else {
        _filteredSpeeches = _allSpeeches.where((speech) {
          final topic = (speech['topic'] ?? '').toLowerCase();
          final searchLower = query.toLowerCase();
          return topic.contains(searchLower);
        }).toList();
      }
      _applySorting();
    });
  }

  void _applySorting() {
    setState(() {
      switch (_sortBy) {
        case 'newest':
          _filteredSpeeches.sort((a, b) {
            final aTime = a['timestamp'] ?? '';
            final bTime = b['timestamp'] ?? '';
            return bTime.compareTo(aTime);
          });
          break;
        case 'oldest':
          _filteredSpeeches.sort((a, b) {
            final aTime = a['timestamp'] ?? '';
            final bTime = b['timestamp'] ?? '';
            return aTime.compareTo(bTime);
          });
          break;
        case 'highest':
          _filteredSpeeches.sort((a, b) {
            final aScore = (a['overall_score'] ?? 0).toDouble();
            final bScore = (b['overall_score'] ?? 0).toDouble();
            return bScore.compareTo(aScore);
          });
          break;
        case 'lowest':
          _filteredSpeeches.sort((a, b) {
            final aScore = (a['overall_score'] ?? 0).toDouble();
            final bScore = (b['overall_score'] ?? 0).toDouble();
            return aScore.compareTo(bScore);
          });
          break;
      }
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort by',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSortOption('Newest First', 'newest', Icons.access_time),
            _buildSortOption('Oldest First', 'oldest', Icons.history),
            _buildSortOption('Highest Score', 'highest', Icons.arrow_upward),
            _buildSortOption('Lowest Score', 'lowest', Icons.arrow_downward),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value, IconData icon) {
    final isSelected = _sortBy == value;

    return InkWell(
      onTap: () {
        setState(() => _sortBy = value);
        _applySorting();
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentColor
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.accentColor : AppTheme.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.accentColor : AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check, color: AppTheme.accentColor),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSpeech(String analysisId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Speech',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this speech?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await ApiService.deleteAnalysis(
          analysisId: analysisId,
          userId: user.uid,
        );

        await _loadHistory();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Speech deleted successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        title: Text(
          'Speech History',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.sort, color: AppTheme.textPrimary),
            onPressed: _showSortOptions,
            tooltip: 'Sort',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: AppTheme.cardColor,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.textTertiary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterSpeeches,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search speeches...',
                  hintStyle: TextStyle(color: AppTheme.textTertiary),
                  prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear, color: AppTheme.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      _filterSpeeches('');
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),

          // Results Count
          if (!_isLoading && _filteredSpeeches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Text(
                    '${_filteredSpeeches.length} ${_filteredSpeeches.length == 1 ? 'speech' : 'speeches'}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: _isLoading
                ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentColor,
              ),
            )
                : _filteredSpeeches.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _loadHistory,
              color: AppTheme.accentColor,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filteredSpeeches.length,
                itemBuilder: (context, index) =>
                    _buildSpeechCard(_filteredSpeeches[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchController.text.isNotEmpty;

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
                hasSearch ? Icons.search_off : Icons.mic_off,
                size: 64,
                color: AppTheme.accentColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasSearch ? 'No matches found' : 'No speeches yet',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasSearch
                  ? 'Try searching with different keywords'
                  : 'Record or upload your first speech to get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
              ),
            ),
            if (!hasSearch) ...[
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
          ],
        ),
      ),
    );
  }

  Widget _buildSpeechCard(Map<String, dynamic> speech) {
    final topic = speech['topic'] ?? 'Untitled';
    final score = (speech['overall_score'] ?? 0).toDouble();
    final timestamp = speech['timestamp'];
    final date = timestamp != null ? _formatDate(timestamp) : 'Recently';
    final analysisId = speech['analysis_id'] ?? speech['id'];

    final duration = speech['duration'];
    final durationSeconds = duration is Map ? (duration['seconds'] ?? 0) : 0;
    final durationText = _formatDuration(durationSeconds);

    return Dismissible(
      key: Key(analysisId?.toString() ?? topic),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        if (analysisId != null) {
          _deleteSpeech(analysisId.toString());
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                color: AppTheme.getScoreColor(score).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Score Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.getScoreColor(score),
                            AppTheme.getScoreColor(score).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.getColoredShadow(
                          AppTheme.getScoreColor(score),
                        ),
                      ),
                      child: Text(
                        score.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppTheme.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                date,
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              if (durationText.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.timer,
                                  size: 14,
                                  color: AppTheme.textTertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  durationText,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
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
              ],
            ),
          ),
        ),
      ),
    );
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
    if (seconds == 0) return '';

    final minutes = seconds ~/ 60;
    final secs = seconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }
}