import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/timer_provider.dart';
import 'focus.dart';  

class TimerCompleteScreen extends StatefulWidget {
  const TimerCompleteScreen({super.key});

  @override
  State<TimerCompleteScreen> createState() => _TimerCompleteScreenState();
}

class _TimerCompleteScreenState extends State<TimerCompleteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green.shade400,
                Colors.green.shade700,
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Animated background particles
                ...List.generate(20, (index) => _buildFloatingParticle(index)),
                
                // Main content
                Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Success icon with glow effect
                              Container(
                                padding: const EdgeInsets.all(30),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.5),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 80,
                                ),
                              ),
                              
                              const SizedBox(height: 30),
                              
                              // Title with emoji
                              const Text(
                                '🎉 Focus Complete! 🎉',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10.0,
                                      color: Colors.black26,
                                      offset: Offset(2.0, 2.0),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Subtitle
                              const Text(
                                'You completed your\nfocus session!',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Message box
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: const Text(
                                  '⭐ Great job staying focused!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              
                              const SizedBox(height: 50),
                              
                              // Buttons
                              Column(
                                children: [
                                  // Start Another Session button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 60,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final timeProvider = Provider.of<TimeProvider>(
                                          context,
                                          listen: false,
                                        );
                                        
                                        // Navigate back to home first
                                        Navigator.of(context).popUntil((route) => route.isFirst);
                                        
                                        // Then restart timer
                                        await timeProvider.restartTimer();
                                        
                                        // Navigate to focus screen
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const FocusScreen(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        elevation: 5,
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.refresh, size: 28),
                                          SizedBox(width: 10),
                                          Text(
                                            'Start Another Session',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Done button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 60,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        // Navigate back to home
                                        Navigator.of(context).popUntil((route) => route.isFirst);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.home, size: 28),
                                          SizedBox(width: 10),
                                          Text(
                                            'Back to Home',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = index * 0.1;
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(seconds: 3 + index % 3),
      builder: (context, double value, child) {
        return Positioned(
          left: (index % 5) * 80.0,
          top: value * MediaQuery.of(context).size.height,
          child: Opacity(
            opacity: 0.3,
            child: Icon(
              _getRandomIcon(index),
              color: Colors.white,
              size: 20 + (index % 3) * 10,
            ),
          ),
        );
      },
      onEnd: () {
        // Restart animation
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  IconData _getRandomIcon(int index) {
    final icons = [
      Icons.star,
      Icons.favorite,
      Icons.emoji_events,
      Icons.celebration,
      Icons.whatshot,
    ];
    return icons[index % icons.length];
  }
}