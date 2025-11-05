// lib/screens/installed_apps_test.dart
import 'package:flutter/material.dart';
import 'package:felinefocused/service/app_getter_service.dart';

class InstalledAppsTestScreen extends StatefulWidget {
  const InstalledAppsTestScreen({super.key});

  @override
  State<InstalledAppsTestScreen> createState() => _InstalledAppsTestScreenState();
}

class _InstalledAppsTestScreenState extends State<InstalledAppsTestScreen> {
  final InstalledAppsService _service = InstalledAppsService.instance;
  bool loading = true;
  List<AppViewModel> apps = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _service.getLaunchableAppViewModels();
    setState(() {
      apps = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Installed Apps (launchable)'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: apps.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, i) {
                final a = apps[i];
                return ListTile(
                  leading: a.icon != null ? Image.memory(a.icon!, width: 40, height: 40) : null,
                  title: Text(a.name),
                  subtitle: Text(a.packageName),
                );
              },
            ),
    );
  }
}