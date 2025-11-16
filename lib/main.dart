import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'provider/timer_provider.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'service/app_block_service.dart'; 
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'overlays/completion_overlay.dart';
import 'overlays/overlay_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Only initialize permissions, don't start monitoring yet
  await AppBlockManager.instance.initialize();

  // Create and initialize TimeProvider
  final timeProvider = TimeProvider();
  await timeProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: timeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

/// Single entry point for ALL overlays - switches content based on type
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI for overlay
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DynamicOverlayScreen(),
    ),
  );
}

/// Dynamic overlay that shows different content based on OverlayManager state
class DynamicOverlayScreen extends StatefulWidget {
  const DynamicOverlayScreen({super.key});

  @override
  State<DynamicOverlayScreen> createState() => _DynamicOverlayScreenState();
}

class _DynamicOverlayScreenState extends State<DynamicOverlayScreen> {
  OverlayType _currentType = OverlayType.blocking;

  @override
  void initState() {
    super.initState();
    
    debugPrint("🎨 Overlay initialized with type: ${OverlayManager.currentType}");
    _currentType = OverlayManager.currentType;
    
    // Listen for overlay data messages from main app
    FlutterOverlayWindow.overlayListener.listen((data) {
      debugPrint("📨 Overlay received data: $data");
      
      if (data == 'completion') {
        setState(() {
          _currentType = OverlayType.completion;
          OverlayManager.setOverlayType(OverlayType.completion);
        });
      } else if (data == 'blocking') {
        setState(() {
          _currentType = OverlayType.blocking;
          OverlayManager.setOverlayType(OverlayType.blocking);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("🎨 Building overlay with type: $_currentType");
    
    // Show different content based on current overlay type
    switch (_currentType) {
      case OverlayType.completion:
        return const CompletionOverlayContent();
      
      case OverlayType.blocking:
        return const BlockingOverlayScreen();
    }
  }
}

// Blocking overlay screen
class BlockingOverlayScreen extends StatelessWidget {
  const BlockingOverlayScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.95),
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Block icon
                          Container(
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.block,
                              color: Colors.red,
                              size: 80,
                            ),
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Title
                          const Text(
                            "Access Blocked!",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Message
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: const Text(
                              "This app is restricted\nduring focus time.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                          const SizedBox(height: 25),
                          
                          // Instruction
                          const Text(
                            "🔒 Stay focused on your goals",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}