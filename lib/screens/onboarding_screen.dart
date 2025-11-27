import 'package:flutter/material.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  
  bool _accessibilityEnabled = false;
  bool _overlayEnabled = false;
  bool _isCheckingPermissions = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isCheckingPermissions = true;
    });

    try {
      final accessibility = await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
      final overlay = await FlutterOverlayWindow.isPermissionGranted();

      setState(() {
        _accessibilityEnabled = accessibility;
        _overlayEnabled = overlay;
        _isCheckingPermissions = false;
      });
    } catch (e) {
      debugPrint("Error checking permissions: $e");
      setState(() {
        _isCheckingPermissions = false;
      });
    }
  }

  Future<void> _requestAccessibilityPermission() async {
    try {
      await FlutterAccessibilityService.requestAccessibilityPermission();
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Enable Accessibility Service'),
            content: const Text(
              'Please enable "Feline Focused" in the Accessibility settings.\n\n'
              '1. Find "Feline Focused" in the list\n'
              '2. Toggle it ON\n'
              '3. Confirm any warnings\n'
              '4. Return to this app',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 500));
                  await _checkPermissions();
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint("Error requesting accessibility permission: $e");
    }
  }

  Future<void> _requestOverlayPermission() async {
    try {
      await FlutterOverlayWindow.requestPermission();
      await Future.delayed(const Duration(seconds: 1));
      await _checkPermissions();
    } catch (e) {
      debugPrint("Error requesting overlay permission: $e");
    }
  }

  Future<void> _completeOnboarding() async {
    if (!_accessibilityEnabled || !_overlayEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable all required permissions to continue'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mark onboarding as complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (mounted) {
      // After onboarding, go to the login screen so the normal auth flow
      // determines whether the user should see HomePage or LoginScreen.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? Colors.green
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildAccessibilityPage(),
                  _buildOverlayPage(),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _currentPage == 2 && _accessibilityEnabled && _overlayEnabled
                        ? _completeOnboarding
                        : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _currentPage == 2 ? 'Get Started' : 'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App icon/illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const  // App Logo/Icon
                 Image(
                    image: AssetImage('assets/feline-focused-logo.png'),
                    width: 100,
                    height: 100,
                    
                  ),
          ),
          
          const SizedBox(height: 40),
          
          const Text(
            'Welcome to\nFeline Focused',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          Text(
            'Stay focused by blocking distracting apps and content',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          _buildFeatureItem(
            icon: Icons.block,
            title: 'Block Distractions',
            description: 'Temporarily block apps and reels during focus time',
          ),
          
          const SizedBox(height: 16),
          
          _buildFeatureItem(
            icon: Icons.timer,
            title: 'Track Progress',
            description: 'Monitor your focus sessions and build streaks',
          ),
          
          const SizedBox(height: 16),
          
          _buildFeatureItem(
            icon: Icons.trending_up,
            title: 'Stay Motivated',
            description: 'See your daily stats and improvements',
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilityPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.accessibility_new,
            size: 100,
            color: _accessibilityEnabled ? Colors.green : Colors.grey.shade400,
          ),
          
          const SizedBox(height: 30),
          
          const Text(
            'Accessibility Service',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          Text(
            'This permission allows Feline Focused to:',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          _buildPermissionExplanation(
            icon: Icons.visibility,
            text: 'Detect which apps you open',
          ),
          
          const SizedBox(height: 12),
          
          _buildPermissionExplanation(
            icon: Icons.video_library,
            text: 'Identify reels and shorts content',
          ),
          
          const SizedBox(height: 12),
          
          _buildPermissionExplanation(
            icon: Icons.security,
            text: 'Block distracting apps in real-time',
          ),
          
          const SizedBox(height: 40),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'We never collect or share your data. Everything stays on your device.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          if (_isCheckingPermissions)
            const CircularProgressIndicator()
          else if (!_accessibilityEnabled)
            ElevatedButton.icon(
              onPressed: _requestAccessibilityPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text(
                'Enable Accessibility',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Enabled ✓',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverlayPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.layers,
            size: 100,
            color: _overlayEnabled ? Colors.green : Colors.grey.shade400,
          ),
          
          const SizedBox(height: 30),
          
          const Text(
            'Display Over Other Apps',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          Text(
            'This permission allows Feline Focused to:',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          _buildPermissionExplanation(
            icon: Icons.block,
            text: 'Show blocking screen over restricted apps',
          ),
          
          const SizedBox(height: 12),
          
          _buildPermissionExplanation(
            icon: Icons.celebration,
            text: 'Display completion message when you finish',
          ),
          
          const SizedBox(height: 12),
          
          _buildPermissionExplanation(
            icon: Icons.notifications_active,
            text: 'Keep you focused during sessions',
          ),
          
          const SizedBox(height: 40),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'The overlay only appears during active focus sessions.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          if (_isCheckingPermissions)
            const CircularProgressIndicator()
          else if (!_overlayEnabled)
            ElevatedButton.icon(
              onPressed: _requestOverlayPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text(
                'Enable Overlay',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Enabled ✓',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 20),
          
          if (_accessibilityEnabled && _overlayEnabled)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '🎉 All set! Tap "Get Started" to begin',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.green.shade700, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionExplanation({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.green.shade700, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }
}