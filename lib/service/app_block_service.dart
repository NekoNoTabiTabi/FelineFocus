import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../overlays/overlay_manager.dart';
import '../models/blocked_app_section.dart';
import '../models/reels_config.dart';

class AppBlockManager {
  AppBlockManager._();
  static final AppBlockManager instance = AppBlockManager._();

  final List<BlockedAppSection> _blockedAppSections = [];
  bool _blockReels = false;
  StreamSubscription? _subscription;
  bool _blockingEnabled = false;
  bool _isListening = false;

  String? _lastBlockedPackage;
  String? _lastBlockedNodeId;
  
  // NEW: Debouncing for reels detection
  Timer? _reelsDebounceTimer;
  bool _isReelsBlocked = false;
  String? _currentReelsPackage;
  
  // NEW: Keep track of which type of blocking is active
  BlockingType? _currentBlockingType;

  // Debug modes
  static const bool _debugMode = true;
  static const bool _debugSubNodes = false; // Set to true when you need detailed info

  // Configuration
  static const Duration _reelsDebounceDelay = Duration(milliseconds: 100000); // Keep overlay active for 1.5s after last reels detection

  List<BlockedAppSection> get blockedAppSections => List.unmodifiable(_blockedAppSections);
  bool get blockReels => _blockReels;
  bool get isBlockingEnabled => _blockingEnabled;
  bool get isListening => _isListening;

  void setBlockedAppSections(List<BlockedAppSection> sections) {
    _blockedAppSections
      ..clear()
      ..addAll(sections);
    debugPrint("🔒 Updated blocked app sections: ${_blockedAppSections.length} entries");
  }

  void setBlockReels(bool value) {
    _blockReels = value;
    debugPrint("🎬 Reels blocking set to: $value");
  }

  Future<void> initialize() async {
    debugPrint("🔧 Initializing AppBlockManager (permissions only)");
    
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
    }
    
    if (!await FlutterAccessibilityService.isAccessibilityPermissionEnabled()) {
      await FlutterAccessibilityService.requestAccessibilityPermission();
    }
    
