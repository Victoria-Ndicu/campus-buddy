// ============================================================
//  CampusBuddy — main.dart
//
//  Native splash is already configured via flutter_native_splash.
//  This file:
//    1. Preserves the native splash while the app boots
//    2. Removes it once the first frame is ready
//    3. Routes directly to HomeScreen
//
//  No custom Flutter splash screen needed here.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// ── HomeScreen ───────────────────────────────────────────────
// FILE LIVES AT:
//   lib/features/home/screens/home_screen.dart
//
// That path matches your folder structure from the docs:
//   lib/
//   └── features/
//       └── home/
//           └── screens/
//               └── home_screen.dart   ← paste your HomeScreen here
//
import 'features/home/screens/home_screen.dart';

// ─────────────────────────────────────────────────────────────
//  ENTRY POINT
// ─────────────────────────────────────────────────────────────
void main() {
  // Preserve native splash until we are ready to show the UI
  final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // White icons on the brand-blue header
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFF5F4F0),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Portrait only
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const CampusBuddyApp());
}

// ─────────────────────────────────────────────────────────────
//  ROOT APP
// ─────────────────────────────────────────────────────────────
class CampusBuddyApp extends StatefulWidget {
  const CampusBuddyApp({super.key});

  @override
  State<CampusBuddyApp> createState() => _CampusBuddyAppState();
}

class _CampusBuddyAppState extends State<CampusBuddyApp> {

  @override
  void initState() {
    super.initState();
    _removeSplash();
  }

  // ── Remove native splash on first frame ───────────────────
  // Do any async work BEFORE calling remove() so the
  // native splash stays visible while the app initialises.
  //
  // Later, when you add Firebase + SharedPreferences, do it here:
  //
  //   Future<void> _removeSplash() async {
  //     await Firebase.initializeApp(...);
  //     final prefs = await SharedPreferences.getInstance();
  //     FlutterNativeSplash.remove();
  //   }
  //
  void _removeSplash() {
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusBuddy',
      debugShowCheckedModeBanner: false,

      // ── Theme ─────────────────────────────────────────────
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667EEA),
          primary: const Color(0xFF667EEA),
          surface: const Color(0xFFF5F4F0),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F4F0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
      ),

      // ── Start here after native splash ────────────────────
      home: const HomeScreen(),

      // ── Named routes — add each screen as you build them ──
      routes: {
        '/home'    : (_) => const HomeScreen(),

        // ── Uncomment as you create each file: ──────────────
        // '/welcome'       : (_) => const WelcomeScreen(),
        // '/sign-in'       : (_) => const SignInScreen(),
        // '/sign-up'       : (_) => const SignUpScreen(),
        // '/verification'  : (_) => const VerificationScreen(),
        // '/reset-password': (_) => const ResetPasswordScreen(),
        // '/study-buddy'   : (_) => const StudyBuddyHome(),
        // '/market'        : (_) => const MarketHome(),
        // '/housing'       : (_) => const HousingHome(),
        // '/events'        : (_) => const EventHome(),
      },
    );
  }
}