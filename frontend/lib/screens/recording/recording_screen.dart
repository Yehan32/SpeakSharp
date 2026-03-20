import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';
import 'playback_screen.dart';

class RecordingScreen extends StatefulWidget {
  final String topic;
  final String expectedDuration;

  const RecordingScreen({
    Key? key,
    required this.topic,
    required this.expectedDuration,
  }) : super(key: key);

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with SingleTickerProviderStateMixin {
  final _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  bool _isPaused = false;
  String? _audioPath;

  // Timer variables
  int _recordDuration = 0;
  Timer? _timer;
  Timer? _amplitudeTimer;

  // Animation for recording indicator
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Audio amplitude (for visual feedback)
  double _currentAmplitude = 0.0;

  @override
  void initState() {
    super.initState();

    // Setup animation for pulsing record button
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Request microphone permission and start recording
    _initRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    _animationController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _initRecording() async {
    // Request microphone permission
    final status = await Permission.microphone.request();

    if (status != PermissionStatus.granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required to record audio'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
      return;
    }

    // Start recording automatically
    await _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        // Get temporary directory
        final Directory appDirectory = await getApplicationDocumentsDirectory();
        final String filePath = '${appDirectory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        // Start recording
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _audioPath = filePath;
        });

        // Start timer
        _startTimer();

        // Start amplitude monitoring (for visual feedback)
        _startAmplitudeMonitoring();
      }
    } catch (e) {
      print('Error starting recording: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordDuration++;
      });
    });
  }

  void _startAmplitudeMonitoring() {
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (_isRecording && !_isPaused) {
        final amplitude = await _audioRecorder.getAmplitude();
        setState(() {
          // Normalize amplitude to 0-1 range
          _currentAmplitude = (amplitude.current + 50) / 50;
          _currentAmplitude = _currentAmplitude.clamp(0.0, 1.0);
        });
      }
    });
  }

  Future<void> _pauseRecording() async {
    await _audioRecorder.pause();
    _timer?.cancel();
    setState(() {
      _isPaused = true;
    });
  }

  Future<void> _resumeRecording() async {
    await _audioRecorder.resume();
    _startTimer();
    setState(() {
      _isPaused = false;
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _amplitudeTimer?.cancel();

    final path = await _audioRecorder.stop();

    setState(() {
      _isRecording = false;
      _audioPath = path;
    });

    if (path != null && mounted) {
      // Navigate to playback screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PlaybackScreen(
            audioPath: path,
            topic: widget.topic,
            expectedDuration: widget.expectedDuration,
            recordingDuration: _recordDuration,
          ),
        ),
      );
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () async {
            final shouldExit = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text('Cancel Recording?',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold)),
                content: Text('Your recording will be lost.',
                    style: TextStyle(color: AppTheme.textSecondary)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Continue',
                        style: TextStyle(color: AppTheme.accentColor)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(
                        foregroundColor: AppTheme.errorColor),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            );
            if (shouldExit == true) {
              _timer?.cancel();
              _amplitudeTimer?.cancel();
              await _audioRecorder.stop();
              if (mounted) Navigator.pop(context);
            }
          },
        ),
        title: Text(
          widget.topic,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Duration badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.accentColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined,
                        color: AppTheme.accentColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Expected: ${widget.expectedDuration}',
                      style: TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Recording Visualization
              _buildRecordingVisualization(),

              const SizedBox(height: 40),

              // Timer Display
              Text(
                _formatDuration(_recordDuration),
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 64,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 4,
                ),
              ),

              const SizedBox(height: 8),

              // Status pill
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _isPaused
                      ? AppTheme.warningColor.withOpacity(0.1)
                      : AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isPaused
                            ? AppTheme.warningColor
                            : AppTheme.errorColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isPaused ? 'PAUSED' : 'RECORDING',
                      style: TextStyle(
                        color: _isPaused
                            ? AppTheme.warningColor
                            : AppTheme.errorColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: _isPaused ? Icons.play_arrow : Icons.pause,
                    label: _isPaused ? 'Resume' : 'Pause',
                    color: AppTheme.warningColor,
                    onPressed:
                    _isPaused ? _resumeRecording : _pauseRecording,
                  ),
                  _buildControlButton(
                    icon: Icons.stop,
                    label: 'Stop',
                    color: AppTheme.errorColor,
                    onPressed: _stopRecording,
                    isLarge: true,
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingVisualization() {
    return Column(
      children: [
        ScaleTransition(
          scale: _animation,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.accentColor.withOpacity(0.2),
                  AppTheme.accentColor.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isPaused
                      ? LinearGradient(colors: [
                    AppTheme.warningColor,
                    AppTheme.warningColor.withOpacity(0.8)
                  ])
                      : AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: (_isPaused
                          ? AppTheme.warningColor
                          : AppTheme.accentColor)
                          .withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  _isPaused ? Icons.pause : Icons.mic,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Live amplitude bars
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(24, (i) {
              final h = _isPaused
                  ? 4.0
                  : (4.0 + _currentAmplitude * 36 * (0.4 + (i % 4) * 0.2));
              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 3,
                height: h.clamp(4.0, 40.0),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isLarge = false,
  }) {
    final size = isLarge ? 80.0 : 64.0;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(size / 2),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: isLarge ? 40 : 32,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}