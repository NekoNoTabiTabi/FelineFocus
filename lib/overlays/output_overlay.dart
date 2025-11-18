import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'completion_overlay.dart';
import 'overlay_manager.dart';
import 'app_blocking_overlay.dart';


/// Output overlay that shows different content based on OverlayManager state
class OutputOverlay extends StatefulWidget {
  const OutputOverlay({super.key});

  @override
  State<OutputOverlay> createState() => _OutputOverlayState();
}

class _OutputOverlayState extends State<OutputOverlay> {
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
