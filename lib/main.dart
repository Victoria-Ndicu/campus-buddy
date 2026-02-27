// main.dart
// ─────────────────────────────────────────────────────────────────────────
//  App entry point.
//
//  AuthGate is the MaterialApp home. On every cold start it:
//    1. Shows AuthSplashScreen (animated branding)
//    2. Reads SharedPreferences for a stored auth token
//    3a. Token found  →  HomeScreen   (user stays logged in)
//    3b. No token     →  AuthLoginScreen
//
//  Logout flow (call from any screen):
//    await authClearToken();
//    Navigator.of(context).pushAndRemoveUntil(
//      MaterialPageRoute(builder: (_) => const AuthGate()),
//      (_) => false,
//    );
// ─────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Auth module — single import via barrel
import 'features/auth/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const CampusBuddyApp());
}

class CampusBuddyApp extends StatelessWidget {
  const CampusBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusBuddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display', // falls back to system sans-serif
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667EEA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F4F0),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        useMaterial3: true,
      ),
      // ── AuthGate is the root — it decides what screen to show ──────────
      home: const AuthGate(),
    );
  }
}