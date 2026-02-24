// ============================================================
//  CampusBuddy — main.dart
//  University Super-App: StudyBuddy · CampusMarket ·
//  Housing Hub · EventBoard
//
//  Author  : CampusBuddy Team
//  Version : 1.0.0
//
//  STRUCTURE
//  ─────────────────────────────────────────────────────────
//  1. App Entry Point     → main()
//  2. Root App Widget     → CampusBuddyApp
//  3. App-Level Routing   → AppRouter  (see core/routing/)
//  4. Auth Entry Decision → AuthGate   (see core/auth/)
//  5. Global State Setup  → Riverpod ProviderScope
//  6. App Constants       → AppConstants
//  7. Named Routes        → Routes
//  8. App Theme           → AppTheme
//  9. File Structure      → at bottom of file
// 10. pubspec deps        → at bottom of file
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Firebase generated options ──────────────────────────────
import 'firebase_options.dart';

// ── App-level providers (no business logic here) ────────────
import 'core/providers/auth_provider.dart';
import 'core/providers/onboarding_provider.dart';

// ── Router ───────────────────────────────────────────────────
import 'core/routing/app_router.dart';

// ── Theme ────────────────────────────────────────────────────
import 'core/theme/app_theme.dart';

// ── Screens registered for named routing ─────────────────────
//    (No UI logic here — screens live in their own files)
import 'features/auth/screens/welcome_screen.dart';
import 'features/auth/screens/sign_in_screen.dart';
import 'features/auth/screens/sign_up_screen.dart';
import 'features/auth/screens/verification_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/auth/screens/check_mail_screen.dart';
import 'features/auth/screens/new_password_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/study_buddy/screens/study_buddy_home.dart';
import 'features/campus_market/screens/market_home.dart';
import 'features/housing_hub/screens/housing_home.dart';
import 'features/event_board/screens/event_home.dart';

// ============================================================
// 1️⃣  APP ENTRY POINT
// ============================================================

Future<void> main() async {
  // Ensure Flutter engine is bound before any async work
  WidgetsFlutterBinding.ensureInitialized();

  // ── Lock orientation to portrait ────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── System UI overlay — white icons on brand blue header ─
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFF5F4F0),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // ── Firebase initialization ─────────────────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Local storage — read before runApp to avoid flash ───
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool onboardingComplete =
      prefs.getBool(AppConstants.kOnboardingCompleteKey) ?? false;

  // ── Run app wrapped in ProviderScope (Riverpod root) ────
  runApp(
    ProviderScope(
      overrides: [
        // Inject SharedPreferences instance into the provider tree
        sharedPreferencesProvider.overrideWithValue(prefs),
        onboardingCompleteProvider.overrideWithValue(onboardingComplete),
      ],
      child: const CampusBuddyApp(),
    ),
  );
}

// ============================================================
// 2️⃣  ROOT APP WIDGET
// ============================================================

class CampusBuddyApp extends ConsumerWidget {
  const CampusBuddyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch router — auth state changes trigger re-navigation
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      // ── App identity ─────────────────────────────────────
      title: 'CampusBuddy',
      debugShowCheckedModeBanner: false,

      // ── Routing (GoRouter) ───────────────────────────────
      routerConfig: router,

      // ── Light theme ──────────────────────────────────────
      theme: AppTheme.light,

      // ── Dark theme ───────────────────────────────────────
      darkTheme: AppTheme.dark,

      // ── Follow system preference ─────────────────────────
      themeMode: ThemeMode.system,

