// auth module — auth_verify_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../widgets/au_widgets.dart';
import 'auth_gate.dart';
import '../../home/screens/home_screen.dart';

const _baseUrl = 'https://campusbuddybackend-production-3d8a.up.railway.app';

class AuthVerifyScreen extends StatefulWidget {
  final String email;
  const AuthVerifyScreen({super.key, this.email = ''});

  @override
  State<AuthVerifyScreen> createState() => _AuthVerifyScreenState();
}

class _AuthVerifyScreenState extends State<AuthVerifyScreen> {
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _focusNodes  = List.generate(4, (_) => FocusNode());
  bool _loading      = false;
  bool _resending    = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNodes[0].requestFocus());
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 3) _focusNodes[index + 1].requestFocus();
    if (value.isEmpty && index > 0)     _focusNodes[index - 1].requestFocus();
    setState(() {});
    if (_otp.length == 4) _onVerify();
  }

  /// Calls POST /api/v1/auth/verify-otp/
  Future<void> _onVerify() async {
    if (_otp.length < 4) { _snack('Please enter the full 4-digit code.'); return; }
    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/auth/verify-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'code': _otp,
        }),
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // ✅ OTP correct — save tokens and go home
        // Backend returns: { accessToken, refreshToken, user }
        final accessToken  = data['accessToken']  ?? '';
        final refreshToken = data['refreshToken'] ?? '';
        await authSaveToken(accessToken);
        // Uncomment when you add authSaveRefreshToken to auth_gate.dart:
        // await authSaveRefreshToken(refreshToken);

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HomeScreen()),
          (_) => false,
        );
      } else {
        // ❌ Wrong OTP or expired — show error and clear boxes
        // AppError returns: { code: "INVALID_OTP", message: "..." }
        final message = data['message']
            ?? data['detail']
            ?? data['error']
            ?? 'Invalid or expired code. Please try again.';
        _snack(message);
        _clearOtp();
      }
    } catch (e) {
      _snack('Network error. Please check your connection.');
      _clearOtp();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Calls POST /api/v1/auth/request-otp/ to resend the code
  Future<void> _resendOtp() async {
    if (_resending) return;
    setState(() => _resending = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/auth/request-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        _snack('A new code has been sent to ${widget.email}');
        _clearOtp();
        _focusNodes[0].requestFocus();
      } else {
        final data = jsonDecode(response.body);
        _snack(data['message'] ?? data['detail'] ?? 'Could not resend code.');
      }
    } catch (e) {
      _snack('Network error. Please check your connection.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _clearOtp() {
    for (final c in _controllers) c.clear();
    setState(() {});
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
              height: 210,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AUBackButton(),
                      const SizedBox(height: 8),
                      Text('Verification',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.75))),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AUScreenTitle('Enter your\nVerification Code'),

                  // Email hint
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      'Code sent to ${widget.email}',
                      style: TextStyle(fontSize: 13, color: AUColors.text2),
                    ),
                  ),

                  // OTP boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      return Container(
                        width: 56, height: 56,
                        margin: EdgeInsets.only(left: i == 0 ? 0 : 10),                       
                        decoration: BoxDecoration(
                          color: _controllers[i].text.isNotEmpty
                              ? AUColors.brandPale
                              : AUColors.offWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _focusNodes[i].hasFocus
                                ? AUColors.brand
                                : AUColors.border,
                            width: 2,
                          ),
                        ),
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AUColors.brand),
                          decoration: const InputDecoration(
                              border: InputBorder.none, counterText: ''),
                          onChanged: (v) => _onOtpChanged(i, v),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 28),

                  Text("We've sent a verification code to your email address.",
                      style: TextStyle(
                          fontSize: 13, color: AUColors.text2, height: 1.6)),
                  const SizedBox(height: 4),
                  Text('Please check your inbox (and spam folder).',
                      style: TextStyle(fontSize: 13, color: AUColors.text2)),

                  const SizedBox(height: 20),

                  Text("Didn't receive the code?",
                      style: TextStyle(fontSize: 13, color: AUColors.text2)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _resending ? null : _resendOtp,
                    child: _resending
                        ? SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AUColors.brand),
                          )
                        : Text('Resend code',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AUColors.brand)),
                  ),

                  const SizedBox(height: 32),

                  AUPrimaryButton(
                      label: 'Verify', loading: _loading, onTap: _onVerify),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}