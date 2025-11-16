import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'app_block_service.dart';

class CompletionOverlayService {
  CompletionOverlayService._();
  static final CompletionOverlayService instance = CompletionOverlayService._();

  bool _isShowing = false;

  /// Show the completion overlay
  Future<void> showCompletionOverlay() async {
    if (_isShowing) {
      debugPrint("⚠️ Completion overlay already showing");
      return;
    }

    try {
      // Ensure overlay permission
      if (!await FlutterOverlayWindow.isPermissionGranted()) {
        debugPrint("❌ Overlay permission not granted");
        return;
      }

      debugPrint("🎉 Preparing to show completion overlay");
      
      // First, disable blocking to ensure no conflicts
      await AppBlockManager.instance.disableBlocking();
      
      // Wait a moment
      await Future.delayed(const Duration(milliseconds: 200));
      
      _isShowing = true;

      // If overlay is already active, just change the content
      if (await FlutterOverlayWindow.isActive()) {
        debugPrint("🔄 Updating existing overlay to completion type");
        await FlutterOverlayWindow.shareData('completion');
      } else {
        debugPrint("🎉 Showing new completion overlay");
        // Send message to set overlay type to completion
        await FlutterOverlayWindow.shareData('completion');
        
        await FlutterOverlayWindow.showOverlay(
          enableDrag: false,
          flag: OverlayFlag.defaultFlag,
          visibility: NotificationVisibility.visibilityPublic,
        );
      }

      debugPrint("✅ Completion overlay shown");
    } catch (e) {
      debugPrint("❌ Error showing completion overlay: $e");
      _isShowing = false;
    }
  }

  /// Hide the completion overlay
  Future<void> hideCompletionOverlay() async {
    if (!_isShowing) return;

    try {
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
        debugPrint("🔒 Completion overlay closed");
      }
    } catch (e) {
      debugPrint("❌ Error closing completion overlay: $e");
    } finally {
      _isShowing = false;
    }
  }

  /// Auto-close overlay after a delay
  Future<void> showCompletionOverlayWithAutoClose({
    Duration duration = const Duration(seconds: 10),
  }) async {
    await showCompletionOverlay();
    
    // Auto-close after duration
    await Future.delayed(duration);
    await hideCompletionOverlay();
  }
}