import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'app_block_service.dart';
import '../overlays/overlay_manager.dart';

class CompletionOverlayService {
  CompletionOverlayService._();
  static final CompletionOverlayService instance = CompletionOverlayService._();

  bool _isShowing = false;
  bool _deferredRequested = false;
  Duration? _pendingAutoCloseDuration;
  Timer? _autoCloseTimer;
  WidgetsBindingObserver? _lifecycleObserver;

  Future<void> _performShow() async {
    try {
      _isShowing = true;

      // Set the overlay type BEFORE showing/updating
      OverlayManager.setOverlayType(OverlayType.completion);

      // Check if overlay is already active
      final isActive = await FlutterOverlayWindow.isActive();

      if (isActive) {
        debugPrint("🔄 Updating existing overlay to completion type");
        // Send data to switch overlay content
        await FlutterOverlayWindow.shareData('completion');
      } else {
        debugPrint("🎉 Showing new completion overlay");

        // Send data to set overlay type
        await FlutterOverlayWindow.shareData('completion');

        // Small delay to ensure data is received
        await Future.delayed(const Duration(milliseconds: 100));

        // Show the overlay with full-screen configuration
        await FlutterOverlayWindow.showOverlay(
          enableDrag: false,
          flag: OverlayFlag.defaultFlag,
          visibility: NotificationVisibility.visibilityPublic,
          alignment: OverlayAlignment.center,
          positionGravity: PositionGravity.none,
        );
      }

      debugPrint("✅ Completion overlay shown/updated");

      // If an auto-close duration was requested while deferred, schedule it
      if (_pendingAutoCloseDuration != null) {
        _autoCloseTimer?.cancel();
        _autoCloseTimer = Timer(_pendingAutoCloseDuration!, () async {
          await hideCompletionOverlay();
        });
        _pendingAutoCloseDuration = null;
      }
    } catch (e) {
      debugPrint("❌ Error performing show: $e");
      _isShowing = false;
    }
  }

  /// Show the completion overlay with proper full-screen configuration
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

      // If the app is currently foregrounded, defer showing the external
      // overlay until the app moves to the background. This prevents the
      // overlay from appearing inside the app UI.
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle == AppLifecycleState.resumed) {
        debugPrint("ℹ️ App is foregrounded - deferring external completion overlay until background");

        // Mark that we want to show when backgrounded and attach an observer
        // if not already attached.
        _deferredRequested = true;
        if (_lifecycleObserver == null) {
          _lifecycleObserver = _LifecycleObserver(onChanged: (state) async {
            if (state != AppLifecycleState.resumed) {
              // App left foreground; attempt to show now.
              try {
                await _performShow();
              } finally {
                // Clear deferred state and remove observer
                _deferredRequested = false;
                if (_lifecycleObserver != null) {
                  WidgetsBinding.instance.removeObserver(_lifecycleObserver!);
                  _lifecycleObserver = null;
                }
              }
            }
          });
          WidgetsBinding.instance.addObserver(_lifecycleObserver!);
        }

        return;
      }

      debugPrint("🎉 Preparing to show completion overlay");
      
      // First, disable blocking to ensure no conflicts
      await AppBlockManager.instance.disableBlocking();

      // Wait a short time for any blocking overlay to close
      await Future.delayed(const Duration(milliseconds: 300));

      // Now perform the actual show sequence
      await _performShow();
    } catch (e) {
      debugPrint("❌ Error showing completion overlay: $e");
      _isShowing = false;
    }
  }

  /// Hide the completion overlay
  Future<void> hideCompletionOverlay() async {
    if (!_isShowing) return;

    try {
      _autoCloseTimer?.cancel();
      _autoCloseTimer = null;

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

    // If the overlay is already showing, schedule auto-close. If the show
    // was deferred because the app was foregrounded, store the pending
    // duration so it can be scheduled once the overlay actually appears.
    if (_isShowing) {
      _autoCloseTimer?.cancel();
      _autoCloseTimer = Timer(duration, () async {
        await hideCompletionOverlay();
      });
    } else if (_deferredRequested) {
      _pendingAutoCloseDuration = duration;
    }
  }
}

class _LifecycleObserver with WidgetsBindingObserver {
  final void Function(AppLifecycleState) onChanged;
  _LifecycleObserver({required this.onChanged});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      onChanged(state);
    } catch (_) {
      // Ignore
    }
  }
}