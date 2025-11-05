import 'package:flutter/material.dart';
import 'package:block_app/block_app.dart';
import 'dart:developer';



class AppBlockService {
  AppBlockService._privateConstructor();
  static final AppBlockService instance = AppBlockService._privateConstructor();

  final BlockApp _blockApp = BlockApp();

  /// Initialize the service and check permissions
  Future<void> initialize() async {
    await _blockApp.initialize(
      config: const AppBlockConfig(
        defaultMessage: 'This app is blocked',
        overlayBackgroundColor: Colors.black87,
        overlayTextColor: Colors.white,
        actionButtonText: 'Close',
        autoStartService: true,
      ),
    );
  }

  /// Request necessary permissions from the user
  Future<void> requestPermissions() async {
    await _blockApp.requestOverlayPermission();
    await _blockApp.requestUsageStatsPermission();
  }

  /// Check if required permissions are granted
  Future<bool> hasRequiredPermissions() async {
    final permissions = await _blockApp.checkPermissions();
    return permissions['hasOverlayPermission'] == true &&
        permissions['hasUsageStatsPermission'] == true;
  }

  /// Get all installed apps (optionally including system apps)
  Future<List<dynamic>> getInstalledApps({bool includeSystemApps = false}) async {
    return await _blockApp.getInstalledApps(
      includeSystemApps: includeSystemApps,
    );
  }

  /// Block specific apps by package name
  Future<void> blockSelectedApps(List<String> packageNames) async {
    for (final pkg in packageNames) {
      await _blockApp.blockApp(pkg);
    }
  }

  /// Unblock all apps
  Future<void> unblockAll() async {
    await _blockApp.unblockAllApps();
  }

  /// Check if an app is currently blocked
  Future<bool> isAppBlocked(String packageName) async {
    return await _blockApp.isAppBlocked(packageName);
  }

  /// Listen for attempts to open blocked apps
  void listenForBlockedAppAttempts() {
    _blockApp.onBlockedAppDetected((packageName) {
      debugPrint('⚠️ User tried to open blocked app: $packageName');
    });
  }

   
  
}
 