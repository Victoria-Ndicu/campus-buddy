import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Stack(
        children: [
          Column(
            children: [
              // ── Tall wave header ──────────────────────────────────
              Expanded(
                flex: 55,
                child: Stack(
                  children: [
                    Container(color: AppColors.brand),
                    Positioned.fill(child: CustomPaint(painter: _WelcomeTopoPainter())),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: ClipPath(
                        clipper: _WelcomeWaveClipper(),
                        child: Container(height: 80, color: AppColors.offWhite),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Content ───────────────────────────────────────────
              Expanded(
                flex: 45,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.text2,
                            height: 1.65,
                          ),
                          children: [
                            const TextSpan(
                                text: 'Everything you need for campus life — '),
                            TextSpan(
                              text:
                                  'study support, housing, events,',
                              style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w600),
                            ),
                            const TextSpan(text: ' and a '),
                            TextSpan(
                              text: 'student marketplace',
                              style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w600),
                            ),
                            const TextSpan(
                                text: ' — all in one trusted platform.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Continue FAB ───────────────────────────────────────────
          Positioned(
            bottom: 40,
            right: 28,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/login'),
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

          // ── Home Indicator ─────────────────────────────────────────
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

// ── Custom Painters ────────────────────────────────────────────────────────

class _WelcomeTopoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Multiple ellipse clusters like the HTML
    for (final r in [140.0, 110.0, 80.0, 50.0]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(size.width * 0.32, size.height * 0.23),
              width: r * 2,
              height: r * 1.4),
          paint);
    }
    for (final r in [130.0, 100.0, 68.0]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(size.width * 0.8, size.height * 0.5),
              width: r * 2,
              height: r * 1.6),
          paint);
    }
    for (final r in [110.0, 80.0, 52.0]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(size.width * 0.21, size.height * 0.68),
              width: r * 2,
              height: r * 1.4),
          paint);
    }

    // Organic path lines
    final p1 = Path()
      ..moveTo(size.width * 0.08, size.height * 0.36)
      ..cubicTo(size.width * 0.24, size.height * 0.27, size.width * 0.4,
          size.height * 0.39, size.width * 0.72, size.height * 0.36)
      ..cubicTo(size.width * 0.88, size.height * 0.23, size.width,
          size.height * 0.32, size.width, size.height * 0.32);
    canvas.drawPath(p1, paint);

    final p2 = Path()
      ..moveTo(0, size.height * 0.45)
      ..cubicTo(size.width * 0.16, size.height * 0.36, size.width * 0.32,
          size.height * 0.45, size.width * 0.64, size.height * 0.43)
      ..cubicTo(size.width * 0.8, size.height * 0.54, size.width,
          size.height * 0.41, size.width, size.height * 0.41);
    canvas.drawPath(p2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WelcomeWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(
        size.width * 0.21, size.height, size.width * 0.5, size.height * 0.69);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.44, size.width, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
