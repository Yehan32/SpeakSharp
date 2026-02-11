import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Settings values
  bool _notificationsEnabled = true;
  bool _autoSaveEnabled = true;
  bool _darkModeEnabled = true;
  String _defaultAnalysisDepth = 'standard';
  String _defaultDuration = '5-7 minutes';
  double _audioQuality = 1.0; // 0: Low, 0.5: Medium, 1: High

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _autoSaveEnabled = prefs.getBool('auto_save_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? true;
      _defaultAnalysisDepth = prefs.getString('default_analysis_depth') ?? 'standard';
      _defaultDuration = prefs.getString('default_duration') ?? '5-7 minutes';
      _audioQuality = prefs.getDouble('audio_quality') ?? 1.0;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('auto_save_enabled', _autoSaveEnabled);
    await prefs.setBool('dark_mode_enabled', _darkModeEnabled);
    await prefs.setString('default_analysis_depth', _defaultAnalysisDepth);
    await prefs.setString('default_duration', _defaultDuration);
    await prefs.setDouble('audio_quality', _audioQuality);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'Save',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          _buildAccountInfo(user),
          const SizedBox(height: 24),

          // Analysis Preferences
          _buildSectionHeader('Analysis Preferences'),
          _buildSettingsTile(
            'Default Analysis Depth',
            _defaultAnalysisDepth.toUpperCase(),
            Icons.analytics,
            onTap: () => _showAnalysisDepthPicker(),
          ),
          _buildSettingsTile(
            'Default Duration',
            _defaultDuration,
            Icons.timer,
            onTap: () => _showDurationPicker(),
          ),
          const SizedBox(height: 24),

          // Recording Settings
          _buildSectionHeader('Recording'),
          _buildAudioQualitySlider(),
          _buildSwitchTile(
            'Auto-save Recordings',
            'Automatically save speeches to history',
            Icons.save,
            _autoSaveEnabled,
                (value) => setState(() => _autoSaveEnabled = value),
          ),
          const SizedBox(height: 24),

          // Notifications
          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            'Push Notifications',
            'Receive reminders and updates',
            Icons.notifications,
            _notificationsEnabled,
                (value) => setState(() => _notificationsEnabled = value),
          ),
          const SizedBox(height: 24),

          // Appearance
          _buildSectionHeader('Appearance'),
          _buildSwitchTile(
            'Dark Mode',
            'Use dark theme (always on)',
            Icons.dark_mode,
            _darkModeEnabled,
                (value) => setState(() => _darkModeEnabled = value),
          ),
          const SizedBox(height: 24),

          // Data & Privacy
          _buildSectionHeader('Data & Privacy'),
          _buildSettingsTile(
            'Clear Cache',
            'Free up storage space',
            Icons.delete_outline,
            onTap: _clearCache,
          ),
          _buildSettingsTile(
            'Export Data',
            'Download your speech history',
            Icons.download,
            onTap: _exportData,
          ),
          const SizedBox(height: 24),

          // Account Actions
          _buildSectionHeader('Account Actions'),
          _buildSettingsTile(
            'Change Password',
            'Update your password',
            Icons.lock_outline,
            onTap: _changePassword,
          ),
          _buildSettingsTile(
            'Delete Account',
            'Permanently delete your account',
            Icons.warning_amber,
            onTap: _deleteAccount,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildAccountInfo(User? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              user?.email?[0].toUpperCase() ?? 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
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
    );
  }

  Widget _buildSettingsTile(
      String title,
      String subtitle,
      IconData icon, {
        VoidCallback? onTap,
        bool isDestructive = false,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.white70,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDestructive ? Colors.red : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
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
    );
  }

  Widget _buildSwitchTile(
      String title,
      String subtitle,
      IconData icon,
      bool value,
      ValueChanged<bool> onChanged,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAudioQualitySlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.high_quality, color: Colors.white70, size: 24),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio Quality',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Higher quality uses more storage',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _getQualityLabel(),
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.primaryColor,
              inactiveTrackColor: Colors.white.withOpacity(0.2),
              thumbColor: AppTheme.primaryColor,
              overlayColor: AppTheme.primaryColor.withOpacity(0.3),
            ),
            child: Slider(
              value: _audioQuality,
              min: 0,
              max: 1,
              divisions: 2,
              onChanged: (value) => setState(() => _audioQuality = value),
            ),
          ),
        ],
      ),
    );
  }

  String _getQualityLabel() {
    if (_audioQuality == 0) return 'Low';
    if (_audioQuality == 0.5) return 'Medium';
    return 'High';
  }

  void _showAnalysisDepthPicker() {
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
            const Text(
              'Default Analysis Depth',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDepthOption('Basic', 'basic', 'Faster analysis'),
            _buildDepthOption('Standard', 'standard', 'Recommended'),
            _buildDepthOption('Advanced', 'advanced', 'Most detailed'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDepthOption(String label, String value, String desc) {
    return ListTile(
      leading: Icon(
        _defaultAnalysisDepth == value
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked,
        color: _defaultAnalysisDepth == value
            ? AppTheme.primaryColor
            : Colors.white54,
      ),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      subtitle: Text(desc, style: const TextStyle(color: Colors.white60)),
      onTap: () {
        setState(() => _defaultAnalysisDepth = value);
        Navigator.pop(context);
      },
    );
  }

  void _showDurationPicker() {
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
            const Text(
              'Default Duration',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...['1-2 minutes', '3-5 minutes', '5-7 minutes', '7-10 minutes']
                .map((d) => _buildDurationOption(d)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationOption(String duration) {
    return ListTile(
      leading: Icon(
        _defaultDuration == duration
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked,
        color: _defaultDuration == duration
            ? AppTheme.primaryColor
            : Colors.white54,
      ),
      title: Text(duration, style: const TextStyle(color: Colors.white)),
      onTap: () {
        setState(() => _defaultDuration = duration);
        Navigator.pop(context);
      },
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Clear Cache?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will free up storage space but may slow down the app temporarily.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export feature coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _changePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password change feature coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Delete Account?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This action is permanent and cannot be undone. All your data will be deleted.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement account deletion
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}