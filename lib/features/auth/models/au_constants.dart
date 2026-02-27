// auth module — au_constants.dart
import 'package:flutter/material.dart';

// ── Color tokens ──────────────────────────────────────────────
class AUColors {
  static const Color brand      = Color(0xFF667EEA);
  static const Color brandDark  = Color(0xFF5569D4);
  static const Color brandDeep  = Color(0xFF4A55C0);
  static const Color brandPale  = Color(0xFFEEF1FD);
  static const Color surface2   = Color(0xFFF8F9FA);
  static const Color surface3   = Color(0xFFF1F3F5);
  static const Color border     = Color(0xFFCCCCEE);
  static const Color text       = Color(0xFF1A1A2E);
  static const Color text2      = Color(0xFF555577);
  static const Color text3      = Color(0xFF9999BB);
  static const Color green      = Color(0xFF10B981);
  static const Color accent     = Color(0xFFF59E0B);
  static const Color accent2    = Color(0xFFEF4444);
  static const Color offWhite   = Color(0xFFF5F4F0);
}

// ── Reusable decorations ─────────────────────────────────────
class AUTheme {
  static BoxDecoration get card => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AUColors.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration brandGradient() => const BoxDecoration(
    gradient: LinearGradient(
      colors: [AUColors.brand, AUColors.brandDeep],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
  );
}