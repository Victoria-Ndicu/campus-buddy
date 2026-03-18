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
              padding: const EdgeInsets.fromLTRB(28, 48, 28, 40),
              child: Column(
                children: [
                  // Envelope icon — matches HTML SVG design
                  Container(
                    width: 88,
                    height: 88,
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

                  const SizedBox(height: 28),

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

                  Text(
                    'We have sent password recovery\ninstructions to your email.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AUColors.text2,
                      height: 1.65,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Open mail button
                  AUPrimaryButton(
                    label: 'Open mail',
                    onTap: () {
                      // TODO: use url_launcher to open mail app
                      // launchUrl(Uri.parse('mailto:'));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text('Opening mail app…'),
                        backgroundColor: AUColors.brand,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ));
                    },
                  ),

                  const SizedBox(height: 20),

                  // "Did not receive" + "try another email"
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                          fontSize: 12, color: AUColors.text2, height: 1.7),
                      children: [
                        const TextSpan(
                            text: 'Did not receive the email? Check spam folder, or '),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'try another email address.',
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

                  const SizedBox(height: 32),

                  // Skip ahead to new password (for testing / deep link)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AuthNewPasswordScreen()),
                    ),
                    child: Text(
                      'I have a reset code →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AUColors.brand,
                      ),
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

// ── Envelope painter matching HTML SVG ────────────────────────
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

    // Flap V from top corners to center
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