import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'dart:ui' as ui; 

class AppBlockManager {
  AppBlockManager._();
  static final AppBlockManager instance = AppBlockManager._();

  final List<String> _blockedApps = [];
  StreamSubscription? _subscription;

  String? _lastBlockedPackage; // track last app we blocked

  /// Get current blocked apps (read-only)
  List<String> get blockedApps => List.unmodifiable(_blockedApps);

  /// Update blocked apps dynamically from settings
  void setBlockedApps(List<String> packages) {
    _blockedApps
      ..clear()
      ..addAll(packages);
    debugPrint("🔒 Updated blocked apps: $_blockedApps");
  }

  /// Initialize manager: permissions + accessibility listener
  Future<void> initialize() async {
    // Ensure overlay permission
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
    }
   
    // Listen to accessibility events
   bool _overlayProcessing = false;

_subscription = FlutterAccessibilityService.accessStream.listen((event) async {
  final packageName = event.packageName;
  if (packageName == null) return;

  debugPrint("📱 [Event] Package: $packageName | Type: ${event.eventType}");

  if (_overlayProcessing) return; // skip if an overlay operation is running

  _overlayProcessing = true;

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
    _overlayProcessing = false;
  }
});
  }

  /// Dispose listener and hide overlay
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _hideOverlay();
    _lastBlockedPackage = null;
  }

  /// Show overlay (uses overlayMain entrypoint)
Future<void> _showOverlay() async {
  if (!await FlutterOverlayWindow.isActive()) {
    debugPrint("🪟 [Overlay] Displaying blocking screen");

    await FlutterOverlayWindow.showOverlay(
      enableDrag: false,
      flag: OverlayFlag.defaultFlag,
    
    
      overlayContent: 'Blocked', // simple text OR use overlayChild if available
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
