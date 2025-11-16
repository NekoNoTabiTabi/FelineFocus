import 'package:flutter/material.dart';
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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

/// Single entry point for ALL overlays - switches content based on type
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  
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
  @override
  void initState() {
    super.initState();
    
    // Listen for overlay data messages from main app
    FlutterOverlayWindow.overlayListener.listen((data) {
      debugPrint("📨 Overlay received data: $data");
      
      if (data == 'completion') {
        setState(() {
          OverlayManager.setOverlayType(OverlayType.completion);
        });
      } else if (data == 'blocking') {
        setState(() {
          OverlayManager.setOverlayType(OverlayType.blocking);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show different content based on current overlay type
    switch (OverlayManager.currentType) {
      case OverlayType.completion:
        return GestureDetector(
          onTap: () async {
            await FlutterOverlayWindow.closeOverlay();
          },
          child: const CompletionOverlayContent(),
        );
      
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
      color: Colors.black.withOpacity(0.9),
      child: SizedBox.expand(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, color: Colors.red, size: 80),
              const SizedBox(height: 20),
              const Text(
                "Access Blocked!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "This app is restricted during focus time.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}