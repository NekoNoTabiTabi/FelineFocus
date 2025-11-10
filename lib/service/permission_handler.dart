import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';


class Permissions {
  Permissions._();
  static final instance = Permissions._();



  /// Check if accessibility service is enabled
  Future<bool> hasAccessibilityPermission() async {
    return await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
  }

  /// Request accessibility service if not enabled
  Future<void> requestAccessibilityPermission() async {
    if (!await hasAccessibilityPermission()) {
      await FlutterAccessibilityService.requestAccessibilityPermission();
    }
  }

  /// Check if overlay permission is granted
  Future<bool> hasOverlayPermission() async {
    return await FlutterOverlayWindow.isPermissionGranted();
  }

  /// Request overlay permission
  Future<void> requestOverlayPermission() async {
    if (!await hasOverlayPermission()) {
      await FlutterOverlayWindow.requestPermission();
    }
  }

  /// Convenience method: request all permissions needed
  Future<void> requestAllPermissions() async {
   
    await requestAccessibilityPermission();
    await requestOverlayPermission();
  }

  /// Convenience check: all permissions granted
  Future<bool> allPermissionsGranted() async {
    return 
        (await hasAccessibilityPermission()) &&
        (await hasOverlayPermission());
  }
}