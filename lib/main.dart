import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'provider/timer_provider.dart';
import 'provider/auth_provider.dart';
import 'service/app_block_service.dart'; 
import 'service/auth_service.dart';
import 'overlays/output_overlay.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase FIRST
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize AuthService
  await AuthService.instance.initialize();
  
  // Wait for Firebase Auth to fully initialize
  await Future.delayed(const Duration(milliseconds: 300));
  
  debugPrint("🔥 Firebase initialized - Current user: ${AuthService.instance.currentUser?.email ?? 'None'}");

  // Initialize permissions
  await AppBlockManager.instance.initialize();

  // Create TimeProvider
  final timeProvider = TimeProvider();
  await timeProvider.initialize();

  // Check if onboarding is complete
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: timeProvider),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        // NEW: Listen to auth changes and update TimeProvider. Use a
        // ChangeNotifierProxyProvider so the provided type is change-notifier-aware
        // (avoids providing a Listenable via a plain Provider which triggers
        // runtime checks).
        ChangeNotifierProxyProvider<AuthProvider, TimeProvider>(
          create: (_) => timeProvider,
          update: (context, authProvider, previous) {
            final userId = authProvider.user?.uid;
            previous?.setUser(userId);
            return previous ?? timeProvider;
          },
        ),
      ],
      child: MyApp(showOnboarding: !onboardingComplete),
    ),
  );
}

/// Single entry point for ALL overlays
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  
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