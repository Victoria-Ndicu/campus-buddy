// auth module — auth_check_mail_screen.dart
import 'package:flutter/material.dart';
import '../widgets/au_widgets.dart';
import 'auth_new_password_screen.dart';

class AuthCheckMailScreen extends StatelessWidget {
  final String email;
  const AuthCheckMailScreen({super.key, this.email = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AUColors.offWhite,
      body: SingleChildScrollView(
        child: Column(
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

            // ── Content ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 56, 28, 40),
              child: Column(
                children: [
                  // Envelope icon
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AUColors.brandPale,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CustomPaint(
                        size: const Size(52, 40),
                        painter: _EnvelopePainter(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Check your mail',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AUColors.text,
                      letterSpacing: -0.4,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    width: 48,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AUColors.brand,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Show the email address they used
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                          fontSize: 13, color: AUColors.text2, height: 1.65),
                      children: [
                        const TextSpan(
                            text: 'We sent a password reset code to\n'),
                        TextSpan(
                          text: email,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AUColors.text,
                          ),
                        ),
                        const TextSpan(
                            text: '\n\nPlease check your inbox and spam folder.'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Primary CTA — go enter the code
                  AUPrimaryButton(
                    label: 'Enter reset code',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AuthNewPasswordScreen(email: email),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Did not receive
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                          fontSize: 12, color: AUColors.text2, height: 1.7),
                      children: [
                        const TextSpan(
                            text: 'Didn\'t receive the email? '),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Try another address.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AUColors.brand,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

// ── Envelope painter ──────────────────────────────────────────
class _EnvelopePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = AUColors.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Envelope body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, s.width, s.height), const Radius.circular(4)),
      p,
    );

    // Flap V
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(s.width / 2, s.height * 0.6)
        ..lineTo(s.width, 0),
      p,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}