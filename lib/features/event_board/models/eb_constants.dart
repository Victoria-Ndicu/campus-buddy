import 'package:flutter/material.dart';

// ── EB = EventBoard prefix ───────────────────────────────────────────────────
// Brand accent: electric violet #7C3AED

class EBColors {
  // Primary accent — violet
  static const Color brand     = Color(0xFF7C3AED);
  static const Color brandDark = Color(0xFF5B21B6);
  static const Color brandLight= Color(0xFFA78BFA);
  static const Color brandPale = Color(0xFFF5F3FF);
  static const Color brandXp   = Color(0xFFFAF9FF);

  // Supporting event category colours
  static const Color blue      = Color(0xFF667EEA);
  static const Color bluePale  = Color(0xFFEEF1FD);
  static const Color green     = Color(0xFF10B981);
  static const Color greenPale = Color(0xFFECFDF5);
  static const Color pink      = Color(0xFFEC4899);
  static const Color pinkPale  = Color(0xFFFDF2F8);
  static const Color amber     = Color(0xFFF59E0B);
  static const Color amberPale = Color(0xFFFFFBEB);
  static const Color teal      = Color(0xFF0D9488);
  static const Color tealPale  = Color(0xFFECFDF5);
  static const Color coral     = Color(0xFFEF4444);
  static const Color coralPale = Color(0xFFFEF2F2);
  static const Color sky       = Color(0xFF0EA5E9);

  // Surfaces
  static const Color surface   = Color(0xFFFFFFFF);
  static const Color surface2  = Color(0xFFF8F9FF);
  static const Color surface3  = Color(0xFFF0F2FC);
  static const Color border    = Color(0xFFE1E5F7);

  // Text
  static const Color text      = Color(0xFF0D0F1E);
  static const Color text2     = Color(0xFF4A4E6A);
  static const Color text3     = Color(0xFF9396B2);
}

class EBTheme {
  static BoxDecoration get card => BoxDecoration(
    color: EBColors.surface,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: EBColors.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.07),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get cardSm => BoxDecoration(
    color: EBColors.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: EBColors.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration brandGradient() => const BoxDecoration(
    gradient: LinearGradient(
      colors: [EBColors.brand, EBColors.brandDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
  );
}

// ── Event category helper ────────────────────────────────────────────────────
class EBCategory {
  final String label, emoji;
  final Color color, pale;
  const EBCategory(this.label, this.emoji, this.color, this.pale);

  static const academic = EBCategory('Academic', '📚', EBColors.blue, EBColors.bluePale);
  static const social   = EBCategory('Social',   '🎵', EBColors.pink, EBColors.pinkPale);
  static const sports   = EBCategory('Sports',   '⚽', EBColors.green, EBColors.greenPale);
  static const cultural = EBCategory('Cultural', '🎭', EBColors.pink, EBColors.pinkPale);
  static const career   = EBCategory('Career',   '🛠', EBColors.amber, EBColors.amberPale);
  static const all      = [academic, social, sports, cultural, career];
}