// ============================================================
//  CampusBuddy — main.dart  (updated for StudyBuddy module)
//
//  Changes from the original:
//    1. Added:  import 'features/study_buddy/screens/study_buddy.dart';
//    2. Uncommented the '/study-buddy' route
//
//  Everything else is identical to the original file.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'features/home/screens/home_screen.dart';

// ── NEW: import the entire StudyBuddy module with one line ────
import 'features/study_buddy/study_buddy.dart';

// ─────────────────────────────────────────────────────────────
//  ENTRY POINT
// ─────────────────────────────────────────────────────────────
void main() {
  final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFF5F4F0),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

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

  void _removeSplash() {
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusBuddy',
      debugShowCheckedModeBanner: false,

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

      home: const HomeScreen(),

      routes: {
        '/home'        : (_) => const HomeScreen(),
        '/study-buddy' : (_) => const StudyBuddyHome(),

        // ── Uncomment as you create each file: ────────────────
        // '/welcome'       : (_) => const WelcomeScreen(),
        // '/sign-in'       : (_) => const SignInScreen(),
        // '/sign-up'       : (_) => const SignUpScreen(),
        // '/verification'  : (_) => const VerificationScreen(),
        // '/reset-password': (_) => const ResetPasswordScreen(),
        // '/market'        : (_) => const MarketHome(),
        // '/housing'       : (_) => const HousingHome(),
        // '/events'        : (_) => const EventHome(),
      },
    );
  }
}