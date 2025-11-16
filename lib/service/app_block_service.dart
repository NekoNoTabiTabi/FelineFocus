import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class AppBlockManager {
  AppBlockManager._();
  static final AppBlockManager instance = AppBlockManager._();

  final List<String> _blockedApps = [];
  StreamSubscription? _subscription;
  bool _blockingEnabled = false;
  bool _isListening = false; // Track if we're actively listening

  String? _lastBlockedPackage;

  /// Get current blocked apps (read-only)
  List<String> get blockedApps => List.unmodifiable(_blockedApps);
  
  /// Check if blocking is currently active
  bool get isBlockingEnabled => _blockingEnabled;
  
  /// Check if accessibility listener is active
  bool get isListening => _isListening;

  /// Update blocked apps dynamically from settings
  void setBlockedApps(List<String> packages) {
    _blockedApps
      ..clear()
      ..addAll(packages);
    debugPrint("🔒 Updated blocked apps: $_blockedApps");
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

      debugPrint("📱 [Event] Package: $packageName | Type: ${event.eventType}");

      // Only block if blocking is enabled
      if (!_blockingEnabled) {
        return;
      }

      if (overlayProcessing) return;

      overlayProcessing = true;

      try {
        if (_blockedApps.contains(packageName) && _lastBlockedPackage != packageName) {
          debugPrint("🚫 [Block Triggered] App: $packageName");
          _lastBlockedPackage = packageName;
          await _showOverlay();
        } else if (_lastBlockedPackage != null && packageName != "com.example.felinefocused") {
          debugPrint("✅ [Unblocked] App switched from $_lastBlockedPackage to $packageName");
          _lastBlockedPackage = null;
          await _hideOverlay();
        }
      } finally {
        overlayProcessing = false;
      }
    });
    
    debugPrint("🎧 Accessibility listener started - monitoring ${_blockedApps.length} apps");
  }

  /// Stop accessibility monitoring (called when timer stops/resets)
  Future<void> disableBlocking() async {
    _blockingEnabled = false;
    _lastBlockedPackage = null;
    
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

  /// Show overlay
  Future<void> _showOverlay() async {
    if (!await FlutterOverlayWindow.isActive()) {
      debugPrint("🪟 [Overlay] Displaying blocking screen");

      await FlutterOverlayWindow.showOverlay(
        enableDrag: false,
        flag: OverlayFlag.defaultFlag,
        overlayContent: 'Blocked',
        visibility: NotificationVisibility.visibilityPublic,
      );
    }
  }

  /// Hide overlay if active
  Future<void> _hideOverlay() async {
    if (await FlutterOverlayWindow.isActive()) {
      debugPrint("🪟 [Overlay] Hiding blocking screen");
      await FlutterOverlayWindow.closeOverlay();
    }
  }
}