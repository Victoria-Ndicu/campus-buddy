import 'package:flutter/material.dart';

class SBColors {
  static const Color brand      = Color(0xFF4F46E5);
  static const Color brandDark  = Color(0xFF3730A3);
  static const Color brandLight = Color(0xFF818CF8);
  static const Color brandPale  = Color(0xFFEEF2FF);
  static const Color surface2   = Color(0xFFF8F9FA);
  static const Color surface3   = Color(0xFFF1F3F5);
  static const Color border     = Color(0xFFE2E8F0);
  static const Color text       = Color(0xFF1E293B);
  static const Color text2      = Color(0xFF64748B);
  static const Color text3      = Color(0xFF94A3B8);
  static const Color green      = Color(0xFF10B981);
  static const Color accent     = Color(0xFFF59E0B);
  static const Color accent2    = Color(0xFFEF4444);
}

class SBTheme {
  static BoxDecoration get card => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: SBColors.border),
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
      colors: [SBColors.brand, SBColors.brandDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
  );
}