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
  bool _isLoading = true;
  List<Map<String, dynamic>> _allSpeeches = [];
  List<Map<String, dynamic>> _filteredSpeeches = [];
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'newest'; // newest, oldest, highest, lowest

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_filterSpeeches);
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
      setState(() {
        _allSpeeches = history;
        _filteredSpeeches = history;
        _isLoading = false;
        _applySorting();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load history: $e');
    }
  }

  void _filterSpeeches() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSpeeches = List.from(_allSpeeches);
      } else {
        _filteredSpeeches = _allSpeeches.where((speech) {
          final topic = (speech['topic'] ?? '').toString().toLowerCase();
          return topic.contains(query);
        }).toList();
      }
      _applySorting();
    });
  }

  void _applySorting() {
    switch (_sortBy) {
      case 'newest':
        _filteredSpeeches.sort((a, b) {
          final aTime = _parseTimestamp(a['timestamp']);
          final bTime = _parseTimestamp(b['timestamp']);
          return bTime.compareTo(aTime);
        });
        break;
      case 'oldest':
        _filteredSpeeches.sort((a, b) {
          final aTime = _parseTimestamp(a['timestamp']);
          final bTime = _parseTimestamp(b['timestamp']);
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
  }

  DateTime _parseTimestamp(dynamic timestamp) {
    try {
      if (timestamp is String) {
        return DateTime.parse(timestamp);
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  Future<void> _deleteAnalysis(String analysisId, int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Delete Speech?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.deleteAnalysis(
        analysisId: analysisId,
        userId: user.uid,
      );

      setState(() {
        _allSpeeches.removeAt(index);
        _filteredSpeeches = List.from(_allSpeeches);
        _filterSpeeches();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('Failed to delete speech: $e');
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sort By',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSortOption('Newest First', 'newest'),
            _buildSortOption('Oldest First', 'oldest'),
            _buildSortOption('Highest Score', 'highest'),
            _buildSortOption('Lowest Score', 'lowest'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? AppTheme.primaryColor : AppTheme.textTertiary,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: () {
        setState(() {
          _sortBy = value;
          _applySorting();
        });
        Navigator.pop(context);
      },
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Speech History',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort, color: AppTheme.textPrimary),
            onPressed: _showSortOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search speeches...',
                hintStyle: TextStyle(color: AppTheme.textTertiary),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textTertiary),
                filled: true,
                fillColor: AppTheme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.textTertiary),
                  onPressed: () {
                    _searchController.clear();
                    _filterSpeeches();
                  },
                )
                    : null,
              ),
            ),
          ),

          // Results Count
          if (_filteredSpeeches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${_filteredSpeeches.length} speech${_filteredSpeeches.length == 1 ? '' : 'es'}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Speeches List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSpeeches.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _loadHistory,
              color: AppTheme.primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredSpeeches.length,
                itemBuilder: (context, index) {
                  return _buildSpeechCard(
                    _filteredSpeeches[index],
                    index,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.mic_off,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No speeches found' : 'No speeches yet',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Try a different search term'
                : 'Record or upload your first speech',
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechCard(Map<String, dynamic> speech, int index) {
    final topic = speech['topic'] ?? 'Untitled';
    final score = (speech['overall_score'] ?? 0).toDouble();
    final timestamp = speech['timestamp'];
    final date = timestamp != null ? _formatDate(timestamp) : 'Recently';
    final analysisId = speech['analysis_id'] ?? speech['id'];

    return Dismissible(
      key: Key(analysisId ?? '$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: AppTheme.textPrimary, size: 32),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            title: const Text(
              'Delete Speech?',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            content: const Text(
              'This action cannot be undone.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && analysisId != null) {
          ApiService.deleteAnalysis(
            analysisId: analysisId,
            userId: user.uid,
          ).then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Speech deleted'),
                backgroundColor: Colors.green,
              ),
            );
          }).catchError((e) {
            _loadHistory(); // Reload on error
            _showError('Failed to delete: $e');
          });
        }

        setState(() {
          _filteredSpeeches.removeAt(index);
          _allSpeeches.remove(speech);
        });
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
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                // Score Circle
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getScoreColor(score).withOpacity(0.2),
                    border: Border.all(
                      color: _getScoreColor(score),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      score.toStringAsFixed(0),
                      style: TextStyle(
                        color: _getScoreColor(score),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: TextStyle(
                              color: AppTheme.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        ],
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

  Color _getScoreColor(double score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.blue;
    if (score >= 55) return Colors.orange;
    return Colors.red;
  }
}