import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class WaveHeader extends StatelessWidget {
  final double height;

  const WaveHeader({super.key, this.height = 220});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          // Brand background
          Container(
            width: double.infinity,
            height: height,
            color: AppColors.brand,
          ),
          // Topo lines
          Positioned.fill(
            child: CustomPaint(painter: _TopoPainter()),
          ),
          // Wave curve at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _WaveClipper(),
              child: Container(
                height: 60,
                color: AppColors.offWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw ellipses
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * 0.75, size.height * 0.4),
            width: 260,
            height: 130),
        paint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * 0.75, size.height * 0.4),
            width: 196,
            height: 100),
        paint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * 0.75, size.height * 0.4),
            width: 130,
            height: 64),
        paint);

    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * 0.2, size.height * 0.8),
            width: 220,
            height: 120),
        paint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * 0.2, size.height * 0.8),
            width: 156,
            height: 84),
        paint);

    // Organic curves
    final path1 = Path();
    path1.moveTo(0, size.height * 0.35);
    path1.quadraticBezierTo(
        size.width * 0.42, size.height * 0.18, size.width * 0.85, size.height * 0.4);
    path1.quadraticBezierTo(
        size.width * 0.93, size.height * 0.46, size.width, size.height * 0.35);
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.62);
    path2.quadraticBezierTo(
        size.width * 0.37, size.height * 0.5, size.width * 0.72, size.height * 0.65);
    path2.quadraticBezierTo(
        size.width * 0.9, size.height * 0.72, size.width, size.height * 0.62);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.4);
    path.quadraticBezierTo(
        size.width * 0.25, 0, size.width * 0.5, size.height * 0.55);
    path.quadraticBezierTo(
        size.width * 0.75, size.height, size.width, size.height * 0.3);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
