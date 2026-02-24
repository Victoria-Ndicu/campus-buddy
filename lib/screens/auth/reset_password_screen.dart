import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/wave_header.dart';
import '../widgets/auth_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Stack(
        children: [
          Column(
            children: [
              // ── Wave header ─────────────────────────────────────
              const WaveHeader(height: 200),

              // ── Content ─────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ScreenTitle(
                        title: 'Reset\npassword',
                        fontSize: 28,
                        underlineBottomSpacing: 22,
                      ),

                      const Text(
                        "Enter the email linked to your CampusBuddy account.\n\nWe'll send you a link to reset your password.",
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.text2,
                          height: 1.65,
                        ),
                      ),

                      const SizedBox(height: 28),

                      UnderlineInputField(
                        label: 'Email',
                        hint: 'you@university.edu',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                      ),

                      const SizedBox(height: 16),

                      PrimaryButton(
                        label: 'Send Instructions',
                        onTap: () {
                          Navigator.pushNamed(context, '/check-mail');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
