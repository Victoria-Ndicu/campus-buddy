// auth module — auth_splash_screen.dart
import 'package:flutter/material.dart';
import '../widgets/au_widgets.dart';

class AuthSplashScreen extends StatefulWidget {
  const AuthSplashScreen({super.key});

  @override
  State<AuthSplashScreen> createState() => _AuthSplashScreenState();
}

class _AuthSplashScreenState extends State<AuthSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [AUColors.brand, AUColors.brandDeep],
          ),
        ),
        child: CustomPaint(
          painter: _SplashBgPainter(),
          child: SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo ring
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                        ),
                        child: Center(
                          child: Container(
                            width: 64, height: 64,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFFCC1616), Color(0xFFA80F0F)],
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Text('C', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Wordmark
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          children: [
                            TextSpan(text: 'Campus', style: TextStyle(color: Colors.white)),
                            TextSpan(text: 'Buddy',  style: TextStyle(color: Color(0xFFFFD580))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your campus life, simplified.',
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.70), fontWeight: FontWeight.w500, letterSpacing: 0.3),
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: 28, height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.6)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = Colors.white.withOpacity(0.07)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    for (double r = 80; r <= 260; r += 60) canvas.drawCircle(Offset(s.width * 0.85, s.height * 0.15), r, p);
    for (double r = 60; r <= 200; r += 50) canvas.drawCircle(Offset(s.width * 0.12, s.height * 0.85), r, p);
  }
  @override bool shouldRepaint(_) => false;
}