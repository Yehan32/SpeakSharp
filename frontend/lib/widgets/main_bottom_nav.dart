import 'package:flutter/material.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';

/// Shared bottom navigation bar used by Home, History, and Profile screens.
/// Pass the index of the current screen: 0=Home, 1=History, 2=Profile
class MainBottomNav extends StatelessWidget {
  final int currentIndex;

  const MainBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home,
                label: 'Home',
                index: 0,
                route: '/home',
              ),
              _buildNavItem(
                context,
                icon: Icons.history,
                label: 'History',
                index: 1,
                route: '/history',
              ),
              _buildNavItem(
                context,
                icon: Icons.person,
                label: 'Profile',
                index: 2,
                route: '/profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required int index,
        required String route,
      }) {
    final isActive = currentIndex == index;

    return InkWell(
      onTap: () {
        if (!isActive) {
          // Use pushReplacementNamed so back button doesn't stack screens
          Navigator.pushReplacementNamed(context, route);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.accentColor : AppTheme.textTertiary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.accentColor : AppTheme.textTertiary,
                fontSize: 12,
                fontWeight:
                isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}