// campus_market/widgets/cm_widgets.dart
import 'package:flutter/material.dart';
import '../models/cm_constants.dart';

// ── CMSearchBar ────────────────────────────────────────────────
class CMSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  const CMSearchBar({super.key, required this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CMColors.border),
        boxShadow: [
          BoxShadow(
            color: CMColors.brand.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(children: [
        Text('🔍', style: TextStyle(fontSize: 16, color: CMColors.text3)),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 13, color: CMColors.text3),
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── CMChip ─────────────────────────────────────────────────────
class CMChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const CMChip({super.key, required this.label, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? CMColors.brand : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? CMColors.brand : CMColors.border,
          ),
          boxShadow: active
              ? [BoxShadow(color: CMColors.brand.withOpacity(0.25), blurRadius: 8)]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : CMColors.text2,
          ),
        ),
      ),
    );
  }
}

// ── CMSectionLabel ─────────────────────────────────────────────
class CMSectionLabel extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const CMSectionLabel({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: CMColors.text)),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: CMColors.brand)),
            ),
        ],
      ),
    );
  }
}

// ── CMTag ──────────────────────────────────────────────────────
class CMTag extends StatelessWidget {
  final String label;
  const CMTag(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CMColors.brandPale,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: CMColors.brandDark)),
    );
  }
}

// ── CMPrimaryButton ────────────────────────────────────────────
class CMPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const CMPrimaryButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [CMColors.brand, CMColors.brandDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: CMColors.brand.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3)),
        ),
      ),
    );
  }
}

// ── CMFormField ────────────────────────────────────────────────
class CMFormField extends StatelessWidget {
  final String label;
  final String value;
  final bool multiline;
  final bool active;
  const CMFormField({
    super.key,
    required this.label,
    required this.value,
    this.multiline = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? CMColors.brandPale : CMColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: active ? CMColors.brand.withOpacity(0.4) : CMColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: CMColors.text3)),
        const SizedBox(height: 4),
        Text(value,
            maxLines: multiline ? null : 1,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: CMColors.text)),
      ]),
    );
  }
}