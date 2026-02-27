// auth module — auth_login_screen.dart
import 'package:flutter/material.dart';
import '../widgets/au_widgets.dart';
import 'auth_signup_screen.dart';
import 'auth_reset_screen.dart';
import 'auth_gate.dart';
import '../../home/screens/home_screen.dart';

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
  void dispose() { _emailCtrl.dispose(); _passwordCtrl.dispose(); super.dispose(); }

  Future<void> _onLogin() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) { _snack('Please fill in all fields.'); return; }

    setState(() => _loading = true);

    // TODO: replace with your real API call
    await Future.delayed(const Duration(milliseconds: 1200));
    await authSaveToken('mock_token_${email.hashCode}');

    if (!mounted) return;
    setState(() => _loading = false);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeScreen()),
      (_) => false,
    );
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
            // Wave header
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

            // Form
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

                  // Remember me + Forgot
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _rememberMe = !_rememberMe),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 18, height: 18,
                              decoration: BoxDecoration(
                                color: _rememberMe ? AUColors.brand : Colors.transparent,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: AUColors.brand),
                              ),
                              child: _rememberMe
                                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text('Remember Me', style: TextStyle(fontSize: 12, color: AUColors.text2)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AuthResetScreen())),
                        child: Text('Forgot Password?',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AUColors.brand)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  AUPrimaryButton(label: 'Login', loading: _loading, onTap: _onLogin),

                  const SizedBox(height: 24),

                  AULinkRow(
                    text: "Don't have an account?",
                    linkText: 'Sign up',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AuthSignupScreen())),
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