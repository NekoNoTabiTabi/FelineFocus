import 'package:flutter/material.dart';
import 'package:felinefocused/service/app_block_service.dart';

import 'package:felinefocused/service/app_getter_service.dart';


class BlockAppsScreen extends StatefulWidget {
  const BlockAppsScreen({super.key});

  @override
  State<BlockAppsScreen> createState() => _BlockAppsScreenState();
}

class _BlockAppsScreenState extends State<BlockAppsScreen> {
  final AppBlockManager _manager = AppBlockManager.instance;
  List<AppViewModel> apps = [];
  Set<String> selectedPackages = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
    _manager.listenForBlockedAppAttempts();
  }

  Future<void> _loadApps() async {
    final result = await _manager.getLaunchableApps();
    setState(() {
      apps = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Apps to Block')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                final isSelected = selectedPackages.contains(app.packageName);
                return ListTile(
                  leading: app.icon != null
                      ? Image.memory(app.icon!, width: 40, height: 40, fit: BoxFit.contain)
                      : CircleAvatar(child: Text(app.name[0])),
                  title: Text(app.name),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          selectedPackages.add(app.packageName);
                        } else {
                          selectedPackages.remove(app.packageName);
                        }
                      });
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _manager.blockApps(selectedPackages.toList());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected apps are now blocked')),
          );
        },
        label: const Text('Block Selected Apps'),
        icon: const Icon(Icons.block),
      ),
    );
  }
}