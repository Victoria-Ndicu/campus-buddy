// auth module — auth_signup_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/au_widgets.dart';
import 'auth_verify_screen.dart';

class AuthSignupScreen extends StatefulWidget {
  const AuthSignupScreen({super.key});

  @override
  State<AuthSignupScreen> createState() => _AuthSignupScreenState();
}

class _AuthSignupScreenState extends State<AuthSignupScreen> {
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _loading       = false;

  static const _baseUrl = 'https://campusbuddybackend-production.up.railway.app';

  @override
  void dispose() {
    _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passwordCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _onCreate() async {
    final email    = _emailCtrl.text.trim();
    final phone    = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm  = _confirmCtrl.text;

    if (email.isEmpty || phone.isEmpty || password.isEmpty) { _snack('Please fill in all fields.'); return; }
    if (password != confirm) { _snack('Passwords do not match.'); return; }
    if (password.length < 8) { _snack('Password must be at least 8 characters.'); return; }

    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email':    email,
          'phone':    phone,
          'password': password,
        }),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Registration successful — go to OTP verification
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AuthVerifyScreen(email: email)),
        );
      } else {
        // Show error from backend
        final message = data['message'] ?? data['detail'] ?? 'Registration failed. Please try again.';
        _snack(message);
      }
    } catch (e) {
      if (!mounted) return;
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
            AUWaveHeader(
              height: 220,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(children: [AUBackButton()]),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AUScreenTitle('Sign up'),

                  AUInputField(label: 'Email',            hint: 'sarah@uon.ac.ke',     controller: _emailCtrl,    iconEmoji: '✉', keyboardType: TextInputType.emailAddress),
                  AUInputField(label: 'Phone no',         hint: '+254 700 000 000',    controller: _phoneCtrl,    iconEmoji: '📱', keyboardType: TextInputType.phone),
                  AUInputField(label: 'Password',         hint: 'Create a password',   controller: _passwordCtrl, iconEmoji: '🔒', isPassword: true),
                  AUInputField(label: 'Confirm Password', hint: 'Confirm password',    controller: _confirmCtrl,  iconEmoji: '🔒', isPassword: true),

                  const SizedBox(height: 4),

                  AUPrimaryButton(label: 'Create Account', loading: _loading, onTap: _onCreate),

                  const SizedBox(height: 24),

                  AULinkRow(
                    text: 'Already have an account?',
                    linkText: 'Login',
                    onTap: () => Navigator.pop(context),
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