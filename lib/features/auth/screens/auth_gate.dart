// auth module — auth_gate.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_splash_screen.dart';
import 'auth_login_screen.dart';
import '../../home/screens/home_screen.dart';

// ─────────────────────────────────────────────────────────────
//  Token helpers — call from anywhere in the app
// ─────────────────────────────────────────────────────────────
const _kTokenKey = 'auth_token';

Future<void> authSaveToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kTokenKey, token);
}

Future<String?> authReadToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_kTokenKey);
}

Future<void> authClearToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kTokenKey);
}

// ─────────────────────────────────────────────────────────────
//  AuthGate — cold-start router
// ─────────────────────────────────────────────────────────────
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _decideRoute();
  }

  Future<void> _decideRoute() async {
    // Keep splash visible for minimum duration
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final token = await authReadToken();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => (token != null && token.isNotEmpty)
            ? HomeScreen()
            : AuthLoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const AuthSplashScreen();
}