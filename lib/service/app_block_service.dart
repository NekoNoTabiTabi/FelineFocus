import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../overlays/overlay_manager.dart';
import '../models/blocked_app_section.dart';

class AppBlockManager {
  AppBlockManager._();
  static final AppBlockManager instance = AppBlockManager._();

  final List<BlockedAppSection> _blockedAppSections = [];
  StreamSubscription? _subscription;
  bool _blockingEnabled = false;
  bool _isListening = false;

  String? _lastBlockedPackage;
  String? _lastWindowContent;

  /// Get current blocked apps (read-only)
  List<BlockedAppSection> get blockedAppSections => List.unmodifiable(_blockedAppSections);
  
  /// Check if blocking is currently active
  bool get isBlockingEnabled => _blockingEnabled;
  
  /// Check if accessibility listener is active
  bool get isListening => _isListening;

  /// Update blocked app sections dynamically from settings
  void setBlockedAppSections(List<BlockedAppSection> sections) {
    _blockedAppSections
      ..clear()
      ..addAll(sections);
    debugPrint("🔒 Updated blocked app sections: ${_blockedAppSections.length} entries");
  }

  /// Initialize permissions only (don't start listening yet)
  Future<void> initialize() async {
    debugPrint("🔧 Initializing AppBlockManager (permissions only)");
    
    // Ensure overlay permission
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
    }
    
    // Check accessibility permission (but don't start listening)
    if (!await FlutterAccessibilityService.isAccessibilityPermissionEnabled()) {
      await FlutterAccessibilityService.requestAccessibilityPermission();
    }
    
    debugPrint("✅ AppBlockManager initialized (ready to start)");
  }

  /// Start accessibility monitoring (called when timer starts)
  Future<void> enableBlocking() async {
    if (_isListening) {
      debugPrint("⚠️ Already listening to accessibility events");
      return;
    }

    _blockingEnabled = true;
    _isListening = true;
    
    debugPrint("✅ Starting accessibility service monitoring");

    bool overlayProcessing = false;

    _subscription = FlutterAccessibilityService.accessStream.listen((event) async {
      final packageName = event.packageName;
      if (packageName == null) return;

      // Get available event data - check what's actually available
      final eventType = event.eventType.toString() ?? "";
      final capturedText = event.nodeId.toString() ?? "";
      
      // Try to get window/screen information from the event
      String windowContent = "";
      try {
        // Some events might have text content
        windowContent = capturedText;
      } catch (e) {
        debugPrint("⚠️ Error accessing event content: $e");
      }
      
      debugPrint("📱 [Event] Package: $packageName | Type: $eventType | Text: $capturedText}");

      // Only block if blocking is enabled
      if (!_blockingEnabled) {
        return;
      }

      if (overlayProcessing) return;

      overlayProcessing = true;

      try {
        // Check if this app/section should be blocked
        final shouldBlock = _shouldBlockPackage(packageName, windowContent, eventType);
        
        if (shouldBlock && (_lastBlockedPackage != packageName || _lastWindowContent != windowContent)) {
          debugPrint("🚫 [Block Triggered] Package: $packageName, Content: $windowContent");
          _lastBlockedPackage = packageName;
          _lastWindowContent = windowContent;
          await _showBlockingOverlay();
        } else if (_lastBlockedPackage != null && packageName != "com.example.felinefocused") {
          // User switched to a different, non-blocked context
          final stillBlocked = _shouldBlockPackage(packageName, windowContent, eventType);
          if (!stillBlocked) {
            debugPrint("✅ [Unblocked] Switched from $_lastBlockedPackage to $packageName");
            _lastBlockedPackage = null;
            _lastWindowContent = null;
            await _hideOverlay();
          }
        }
      } finally {
        overlayProcessing = false;
      }
    });
    
    debugPrint("🎧 Accessibility listener started - monitoring ${_blockedAppSections.length} app sections");
  }

  /// Check if a package should be blocked based on available event data
  bool _shouldBlockPackage(String packageName, String windowContent, String eventType) {
    for (final section in _blockedAppSections) {
      // Check if package matches
      if (section.packageName != packageName) continue;
      
      // If blocking entire app, block it
      if (section.blockEntireApp) {
        debugPrint("🎯 Blocking entire app: ${section.appName}");
        return true;
      }
      
      // If no keywords specified but app is in list, block it
      if (section.blockedKeywords.isEmpty) {
        debugPrint("🎯 Blocking app (no specific keywords): ${section.appName}");
        return true;
      }
      
      // Check if any blocked keywords match the available content
      final combinedText = '${windowContent.toLowerCase()} ${eventType.toLowerCase()} $packageName'.toLowerCase();
      
      for (final keyword in section.blockedKeywords) {
        if (combinedText.contains(keyword.toLowerCase())) {
          debugPrint("🎯 Keyword match: '$keyword' found in event data");
          return true;
        }
      }
    }
    
    return false;
  }

  /// Stop accessibility monitoring (called when timer stops/resets)
  Future<void> disableBlocking() async {
    _blockingEnabled = false;
    _lastBlockedPackage = null;
    _lastWindowContent = null;
    
    // Stop listening to accessibility events
    await _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    
    await _hideOverlay();
    
    debugPrint("❌ Accessibility service stopped - App blocking DISABLED");
  }

  /// Dispose listener and hide overlay
  Future<void> dispose() async {
    await disableBlocking();
    debugPrint("🗑️ AppBlockManager disposed");
  }

  /// Show blocking overlay with proper full-screen configuration
  Future<void> _showBlockingOverlay() async {
    if (!await FlutterOverlayWindow.isActive()) {
      debugPrint("🪟 [Overlay] Displaying blocking screen");
      
      // Set overlay type to blocking
      OverlayManager.setOverlayType(OverlayType.blocking);
      
      // Send message to overlay
      await FlutterOverlayWindow.shareData('blocking');
      
      // Small delay
      await Future.delayed(const Duration(milliseconds: 100));

      await FlutterOverlayWindow.showOverlay(
        enableDrag: false,
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
       
        alignment: OverlayAlignment.center,
        positionGravity: PositionGravity.none,
      );
    }
  }

  /// Hide overlay if active
  Future<void> _hideOverlay() async {
    if (await FlutterOverlayWindow.isActive()) {
      debugPrint("🪟 [Overlay] Hiding overlay screen");
      await FlutterOverlayWindow.closeOverlay();
    }
  }
}