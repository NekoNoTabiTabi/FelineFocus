
import 'dart:developer';
import 'dart:typed_data';


import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

/// Service to fetch installed apps and filter launchable / user apps.
/// Uses the `installed_apps` package. It's implemented defensively:
/// if the app model has slightly different fields, we'll log the issue.
class InstalledAppsService {
  InstalledAppsService._private();
  static final InstalledAppsService instance = InstalledAppsService._private();

  /// Raw fetch of all installed apps (may include system apps).
  Future<List<AppInfo>> getAllApps({bool includeSystemApps = true}) async {
    try {
      log('InstalledAppsService: fetching installed apps (includeSystem=$includeSystemApps)');
      final apps = await InstalledApps.getInstalledApps();
      log('InstalledAppsService: fetched ${apps.length} apps');
      // Print first few for quick debugging
      for (var i = 0; i < apps.length && i < 10; i++) {
        try {
          final a = apps[i];
          log('  app[$i]: name="${a.name}" package="${a.packageName}" isSystem=${a.isSystemApp}');
        } catch (e) {
          log('  app[$i]: (could not read fields) $e');
        }
      }
      return apps;
    } catch (e, st) {
      log('InstalledAppsService.getAllApps error: $e\n$st');
      return <AppInfo>[];
    }
  }

 
  Future<List<AppInfo>> getLaunchableApps() async {
  try {
    // excludeNonLaunchableApps = true ensures we only get apps with a valid launch intent
    final allApps = await InstalledApps.getInstalledApps(
      excludeSystemApps: false,
      excludeNonLaunchableApps: true,
      withIcon: true
    );

    // Filter user apps unless includeSystemApps == true
    final launchableApps = allApps.where((app) => app.isLaunchableApp == true).toList();

    log('InstalledAppsService: Found ${launchableApps.length} launchable apps');
    return launchableApps;
  } catch (e, st) {
    log('InstalledAppsService.getLaunchableApps error: $e\n$st');
    return [];
  }
}

  /// Convenience: returns lightweight view model for UI (name, package, optional icon)
  Future<List<AppViewModel>> getLaunchableAppViewModels({bool includeIcons = false}) async {
    final apps = await getLaunchableApps();
    final list = <AppViewModel>[];
    for (final a in apps) {
      Uint8List? icon;
      try {
        // If the library returned icons, some AppInfo variants put it in `icon` or `appIcon`
        final maybe = (a as dynamic);
        if (maybe.icon != null && maybe.icon is Uint8List) {
          icon = maybe.icon as Uint8List;
        } else if (maybe.appIcon != null && maybe.appIcon is Uint8List) {
          icon = maybe.appIcon as Uint8List;
        }
      } catch (_) {}
      list.add(AppViewModel(
        name: a.name ,
        packageName: a.packageName,
        icon: icon,
      ));
    }
    return list;
  }
}

/// Small UI-friendly model
class AppViewModel {
  final String name;
  final String packageName;
  final Uint8List? icon;
  AppViewModel({
    required this.name,
    required this.packageName,
    this.icon,
  });
}