import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';
import 'package:Speak_Sharp/services/api_service.dart';
import '../analysis/feedback_screen.dart';

class PlaybackScreen extends StatefulWidget {
  final String audioPath;
  final String topic;
  final String expectedDuration;
  final int recordingDuration;

  const PlaybackScreen({
    super.key,
    required this.audioPath,
    required this.topic,
    required this.expectedDuration,
    required this.recordingDuration,
  });

  @override
  State<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initAudioPlayer() {
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() {
        _duration = duration;
      });
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() {
        _position = position;
      });
    });

    // Auto-play when screen opens
    _playAudio();
  }

  Future<void> _playAudio() async {
    try {
      await _audioPlayer.play(DeviceFileSource(widget.audioPath));
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to play audio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
  }

  Future<void> _resumeAudio() async {
    await _audioPlayer.resume();
  }

  Future<void> _seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _uploadAndAnalyze() async {
    if (!mounted) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      print('Starting upload and analysis...');

      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Upload and analyze with progress tracking
      final results = await ApiService.analyzeSpeech(
        audioFile: File(widget.audioPath),
        userId: user.uid,
        topic: widget.topic,
        expectedDuration: widget.expectedDuration,
        speechTitle: 'Speech on ${widget.topic}',
        gender: 'auto',
        analysisDepth: 'standard',
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
            });
          }
        },
      );

      print('Analysis complete!');

      if (!mounted) return;

      // Navigate to feedback screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FeedbackScreen(
            analysisResults: results,
            audioPath: widget.audioPath,
          ),
        ),
      );

    } catch (e) {
      print('Upload/Analysis error: $e');

      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      // Show error dialog with retry option
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: const Text(
            'Analysis Failed',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Failed to analyze speech: $e\n\nPlease check your internet connection and try again.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _uploadAndAnalyze(); // Retry
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _reRecord() async {
    // Show confirmation dialog
    final shouldReRecord = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Re-record Speech?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Your current recording will be lost.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Re-record'),
          ),
        ],
      ),
    );

    if (shouldReRecord == true && mounted) {
      // Delete current recording
      try {
        final file = File(widget.audioPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting file: $e');
      }

      if (mounted) {
        // Go back to recording screen
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Review Recording',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: _isUploading ? _buildUploadingView() : _buildPlaybackView(),
      ),
    );
  }

  Widget _buildPlaybackView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Topic Display
          Text(
            widget.topic,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Duration Info
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Recording: ${_formatDuration(Duration(seconds: widget.recordingDuration))}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),

          const Spacer(),

          // Waveform Visualization (simplified)
          _buildWaveformVisualization(),

          const SizedBox(height: 40),

          // Progress Bar
          Column(
            children: [
              Slider(
                value: _position.inSeconds.toDouble(),
                max: _duration.inSeconds.toDouble() > 0
                    ? _duration.inSeconds.toDouble()
                    : 1,
                onChanged: (value) {
                  _seekTo(Duration(seconds: value.toInt()));
                },
                activeColor: AppTheme.primaryColor,
                inactiveColor: AppTheme.primaryColor.withOpacity(0.3),
              ),

              // Time labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Play/Pause Button
          GestureDetector(
            onTap: _isPlaying ? _pauseAudio : _resumeAudio,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),

          const Spacer(),

          // Action Buttons
          Row(
            children: [
              // Re-record Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reRecord,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Re-record'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Analyze Button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _uploadAndAnalyze,
                  icon: const Icon(Icons.analytics),
                  label: const Text('Analyze Speech'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUploadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(seconds: 2),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: 0.8 + (value * 0.2),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.accentColor,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.cloud_upload,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            const Text(
              'Analyzing Your Speech',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              _getUploadMessage(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Progress Bar
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 300),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _uploadProgress,
                  minHeight: 8,
                  backgroundColor: AppTheme.cardColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              '${(_uploadProgress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getUploadMessage() {
    if (_uploadProgress < 0.3) {
      return 'Uploading your recording...';
    } else if (_uploadProgress < 0.6) {
      return 'Transcribing speech...';
    } else if (_uploadProgress < 0.9) {
      return 'Analyzing voice patterns...';
    } else {
      return 'Almost done...';
    }
  }

  Widget _buildWaveformVisualization() {
    // Simplified waveform - just bars for visual effect
    return SizedBox(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(30, (index) {
          // Create random-looking heights based on position
          final heightFactor = (index % 3 == 0) ? 0.8 : (index % 2 == 0) ? 0.5 : 0.3;
          final isActive = _isPlaying && (_position.inMilliseconds % 1000) > (index * 33);

          return Container(
            width: 4,
            height: 100 * heightFactor,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primaryColor
                  : AppTheme.primaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}