import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _analysisDepth = 'standard';
  String _expectedDuration = '5-7 minutes';
  bool _autoSave = true;
  bool _pushNotifications = true;
  bool _darkMode = false;
  double _audioQuality = 0.8;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        title: Text(
          'Settings',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'Save',
              style: TextStyle(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Account Section
          _buildSectionHeader('ACCOUNT', Icons.person, AppTheme.voiceColor),
          const SizedBox(height: 12),
          _buildAccountCard(user),

          const SizedBox(height: 32),

          // Analysis Preferences Section
          _buildSectionHeader('ANALYSIS PREFERENCES', Icons.analytics, AppTheme.grammarColor),
          const SizedBox(height: 12),
          _buildAnalysisPreferences(),

          const SizedBox(height: 32),

          // Recording Settings Section
          _buildSectionHeader('RECORDING', Icons.mic, AppTheme.structureColor),
          const SizedBox(height: 12),
          _buildRecordingSettings(),

          const SizedBox(height: 32),

          // Notifications Section
          _buildSectionHeader('NOTIFICATIONS', Icons.notifications, AppTheme.proficiencyColor),
          const SizedBox(height: 12),
          _buildNotifications(),

          const SizedBox(height: 32),

          // Appearance Section
          _buildSectionHeader('APPEARANCE', Icons.palette, AppTheme.accentColor),
          const SizedBox(height: 12),
          _buildAppearance(),

          const SizedBox(height: 32),

          // Data & Privacy Section
          _buildSectionHeader('DATA & PRIVACY', Icons.security, AppTheme.textPrimary),
          const SizedBox(height: 12),
          _buildDataPrivacy(),

          const SizedBox(height: 32),

          // Account Actions Section
          _buildSectionHeader('ACCOUNT ACTIONS', Icons.warning_amber, AppTheme.errorColor),
          const SizedBox(height: 12),
          _buildAccountActions(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textTertiary,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard(User? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: AppTheme.voiceColor.withOpacity(0.2),
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
              gradient: AppTheme.primaryGradient,
            ),
            child: Center(
              child: Text(
                _getInitials(user),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
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
                  user?.displayName ?? 'User',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisPreferences() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: AppTheme.grammarColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          _buildDropdownSetting(
            icon: Icons.analytics,
            title: 'Analysis Depth',
            value: _analysisDepth,
            items: [
              {'value': 'basic', 'label': 'Basic'},
              {'value': 'standard', 'label': 'Standard - Recommended'},
              {'value': 'advanced', 'label': 'Advanced'},
            ],
            onChanged: (value) => setState(() => _analysisDepth = value!),
            color: AppTheme.grammarColor,
          ),
          Divider(height: 1, color: AppTheme.textTertiary.withOpacity(0.1)),
          _buildDropdownSetting(
            icon: Icons.timer,
            title: 'Expected Duration',
            value: _expectedDuration,
            items: [
              {'value': '1-3 minutes', 'label': '1-3 minutes'},
              {'value': '3-5 minutes', 'label': '3-5 minutes'},
              {'value': '5-7 minutes', 'label': '5-7 minutes'},
              {'value': '7-10 minutes', 'label': '7-10 minutes'},
            ],
            onChanged: (value) => setState(() => _expectedDuration = value!),
            color: AppTheme.grammarColor,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingSettings() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: AppTheme.structureColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.structureColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.hd, color: AppTheme.structureColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Audio Quality',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Higher quality uses more storage',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _audioQuality > 0.7 ? 'High' : _audioQuality > 0.4 ? 'Medium' : 'Low',
                      style: TextStyle(
                        color: AppTheme.structureColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppTheme.structureColor,
                    inactiveTrackColor: AppTheme.structureColor.withOpacity(0.2),
                    thumbColor: AppTheme.structureColor,
                    overlayColor: AppTheme.structureColor.withOpacity(0.2),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: _audioQuality,
                    onChanged: (value) => setState(() => _audioQuality = value),
                    min: 0.0,
                    max: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.textTertiary.withOpacity(0.1)),
          _buildSwitchSetting(
            icon: Icons.save,
            title: 'Auto-save Recordings',
            subtitle: 'Automatically save speeches to history',
            value: _autoSave,
            onChanged: (value) => setState(() => _autoSave = value),
            color: AppTheme.structureColor,
          ),
        ],
      ),
    );
  }

  Widget _buildNotifications() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: AppTheme.proficiencyColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: _buildSwitchSetting(
        icon: Icons.notifications_active,
        title: 'Push Notifications',
        subtitle: 'Receive reminders and updates',
        value: _pushNotifications,
        onChanged: (value) => setState(() => _pushNotifications = value),
        color: AppTheme.proficiencyColor,
      ),
    );
  }

  Widget _buildAppearance() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: _buildSwitchSetting(
        icon: Icons.dark_mode,
        title: 'Dark Mode',
        subtitle: 'Use dark theme (always on)',
        value: _darkMode,
        onChanged: (value) => setState(() => _darkMode = value),
        color: AppTheme.accentColor,
      ),
    );
  }

  Widget _buildDataPrivacy() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: AppTheme.textSecondary.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          _buildActionSetting(
            icon: Icons.delete_sweep,
            title: 'Free up storage space',
            subtitle: 'Delete old recordings',
            onTap: _showComingSoon,
            color: AppTheme.textSecondary,
          ),
          Divider(height: 1, color: AppTheme.textTertiary.withOpacity(0.1)),
          _buildActionSetting(
            icon: Icons.download,
            title: 'Download your speech history',
            subtitle: 'Export all your data',
            onTap: _showComingSoon,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          _buildActionSetting(
            icon: Icons.lock,
            title: 'Update your password',
            subtitle: 'Change account password',
            onTap: _showComingSoon,
            color: AppTheme.textSecondary,
          ),
          Divider(height: 1, color: AppTheme.textTertiary.withOpacity(0.1)),
          _buildActionSetting(
            icon: Icons.warning,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account',
            onTap: _confirmDeleteAccount,
            color: AppTheme.errorColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting({
    required IconData icon,
    required String title,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DropdownButton<String>(
            value: value,
            items: items.map((item) {
              return DropdownMenuItem(
                value: item['value'],
                child: Text(
                  item['label']!,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: color),
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSetting({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color == AppTheme.errorColor ? color : AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
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
    );
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Settings saved successfully'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showComingSoon() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Coming Soon',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This feature is under development.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: AppTheme.accentColor),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Account',
          style: TextStyle(
            color: AppTheme.errorColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoon();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getInitials(User? user) {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      final parts = user.displayName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return user.displayName![0].toUpperCase();
    }
    return user?.email?[0].toUpperCase() ?? 'U';
  }
}