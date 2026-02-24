import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../widgets/wave_header.dart';
import '../widgets/auth_widgets.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  bool get _isFilled => _controllers.every((c) => c.text.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Stack(
        children: [
          Column(
            children: [
              // ── Wave header with label ───────────────────────────
              Stack(
                children: [
                  const WaveHeader(height: 210),
                  Positioned(
                    top: 14,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Center(
                        child: Text(
                          'Verification',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.85),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Content ─────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ScreenTitle(
                        title: 'Enter your\nVerification Code',
                        fontSize: 27,
                        underlineBottomSpacing: 30,
                      ),

                      // ── OTP boxes ─────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          return Padding(
                            padding: EdgeInsets.only(
                                right: index < 3 ? 14 : 0),
                            child: _OtpBox(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              onChanged: (v) => _onDigitChanged(index, v),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        "We've sent a verification code to your email address.",
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.text2,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Please check your inbox (and spam folder).',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.text2,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        "Didn't receive the code?",
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.text2,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Resend logic
                        },
                        child: const Text(
                          'Resend code',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brand,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      PrimaryButton(
                        label: 'Verify',
                        onTap: _isFilled
                            ? () {
                                // Navigate after successful verification
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Continue FAB ──────────────────────────────────────────
          Positioned(
            bottom: 40,
            right: 28,
            child: GestureDetector(
              onTap: () {
                // continue action
              },
              child: Row(
                children: [
                  const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.text3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand.withOpacity(0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_forward,
                        color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ),

          const Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: HomeIndicator(),
          ),
        ],
      ),
    );
  }
}

// ── OTP Box widget ─────────────────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: controller.text.isNotEmpty
            ? AppColors.brandPale
            : AppColors.offWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brand, width: 2),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
        ),
        onChanged: onChanged,
      ),
    );
  }
}
