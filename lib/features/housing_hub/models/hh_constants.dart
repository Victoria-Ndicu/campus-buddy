import 'package:flutter/material.dart';

// ── HH = Housing Hub prefix ─────────────────────────────────────────────────
// Brand accent: warm terracotta #E07A5F

class HHColors {
  // Primary accent — terracotta
  static const Color brand      = Color(0xFFE07A5F);
  static const Color brandDark  = Color(0xFFC4674E);
  static const Color brandLight = Color(0xFFE89A85);
  static const Color brandPale  = Color(0xFFFDF0EC);
  static const Color brandXp    = Color(0xFFFFF8F5);

  // Supporting tones from HTML design
  static const Color blue       = Color(0xFF667EEA);
  static const Color bluePale   = Color(0xFFEEF1FD);
  static const Color teal       = Color(0xFF0D9488);
  static const Color tealPale   = Color(0xFFECFDF5);
  static const Color amber      = Color(0xFFF59E0B);
  static const Color amberPale  = Color(0xFFFFFBEB);
  static const Color sky        = Color(0xFF0EA5E9);
  static const Color skyPale    = Color(0xFFF0F9FF);

  // Utility
  static const Color green      = Color(0xFF10B981);
  static const Color greenPale  = Color(0xFFECFDF5);
  static const Color coral      = Color(0xFFEF4444);
  static const Color coralPale  = Color(0xFFFEF2F2);

  // Surfaces
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color surface2   = Color(0xFFF8F9FF);
  static const Color surface3   = Color(0xFFF0F2FC);
  static const Color border     = Color(0xFFE1E5F7);

  // Text
  static const Color text       = Color(0xFF0D0F1E);
  static const Color text2      = Color(0xFF4A4E6A);
  static const Color text3      = Color(0xFF9396B2);
}

class HHTheme {
  static BoxDecoration get card => BoxDecoration(
    color: HHColors.surface,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: HHColors.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.07),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get cardSm => BoxDecoration(
    color: HHColors.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: HHColors.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // NOTE: kept as a method (not const) because LinearGradient + BorderRadius
  // are fine as const, but keeping consistent style with heroGradient below.
  static BoxDecoration brandGradient() => const BoxDecoration(
    gradient: LinearGradient(
      colors: [HHColors.brand, HHColors.brandDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
  );

  // FIX: removed `const` — BorderRadius.circular() is NOT a const constructor,
  // so the BoxDecoration it appears in cannot be const either.
  static BoxDecoration heroGradient() => BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFFE07A5F), Color(0xFFC4674E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(20),
  );
}