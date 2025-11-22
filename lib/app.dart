import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/homepage.dart';
import 'screens/login_screen.dart';
import 'provider/auth_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Feline Focused',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Use auth state to determine initial screen
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Show loading while checking auth state
          if (authProvider.user == null && !authProvider.isLoading) {
            return const LoginScreen();
          }
          
          // User is logged in
          if (authProvider.isLoggedIn) {
            return const HomePage();
          }
          
          // Default to login screen
          return const LoginScreen();
        },
      ),
    );
  }
}