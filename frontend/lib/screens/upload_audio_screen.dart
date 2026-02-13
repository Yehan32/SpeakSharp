import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';
import 'package:Speak_Sharp/services/api_service.dart';
import 'package:Speak_Sharp/screens/analysis/feedback_screen.dart';

class UploadAudioScreen extends StatefulWidget {
  const UploadAudioScreen({super.key});

  @override
  State<UploadAudioScreen> createState() => _UploadAudioScreenState();
}

class _UploadAudioScreenState extends State<UploadAudioScreen> {
  File? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final _topicController = TextEditingController();
  String _selectedDuration = '5-7 minutes';
  String _selectedDepth = 'standard';
  String _selectedGender = 'auto';

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'ogg', 'flac'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();
        final fileSizeMB = fileSize / (1024 * 1024);

        // Check file size (max 50MB)
        if (fileSizeMB > 50) {
          _showError('File too large. Maximum size is 50MB');
          return;
        }

        setState(() {
          _selectedFile = file;
        });
      }
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  Future<void> _uploadAndAnalyze() async {
    if (_selectedFile == null) {
      _showError('Please select an audio file');
      return;
    }

    if (_topicController.text.isEmpty) {
      _showError('Please enter a topic');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('Please login first');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final result = await ApiService.analyzeSpeech(
        audioFile: _selectedFile!,
        userId: user.uid,
        topic: _topicController.text,
        expectedDuration: _selectedDuration,
        gender: _selectedGender,
        analysisDepth: _selectedDepth,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
            });
          }
        },
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FeedbackScreen(
            analysisResults: result,
            audioPath: _selectedFile!.path,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
        _showError('Upload failed: $e');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
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
          'Upload Recording',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        leading: _isUploading
            ? null
            : IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isUploading ? _buildUploadingView() : _buildUploadForm(),
    );
  }

  Widget _buildUploadForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Upload an existing audio file to get instant feedback',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // File Picker
          InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedFile != null
                      ? AppTheme.primaryColor
                      : Colors.white.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedFile != null
                          ? AppTheme.primaryColor.withOpacity(0.2)
                          : Colors.white.withOpacity(0.1),
                    ),
                    child: Icon(
                      _selectedFile != null
                          ? Icons.check_circle
                          : Icons.upload_file,
                      size: 48,
                      color: _selectedFile != null
                          ? AppTheme.primaryColor
                          : AppTheme.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFile != null
                        ? _selectedFile!.path.split('/').last
                        : 'Tap to select audio file',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'MP3, WAV, M4A, OGG, FLAC (Max 50MB)',
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Topic Input
          const Text(
            'Speech Details',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _topicController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Topic *',
              labelStyle: const TextStyle(color: AppTheme.textSecondary),
              hintText: 'e.g., Climate Change',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: AppTheme.cardColor,
              prefixIcon: const Icon(Icons.topic, color: AppTheme.textTertiary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Expected Duration
          DropdownButtonFormField<String>(
            value: _selectedDuration,
            dropdownColor: AppTheme.cardColor,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Expected Duration',
              labelStyle: const TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.cardColor,
              prefixIcon: const Icon(Icons.timer, color: AppTheme.textTertiary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              '1-2 minutes',
              '3-5 minutes',
              '5-7 minutes',
              '7-10 minutes',
              '10-15 minutes',
              '15+ minutes',
            ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (v) => setState(() => _selectedDuration = v!),
          ),

          const SizedBox(height: 16),

          // Analysis Depth
          DropdownButtonFormField<String>(
            value: _selectedDepth,
            dropdownColor: AppTheme.cardColor,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Analysis Depth',
              labelStyle: const TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.cardColor,
              prefixIcon: const Icon(Icons.analytics, color: AppTheme.textTertiary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'basic',
                child: Text('Basic - Fast Analysis'),
              ),
              DropdownMenuItem(
                value: 'standard',
                child: Text('Standard - Recommended'),
              ),
              DropdownMenuItem(
                value: 'advanced',
                child: Text('Advanced - Detailed'),
              ),
            ],
            onChanged: (v) => setState(() => _selectedDepth = v!),
          ),

          const SizedBox(height: 16),

          // Gender Selection
          DropdownButtonFormField<String>(
            value: _selectedGender,
            dropdownColor: AppTheme.cardColor,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Gender (for voice analysis)',
              labelStyle: const TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.cardColor,
              prefixIcon: const Icon(Icons.person, color: AppTheme.textTertiary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'auto',
                child: Text('Auto-detect'),
              ),
              DropdownMenuItem(
                value: 'male',
                child: Text('Male'),
              ),
              DropdownMenuItem(
                value: 'female',
                child: Text('Female'),
              ),
            ],
            onChanged: (v) => setState(() => _selectedGender = v!),
          ),

          const SizedBox(height: 32),

          // Upload Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedFile != null ? _uploadAndAnalyze : null,
              icon: const Icon(Icons.cloud_upload),
              label: const Text(
                'Upload & Analyze',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.cloud_upload,
                size: 64,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Analyzing Your Speech',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Using AI to evaluate your performance',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: 300,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor:
                  AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  minHeight: 10,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${(_uploadProgress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'This may take 1-2 minutes...',
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please don\'t close the app',
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}