      // ── Localization (extend later for Swahili support) ──
      // localizationsDelegates: AppLocalizations.localizationsDelegates,
      // supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

// ============================================================
// 3️⃣  APP-LEVEL ROUTING
//      Full implementation lives in: core/routing/app_router.dart
//      Outline shown here — copy into that file.
// ============================================================

// FILE: lib/core/routing/app_router.dart
//
// import 'package:go_router/go_router.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// final appRouterProvider = Provider<GoRouter>((ref) {
//
//   // Watch auth state — router rebuilds on login/logout
//   final authState = ref.watch(authStateProvider);
//
//   return GoRouter(
//     initialLocation: Routes.welcome,
//     debugLogDiagnostics: true,   // ← remove in production
//
//     // Global redirect logic delegated to AuthGate helper
//     redirect: (context, state) =>
//         AuthRedirect.check(authState, state),
//
//     routes: [
//
//       // ── Auth flow ───────────────────────────────────────
//       GoRoute(
//         path: Routes.welcome,
//         name: Routes.welcome,
//         builder: (_, __) => const WelcomeScreen(),
//       ),
//       GoRoute(
//         path: Routes.signIn,
//         name: Routes.signIn,
//         builder: (_, __) => const SignInScreen(),
//       ),
//       GoRoute(
//         path: Routes.signUp,
//         name: Routes.signUp,
//         builder: (_, __) => const SignUpScreen(),
//       ),
//       GoRoute(
//         path: Routes.verification,
//         name: Routes.verification,
//         // email passed as extra to avoid URL leakage
//         builder: (_, state) => VerificationScreen(
//           email: state.extra as String,
//         ),
//       ),
//       GoRoute(
//         path: Routes.resetPassword,
//         name: Routes.resetPassword,
//         builder: (_, __) => const ResetPasswordScreen(),
//       ),
//       GoRoute(
//         path: Routes.checkMail,
//         name: Routes.checkMail,
//         builder: (_, state) => CheckMailScreen(
//           email: state.extra as String,
//         ),
//       ),
//       GoRoute(
//         path: Routes.newPassword,
//         name: Routes.newPassword,
//         builder: (_, __) => const NewPasswordScreen(),
//       ),
//
//       // ── Main shell (bottom nav) ─────────────────────────
//       ShellRoute(
//         builder: (context, state, child) =>
//             HomeScreen(child: child),
//         routes: [
//           GoRoute(
//             path: Routes.home,
//             name: Routes.home,
//             builder: (_, __) => const HomeTab(),
//           ),
//
//           // StudyBuddy (FR5–FR8)
//           GoRoute(
//             path: Routes.studyBuddy,
//             name: Routes.studyBuddy,
//             builder: (_, __) => const StudyBuddyHome(),
//             routes: [
//               GoRoute(path: 'tutors',    builder: (_, __) => const TutorListScreen()),
//               GoRoute(path: 'groups',    builder: (_, __) => const StudyGroupScreen()),
//               GoRoute(path: 'resources', builder: (_, __) => const ResourceLibraryScreen()),
//               GoRoute(path: 'help',      builder: (_, __) => const AcademicHelpScreen()),
//             ],
//           ),
//
//           // CampusMarket (CM1–CM5)
//           GoRoute(
//             path: Routes.market,
//             name: Routes.market,
//             builder: (_, __) => const MarketHome(),
//             routes: [
//               GoRoute(path: 'browse',    builder: (_, __) => const BrowseScreen()),
//               GoRoute(path: 'chats',     builder: (_, __) => const ChatInboxScreen()),
//               GoRoute(path: 'listings',  builder: (_, __) => const MyListingsScreen()),
//               GoRoute(path: 'donations', builder: (_, __) => const DonationHubScreen()),
//             ],
//           ),
//
//           // Housing Hub (HH1–HH4)
//           GoRoute(
//             path: Routes.housing,
//             name: Routes.housing,
//             builder: (_, __) => const HousingHome(),
//             routes: [
//               GoRoute(path: 'map',       builder: (_, __) => const HousingMapScreen()),
//               GoRoute(path: 'roommates', builder: (_, __) => const RoommateMatchScreen()),
//               GoRoute(path: 'alerts',    builder: (_, __) => const HousingAlertsScreen()),
//             ],
//           ),
//
//           // EventBoard (EB1–EB4)
//           GoRoute(
//             path: Routes.events,
//             name: Routes.events,
//             builder: (_, __) => const EventHome(),
//             routes: [
//               GoRoute(path: 'calendar',  builder: (_, __) => const EventCalendarScreen()),
//               GoRoute(path: 'rsvps',     builder: (_, __) => const MyRsvpsScreen()),
//               GoRoute(path: 'create',    builder: (_, __) => const CreateEventScreen()),
//             ],
//           ),
//         ],
//       ),
//     ],
//   );
// });

// ============================================================
// 4️⃣  AUTH ENTRY DECISION
//      Full implementation lives in: core/auth/auth_gate.dart
// ============================================================

// FILE: lib/core/auth/auth_gate.dart
//
// /// AuthGate reads state — it does NOT contain business logic.
// ///
// /// Decision tree:
// ///   1. Loading              → SplashScreen (no flash)
// ///   2. Onboarding incomplete→ /welcome
// ///   3. Not authenticated    → /sign-in
// ///   4. Email not verified   → /verification
// ///   5. Authenticated ✓      → /home
//
// class AuthGate extends ConsumerWidget {
//   const AuthGate({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final authAsync     = ref.watch(authStateProvider);
//     final onboardingDone = ref.watch(onboardingCompleteProvider);
//
//     return authAsync.when(
//       loading: () => const SplashScreen(),
//       error:   (_, __) => const SignInScreen(),
//       data:    (user) {
//         if (!onboardingDone)      return const WelcomeScreen();
//         if (user == null)         return const SignInScreen();
//         if (!user.emailVerified)  return const VerificationScreen();
//         return const HomeScreen();
//       },
//     );
//   }
// }
//
// /// Pure redirect helper — no widgets, no state
// abstract class AuthRedirect {
//   static String? check(AsyncValue<User?> authState, GoRouterState state) {
//     final bool loggedIn = authState.valueOrNull != null;
//     final bool goingToAuth = state.matchedLocation.startsWith('/sign')
//         || state.matchedLocation == Routes.welcome
//         || state.matchedLocation == Routes.resetPassword;
//
//     if (!loggedIn && !goingToAuth) return Routes.signIn;
//     if (loggedIn && goingToAuth)   return Routes.home;
//     return null; // no redirect needed
//   }
// }

// ============================================================
// 5️⃣  GLOBAL PROVIDERS
//      Lives in: core/providers/
// ============================================================

// FILE: lib/core/providers/auth_provider.dart
//
// /// Streams Firebase auth state changes — no business logic.
// final authStateProvider = StreamProvider<User?>((ref) {
//   return FirebaseAuth.instance.authStateChanges();
// });
//
// /// SharedPreferences instance injected at startup in main().
// final sharedPreferencesProvider =
//     Provider<SharedPreferences>((_) => throw UnimplementedError());

// FILE: lib/core/providers/onboarding_provider.dart
//
// /// Boolean read at startup from SharedPreferences.
// /// Overridden in ProviderScope before runApp().
// final onboardingCompleteProvider =
//     Provider<bool>((_) => throw UnimplementedError());

// ============================================================
// 6️⃣  APP CONSTANTS
//      Lives in: core/constants/app_constants.dart
// ============================================================

abstract class AppConstants {
  // SharedPreferences keys
  static const String kOnboardingCompleteKey = 'onboarding_complete';
  static const String kAuthTokenKey          = 'auth_token';
  static const String kUserIdKey             = 'user_id';
  static const String kThemeModeKey          = 'theme_mode';

