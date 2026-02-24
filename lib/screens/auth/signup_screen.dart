import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/wave_header.dart';
import '../widgets/auth_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Wave header ──────────────────────────────────────
                const WaveHeader(height: 220),

                // ── Form content ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ScreenTitle(title: 'Sign up'),

                      // Email
                      UnderlineInputField(
                        label: 'Email',
                        hint: 'you@university.edu',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                      ),

                      // Phone number
                      UnderlineInputField(
                        label: 'Phone no',
                        hint: '+00 000-0000-000',
                        icon: Icons.phone_android,
                        keyboardType: TextInputType.phone,
                        controller: _phoneController,
                      ),

                      // Password
                      UnderlineInputField(
                        label: 'Password',
                        hint: 'Enter your password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        controller: _passwordController,
                      ),

                      // Confirm Password
                      UnderlineInputField(
                        label: 'Confirm Password',
                        hint: 'Confirm your password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        controller: _confirmPasswordController,
                      ),

                      // Create Account button
                      PrimaryButton(
                        label: 'Create Account',
                        onTap: () {
                          Navigator.pushNamed(context, '/verification');
                        },
                      ),

                      const SizedBox(height: 16),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an Account! ',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.text2),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/login'),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brand,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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
