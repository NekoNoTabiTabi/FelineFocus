import 'package:flutter/material.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../provider/timer_provider.dart';
import '../provider/auth_provider.dart';



class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _accessibilityEnabled = false;
  bool _overlayEnabled = false;
  bool _isCheckingPermissions = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isCheckingPermissions = true;
    });

    try {
      final accessibilityStatus = await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
      final overlayStatus = await FlutterOverlayWindow.isPermissionGranted();

      setState(() {
        _accessibilityEnabled = accessibilityStatus;
        _overlayEnabled = overlayStatus;
        _isCheckingPermissions = false;
      });
    } catch (e) {
      debugPrint("Error checking permissions: $e");
      setState(() {
        _isCheckingPermissions = false;
      });
    }
  }

  Future<void> _requestAccessibilityPermission() async {
    try {
      await FlutterAccessibilityService.requestAccessibilityPermission();
      
      // Show dialog explaining user needs to manually enable it
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Enable Accessibility Service'),
            content: const Text(
              'Please enable "Feline Focused" in the Accessibility settings that just opened.\n\n'
              '1. Find "Feline Focused" in the list\n'
              '2. Toggle it ON\n'
              '3. Confirm any warnings\n'
              '4. Come back to this app',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _checkPermissions(); // Recheck after user comes back
                },
                child: const Text('I\'ve Enabled It'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint("Error requesting accessibility permission: $e");
    }
  }

  Future<void> _requestOverlayPermission() async {
    try {
      await FlutterOverlayWindow.requestPermission();
      
    } catch (e) {
      debugPrint("Error requesting overlay permission: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeProvider = Provider.of<TimeProvider>(context);
    final allPermissionsGranted = _accessibilityEnabled && _overlayEnabled;

    // DEBUG: Print current Firebase user and AuthProvider values to help
    // verify whether Firebase Auth is initialized and user profile is available.
    final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
    debugPrint('DEBUG: Firebase currentUser -> uid=${firebaseUser?.uid}, name=${firebaseUser?.displayName}, email=${firebaseUser?.email}');
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    debugPrint('DEBUG: AuthProvider -> name=${authProv.userDisplayName}, email=${authProv.userEmail}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)       ),
        backgroundColor: Colors.green,
      ),
      body: _isCheckingPermissions
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [


                     const SizedBox(height: 32),

                  // Account Section
                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // User Info Card
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.green.shade100,
                                    backgroundImage: authProvider.userPhotoUrl != null
                                        ? NetworkImage(authProvider.userPhotoUrl!)
                                        : null,
                                    child: authProvider.userPhotoUrl == null
                                        ? Icon(
                                            Icons.person,
                                            size: 30,
                                            color: Colors.green.shade700,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          authProvider.userDisplayName ?? 'User',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          authProvider.userEmail ?? 'email@example.com',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              // Logout Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final shouldLogout = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Logout'),
                                        content: const Text('Are you sure you want to logout?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            child: const Text(
                                              'Logout',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (shouldLogout == true && mounted) {
                                      await authProvider.signOut();
                                      // Navigation will be handled by auth state listener
                                    }
                                  },
                                  icon: const Icon(Icons.logout),
                                  label: const Text('Logout'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),                 
                  
                  // Permissions Section
                  const Text(
                    'Required Permissions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Permissions Status Card
                  Card(
                    elevation: 4,
                    color: allPermissionsGranted 
                        ? Colors.green.shade50 
                        : Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                allPermissionsGranted 
                                    ? Icons.check_circle 
                                    : Icons.warning,
                                color: allPermissionsGranted 
                                    ? Colors.green 
                                    : Colors.orange,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  allPermissionsGranted
                                      ? 'All permissions granted!'
                                      : 'Permissions Required',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: allPermissionsGranted 
                                        ? Colors.green.shade800 
                                        : Colors.orange.shade800,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _checkPermissions,
                                tooltip: 'Refresh status',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            allPermissionsGranted
                                ? 'Your app is ready to block distractions!'
                                : 'Please enable the required permissions below to use all features.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Accessibility Service Card
                  _buildPermissionCard(
                    icon: Icons.accessibility_new,
                    title: 'Accessibility Service',
                    description: 'Required to detect and block apps/reels in real-time',
                    isEnabled: _accessibilityEnabled,
                    onTap: _accessibilityEnabled ? null : _requestAccessibilityPermission,
                  ),

                  const SizedBox(height: 12),

                  // Overlay Permission Card
                  _buildPermissionCard(
                    icon: Icons.stacked_bar_chart,
                    title: 'Display Over Other Apps',
                    description: 'Required to show blocking screen over other apps',
                    isEnabled: _overlayEnabled,
                    onTap: _overlayEnabled ? null : _requestOverlayPermission,
                  ),

                  const SizedBox(height: 32),

                  // App Settings Section
                  const Text(
                    'App Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Blocking Status
                  Card(
                    child: ListTile(
                      leading: Icon(
                        timeProvider.isRunning 
                            ? Icons.lock 
                            : Icons.lock_open,
                        color: timeProvider.isRunning 
                            ? Colors.green 
                            : Colors.grey,
                      ),
                      title: const Text('Blocking Status'),
                      subtitle: Text(
                        timeProvider.isRunning 
                            ? 'Active - Apps are being blocked'
                            : 'Inactive - No blocking active',
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: timeProvider.isRunning 
                              ? Colors.green.shade100 
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          timeProvider.isRunning ? 'ON' : 'OFF',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: timeProvider.isRunning 
                                ? Colors.green.shade800 
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Blocked Apps Count
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.block, color: Colors.red),
                      title: const Text('Blocked Apps'),
                      subtitle: Text(
                        '${timeProvider.selectedAppSections.length} apps selected',
                      ),
                      trailing: Text(
                        '${timeProvider.selectedAppSections.length}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Reels Blocking Status
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.video_library,
                        color: timeProvider.blockReels 
                            ? Colors.purple 
                            : Colors.grey,
                      ),
                      title: const Text('Reels Blocking'),
                      subtitle: Text(
                        timeProvider.blockReels
                            ? 'All reels & shorts will be blocked'
                            : 'Reels blocking is disabled',
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: timeProvider.blockReels
                              ? Colors.purple.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          timeProvider.blockReels ? 'ON' : 'OFF',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: timeProvider.blockReels
                                ? Colors.purple.shade800
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Danger Zone
                  const Text(
                    'Danger Zone',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    color: Colors.red.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Clear All Data'),
                      subtitle: const Text('Reset timer, apps, and all settings'),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear All Data?'),
                            content: const Text(
                              'This will reset:\n'
                              '• Timer duration\n'
                              '• Blocked apps list\n'
                              '• Reels blocking settings\n\n'
                              'This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  await timeProvider.clearAllData();
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('All data cleared'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text(
                                  'Clear Data',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

const SizedBox(height: 12),

Card(
  color: Colors.red.shade50,
  child: ListTile(
    leading: const Icon(Icons.history_toggle_off, color: Colors.red),
    title: const Text('Clear Focus History'),
    subtitle: const Text('Delete all focus session records'),
    onTap: () {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear Focus History?'),
          content: const Text(
            'This will permanently delete all your focus session records.\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final timeProvider = Provider.of<TimeProvider>(
                  context,
                  listen: false,
                );
                await timeProvider.clearUserHistory();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Focus history cleared'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Clear History',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    },
  ),
),

                  const SizedBox(height: 32),

                  // App Info
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'Feline Focused',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isEnabled,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEnabled 
                      ? Colors.green.shade100 
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isEnabled ? Colors.green : Colors.orange,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          isEnabled ? Icons.check_circle : Icons.cancel,
                          color: isEnabled ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (!isEnabled) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Tap to enable',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}