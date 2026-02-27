// auth module — au_widgets.dart
// NOTE: Screens should import ONLY this file for both widgets AND colors.
//       Do NOT import au_constants.dart directly in any screen file.
import 'package:flutter/material.dart';
import '../models/au_constants.dart';

// Re-export AUColors so screens can use it via this single import
export '../models/au_constants.dart';

// ─────────────────────────────────────────────────────────────
//  AUBackButton
// ─────────────────────────────────────────────────────────────
class AUBackButton extends StatelessWidget {
  const AUBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  AULogoMark
// ─────────────────────────────────────────────────────────────
class AULogoMark extends StatelessWidget {
  const AULogoMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFCC1616), Color(0xFFA80F0F)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: const Center(child: Text('C', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, height: 1))),
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              children: [
                TextSpan(text: 'Campus', style: TextStyle(color: const Color(0xFFCC1616))),
                TextSpan(text: 'Buddy',  style: TextStyle(color: AUColors.brand)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  AUWaveHeader
// ─────────────────────────────────────────────────────────────
class AUWaveHeader extends StatelessWidget {
  final double height;
  final Widget? child;

  const AUWaveHeader({super.key, this.height = 220, this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [AUColors.brand, AUColors.brandDeep],
                ),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _AUTopoPainter())),
          if (child != null) child!,
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 56),
              painter: _AUWavePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  AUScreenTitle
// ─────────────────────────────────────────────────────────────
class AUScreenTitle extends StatelessWidget {
  final String title;
  const AUScreenTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AUColors.text, letterSpacing: -0.5, height: 1.1),
        ),
        const SizedBox(height: 8),
        Container(
          width: 48, height: 3,
          decoration: BoxDecoration(color: AUColors.brand, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 26),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  AUInputField
// ─────────────────────────────────────────────────────────────
class AUInputField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final String iconEmoji;
  final TextInputType keyboardType;

  const AUInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.iconEmoji = '✉',
    this.keyboardType = TextInputType.text,
  });

  @override
  State<AUInputField> createState() => _AUInputFieldState();
}

class _AUInputFieldState extends State<AUInputField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AUColors.text)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AUColors.brand, width: 1.5)),
          ),
          child: Row(
            children: [
              Text(widget.iconEmoji, style: TextStyle(fontSize: 15, color: AUColors.text3)),
              const SizedBox(width: 8),
              Container(width: 1, height: 16, color: AUColors.text3.withOpacity(0.5)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  obscureText: widget.isPassword && _obscure,
                  keyboardType: widget.keyboardType,
                  style: TextStyle(fontSize: 13, color: AUColors.text),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: TextStyle(fontSize: 13, color: AUColors.text3),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              if (widget.isPassword)
                GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Text(_obscure ? '👁' : '🙈', style: const TextStyle(fontSize: 16)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  AUPrimaryButton
// ─────────────────────────────────────────────────────────────
class AUPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const AUPrimaryButton({super.key, required this.label, this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(color: AUColors.brand, borderRadius: BorderRadius.circular(14)),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Text(label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.2)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  AULinkRow
// ─────────────────────────────────────────────────────────────
class AULinkRow extends StatelessWidget {
  final String text;
  final String linkText;
  final VoidCallback onTap;

  const AULinkRow({super.key, required this.text, required this.linkText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text, style: TextStyle(fontSize: 13, color: AUColors.text2)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onTap,
          child: Text(linkText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AUColors.brand)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PRIVATE PAINTERS
// ─────────────────────────────────────────────────────────────
class _AUTopoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (final e in [
      [0.75 * s.width, 0.35 * s.height, 130.0, 70.0],
      [0.75 * s.width, 0.35 * s.height, 96.0,  50.0],
      [0.75 * s.width, 0.35 * s.height, 62.0,  32.0],
      [0.22 * s.width, 0.75 * s.height, 110.0, 58.0],
      [0.22 * s.width, 0.75 * s.height, 78.0,  40.0],
    ]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(e[0], e[1]), width: e[2] * 2, height: e[3] * 2), p);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _AUWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawPath(
      Path()
        ..moveTo(0, s.height * 0.2)
        ..quadraticBezierTo(s.width * 0.27, s.height * 1.1, s.width * 0.52, s.height * 0.6)
        ..quadraticBezierTo(s.width * 0.78, s.height * 0.1, s.width, s.height * 0.95)
        ..lineTo(s.width, s.height)
        ..lineTo(0, s.height)
        ..close(),
      Paint()..color = AUColors.offWhite,
    );
  }
  @override bool shouldRepaint(_) => false;
}