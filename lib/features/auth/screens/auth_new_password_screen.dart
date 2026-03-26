// auth module — auth_new_password_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../widgets/au_widgets.dart';
import 'auth_login_screen.dart';

const _baseUrl = 'https://campusbuddybackend-production.up.railway.app';

class AuthNewPasswordScreen extends StatefulWidget {
  final String email;
  const AuthNewPasswordScreen({super.key, this.email = ''});

  @override
  State<AuthNewPasswordScreen> createState() => _AuthNewPasswordScreenState();
}

class _AuthNewPasswordScreenState extends State<AuthNewPasswordScreen> {
  // OTP controllers
  final _otpControllers = List.generate(4, (_) => TextEditingController());
  final _otpFocusNodes  = List.generate(4, (_) => FocusNode());

  // Password controllers
  final _newPassCtrl     = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _loading = false;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _otpFocusNodes[0].requestFocus(),
    );
  }

  @override
  void dispose() {
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 3) _otpFocusNodes[index + 1].requestFocus();
    if (value.isEmpty && index > 0)     _otpFocusNodes[index - 1].requestFocus();
    setState(() {});
  }

  Future<void> _onReset() async {
    final code    = _otp;
    final pass    = _newPassCtrl.text;
    final confirm = _confirmPassCtrl.text;

    if (code.length < 4) {
      _snack('Please enter the 4-digit reset code.');
      return;
    }
    if (pass.isEmpty || confirm.isEmpty) {
      _snack('Please fill in both password fields.');
      return;
    }
    if (pass != confirm) {
      _snack('Passwords do not match.');
      return;
    }
    if (pass.length < 8) {
      _snack('Password must be at least 8 characters.');
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/auth/reset-password/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email':       widget.email,
          'code':        code,
          'newPassword': pass,
        }),
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // ✅ Password reset — show success state
        setState(() => _success = true);
      } else {
        // ❌ Wrong/expired code or validation error
        // AppError returns { code, message }
        final code_   = data['code']    ?? '';
        final message = data['message'] ?? data['detail'] ?? 'Something went wrong. Please try again.';

        if (code_ == 'INVALID_OTP') {
          _snack('Incorrect or expired reset code. Please try again.');
          // Clear OTP boxes so user can re-enter
          for (final c in _otpControllers) c.clear();
          setState(() {});
          _otpFocusNodes[0].requestFocus();
        } else if (code_ == 'OTP_MAX_ATTEMPTS') {
          _snack('Too many failed attempts. Please request a new reset code.');
          // Send them back to the reset screen
          if (mounted) Navigator.pop(context);
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
      body: _success ? _buildSuccess(context) : _buildForm(context),
    );
  }

  // ── Form: enter code + new password ──────────────────────
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
                  'Enter the code sent to ${widget.email} and choose a new password.',
                  style: TextStyle(
                      fontSize: 13, color: AUColors.text2, height: 1.65),
                ),

                const SizedBox(height: 28),

                // ── Reset code label ────────────────────────
                Text(
                  'Reset Code',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AUColors.text,
                  ),
                ),
                const SizedBox(height: 10),

                // ── OTP boxes ───────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List.generate(4, (i) {
                    return Container(
                      width: 62, height: 62,
                      margin: EdgeInsets.only(left: i == 0 ? 0 : 10),
                      decoration: BoxDecoration(
                        color: _otpControllers[i].text.isNotEmpty
                            ? AUColors.brandPale
                            : AUColors.offWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _otpFocusNodes[i].hasFocus
                              ? AUColors.brand
                              : AUColors.border,
                          width: 2,
                        ),
                      ),
                      child: TextField(
                        controller: _otpControllers[i],
                        focusNode: _otpFocusNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AUColors.brand),
                        decoration: const InputDecoration(
                            border: InputBorder.none, counterText: ''),
                        onChanged: (v) => _onOtpChanged(i, v),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                // ── New password fields ─────────────────────
                AUInputField(
                  label: 'New Password',
                  hint: 'Enter new password',
                  controller: _newPassCtrl,
                  iconEmoji: '🔒',
                  isPassword: true,
                ),

                AUInputField(
                  label: 'Confirm Password',
                  hint: 'Confirm new password',
                  controller: _confirmPassCtrl,
                  iconEmoji: '🔒',
                  isPassword: true,
                ),

                const SizedBox(height: 8),

                AUPrimaryButton(
                  label: 'Reset Password',
                  loading: _loading,
                  onTap: _onReset,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Success state ─────────────────────────────────────────
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
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(Icons.check, color: Colors.white, size: 44),
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Password Reset!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AUColors.text,
                letterSpacing: -0.4,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: 48, height: 3,
              decoration: BoxDecoration(
                color: AUColors.brand,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Your password has been successfully reset. You can now sign in with your new password.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AUColors.text2, height: 1.65),
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