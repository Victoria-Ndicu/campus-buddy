// auth module — auth_new_password_screen.dart
import 'package:flutter/material.dart';
import '../widgets/au_widgets.dart';
import 'auth_login_screen.dart';

class AuthNewPasswordScreen extends StatefulWidget {
  final String resetToken;
  const AuthNewPasswordScreen({super.key, this.resetToken = ''});

  @override
  State<AuthNewPasswordScreen> createState() => _AuthNewPasswordScreenState();
}

class _AuthNewPasswordScreenState extends State<AuthNewPasswordScreen> {
  final _newPassCtrl     = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _loading          = false;
  bool _success          = false;

  @override
  void dispose() { _newPassCtrl.dispose(); _confirmPassCtrl.dispose(); super.dispose(); }

  Future<void> _onReset() async {
    final pass    = _newPassCtrl.text;
    final confirm = _confirmPassCtrl.text;
    if (pass.isEmpty || confirm.isEmpty) { _snack('Please fill in both fields.'); return; }
    if (pass != confirm)                 { _snack('Passwords do not match.'); return; }
    if (pass.length < 8)                 { _snack('Password must be at least 8 characters.'); return; }

    setState(() => _loading = true);
    // TODO: call your reset-password API
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() { _loading = false; _success = true; });
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
      body: _success ? _buildSuccess(context) : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
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
                AUScreenTitle('Create new\npassword'),
                Text(
                  'Your new password must be different from the previous password.',
                  style: TextStyle(fontSize: 13, color: AUColors.text2, height: 1.65),
                ),
                const SizedBox(height: 28),
                AUInputField(label: 'New Password',     hint: 'Enter new password',    controller: _newPassCtrl,     iconEmoji: '🔒', isPassword: true),
                AUInputField(label: 'Confirm Password', hint: 'Confirm new password',  controller: _confirmPassCtrl, iconEmoji: '🔒', isPassword: true),
                const SizedBox(height: 8),
                AUPrimaryButton(label: 'Reset Password', loading: _loading, onTap: _onReset),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AUColors.brand, AUColors.brandDeep],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: const Center(child: Icon(Icons.check, color: Colors.white, size: 44)),
            ),
            const SizedBox(height: 28),
            Text('Password Reset!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AUColors.text, letterSpacing: -0.4)),
            const SizedBox(height: 10),
            Container(
              width: 48, height: 3,
              decoration: BoxDecoration(color: AUColors.brand, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text(
              'Your password has been successfully reset. You can now sign in with your new password.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AUColors.text2, height: 1.65),
            ),
            const SizedBox(height: 36),
            AUPrimaryButton(
              label: 'Back to Sign In',
              onTap: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => AuthLoginScreen()),
                (_) => false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}