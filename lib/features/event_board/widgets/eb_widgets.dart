import 'package:flutter/material.dart';
import '../models/eb_constants.dart';

// ── EBSearchBar ──────────────────────────────────────────────────────────────
class EBSearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback? onTap;
  const EBSearchBar({super.key, this.hint = 'Search events, clubs, dates...', this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: EBColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EBColors.border, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          const Text('🔍', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(child: Text(hint, style: TextStyle(fontSize: 13, color: EBColors.text3))),
        ]),
      ),
    );
  }
}

// ── EBChip ───────────────────────────────────────────────────────────────────
class EBChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const EBChip({super.key, required this.label, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: active ? EBColors.brand : EBColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? EBColors.brand : EBColors.border, width: 1.5),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: active ? Colors.white : EBColors.text2)),
      ),
    );
  }
}

// ── EBSectionLabel ────────────────────────────────────────────────────────────
class EBSectionLabel extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const EBSectionLabel({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 9),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: EBColors.text)),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EBColors.brand)),
          ),
      ]),
    );
  }
}

// ── EBTag ─────────────────────────────────────────────────────────────────────
class EBTag extends StatelessWidget {
  final String label;
  final Color? bg;
  final Color? fg;
  const EBTag(this.label, {super.key, this.bg, this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg ?? EBColors.brandPale,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg ?? EBColors.brand)),
    );
  }
}

// ── EBPrimaryButton ───────────────────────────────────────────────────────────
class EBPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const EBPrimaryButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [EBColors.brand, EBColors.brandDark]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: EBColors.brand.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Center(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white))),
      ),
    );
  }
}

// ── EBFormField ───────────────────────────────────────────────────────────────
class EBFormField extends StatelessWidget {
  final String label, value;
  final bool multiline, active;
  const EBFormField({super.key, required this.label, required this.value,
      this.multiline = false, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? EBColors.brandXp : EBColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? EBColors.brand : EBColors.border, width: active ? 1.5 : 1.0),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EBColors.text3)),
        const SizedBox(height: 4),
        Text(value, maxLines: multiline ? null : 1,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EBColors.text)),
      ]),
    );
  }
}

// ── EBToggleRow ───────────────────────────────────────────────────────────────
class EBToggleRow extends StatelessWidget {
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const EBToggleRow({super.key, required this.label, required this.subtitle,
      required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EBColors.text)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 11, color: EBColors.text3)),
        ])),
        Switch(value: value, onChanged: onChanged, activeColor: EBColors.brand),
      ]),
    );
  }
}

// ── EBRsvpButton ─────────────────────────────────────────────────────────────
class EBRsvpButton extends StatelessWidget {
  final bool going;
  final VoidCallback onTap;
  final Color color;
  const EBRsvpButton({super.key, required this.going, required this.onTap, this.color = EBColors.brand});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: going ? EBColors.green : color,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(going ? 'Going ✓' : 'RSVP',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }
}