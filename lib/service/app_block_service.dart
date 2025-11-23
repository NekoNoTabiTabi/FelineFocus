import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../overlays/overlay_manager.dart';
import '../models/blocked_app_section.dart';
import '../models/reels_config.dart';
import 'app_exit_service.dart'; // ADD THIS

class AppBlockManager {
  AppBlockManager._();
  static final AppBlockManager instance = AppBlockManager._();

  final List<BlockedAppSection> _blockedAppSections = [];
  bool _blockReels = false;
  bool _autoExitEnabled = true; // NEW: Control auto-exit feature
  StreamSubscription? _subscription;
  bool _blockingEnabled = false;
  bool _isListening = false;

  String? _lastBlockedPackage;
  String? _lastBlockedNodeId;
  
  Timer? _reelsDebounceTimer;
  bool _isReelsBlocked = false;
  String? _currentReelsPackage;
  
  BlockingType? _currentBlockingType;

  // NEW: Auto-exit timer
  Timer? _autoExitTimer;
  static const Duration _autoExitDelay = Duration(milliseconds: 500);

  static const bool _debugMode = true;
  static const bool _debugSubNodes = true;

  static const Duration _reelsDebounceDelay = Duration(milliseconds: 1500);

  List<BlockedAppSection> get blockedAppSections => List.unmodifiable(_blockedAppSections);
  bool get blockReels => _blockReels;
  bool get autoExitEnabled => _autoExitEnabled; // NEW
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

  // NEW: Enable/disable auto-exit
  void setAutoExit(bool value) {
    _autoExitEnabled = value;
    debugPrint("🚪 Auto-exit set to: $value");
  }

  Future<void> initialize() async {
    debugPrint("🔧 Initializing AppBlockManager (permissions only)");
    // NOTE: Do not request permissions automatically here. Requesting should
    // be driven by the onboarding flow or explicit user action so the app
    // doesn't prompt for permissions before the UI is ready.
    final overlayGranted = await FlutterOverlayWindow.isPermissionGranted();
    final accessibilityGranted = await FlutterAccessibilityService.isAccessibilityPermissionEnabled();

    debugPrint("🔧 Initial permission state - overlay: $overlayGranted, accessibility: $accessibilityGranted");
    debugPrint("✅ AppBlockManager initialized (ready to start)");
  }

  /// Request required runtime permissions. This is intended to be called from
  /// onboarding or when the user explicitly enables features.
  Future<void> requestPermissions() async {
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
    }

    if (!await FlutterAccessibilityService.isAccessibilityPermissionEnabled()) {
      await FlutterAccessibilityService.requestAccessibilityPermission();
    }
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
    debugPrint("🚪 Auto-exit: $_autoExitEnabled");

    bool overlayProcessing = false;

    _subscription = FlutterAccessibilityService.accessStream.listen((event) async {
      final packageName = event.packageName;
      if (packageName == null) return;

      if (packageName == "com.example.felinefocused") return;

      final nodeId = event.nodeId?.toString() ?? "";
      final subNodes = event.subNodes;

      if (!_blockingEnabled) return;
      if (overlayProcessing) return;

      overlayProcessing = true;

      try {
        // Check ENTIRE APP blocking first
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
            
            // NEW: Schedule auto-exit for entire app blocking
            if (_autoExitEnabled) {
              _scheduleAutoExit(packageName);
            }
          }
        } else if (_blockReels && ReelsConfig.hasReelsContent(packageName)) {
          // REELS BLOCKING - check for reels content with debouncing
          final isReelsDetected = _detectReelsInContent(packageName, nodeId, subNodes);
          
          if (isReelsDetected) {
            _currentReelsPackage = packageName;
            
            if (!_isReelsBlocked || _currentBlockingType != BlockingType.reels) {
              debugPrint("🎬 [REELS BLOCKED] ${ReelsConfig.getFriendlyName(packageName)}");
              _currentBlockingType = BlockingType.reels;
              _isReelsBlocked = true;
              await _showBlockingOverlay();
              
              // NEW: Schedule auto-exit for reels (but with shorter delay)
              if (_autoExitEnabled) {
                _scheduleAutoExit(packageName, isReelsOnly: true);
              }
            }
            
            _reelsDebounceTimer?.cancel();
            _reelsDebounceTimer = Timer(_reelsDebounceDelay, () async {
              if (_currentReelsPackage == packageName && _isReelsBlocked) {
                debugPrint("⏱️ [REELS DEBOUNCE] Checking if user left reels section...");
              }
            });
            
          } else if (_isReelsBlocked && _currentReelsPackage == packageName) {
            _reelsDebounceTimer?.cancel();
            _reelsDebounceTimer = Timer(_reelsDebounceDelay, () async {
              debugPrint("✅ [REELS UNBLOCKED] User left reels section");
              _isReelsBlocked = false;
              _currentReelsPackage = null;
              _currentBlockingType = null;
              _autoExitTimer?.cancel(); // Cancel auto-exit if user navigated away
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
            _autoExitTimer?.cancel();
            await _hideOverlay();
          }
        }

      } finally {
        overlayProcessing = false;
      }
    });
    
    debugPrint("🎧 Accessibility listener started");
  }

  /// NEW: Schedule automatic app exit
  void _scheduleAutoExit(String packageName, {bool isReelsOnly = false}) {
    _autoExitTimer?.cancel();
    
    // For entire app blocks, exit faster
    final delay = isReelsOnly 
        ? const Duration(seconds: 2) 
        : _autoExitDelay;
    
    _autoExitTimer = Timer(delay, () async {
      debugPrint("🚪 [AUTO-EXIT] Closing $packageName");
      await AppExitService.instance.closeAppAndGoHome(packageName);
      
      // Hide overlay after closing app
      await Future.delayed(const Duration(milliseconds: 300));
      await _hideOverlay();
    });
  }

  bool _isEntireAppBlocked(String packageName) {
    for (final section in _blockedAppSections) {
      if (section.packageName == packageName && section.blockEntireApp) {
        return true;
      }
    }
    return false;
  }

  bool _detectReelsInContent(String packageName, String nodeId, List<dynamic>? subNodes) {
    final keywords = ReelsConfig.getKeywords(packageName);
    final nodeIdLower = nodeId.toLowerCase();
    
    for (final keyword in keywords) {
      if (nodeIdLower.contains(keyword.toLowerCase())) {
        if (_debugMode) {
          debugPrint("🎬 Reels keyword '$keyword' found in NodeId");
        }
        return true;
      }
    }
    
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

  String _getAppName(String packageName) {
    for (final section in _blockedAppSections) {
      if (section.packageName == packageName) {
        return section.appName;
      }
    }
    return packageName;
  }

  List<String> _findReelsKeywordsInSubNodes(List<dynamic> subNodes, String packageName) {
    final keywords = ReelsConfig.getKeywords(packageName);
    final foundKeywords = <String>[];
    
    for (final subNode in subNodes) {
      try {
        final subNodeText = [
          subNode.nodeId?.toString() ?? "",
          subNode.text?.toString() ?? "",
          subNode.contentDescription?.toString() ?? "",
          subNode.viewIdResourceName?.toString() ?? "",
          subNode.className?.toString() ?? "",
        ].join(" ").toLowerCase();
        
        for (final keyword in keywords) {
          if (subNodeText.contains(keyword.toLowerCase()) && !foundKeywords.contains(keyword)) {
            foundKeywords.add(keyword);
          }
        }
      } catch (e) {
        // Silently continue
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
    _autoExitTimer?.cancel(); // NEW: Cancel auto-exit timer
    
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

enum BlockingType {
  entireApp,
  reels,
}