  // App metadata
  static const String appName    = 'CampusBuddy';
  static const String appVersion = '1.0.0';

  // Feature flags (toggle modules without a rebuild)
  static const bool enableHousingHub  = true;
  static const bool enableEventBoard  = true;
  static const bool enableMarketplace = true;
  static const bool enableStudyBuddy  = true;
}

// ============================================================
// 7️⃣  NAMED ROUTES
//      Lives in: core/routing/routes.dart
// ============================================================

abstract class Routes {
  // ── Auth ──────────────────────────────────────────────────
  static const String welcome       = '/';
  static const String signIn        = '/sign-in';
  static const String signUp        = '/sign-up';
  static const String verification  = '/verification';
  static const String resetPassword = '/reset-password';
  static const String checkMail     = '/check-mail';
  static const String newPassword   = '/new-password';

  // ── Main shell ────────────────────────────────────────────
  static const String home          = '/home';

  // ── StudyBuddy ────────────────────────────────────────────
  static const String studyBuddy    = '/home/study-buddy';
  static const String tutors        = '/home/study-buddy/tutors';
  static const String studyGroups   = '/home/study-buddy/groups';
  static const String resources     = '/home/study-buddy/resources';
  static const String academicHelp  = '/home/study-buddy/help';

  // ── CampusMarket ──────────────────────────────────────────
  static const String market        = '/home/market';
  static const String marketBrowse  = '/home/market/browse';
  static const String marketChats   = '/home/market/chats';
  static const String myListings    = '/home/market/listings';
  static const String donations     = '/home/market/donations';

