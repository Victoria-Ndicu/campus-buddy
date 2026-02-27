// campus_market/models/cm_constants.dart
import 'package:flutter/material.dart';

class CMColors {
  static const Color brand      = Color(0xFFE07A5F); // terra
  static const Color brandDark  = Color(0xFFC4674E); // terraD
  static const Color brandLight = Color(0xFFEA9A84);
  static const Color brandPale  = Color(0xFFFDF0EC); // terraPale
  static const Color surface2   = Color(0xFFF5F4F0);
  static const Color surface3   = Color(0xFFF1F3F5);
  static const Color border     = Color(0xFFE8D8D3);
  static const Color text       = Color(0xFF1A1A2E);
  static const Color text2      = Color(0xFF555577);
  static const Color text3      = Color(0xFF9999BB);
  static const Color green      = Color(0xFF10B981);
  static const Color accent     = Color(0xFFF59E0B);
  static const Color accent2    = Color(0xFFEF4444);
  static const Color violet     = Color(0xFF7C3AED);
}

class CMTheme {
  static BoxDecoration get card => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: CMColors.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );

  static BoxDecoration brandGradient() => BoxDecoration(
    gradient: LinearGradient(
      colors: [CMColors.brand, CMColors.brandDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
  );

  static BoxDecoration get headerGradient => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEA9A84), CMColors.brand, CMColors.brandDark],
    ),
  );
}