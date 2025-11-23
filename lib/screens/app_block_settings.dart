import 'package:flutter/material.dart';
import 'package:felinefocused/service/app_getter_service.dart';
import 'package:provider/provider.dart';
import '../provider/timer_provider.dart';
import '../models/blocked_app_section.dart';
import '../models/reels_config.dart';
import '../service/app_block_service.dart';

class BlockAppsScreen extends StatefulWidget {
  const BlockAppsScreen({super.key});

  @override
  State<BlockAppsScreen> createState() => _BlockAppsScreenState();
}

class _BlockAppsScreenState extends State<BlockAppsScreen> {
  List<AppViewModel> apps = [];
  List<BlockedAppSection> selectedSections = [];
  bool blockReels = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final list = await InstalledAppsService.instance.getLaunchableAppViewModels();
    
    final timeProvider = Provider.of<TimeProvider>(context, listen: false);
    selectedSections = List.from(timeProvider.selectedAppSections);
    blockReels = timeProvider.blockReels;
    
    setState(() {
      apps = list;
      loading = false;
    });
  }

  bool _isAppSelected(String packageName) {
    return selectedSections.any((s) => s.packageName == packageName);
  }

  void _toggleAppBlocking(AppViewModel app) {
    setState(() {
      if (_isAppSelected(app.packageName)) {
        // Remove blocking
        selectedSections.removeWhere((s) => s.packageName == app.packageName);
      } else {
        // Add blocking (entire app)
        selectedSections.add(BlockedAppSection(
          packageName: app.packageName,
          appName: app.name,
          blockEntireApp: true,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Block Apps & Content'),
        backgroundColor: Colors.green,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // REELS BLOCKING CARD
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          blockReels = !blockReels;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.video_library,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Block All Reels & Shorts',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'YouTube, Instagram, TikTok, Facebook & more',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Transform.scale(
                              scale: 1.2,
                              child: Switch(
                                value: blockReels,
                                onChanged: (value) {
                                  setState(() {
                                    blockReels = value;
                                  });
                                },
                                activeColor: Colors.white,
                                activeTrackColor: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),



                // Show which apps will be affected by reels blocking
                if (blockReels)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Shorts/Reels will be blocked in: ${ReelsConfig.getAllReelsApps().map((p) => ReelsConfig.getFriendlyName(p)).join(", ")}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Divider
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR BLOCK ENTIRE APPS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                ),

                // Selection count
                if (selectedSections.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.block, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedSections.length} ${selectedSections.length == 1 ? 'app' : 'apps'} will be completely blocked',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Apps list
                Expanded(
                  child: ListView.builder(
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      final isSelected = _isAppSelected(app.packageName);
                      final hasReels = ReelsConfig.hasReelsContent(app.packageName);
                      
                      return ListTile(
                        leading: app.icon != null
                            ? Image.memory(app.icon!, width: 40, height: 40, fit: BoxFit.contain)
                            : CircleAvatar(child: Text(app.name[0])),
                        title: Text(app.name),
                        subtitle: hasReels
                            ? Row(
                                children: [
                                  Icon(Icons.video_library, size: 14, color: Colors.green.shade400),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Has Reels/Shorts',
                                    style: TextStyle(fontSize: 12, color: Colors.green.shade400),
                                  ),
                                ],
                              )
                            : null,
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (val) => _toggleAppBlocking(app),
                          activeColor: Colors.green,
                        ),
                        onTap: () => _toggleAppBlocking(app),
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
          timeProvider.setBlockReels(blockReels);

          String message = '';
          if (blockReels && selectedSections.isNotEmpty) {
            message = 'Reels blocked + ${selectedSections.length} apps blocked';
          } else if (blockReels) {
            message = 'All reels & shorts will be blocked';
          } else if (selectedSections.isNotEmpty) {
            message = '${selectedSections.length} apps will be blocked';
          } else {
            message = 'No blocking configured';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          
          Navigator.pop(context);
        },
        label: const Text('Save Settings'),
        icon: const Icon(Icons.check),
        backgroundColor: Colors.green,
      ),
    );
  }
}