  // ── Housing Hub ───────────────────────────────────────────
  static const String housing       = '/home/housing';
  static const String housingMap    = '/home/housing/map';
  static const String roommates     = '/home/housing/roommates';
  static const String housingAlerts = '/home/housing/alerts';

  // ── EventBoard ────────────────────────────────────────────
  static const String events        = '/home/events';
  static const String eventCalendar = '/home/events/calendar';
  static const String myRsvps       = '/home/events/rsvps';
  static const String createEvent   = '/home/events/create';
}

// ============================================================
// 8️⃣  APP THEME
//      Lives in: core/theme/app_theme.dart
//      Colours derived from the UI: #667EEA brand blue,
//      off-white surfaces, Inter typography.
// ============================================================

abstract class AppTheme {
  // ── Brand palette ──────────────────────────────────────────
  static const Color brand      = Color(0xFF667EEA);
  static const Color brandDark  = Color(0xFF4A5FCC);
  static const Color brandLight = Color(0xFF8B9EF0);
  static const Color brandPale  = Color(0xFFEEF1FD);

  // ── Module accents ─────────────────────────────────────────
  static const Color terra      = Color(0xFFE07A5F); // Housing Hub
  static const Color violet     = Color(0xFF7C3AED); // EventBoard
  static const Color green      = Color(0xFF10B981); // Success/Donations
  static const Color amber      = Color(0xFFF59E0B); // Alerts/Warnings
  static const Color coral      = Color(0xFFEF4444); // Errors/Destructive

  // ── Surfaces ───────────────────────────────────────────────
  static const Color offWhite   = Color(0xFFF5F4F0);
  static const Color textPri    = Color(0xFF1A1A2E);
  static const Color textSec    = Color(0xFF555577);
  static const Color textHint   = Color(0xFF9999BB);
  static const Color border     = Color(0xFFE1E5F7);

  // ── LIGHT THEME ────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.light,
      primary: brand,
      onPrimary: Colors.white,
      secondary: terra,
      surface: offWhite,
      onSurface: textPri,
      error: coral,
    ),

    // ── Typography: Inter — matches every auth screen ────────
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textPri, letterSpacing: -0.5),
      displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textPri, letterSpacing: -0.3),
      displaySmall:  TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textPri),
      headlineLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textPri),
      headlineMedium:TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textPri),
      headlineSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPri),
      titleLarge:    TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPri),
      bodyLarge:     TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: textSec),
      bodyMedium:    TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: textSec),
      bodySmall:     TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: textHint),
      labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
      labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSec),
      labelSmall:    TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2),
    ),

    // ── AppBar — transparent over wavy blue header ──────────
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),

    // ── ElevatedButton — full-width pill (Login / Create Account) ─
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        minimumSize: const Size(double.infinity, 54),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    ),

    // ── OutlinedButton ───────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: brand,
        side: const BorderSide(color: brand, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        minimumSize: const Size(double.infinity, 54),
      ),
    ),

    // ── TextFormField — underline style (matches auth screens) ─
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: brand, width: 1.5),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: brand, width: 2.0),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: coral, width: 1.5),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: coral, width: 2.0),
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: textHint,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
    ),

    // ── Card ──────────────────────────────────────────────────
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: border, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 10),
    ),

    // ── BottomNavigationBar ───────────────────────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: brand,
      unselectedItemColor: textHint,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600,
      ),
    ),

    // ── FilterChip / Chip ─────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: offWhite,
      selectedColor: brand,
      labelStyle: const TextStyle(
        fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
      ),
      side: const BorderSide(color: border, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),

    scaffoldBackgroundColor: offWhite,

    dividerTheme: const DividerThemeData(
      color: border, thickness: 1, space: 0,
    ),
  );

  // ── DARK THEME ─────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    colorScheme: ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.dark,
      primary: brand,
      onPrimary: Colors.white,
      surface: const Color(0xFF0F1123),
      onSurface: Colors.white,
      error: coral,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F1123),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1D35),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF2A2D4A), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: const Size(double.infinity, 54),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: brand, width: 1.5),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: brand, width: 2.0),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1A1D35),
      selectedItemColor: brand,
      unselectedItemColor: Color(0xFF6B6F8E),
    ),
  );
}

