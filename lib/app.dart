import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/homepage.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'provider/auth_provider.dart';

class MyApp extends StatelessWidget {
  final bool showOnboarding;

  const MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
  
    if (showOnboarding) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: OnboardingScreen(),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Feline Focused',
      theme: ThemeData(
        primarySwatch: Colors.blue,
       
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(color: Colors.white),
          actionsIconTheme: IconThemeData(color: Colors.white),
          foregroundColor: Colors.white,
        ),
      ),
    
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (authProvider.isLoggedIn) {
            return const HomePage();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}