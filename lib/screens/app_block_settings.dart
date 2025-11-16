import 'package:flutter/material.dart';
import 'package:felinefocused/service/app_getter_service.dart';
import 'package:provider/provider.dart';
import '../provider/timer_provider.dart'; // Add this import

class BlockAppsScreen extends StatefulWidget {
  const BlockAppsScreen({super.key});

  @override
  State<BlockAppsScreen> createState() => _BlockAppsScreenState();
}

class _BlockAppsScreenState extends State<BlockAppsScreen> {
  List<AppViewModel> apps = [];
  Set<String> selectedPackages = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final list = await InstalledAppsService.instance.getLaunchableAppViewModels();
    
    // Load previously selected apps from provider
    final timeProvider = Provider.of<TimeProvider>(context, listen: false);
    selectedPackages = Set.from(timeProvider.selectedApps);
    
    setState(() {
      apps = list;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Apps to Block')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : apps.isEmpty
              ? const Center(child: Text('No launchable apps found'))
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
        onPressed: () {
          // Save selected apps to TimeProvider
          final timeProvider = Provider.of<TimeProvider>(context, listen: false);
          timeProvider.updateSelectedApps(selectedPackages.toList());

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${selectedPackages.length} apps will be blocked during focus sessions')),
          );
          
          Navigator.pop(context);
        },
        label: const Text('Save Selection'),
        icon: const Icon(Icons.check),
      ),
    );
  }
}