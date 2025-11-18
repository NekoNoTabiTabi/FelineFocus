import 'package:flutter/material.dart';
import 'package:felinefocused/service/app_getter_service.dart';
import 'package:provider/provider.dart';
import '../provider/timer_provider.dart';
import '../models/blocked_app_section.dart';

class BlockAppsScreen extends StatefulWidget {
  const BlockAppsScreen({super.key});

  @override
  State<BlockAppsScreen> createState() => _BlockAppsScreenState();
}

class _BlockAppsScreenState extends State<BlockAppsScreen> {
  List<AppViewModel> apps = [];
  List<BlockedAppSection> selectedSections = [];
  bool loading = true;

  // Predefined sections for popular apps
  final Map<String, List<String>> popularAppSections = {
    'com.google.android.youtube': ['shorts', 'short'],
    'com.instagram.android': ['reels', 'reel'],
    'com.facebook.katana': ['reels', 'reel', 'watch'],
    'com.zhiliaoapp.musically': [], // TikTok - block entirely
    'com.snapchat.android': ['spotlight', 'discover'],
  };

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final list = await InstalledAppsService.instance.getLaunchableAppViewModels();
    
    // Load previously selected sections
    final timeProvider = Provider.of<TimeProvider>(context, listen: false);
    selectedSections = List.from(timeProvider.selectedAppSections);
    
    setState(() {
      apps = list;
      loading = false;
    });
  }

  void _showSectionDialog(AppViewModel app) {
    final hasPredefSections = popularAppSections.containsKey(app.packageName);
    final predefSections = hasPredefSections ? popularAppSections[app.packageName]! : <String>[];
    
    // Find existing section for this app
    final existingSection = selectedSections.firstWhere(
      (s) => s.packageName == app.packageName,
      orElse: () => BlockedAppSection(
        packageName: app.packageName,
        appName: app.name,
        blockedKeywords: [],
        blockEntireApp: false,
      ),
    );

    bool blockEntireApp = existingSection.blockEntireApp;
    Set<String> selectedKeywords = Set.from(existingSection.blockedKeywords);
    TextEditingController customKeywordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Block Options for ${app.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Block entire app option
                CheckboxListTile(
                  title: const Text('Block Entire App'),
                  value: blockEntireApp,
                  onChanged: (val) {
                    setDialogState(() {
                      blockEntireApp = val ?? false;
                      if (blockEntireApp) {
                        selectedKeywords.clear();
                      }
                    });
                  },
                ),
                
                const Divider(),
                
                if (!blockEntireApp) ...[
                  const Text(
                    'Or block specific sections:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  
                  // Predefined sections if available
                  if (hasPredefSections) ...[
                    const Text('Popular sections:'),
                    ...predefSections.map((section) => CheckboxListTile(
                      title: Text(section.toUpperCase()),
                      value: selectedKeywords.contains(section),
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            selectedKeywords.add(section);
                          } else {
                            selectedKeywords.remove(section);
                          }
                        });
                      },
                    )),
                    const SizedBox(height: 10),
                  ],
                  
                  // Custom keywords
                  const Text('Custom keywords:'),
                  const SizedBox(height: 5),
                  TextField(
                    controller: customKeywordController,
                    decoration: const InputDecoration(
                      hintText: 'Enter keyword (e.g., "shorts")',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 5),
                  ElevatedButton(
                    onPressed: () {
                      final keyword = customKeywordController.text.trim();
                      if (keyword.isNotEmpty) {
                        setDialogState(() {
                          selectedKeywords.add(keyword);
                          customKeywordController.clear();
                        });
                      }
                    },
                    child: const Text('Add Keyword'),
                  ),
                  
                  // Show selected custom keywords
                  if (selectedKeywords.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: selectedKeywords.map((kw) => Chip(
                        label: Text(kw),
                        onDeleted: () {
                          setDialogState(() {
                            selectedKeywords.remove(kw);
                          });
                        },
                      )).toList(),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Remove any existing section for this app
                  selectedSections.removeWhere((s) => s.packageName == app.packageName);
                  
                  // Add new section if something is selected
                  if (blockEntireApp || selectedKeywords.isNotEmpty) {
                    selectedSections.add(BlockedAppSection(
                      packageName: app.packageName,
                      appName: app.name,
                      blockedKeywords: selectedKeywords.toList(),
                      blockEntireApp: blockEntireApp,
                    ));
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  bool _isAppSelected(String packageName) {
    return selectedSections.any((s) => s.packageName == packageName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Apps/Sections to Block'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : apps.isEmpty
              ? const Center(child: Text('No launchable apps found'))
              : Column(
                  children: [
                    // Show selected count
                    if (selectedSections.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.green.shade50,
                        width: double.infinity,
                        child: Text(
                          '${selectedSections.length} apps/sections selected',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    
                    Expanded(
                      child: ListView.builder(
                        itemCount: apps.length,
                        itemBuilder: (context, index) {
                          final app = apps[index];
                          final isSelected = _isAppSelected(app.packageName);
                          final section = selectedSections.firstWhere(
                            (s) => s.packageName == app.packageName,
                            orElse: () => BlockedAppSection(
                              packageName: '',
                              appName: '',
                              blockedKeywords: [],
                            ),
                          );
                          
                          return ListTile(
                            leading: app.icon != null
                                ? Image.memory(app.icon!, width: 40, height: 40, fit: BoxFit.contain)
                                : CircleAvatar(child: Text(app.name[0])),
                            title: Text(app.name),
                            subtitle: isSelected ? Text(section.toString(), style: const TextStyle(fontSize: 12)) : null,
                            trailing: Icon(
                              isSelected ? Icons.check_circle : Icons.circle_outlined,
                              color: isSelected ? Colors.green : null,
                            ),
                            onTap: () => _showSectionDialog(app),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final timeProvider = Provider.of<TimeProvider>(context, listen: false);
          timeProvider.updateSelectedAppSections(selectedSections);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${selectedSections.length} apps/sections will be blocked'),
            ),
          );
          
          Navigator.pop(context);
        },
        label: const Text('Save Selection'),
        icon: const Icon(Icons.check),
      ),
    );
  }
}