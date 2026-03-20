import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';
import 'package:Speak_Sharp/widgets/main_bottom_nav.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
  }

  // ─── Photo Upload ──────────────────────────────────────────────────────────

  Future<void> _showPhotoOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Profile Photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.camera_alt, color: AppTheme.accentColor),
              ),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.grammarColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.photo_library, color: AppTheme.grammarColor),
              ),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (FirebaseAuth.instance.currentUser?.photoURL != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.delete_outline, color: AppTheme.errorColor),
                ),
                title: Text('Remove photo',
                    style: TextStyle(color: AppTheme.errorColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  _removePhoto();
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;
      await _uploadPhoto(File(picked.path));
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to pick image: $e', isError: true);
    }
  }

  Future<void> _uploadPhoto(File imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      // Upload to Firebase Storage under profile_photos/{uid}.jpg
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${user.uid}.jpg');

      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      // Save URL to Firebase Auth profile
      await user.updatePhotoURL(downloadUrl);
      await user.reload();

      if (!mounted) return;
      setState(() {}); // Rebuild with new photo
      _showSnack('Profile photo updated!');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to upload: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      try {
        await FirebaseStorage.instance
            .ref()
            .child('profile_photos')
            .child('${user.uid}.jpg')
            .delete();
      } catch (_) {}

      await user.updatePhotoURL(null);
      await user.reload();

      if (!mounted) return;
      setState(() {});
      _showSnack('Profile photo removed');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to remove photo: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // StreamBuilder ensures UI refreshes immediately when photoURL changes
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user =
            snapshot.data ?? FirebaseAuth.instance.currentUser;

        if (user == null) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            bottomNavigationBar: const MainBottomNav(currentIndex: 2),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off_outlined,
                      size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                        context, '/auth/login'),
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          bottomNavigationBar: const MainBottomNav(currentIndex: 2),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // ── Gradient Header ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                  decoration: BoxDecoration(
                    gradient: AppTheme.profileGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // ── Tappable Avatar ──
                      GestureDetector(
                        onTap: _isUploadingPhoto
                            ? null
                            : _showPhotoOptions,
                        child: Stack(
                          children: [
                            // Circle avatar
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                    Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: _isUploadingPhoto
                                  ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.accentColor,
                                  strokeWidth: 3,
                                ),
                              )
                                  : ClipOval(
                                child: user.photoURL != null
                                    ? Image.network(
                                  user.photoURL!,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                  loadingBuilder: (_, child,
                                      progress) {
                                    if (progress == null)
                                      return child;
                                    return const Center(
                                      child:
                                      CircularProgressIndicator(
                                        color: AppTheme
                                            .accentColor,
                                        strokeWidth: 2,
                                      ),
                                    );
                                  },
                                  errorBuilder:
                                      (_, __, ___) =>
                                      _initialsWidget(
                                          user),
                                )
                                    : _initialsWidget(user),
                              ),
                            ),

                            // Camera badge — bottom right
                            if (!_isUploadingPhoto)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        user.displayName ?? 'User',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        user.email ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Member since ${_getJoinDate(user)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Text(
                        'Tap photo to change',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Menu ──
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MENU',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textTertiary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuItem(
                        Icons.trending_up,
                        'Progress Dashboard',
                        'Track your improvement',
                        AppTheme.grammarColor,
                            () =>
                            Navigator.pushNamed(context, '/progress'),
                      ),
                      _buildMenuItem(
                        Icons.settings_outlined,
                        'Settings',
                        'App preferences and account',
                        AppTheme.structureColor,
                            () =>
                            Navigator.pushNamed(context, '/settings'),
                      ),
                      _buildMenuItem(
                        Icons.help_outline,
                        'Help & Support',
                        'Get help and FAQs',
                        AppTheme.proficiencyColor,
                            () => _showHelpSupport(context),
                      ),
                      _buildMenuItem(
                        Icons.info_outline,
                        'About',
                        'App version and info',
                        AppTheme.textSecondary,
                            () => _showAboutDialog(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildLogoutButton(),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _initialsWidget(User user) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Text(
        _getInitials(user),
        style: TextStyle(
          color: AppTheme.accentColor,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      IconData icon,
      String title,
      String subtitle,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
          border:
          Border.all(color: color.withOpacity(0.2), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: AppTheme.textTertiary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [
          AppTheme.errorColor,
          AppTheme.errorColor.withOpacity(0.8),
        ]),
        boxShadow:
        AppTheme.getColoredShadow(AppTheme.errorColor),
      ),
      child: ElevatedButton.icon(
        onPressed: _handleLogout,
        icon:
        const Icon(Icons.logout, color: Colors.white),
        label: const Text('Logout',
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding:
          const EdgeInsets.symmetric(vertical: 18),
          minimumSize:
          const Size(double.infinity, 0),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Logout',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to logout?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style:
                TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
          '/auth/login', (_) => false);
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Coming Soon',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold)),
        content: Text('$feature feature is under development.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
                style: TextStyle(color: AppTheme.accentColor)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('About SpeakSharp',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(
              'SpeakSharp helps you improve your public speaking skills with AI-powered analysis and feedback.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Text('© 2026 SpeakSharp',
                style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
                style: TextStyle(color: AppTheme.accentColor)),
          ),
        ],
      ),
    );
  }

  String _getInitials(User user) {
    if (user.displayName != null &&
        user.displayName!.isNotEmpty) {
      final parts = user.displayName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return user.displayName![0].toUpperCase();
    }
    if (user.email != null && user.email!.isNotEmpty) {
      return user.email![0].toUpperCase();
    }
    return 'U';
  }

  String _getJoinDate(User user) {
    if (user.metadata.creationTime != null) {
      final date = user.metadata.creationTime!;
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.year}';
    }
    return 'Recently';
  }

  void _showHelpSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.help_outline,
                        color: AppTheme.proficiencyColor, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Help & Support',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Contact section
                    _buildHelpSection(
                      icon: Icons.email_outlined,
                      color: AppTheme.accentColor,
                      title: 'Contact Us',
                      subtitle: 'yehanheenpella@gmail.com',
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Email: yehanheenpella@gmail.com'),
                            backgroundColor: AppTheme.accentColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // FAQ heading
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'FREQUENTLY ASKED QUESTIONS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textTertiary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),

                    _buildFaqItem(
                      'How does speech analysis work?',
                      'SpeakSharp records your speech, sends it to our AI backend which transcribes it using OpenAI Whisper, then analyzes grammar, voice modulation, structure, fluency, and vocabulary to give you a detailed score.',
                    ),
                    _buildFaqItem(
                      'How long does analysis take?',
                      'Analysis typically takes 1-2 minutes depending on the length of your speech and your internet connection speed.',
                    ),
                    _buildFaqItem(
                      'What audio formats are supported?',
                      'You can upload MP3, WAV, M4A, OGG, and FLAC files up to 50MB. For best results, record in a quiet environment.',
                    ),
                    _buildFaqItem(
                      'Why is my score low?',
                      'Scores are based on grammar accuracy, voice variation, speech structure (intro/body/conclusion), fluency (filler words, pauses), and vocabulary richness. Focus on the lowest scoring category to improve.',
                    ),
                    _buildFaqItem(
                      'Is my speech data private?',
                      'Your recordings are processed securely and stored under your account only. We do not share your data with third parties.',
                    ),
                    _buildFaqItem(
                      'How do I improve my score?',
                      'Practice regularly, reduce filler words (um, uh, like), vary your pitch and tone, structure your speech with a clear intro and conclusion, and expand your vocabulary.',
                    ),
                    _buildFaqItem(
                      'Can I delete my recordings?',
                      'Yes. In the History screen, swipe left on any recording to delete it.',
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSection({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
          border: Border.all(color: color.withOpacity(0.2), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: AppTheme.textTertiary, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
          const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: AppTheme.accentColor,
          collapsedIconColor: AppTheme.textTertiary,
          title: Text(
            question,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Text(
              answer,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}