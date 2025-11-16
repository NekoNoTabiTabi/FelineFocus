import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'provider/timer_provider.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'service/app_block_service.dart'; 
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'overlays/completion_overlay.dart';

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

/// Entry point for blocking overlay (when blocked apps are opened)
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check what type of overlay to show based on data passed
  FlutterOverlayWindow.overlayListener.listen((event) {
    debugPrint("📨 Overlay message received: $event");
  });
  
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlockingOverlayScreen(),
    ),
  );
}

/// Entry point for completion overlay (when timer finishes)
@pragma("vm:entry-point")
void completionOverlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GestureDetector(
        onTap: () async {
          // Close overlay when tapped
          await FlutterOverlayWindow.closeOverlay();
        },
        child: const CompletionOverlayContent(),
      ),
    ),
  );
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