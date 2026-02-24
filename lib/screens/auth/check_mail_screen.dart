import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/wave_header.dart';
import '../widgets/auth_widgets.dart';

class CheckMailScreen extends StatelessWidget {
  const CheckMailScreen({super.key});

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
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── Mail icon ──────────────────────────────
                      const SizedBox(height: 10),
                      CustomPaint(
                        size: const Size(72, 56),
                        painter: _EnvelopePainter(),
                      ),
                      const SizedBox(height: 26),

                      // Title
                      const Text(
                        'Check your mail',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'We have sent password recovery\ninstruction to your email.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.text2,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Open mail button
                      PrimaryButton(
                        label: 'Open mail',
                        onTap: () {
                          // Open mail app or OS intent
                        },
                      ),

                      const SizedBox(height: 8),

                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.text2,
                            height: 1.6,
                          ),
                          children: [
                            const TextSpan(
                                text:
                                    'Did not receive the email? Check spam folder.\nor '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  'try another email address.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.brand,
                                    fontWeight: FontWeight.w700,
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
              ),
            ],
          ),

          // ── Continue FAB ────────────────────────────────────────
          Positioned(
            bottom: 40,
            right: 28,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/new-password'),
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

// ── Envelope icon painter ──────────────────────────────────────────────────

class _EnvelopePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.text
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Envelope rect
    final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(4));
    canvas.drawRRect(rect, paint);

    // Diagonal lines (V shape at top)
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height * 0.57)
      ..lineTo(size.width, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
