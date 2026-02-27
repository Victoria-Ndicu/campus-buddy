// auth module — auth_reset_screen.dart
import 'package:flutter/material.dart';
import '../widgets/au_widgets.dart';
import 'auth_check_mail_screen.dart';

class AuthResetScreen extends StatefulWidget {
  const AuthResetScreen({super.key});

  @override
  State<AuthResetScreen> createState() => _AuthResetScreenState();
}

class _AuthResetScreenState extends State<AuthResetScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading    = false;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _onSend() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) { _snack('Please enter your email address.'); return; }

    setState(() => _loading = true);
    // TODO: call your password-reset API
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _loading = false);

    Navigator.push(context, MaterialPageRoute(builder: (_) => AuthCheckMailScreen(email: email)));
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
              height: 200,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(children: [AUBackButton()]),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AUScreenTitle('Reset password'),

                  Text(
                    'Enter the email linked to your CampusBuddy account.\n\nWe\'ll send you a link to reset your password.',
                    style: TextStyle(fontSize: 13, color: AUColors.text2, height: 1.65),
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

                  AUPrimaryButton(label: 'Send Instructions', loading: _loading, onTap: _onSend),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}