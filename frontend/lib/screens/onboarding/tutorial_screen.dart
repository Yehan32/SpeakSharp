import 'package:flutter/material.dart';
import 'package:Speak_Sharp/utils/app_theme.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({Key? key}) : super(key: key);

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  // ✅ PageController - Controls which page is shown
  final PageController _pageController = PageController();

  // ✅ Tracks current page (0, 1, or 2)
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ✅ Called when user swipes to a new page
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      print('🔄 Swiped to page: $page'); // Debug: See page changes
    });
  }

  // ✅ Called when "Get Started" or "Next" button is tapped
  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // ✅ All buttons go to login
  void _goToLogin() {
    Navigator.of(context).pushReplacementNamed('/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ✅ SWIPEABLE SECTION (Blue/Green part)
          // This entire section is swipeable left/right!
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              // ✅ All 3 screens in PageView
              children: [
                _buildWelcomePage(),      // Page 0: Blue "Welcome to Speak Sharp"
                _buildFeaturesPage(),     // Page 1: Blue "Track Your Progress"
                _buildReadyPage(),        // Page 2: Green "You're All Set!"
              ],
            ),
          ),

          // ✅ WHITE BOTTOM SECTION (Not swipeable)
          // Contains dots and buttons
          _buildActionSection(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // PAGE 1: WELCOME TO SPEAK SHARP (Blue)
  // ═══════════════════════════════════════════════════════
  Widget _buildWelcomePage() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,  // Blue gradient
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        'SS',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontSize: 32,
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'Welcome to\nSpeak Sharp',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 36,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Description
                  Text(
                    'Your personal AI-powered speech coach that helps you become a confident speaker',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Curved bottom (white curve)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.elliptical(200, 60),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // PAGE 2: TRACK YOUR PROGRESS (Blue)
  // ═══════════════════════════════════════════════════════
  Widget _buildFeaturesPage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,  // Blue gradient
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Chart emoji
              const Text(
                '📊',
                style: TextStyle(fontSize: 120),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Track Your Progress',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 15),

              // Description
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Get detailed insights on your speaking patterns and improvement over time',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // PAGE 3: YOU'RE ALL SET! (Green)
  // ═══════════════════════════════════════════════════════
  Widget _buildReadyPage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.successGradient,  // Green gradient
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rocket emoji
              const Text(
                '🚀',
                style: TextStyle(fontSize: 120),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                "You're All Set!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 15),

              // Description
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "Ready to start your speaking improvement journey? Let's record your first speech!",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // WHITE BOTTOM SECTION (Dots + Buttons)
  // ═══════════════════════════════════════════════════════
  Widget _buildActionSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          // Tutorial hint (only on page 1)
          if (_currentPage == 0)
            Column(
              children: [
                const Text(
                  'Swipe to continue',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),

          // ═══════════════════════════════════════════════════
          // ✅ ANIMATED DOTS (Updates as you swipe!)
          // ═══════════════════════════════════════════════════
          SmoothPageIndicator(
            controller: _pageController,  // Connected to PageView
            count: 3,  // 3 pages total
            effect: WormEffect(
              dotHeight: 8,
              dotWidth: 8,
              activeDotColor: AppTheme.accentColor,  // Blue when active
              dotColor: Colors.grey[300]!,           // Grey when inactive
              spacing: 8,
            ),
            // ✅ This makes dots animate smoothly as you swipe!
          ),

          const SizedBox(height: 25),

          // ═══════════════════════════════════════════════════
          // BUTTONS (Change based on current page)
          // ═══════════════════════════════════════════════════
          if (_currentPage < 2) ...[
            // PAGES 1 & 2: Show "Get Started" or "Next" button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _currentPage == 0 ? 'Get Started' : 'Next',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Skip button
            TextButton(
              onPressed: _goToLogin,
              child: const Text(
                'Skip Tutorial',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ] else ...[
            // PAGE 3: Show "Start Recording" and "Explore Features"
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _goToLogin,  // ✅ Goes to login
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Start Recording',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _goToLogin,  // ✅ Goes to login
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Explore Features',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}