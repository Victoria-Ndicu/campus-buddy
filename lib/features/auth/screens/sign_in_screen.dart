import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/wave_header.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                // ── Wave header ─────────────────────────────────────
                const WaveHeader(height: 240),

                // ── Form content ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ScreenTitle(title: 'Sign in'),

                      // Email
                      UnderlineInputField(
                        label: 'Email',
                        hint: 'you@university.edu',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                      ),

                      // Password
                      UnderlineInputField(
                        label: 'Password',
                        hint: 'Enter your password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        controller: _passwordController,
                      ),

                      // Remember me + Forgot password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _rememberMe = !_rememberMe),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _rememberMe
                                        ? AppColors.brand
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: AppColors.brand, width: 1.5),
                                  ),
                                  child: _rememberMe
                                      ? const Icon(Icons.check,
                                          size: 11, color: Colors.white)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Remember Me',
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.text2),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/reset-password'),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brand,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Login button
                      PrimaryButton(
                        label: 'Login',
                        onTap: () {
                          // Handle login logic
                        },
                      ),

                      const SizedBox(height: 16),

                      // Sign up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an Account? ",
                            style: TextStyle(
                                fontSize: 13, color: AppColors.text2),
                          ),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/signup'),
                            child: const Text(
                              'Sign up',
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

          // ── Home Indicator ───────────────────────────────────────
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
