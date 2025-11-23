import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'provider/timer_provider.dart';
import 'provider/auth_provider.dart';
import 'service/app_block_service.dart'; 
import 'service/auth_service.dart'; // ADD THIS
import 'overlays/output_overlay.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase FIRST
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize AuthService (configure App Check, etc.)
  await AuthService.instance.initialize();
  
  // Wait a moment for Firebase Auth to fully initialize
  await Future.delayed(const Duration(milliseconds: 300));
  
  debugPrint("🔥 Firebase initialized - Current user: ${AuthService.instance.currentUser?.email ?? 'None'}");

  // Only initialize permissions, don't start monitoring yet
  await AppBlockManager.instance.initialize();

  // Create and initialize TimeProvider
  final timeProvider = TimeProvider();
  await timeProvider.initialize();

  // Check if onboarding is complete
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: timeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MyApp(showOnboarding: !onboardingComplete),
    ),
  );
}

/// Single entry point for ALL overlays - switches content based on type
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI for overlay
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OutputOverlay(),
    ),
  );
}