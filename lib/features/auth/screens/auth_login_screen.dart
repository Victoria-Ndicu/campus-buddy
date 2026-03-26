// auth module — auth_login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/au_widgets.dart';
import 'auth_signup_screen.dart';
import 'auth_reset_screen.dart';
import 'auth_gate.dart';
import '../../home/screens/home_screen.dart';

const _baseUrl = 'https://campusbuddybackend-production.up.railway.app';

class AuthLoginScreen extends StatefulWidget {
  const AuthLoginScreen({super.key});

  @override
  State<AuthLoginScreen> createState() => _AuthLoginScreenState();
}

class _AuthLoginScreenState extends State<AuthLoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _rememberMe    = true;
  bool _loading       = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _snack('Please fill in all fields.');
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // ✅ Login success — backend returns { accessToken, refreshToken, user }
        final accessToken = data['accessToken'] ?? '';
        await authSaveToken(accessToken);

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HomeScreen()),
          (_) => false,
        );
      } else {
        // ❌ Login failed — AppError returns { code, message }
        // Handle specific error codes from services.login_user:
        //   INVALID_CREDENTIALS → wrong email or password
        //   EMAIL_NOT_VERIFIED  → account exists but OTP not done yet
        final code    = data['code']    ?? '';
        final message = data['message'] ?? data['detail'] ?? 'Login failed. Please try again.';

        if (code == 'EMAIL_NOT_VERIFIED') {
          _snack('Please verify your email before logging in.');
          // Optionally navigate back to verify screen:
          // Navigator.push(context, MaterialPageRoute(
          //   builder: (_) => AuthVerifyScreen(email: email)));
        } else {
          _snack(message);
        }
      }
    } catch (e) {
      _snack('Network error. Please check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AUColors.brandDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AUColors.offWhite,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Wave header ──────────────────────────────────
            AUWaveHeader(
              height: 240,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(children: [AULogoMark()]),
                ),
              ),
            ),

            // ── Form ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AUScreenTitle('Sign in'),

                  AUInputField(
                    label: 'Email',
                    hint: 'sarah@uon.ac.ke',
                    controller: _emailCtrl,
                    iconEmoji: '✉',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  AUInputField(
                    label: 'Password',
                    hint: 'Enter your password',
                    controller: _passwordCtrl,
                    iconEmoji: '🔒',
                    isPassword: true,
                  ),

                  // ── Remember me + Forgot Password ──────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _rememberMe = !_rememberMe),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: _rememberMe ? AUColors.brand : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AUColors.brand),
                              ),
                              child: _rememberMe
                                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text('Remember Me',
                                style: TextStyle(fontSize: 12, color: AUColors.text2)),
                          ],
                        ),
                      ),

                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AuthResetScreen()),
                        ),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AUColors.brand,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  AUPrimaryButton(
                    label: 'Login',
                    loading: _loading,
                    onTap: _onLogin,
                  ),

                  const SizedBox(height: 24),

                  AULinkRow(
                    text: "Don't have an account?",
                    linkText: 'Sign up',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AuthSignupScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}