// ============================================================
// 📁  RECOMMENDED FEATURE-FIRST FILE STRUCTURE
// ============================================================
//
//  lib/
//  ├── main.dart                              ← THIS FILE
//  │
//  ├── firebase_options.dart                  ← auto-generated
//  │
//  ├── core/
//  │   ├── auth/
//  │   │   ├── auth_gate.dart                 ← Route decision widget
//  │   │   └── auth_redirect.dart             ← Pure redirect helper
//  │   │
//  │   ├── constants/
//  │   │   └── app_constants.dart             ← Keys, flags, metadata
//  │   │
//  │   ├── providers/
//  │   │   ├── auth_provider.dart             ← authStateProvider
//  │   │   └── onboarding_provider.dart       ← onboardingCompleteProvider
//  │   │
//  │   ├── routing/
//  │   │   ├── app_router.dart                ← GoRouter config
//  │   │   └── routes.dart                    ← Named path constants
//  │   │
//  │   └── theme/
//  │       └── app_theme.dart                 ← Light + dark ThemeData
//  │
//  ├── features/
//  │   │
//  │   ├── auth/
//  │   │   ├── screens/
//  │   │   │   ├── welcome_screen.dart        ← Wavy hero + tagline
//  │   │   │   ├── sign_in_screen.dart        ← Email + password
//  │   │   │   ├── sign_up_screen.dart        ← Email + phone + password
//  │   │   │   ├── verification_screen.dart   ← 4-digit OTP boxes
//  │   │   │   ├── reset_password_screen.dart ← Enter email
//  │   │   │   ├── check_mail_screen.dart     ← Envelope + open mail
//  │   │   │   └── new_password_screen.dart   ← New + confirm password
//  │   │   ├── providers/
//  │   │   │   └── auth_notifier.dart         ← Login/logout/register logic
//  │   │   └── models/
//  │   │       └── campus_user.dart           ← User model
//  │   │
//  │   ├── home/
//  │   │   └── screens/
//  │   │       └── home_screen.dart           ← Bottom nav shell (ShellRoute)
//  │   │
//  │   ├── study_buddy/                       ── FR5–FR8
//  │   │   ├── screens/
//  │   │   │   ├── study_buddy_home.dart
//  │   │   │   ├── tutor_list_screen.dart
//  │   │   │   ├── tutor_profile_screen.dart
//  │   │   │   ├── study_group_screen.dart
//  │   │   │   ├── resource_library_screen.dart
//  │   │   │   └── academic_help_screen.dart
//  │   │   ├── providers/
//  │   │   │   ├── tutor_provider.dart
//  │   │   │   ├── group_provider.dart
//  │   │   │   └── resource_provider.dart
//  │   │   └── models/
//  │   │       ├── tutor.dart
//  │   │       ├── study_group.dart
//  │   │       └── resource.dart
//  │   │
//  │   ├── campus_market/                     ── CM1–CM5
//  │   │   ├── screens/
//  │   │   │   ├── market_home.dart
//  │   │   │   ├── search_screen.dart
//  │   │   │   ├── item_detail_screen.dart
//  │   │   │   ├── create_listing_screen.dart
//  │   │   │   ├── my_listings_screen.dart
//  │   │   │   ├── chat_inbox_screen.dart
//  │   │   │   ├── chat_thread_screen.dart
//  │   │   │   ├── offers_screen.dart
//  │   │   │   ├── meetup_screen.dart
//  │   │   │   ├── review_screen.dart
//  │   │   │   └── donation_hub_screen.dart
//  │   │   ├── providers/
//  │   │   │   ├── listing_provider.dart
//  │   │   │   ├── chat_provider.dart
//  │   │   │   └── offer_provider.dart
//  │   │   └── models/
//  │   │       ├── listing.dart
//  │   │       ├── message.dart
//  │   │       └── offer.dart
//  │   │
//  │   ├── housing_hub/                       ── HH1–HH4
//  │   │   ├── screens/
//  │   │   │   ├── housing_home.dart
//  │   │   │   ├── listing_detail_screen.dart
//  │   │   │   ├── post_listing_screen.dart
//  │   │   │   ├── housing_map_screen.dart
//  │   │   │   ├── roommate_match_screen.dart
//  │   │   │   ├── roommate_profile_screen.dart
//  │   │   │   └── housing_alerts_screen.dart
//  │   │   ├── providers/
//  │   │   │   ├── housing_provider.dart
//  │   │   │   └── roommate_provider.dart
//  │   │   └── models/
//  │   │       ├── housing_listing.dart
//  │   │       └── roommate_profile.dart
//  │   │
//  │   └── event_board/                       ── EB1–EB4
//  │       ├── screens/
//  │       │   ├── event_home.dart
//  │       │   ├── event_detail_screen.dart
//  │       │   ├── create_event_screen.dart
//  │       │   ├── event_calendar_screen.dart
//  │       │   ├── attendee_list_screen.dart
//  │       │   └── my_rsvps_screen.dart
//  │       ├── providers/
//  │       │   ├── event_provider.dart
//  │       │   └── rsvp_provider.dart
//  │       └── models/
//  │           ├── event.dart
//  │           └── rsvp.dart
//  │
//  ├── shared/
//  │   ├── widgets/
//  │   │   ├── wave_header.dart               ← Blue wavy SVG header
//  │   │   ├── campus_button.dart             ← Reusable ElevatedButton
//  │   │   ├── campus_text_field.dart         ← Underline TextFormField
//  │   │   ├── otp_input_row.dart             ← 4-box OTP widget
//  │   │   ├── item_card.dart                 ← Market listing card
//  │   │   ├── event_card.dart                ← EventBoard card
//  │   │   ├── house_card.dart                ← Housing listing card
//  │   │   ├── roommate_card.dart             ← Roommate match card
//  │   │   └── campus_chip.dart               ← Styled FilterChip
//  │   └── utils/
//  │       ├── validators.dart                ← Email / password rules
//  │       └── formatters.dart                ← Date, currency (KES)
//  │
//  └── l10n/                                  ← Localisation (future)
//      ├── app_en.arb                         ← English
//      └── app_sw.arb                         ← Swahili

