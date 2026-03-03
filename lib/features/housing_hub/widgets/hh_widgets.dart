import 'package:flutter/material.dart';
import '../models/hh_constants.dart';

// ── HHSearchBar ──────────────────────────────────────────────────────────────
class HHSearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback? onTap;
  const HHSearchBar({super.key, this.hint = 'Search location, type, price...', this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 13, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: HHColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: HHColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          const Text('🔍', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(child: Text(hint, style: TextStyle(fontSize: 13, color: HHColors.text3))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: HHColors.brandPale, borderRadius: BorderRadius.circular(8)),
            child: Text('Filter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: HHColors.brand)),
          ),
        ]),
      ),
    );
  }
}

// ── HHChip ───────────────────────────────────────────────────────────────────
class HHChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const HHChip({super.key, required this.label, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: active ? HHColors.brand : HHColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? HHColors.brand : HHColors.border, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : HHColors.text2,
          ),
        ),
      ),
    );
  }
}

// ── HHSectionLabel ────────────────────────────────────────────────────────────
class HHSectionLabel extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const HHSectionLabel({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 9),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: HHColors.text)),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: HHColors.brand)),
          ),
      ]),
    );
  }
}

// ── HHTag ─────────────────────────────────────────────────────────────────────
class HHTag extends StatelessWidget {
  final String label;
  final Color? bg;
  final Color? fg;
  // positional arg so .map<Widget>((t) => HHTag(t)) works
  const HHTag(this.label, {super.key, this.bg, this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg ?? HHColors.brandPale,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg ?? HHColors.brand),
      ),
    );
  }
}

// ── HHPrimaryButton ───────────────────────────────────────────────────────────
class HHPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const HHPrimaryButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [HHColors.brand, HHColors.brandDark]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: HHColors.brand.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Center(
          child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      ),
    );
  }
}

// ── HHFormField ───────────────────────────────────────────────────────────────
class HHFormField extends StatelessWidget {
  final String label;
  final String value;
  final bool multiline;
  final bool active;
  const HHFormField({
    super.key,
    required this.label,
    required this.value,
    this.multiline = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? HHColors.brandXp : HHColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? HHColors.brand : HHColors.border, width: active ? 1.5 : 1.0),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: HHColors.text3)),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: multiline ? null : 1,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: HHColors.text),
        ),
      ]),
    );
  }
}

// ── HHToggleRow ───────────────────────────────────────────────────────────────
class HHToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const HHToggleRow({super.key, required this.label, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: HHColors.text)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 11, color: HHColors.text3)),
        ])),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: HHColors.brand,
        ),
      ]),
    );
  }
}