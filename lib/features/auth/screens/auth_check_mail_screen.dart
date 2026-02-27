// auth module — auth_check_mail_screen.dart
import 'package:flutter/material.dart';
import '../widgets/au_widgets.dart';

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
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 40),
              child: Column(
                children: [
                  // Mail icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: AUColors.brandPale, shape: BoxShape.circle),
                    child: CustomPaint(size: const Size(56, 44), painter: _MailIconPainter()),
                  ),

                  const SizedBox(height: 28),

                  Text('Check your mail',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AUColors.text, letterSpacing: -0.4)),

                  const SizedBox(height: 12),

                  Container(
                    width: 48, height: 3,
                    decoration: BoxDecoration(color: AUColors.brand, borderRadius: BorderRadius.circular(2)),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'We have sent password recovery instructions to your email.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AUColors.text2, height: 1.65),
                  ),

                  const SizedBox(height: 32),

                  AUPrimaryButton(
                    label: 'Open mail',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Opening mail app…'),
                      backgroundColor: AUColors.brand,   // TODO: use url_launcher
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    )),
                  ),

                  const SizedBox(height: 20),

                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(fontSize: 12, color: AUColors.text2, height: 1.7),
                      children: [
                        const TextSpan(text: 'Did not receive the email? Check spam or '),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text('try another email address.',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AUColors.brand)),
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

class _MailIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = AUColors.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s.width, s.height), const Radius.circular(4)), p);
    canvas.drawPath(Path()..moveTo(0, 0)..lineTo(s.width / 2, s.height * 0.58)..lineTo(s.width, 0), p);
  }
  @override bool shouldRepaint(_) => false;
}