// ============================================================
// 📦  PUBSPEC.YAML DEPENDENCIES
// ============================================================
//
//  dependencies:
//    flutter:
//      sdk: flutter
//
//    # Firebase
//    firebase_core: ^3.6.0
//    firebase_auth: ^5.3.0
//    cloud_firestore: ^5.4.0
//    firebase_storage: ^12.3.0
//    firebase_messaging: ^15.1.0        ← Event + housing alerts
//
//    # State management
//    flutter_riverpod: ^2.5.1
//    riverpod_annotation: ^2.3.5
//
//    # Navigation
//    go_router: ^14.2.7
//
//    # Local storage
//    shared_preferences: ^2.3.2
//    flutter_secure_storage: ^9.2.2     ← Auth token storage
//
//    # Network
//    dio: ^5.7.0
//
//    # Maps (Housing Hub)
//    google_maps_flutter: ^2.9.0
//    geolocator: ^13.0.1
//
//    # UI utilities
//    cached_network_image: ^3.4.1
//    flutter_svg: ^2.0.10+1
//    gap: ^3.0.1
//    shimmer: ^3.0.0                    ← Loading skeletons
//    image_picker: ^1.1.2               ← Listing photos
//
//  dev_dependencies:
//    flutter_test:
//      sdk: flutter
//    riverpod_generator: ^2.4.3
//    build_runner: ^2.4.12
//    flutter_lints: ^4.0.0
//    mocktail: ^1.0.4                   ← Unit testing
