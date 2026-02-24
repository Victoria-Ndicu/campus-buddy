import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/wave_header.dart';
import '../widgets/auth_widgets.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ScreenTitle(
                        title: 'Create new\npassword',
                        fontSize: 26,
                        underlineBottomSpacing: 16,
                      ),

                      const Text(
                        'Your password must be different from the previous password.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.text2,
                          height: 1.65,
                        ),
                      ),

                      const SizedBox(height: 28),

                      UnderlineInputField(
                        label: 'New Password',
                        hint: 'Enter your password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        controller: _newPasswordController,
                      ),

                      UnderlineInputField(
                        label: 'Confirm Password',
                        hint: 'Enter your password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        controller: _confirmPasswordController,
                      ),

                      const SizedBox(height: 16),

                      PrimaryButton(
                        label: 'Reset Password',
                        onTap: () {
                          Navigator.pushNamed(context, '/reset-success');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Continue FAB ────────────────────────────────────────
          Positioned(
            bottom: 40,
            right: 28,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/reset-success'),
              child: Row(
                children: [
                  const Text(
                    'Continue',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.text3,
                        fontWeight: FontWeight.w500),
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
