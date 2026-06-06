import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:whatshoppy2/screens/welcome_screen.dart';
import 'package:whatshoppy2/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // No Supabase.initialize() — Flutter no longer calls Supabase directly.
  // All data goes through the Node.js backend.

  runApp(const WhatShoppyApp());
}

class WhatShoppyApp extends StatelessWidget {
  const WhatShoppyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhatShoppy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const WelcomeScreen(),
    );
  }
}
