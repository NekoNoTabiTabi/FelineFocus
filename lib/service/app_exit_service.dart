import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppExitService {
  AppExitService._();
  static final AppExitService instance = AppExitService._();

  static const MethodChannel _channel = MethodChannel('app_exit_channel');

  /// Force close an app by package name
  Future<bool> forceCloseApp(String packageName) async {
    try {
      debugPrint("🚪 Attempting to force close: $packageName");
      
      final result = await _channel.invokeMethod('forceCloseApp', {
        'packageName': packageName,
      });
      
      if (result == true) {
        debugPrint("✅ Successfully closed: $packageName");
        return true;
      } else {
        debugPrint("⚠️ Could not close app: $packageName");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error closing app: $e");
      return false;
    }
  }

  /// Go to home screen (launcher)
  Future<void> goToHomeScreen() async {
    try {
      debugPrint("🏠 Going to home screen");
      await _channel.invokeMethod('goToHomeScreen');
    } catch (e) {
      debugPrint("❌ Error going to home screen: $e");
    }
  }

  /// Combined: Close app and go to home
  Future<void> closeAppAndGoHome(String packageName) async {
    await forceCloseApp(packageName);
    await Future.delayed(const Duration(milliseconds: 200));
    await goToHomeScreen();
  }
}