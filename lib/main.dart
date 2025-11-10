
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'provider/timer_provider.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'service/app_block_service.dart'; 
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBlockManager.instance.initialize();

  // Ensure overlay permission before running app
  if (!await FlutterOverlayWindow.isPermissionGranted()) {
    await FlutterOverlayWindow.requestPermission();
  }

  if (!await FlutterAccessibilityService.isAccessibilityPermissionEnabled()) {
    await FlutterAccessibilityService.requestAccessibilityPermission();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimeProvider()),
      ],
      child: const MyApp(),
    ),
  );

  // Start monitoring apps after the app is running
  

  


}


@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayScreen(),
    ),
  );
}
class OverlayScreen extends StatelessWidget {
  const OverlayScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.9),
      child: SizedBox.expand(
        child: Center(
          child: ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text("Access blocked!"),
            subtitle: const Text("This app is restricted."),
          ),
        ),
      ),
    );
  }
}