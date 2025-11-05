import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'provider/timer_provider.dart'; // make sure path matches your folder
import 'package:felinefocused/service/app_block_service.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBlockManager.instance.initialize();
  await AppBlockManager.instance.requestPermissions();
  AppBlockManager.instance.listenForBlockedAppAttempts();

  runApp(
   
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimeProvider()),
        
      ],
      child: const MyApp(),
    ),
  );
}