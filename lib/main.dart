// ============================================================
//  CampusBuddy — main.dart  (Setup Check / Splash)
//
//  PURPOSE: Verify your Flutter environment is wired up
//  correctly before adding Firebase, Riverpod, or routing.
//
//  Zero external dependencies — runs with a brand-new
//  flutter create project out of the box.
//
//  When ready to go full-app, replace SplashScreen() with
//  your CampusBuddyApp() that has routing + Firebase.
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────
//  ENTRY POINT
// ─────────────────────────────────────────────────────────────
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // White status-bar icons on the blue background
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Portrait only
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const _SetupCheckApp());
}

// ─────────────────────────────────────────────────────────────
//  ROOT  — no Router, no Firebase, no state management
// ─────────────────────────────────────────────────────────────
class _SetupCheckApp extends StatelessWidget {
  const _SetupCheckApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CampusBuddy',
      home: _SplashScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SPLASH SCREEN
// ─────────────────────────────────────────────────────────────
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with TickerProviderStateMixin {

  // ── Controllers ────────────────────────────────────────────
  late final AnimationController _bgCtrl;
  late final AnimationController _logoCtrl;
  late final AnimationController _ringCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _dotsCtrl;

  // ── Animations ─────────────────────────────────────────────
  late final Animation<double> _bgFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _ringSpin;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _dotsFade;

  // ── Brand colours ──────────────────────────────────────────
  static const Color _blue  = Color(0xFF667EEA);
  static const Color _dark  = Color(0xFF4A5FCC);
  static const Color _red   = Color(0xFFCC1616);

  @override
  void initState() {
    super.initState();

    // Background fade-in
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn);

    // Logo pop  (scale 0 → 1.1 → 1.0) + slide up
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
    ]).animate(_logoCtrl);
    _logoFade  = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn);
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));

    // Spinning gradient ring — loops forever
    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _ringSpin = Tween<double>(begin: 0, end: 2 * math.pi).animate(_ringCtrl);

    // Tagline slide-up
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _textFade  = CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    // Loading dots fade-in
    _dotsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _dotsFade = CurvedAnimation(parent: _dotsCtrl, curve: Curves.easeIn);

    // Staggered sequence
    _bgCtrl.forward();
    Future.delayed(const Duration(milliseconds: 180),
        () { if (mounted) _logoCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 700),
        () { if (mounted) _textCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 1000),
        () { if (mounted) _dotsCtrl.forward(); });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _ringCtrl.dispose();
    _textCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: FadeTransition(
        opacity: _bgFade,
        child: Container(
          // ── Blue gradient background ──────────────────────
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8096F0), _blue, _dark],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [

              // ── Topographic lines ──────────────────────────
              CustomPaint(
                size: size,
                painter: _TopoPainter(),
              ),

              // ── Soft blobs for depth ───────────────────────
              Positioned(top: -70, right: -70,
                child: _Blob(260, Colors.white.withOpacity(0.06))),
              Positioned(bottom: 60, left: -90,
                child: _Blob(300, Colors.white.withOpacity(0.04))),

              // ── Centre stack ───────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Spinning ring + logo card
                    SizedBox(
                      width: 210, height: 210,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [

                          // Outer animated ring
                          AnimatedBuilder(
                            animation: _ringSpin,
                            builder: (_, __) => Transform.rotate(
                              angle: _ringSpin.value,
                              child: CustomPaint(
                                size: const Size(210, 210),
                                painter: _RingPainter(),
                              ),
                            ),
                          ),

                          // Static inner ring
                          Container(
                            width: 158, height: 158,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                                width: 1.5,
                              ),
                            ),
                          ),

                          // Logo
                          SlideTransition(
                            position: _logoSlide,
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: FadeTransition(
                                opacity: _logoFade,
                                child: _LogoCard(red: _red, blue: _blue),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 38),

                    // App name  "Campus Buddy"
                    SlideTransition(
                      position: _textSlide,
                      child: FadeTransition(
                        opacity: _textFade,
                        child: Column(
                          children: [
                            RichText(
                              text: const TextSpan(children: [
                                TextSpan(
                                  text: 'Campus',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Buddy',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFCDD8FF),
                                    letterSpacing: -1,
                                  ),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your campus. Simplified.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.60),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 56),

                    // Pulsing dots
                    FadeTransition(
                      opacity: _dotsFade,
                      child: const _PulsingDots(),
                    ),
                  ],
                ),
              ),

              // ── Version — bottom ───────────────────────────
              Positioned(
                bottom: 38, left: 0, right: 0,
                child: FadeTransition(
                  opacity: _dotsFade,
                  child: Text(
                    'v1.0.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.30),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  LOGO CARD   — white circle with red Campus + blue Buddy
// ─────────────────────────────────────────────────────────────
class _LogoCard extends StatelessWidget {
  final Color red;
  final Color blue;
  const _LogoCard({required this.red, required this.blue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140, height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: blue.withOpacity(0.28),
            blurRadius: 48,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Graduation cap
          CustomPaint(
            size: const Size(24, 17),
            painter: _GradCapPainter(color: red),
          ),

          const SizedBox(height: 3),

          // "Campus" — big C + smaller text
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: 'C',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: red,
                  height: 1,
                ),
              ),
              TextSpan(
                text: 'ampus',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: red,
                  height: 1,
                ),
              ),
            ]),
          ),

          const SizedBox(height: 3),

          // "Buddy"
          Text(
            'Buddy',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: blue,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CUSTOM PAINTERS
// ─────────────────────────────────────────────────────────────

/// Graduation cap — flat-top diamond + tassel
class _GradCapPainter extends CustomPainter {
  final Color color;
  const _GradCapPainter({required this.color});

  @override
  void paint(Canvas canvas, Size s) {
    final fill = Paint()..color = color..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Board
    canvas.drawPath(
      Path()
        ..moveTo(0, s.height * 0.45)
        ..lineTo(s.width * 0.5, 0)
        ..lineTo(s.width, s.height * 0.45)
        ..lineTo(s.width * 0.5, s.height * 0.78)
        ..close(),
      fill,
    );

    // Tassel
    canvas.drawLine(
      Offset(s.width * 0.78, s.height * 0.45),
      Offset(s.width * 0.78, s.height),
      stroke,
    );
    canvas.drawCircle(Offset(s.width * 0.78, s.height), 2, fill);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Spinning gradient arc + dot ring
class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final rect = Rect.fromLTWH(12, 12, s.width - 24, s.height - 24);

    // Sweeping gradient arc
    canvas.drawArc(
      rect, 0, math.pi * 1.7, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.9),
          Colors.white.withOpacity(0.0),
        ], stops: const [0.0, 0.3, 0.65, 1.0])
            .createShader(rect),
    );

    // Dots evenly spaced on the ring
    final cx = s.width / 2;
    final cy = s.height / 2;
    final r  = (s.width - 24) / 2;
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 12; i++) {
      final a = (i / 12) * 2 * math.pi;
      canvas.drawCircle(
          Offset(cx + r * math.cos(a), cy + r * math.sin(a)), 2.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Topographic contour lines for background texture
class _TopoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    // Top-left cluster
    for (int i = 0; i < 5; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s.width * 0.14, s.height * 0.17),
          width: 55.0 + i * 28, height: 32.0 + i * 16,
        ),
        p,
      );
    }

    // Bottom-right cluster
    for (int i = 0; i < 4; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s.width * 0.86, s.height * 0.83),
          width: 65.0 + i * 26, height: 38.0 + i * 15,
        ),
        p,
      );
    }

    // Flowing organic curves
    final cp = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    void curve(double x0, double y0, double cx1, double cy1,
        double cx2, double cy2, double x1, double y1) {
      canvas.drawPath(
        Path()..moveTo(x0, y0)..cubicTo(cx1, cy1, cx2, cy2, x1, y1),
        cp,
      );
    }

    curve(0, s.height * 0.22, s.width * 0.3, s.height * 0.08,
        s.width * 0.65, s.height * 0.32, s.width, s.height * 0.28);
    curve(0, s.height * 0.55, s.width * 0.28, s.height * 0.40,
        s.width * 0.62, s.height * 0.65, s.width, s.height * 0.60);
    curve(0, s.height * 0.80, s.width * 0.35, s.height * 0.70,
        s.width * 0.68, s.height * 0.88, s.width, s.height * 0.84);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────
//  SOFT BLOB
// ─────────────────────────────────────────────────────────────
class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob(this.size, this.color);

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ─────────────────────────────────────────────────────────────
//  PULSING LOADING DOTS
// ─────────────────────────────────────────────────────────────
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();
  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with TickerProviderStateMixin {

  final List<AnimationController> _ctrls = [];
  final List<Animation<double>>   _anims = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final c = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 650));
      _ctrls.add(c);
      _anims.add(
        Tween<double>(begin: 0.25, end: 1.0)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
      );
      Future.delayed(Duration(milliseconds: i * 180),
          () { if (mounted) c.repeat(reverse: true); });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Opacity(
            opacity: _anims[i].value,
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: Colors.white.withOpacity(0.45),
                  blurRadius: 8, spreadRadius: 1,
                )],
              ),
            ),
          ),
        ),
      )),
    );
  }
}