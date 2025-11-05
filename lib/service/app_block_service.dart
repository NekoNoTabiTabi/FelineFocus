import 'package:flutter/material.dart';
import 'package:block_app/block_app.dart';
import 'package:felinefocused/service/app_getter_service.dart';

class AppBlockManager {
  AppBlockManager._private();
  static final AppBlockManager instance = AppBlockManager._private();

  final BlockApp _blockApp = BlockApp();

  

  /// Initialize the blocking service
  Future<void> initialize() async {
  await _blockApp.initialize(
  config: AppBlockConfig(
    autoStartService: true,
    customOverlayBuilder: (context, packageName) {
  return Container(
    color: Colors.black.withOpacity(0.9),
    alignment: Alignment.center,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Blocked App',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        Text(
          packageName,
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Return'),
        ),
      ],
    ),
  );
},
  ),
);
  }

  /// Request overlay and usage stats permissions
  Future<void> requestPermissions() async {
    await _blockApp.requestUsageStatsPermission();
    await _blockApp.requestOverlayPermission();
  
  }

  /// Check if all required permissions are granted
  Future<bool> hasRequiredPermissions() async {
    final permissions = await _blockApp.checkPermissions();
    return permissions['hasOverlayPermission'] == true &&
           permissions['hasUsageStatsPermission'] == true;
  }

  /// Get all user-launchable apps using InstalledAppsService
  Future<List<AppViewModel>> getLaunchableApps() async {
    return await InstalledAppsService.instance.getLaunchableAppViewModels();
  }

  /// Block selected apps by package name
  Future<void> blockApps(List<String> packageNames) async {
    for (final pkg in packageNames) {
      await _blockApp.blockApp(pkg);
    }
  }

  /// Unblock all apps
  Future<void> unblockAll() async {
    await _blockApp.unblockAllApps();
  }

  /// Check if a specific app is blocked
  Future<bool> isBlocked(String packageName) async {
    return await _blockApp.isAppBlocked(packageName);
  }

  /// Listen for blocked app attempts
  void listenForBlockedAppAttempts() {
    _blockApp.onBlockedAppDetected((packageName) {
      debugPrint('⚠️ Attempt to open blocked app: $packageName');
   
    });
  }

  

}
