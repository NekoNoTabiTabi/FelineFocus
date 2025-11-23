import 'package:flutter/material.dart';
import 'package:felinefocused/Screens/app_block_settings.dart';
import 'package:felinefocused/Screens/focus.dart';
import 'package:felinefocused/Screens/settings_page.dart';
import 'package:felinefocused/screens/history_screen.dart'; // ADD THIS
import 'package:felinefocused/utils/timer.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:felinefocused/screens/stats_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _accessibilityEnabled = false;
  int _currentIndex = 0; // ADD THIS

  // ADD THIS - Define pages
 final List<Widget> _pages = [
    const _HomeContent(),
    const StatsScreen(),
    const HistoryScreen(),
  ];

  final List<String> _pageTitles = [
    'Feline Focused',
    'Stats',
    'History',
  ];

  @override
  void initState() {
    super.initState();
    _checkAccessibilityStatus();
  }

  Future<void> _checkAccessibilityStatus() async {
    final enabled = await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
    setState(() {
      _accessibilityEnabled = enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
         _pageTitles[_currentIndex], // ADD THIS
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
              _checkAccessibilityStatus();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Accessibility Warning Banner
          if (!_accessibilityEnabled && _currentIndex == 0) // Only show on home
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.orange.shade300,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Colors.orange.shade800,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Accessibility Service Required',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enable it in Settings to block apps',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                      _checkAccessibilityStatus();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Fix'),
                  ),
                ],
              ),
            ),

          // Page Content
          Expanded(
            child: _pages[_currentIndex],
          ),
        ],
      ),
      
      // ADD THIS - Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

// EXTRACT HOME CONTENT TO SEPARATE WIDGET
class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Set Timer
          const TimerDisplay(),

          const SizedBox(height: 50),

          // Start Focus Button
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FocusScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 16,
              ),
            ),
            child: const Text(
              "Start Focus",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),

          const SizedBox(height: 20),

          // App Block Button
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BlockAppsScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 16,
              ),
            ),
            child: const Text(
              'App Block',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}