    debugPrint("✅ AppBlockManager initialized (ready to start)");
  }

  Future<void> enableBlocking() async {
    if (_isListening) {
      debugPrint("⚠️ Already listening to accessibility events");
      return;
    }

    _blockingEnabled = true;
    _isListening = true;
    
    debugPrint("✅ Starting accessibility service monitoring");
    debugPrint("📋 Blocking ${_blockedAppSections.length} apps");
    debugPrint("🎬 Reels blocking: $_blockReels");

    bool overlayProcessing = false;

    _subscription = FlutterAccessibilityService.accessStream.listen((event) async {
      final packageName = event.packageName;
      if (packageName == null) return;

      // Skip our own app
      if (packageName == "com.example.felinefocused") return;

      final nodeId = event.nodeId?.toString() ?? "";
      final eventType = event.eventType?.toString() ?? "";
      final subNodes = event.subNodes;

      if (!_blockingEnabled) return;
      if (overlayProcessing) return;

      overlayProcessing = true;

      try {
        // Check ENTIRE APP blocking first (this takes priority)
        final isEntireAppBlocked = _isEntireAppBlocked(packageName);
        
        if (isEntireAppBlocked) {
          // ENTIRE APP BLOCKING - immediate and persistent
          if (_currentBlockingType != BlockingType.entireApp || _lastBlockedPackage != packageName) {
            debugPrint("🎯 [ENTIRE APP BLOCKED] ${_getAppName(packageName)}");
            _currentBlockingType = BlockingType.entireApp;
            _lastBlockedPackage = packageName;
            _isReelsBlocked = false;
            _currentReelsPackage = null;
            _reelsDebounceTimer?.cancel();
            await _showBlockingOverlay();
          }
        } else if (_blockReels && ReelsConfig.hasReelsContent(packageName)) {
          // REELS BLOCKING - check for reels content with debouncing
          final isReelsDetected = _detectReelsInContent(packageName, nodeId, subNodes);
          
          if (isReelsDetected) {
            // Reels detected - show overlay and reset debounce timer
            _currentReelsPackage = packageName;
            
            if (!_isReelsBlocked || _currentBlockingType != BlockingType.reels) {
              debugPrint("🎬 [REELS BLOCKED] ${ReelsConfig.getFriendlyName(packageName)}");
              _currentBlockingType = BlockingType.reels;
              _isReelsBlocked = true;
              await _showBlockingOverlay();
            }
            
            // Reset debounce timer - keep overlay active
            _reelsDebounceTimer?.cancel();
            _reelsDebounceTimer = Timer(_reelsDebounceDelay, () async {
              // After delay, if still in same app, check if reels still detected
              if (_currentReelsPackage == packageName && _isReelsBlocked) {
                debugPrint("⏱️ [REELS DEBOUNCE] Checking if user left reels section...");
                // Don't hide yet, wait for actual navigation away
              }
            });
            
          } else if (_isReelsBlocked && _currentReelsPackage == packageName) {
            // Was blocked, but no longer detecting reels in this package
            // Start debounce timer to hide overlay
            _reelsDebounceTimer?.cancel();
            _reelsDebounceTimer = Timer(_reelsDebounceDelay, () async {
              debugPrint("✅ [REELS UNBLOCKED] User left reels section");
              _isReelsBlocked = false;
              _currentReelsPackage = null;
              _currentBlockingType = null;
              await _hideOverlay();
            });
          }
        } else {
          // Not blocked at all - hide overlay if it was showing
          if (_currentBlockingType != null) {
            debugPrint("✅ [UNBLOCKED] Switched to safe app: $packageName");
            _currentBlockingType = null;
            _lastBlockedPackage = null;
            _isReelsBlocked = false;
            _currentReelsPackage = null;
            _reelsDebounceTimer?.cancel();
            await _hideOverlay();
          }
        }

      } finally {
        overlayProcessing = false;
      }
    });
    
    debugPrint("🎧 Accessibility listener started");
  }

  /// Check if entire app is blocked (simple and direct)
  bool _isEntireAppBlocked(String packageName) {
    for (final section in _blockedAppSections) {
      if (section.packageName == packageName && section.blockEntireApp) {
        return true;
      }
    }
    return false;
  }

  /// Detect reels in content (nodeId and subNodes)
  bool _detectReelsInContent(String packageName, String nodeId, List<dynamic>? subNodes) {
    final keywords = ReelsConfig.getKeywords(packageName);
    final nodeIdLower = nodeId.toLowerCase();
    
    // Check main nodeId for keywords
    for (final keyword in keywords) {
      if (nodeIdLower.contains(keyword.toLowerCase())) {
        if (_debugMode) {
          debugPrint("🎬 Reels keyword '$keyword' found in NodeId");
        }
        return true;
      }
    }
    
    // Check subNodes for keywords
    if (subNodes != null && subNodes.isNotEmpty) {
      final subNodeKeywords = _findReelsKeywordsInSubNodes(subNodes, packageName);
      if (subNodeKeywords.isNotEmpty) {
        if (_debugMode) {
          debugPrint("🎬 Reels keywords found in SubNodes: ${subNodeKeywords.join(', ')}");
        }
        return true;
      }
    }
    
    return false;
  }

  /// Helper to get app name for logging
  String _getAppName(String packageName) {
    for (final section in _blockedAppSections) {
      if (section.packageName == packageName) {
        return section.appName;
      }
    }
    return packageName;
  }

  /// Find reels keywords in subNodes
  List<String> _findReelsKeywordsInSubNodes(List<dynamic> subNodes, String packageName) {
    final keywords = ReelsConfig.getKeywords(packageName);
    final foundKeywords = <String>[];
    
    for (final subNode in subNodes) {
      try {
        // Combine all text fields from subNode
        final subNodeText = [
          subNode.nodeId?.toString() ?? "",
          subNode.text?.toString() ?? "",
          subNode.contentDescription?.toString() ?? "",
          subNode.viewIdResourceName?.toString() ?? "",
          subNode.className?.toString() ?? "",
        ].join(" ").toLowerCase();
        
        // Check for keyword matches
        for (final keyword in keywords) {
          if (subNodeText.contains(keyword.toLowerCase()) && !foundKeywords.contains(keyword)) {
            foundKeywords.add(keyword);
          }
        }
      } catch (e) {
        // Silently continue if we can't read a subNode
      }
    }
    
    return foundKeywords;
  }

  Future<void> disableBlocking() async {
    _blockingEnabled = false;
    _lastBlockedPackage = null;
    _lastBlockedNodeId = null;
    _isReelsBlocked = false;
    _currentReelsPackage = null;
    _currentBlockingType = null;
    _reelsDebounceTimer?.cancel();
    
    await _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    
    await _hideOverlay();
    
    debugPrint("❌ Accessibility service stopped - App blocking DISABLED");
  }

  Future<void> dispose() async {
    await disableBlocking();
    debugPrint("🗑️ AppBlockManager disposed");
  }

  Future<void> _showBlockingOverlay() async {
    if (!await FlutterOverlayWindow.isActive()) {
      debugPrint("🪟 [Overlay] Displaying blocking screen");
      
      OverlayManager.setOverlayType(OverlayType.blocking);
      await FlutterOverlayWindow.shareData('blocking');
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

  Future<void> _hideOverlay() async {
    if (await FlutterOverlayWindow.isActive()) {
      debugPrint("🪟 [Overlay] Hiding overlay screen");
      await FlutterOverlayWindow.closeOverlay();
    }
  }
}

/// Enum to track what type of blocking is active
enum BlockingType {
  entireApp,  // Blocking entire app - persistent
  reels,      // Blocking reels content - debounced
}