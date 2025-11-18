import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'provider/timer_provider.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'service/app_block_service.dart'; 
import 'overlays/completion_overlay.dart';
import 'overlays/overlay_manager.dart';
import 'overlays/app_blocking_overlay.dart';


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

