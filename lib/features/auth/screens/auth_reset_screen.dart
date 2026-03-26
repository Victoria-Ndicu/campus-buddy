// auth module — auth_reset_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/au_widgets.dart';
import 'auth_check_mail_screen.dart';

const _baseUrl = 'https://campusbuddybackend-production.up.railway.app';

class AuthResetScreen extends StatefulWidget {
  const AuthResetScreen({super.key});

  @override
  State<AuthResetScreen> createState() => _AuthResetScreenState();
}

class _AuthResetScreenState extends State<AuthResetScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading    = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _snack('Please enter your email address.');
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/auth/forgot-password/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (!mounted) return;

      // ✅ Backend always returns 200 regardless of whether email exists
      // (intentional — prevents email enumeration attacks)
      // So we always navigate forward with a generic message.
      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AuthCheckMailScreen(email: email),
          ),
        );
      } else {
        // Only show error on genuine server failures (500, 422, etc.)
        final data = jsonDecode(response.body);
        _snack(data['message'] ?? data['detail'] ?? 'Something went wrong. Please try again.');
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
              height: 200,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(children: [AUBackButton()]),
                ),
              ),
            ),

            // ── Form ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AUScreenTitle('Reset password'),

                  Text(
                    'Enter the email linked to your CampusBuddy account.\n\nIf an account exists, you\'ll receive a reset code shortly.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AUColors.text2,
                      height: 1.65,
                    ),
                  ),

                  const SizedBox(height: 28),

                  AUInputField(
                    label: 'Email',
                    hint: 'sarah@uon.ac.ke',
                    controller: _emailCtrl,
                    iconEmoji: '✉',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 8),

                  AUPrimaryButton(
                    label: 'Send Instructions',
                    loading: _loading,
                    onTap: _onSend,
                  ),

                  const SizedBox(height: 24),

                  AULinkRow(
                    text: 'Remember your password?',
                    linkText: 'Sign in',
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