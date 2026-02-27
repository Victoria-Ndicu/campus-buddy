import 'package:flutter/material.dart';
import '../models/sb_constants.dart';

// ── Search Bar ──────────────────────────────────────────────────────────────
class SBSearchBar extends StatelessWidget {
  final String hint;
  const SBSearchBar({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: SBColors.text3, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: SBColors.text3, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SBColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SBColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SBColors.brand, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ── Chip ────────────────────────────────────────────────────────────────────
class SBChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const SBChip({super.key, required this.label, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? SBColors.brand : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? SBColors.brand : SBColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : SBColors.text2,
          ),
        ),
      ),
    );
  }
}

// ── Section Label ────────────────────────────────────────────────────────────
class SBSectionLabel extends StatelessWidget {
  final String title;
  final String? action;
  const SBSectionLabel({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: SBColors.text,
          ),
        ),
        if (action != null)
          Text(
            action!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SBColors.brand,
            ),
          ),
      ],
    );
  }
}

// ── Tag ──────────────────────────────────────────────────────────────────────
// NOTE: Takes a single positional String so .map(SBTag.new) works
class SBTag extends StatelessWidget {
  final String label;
  const SBTag(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: SBColors.brandPale,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: SBColors.brand,
        ),
      ),
    );
  }
}

// ── Primary Button ───────────────────────────────────────────────────────────
class SBPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const SBPrimaryButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [SBColors.brand, SBColors.brandDark],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Form Field ───────────────────────────────────────────────────────────────
class SBFormField extends StatelessWidget {
  final String label;
  final String value;
  final bool multiline;
  final bool active;
  const SBFormField({
    super.key,
    required this.label,
    required this.value,
    this.multiline = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: SBColors.text3,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: active ? SBColors.brandPale : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? SBColors.brand : SBColors.border,
                width: active ? 1.5 : 1.0,
              ),
            ),
            child: Text(
                    value,
                    style: const TextStyle(fontSize: 13, color: SBColors.text, height: 1.5),
                    maxLines: multiline ? 8 : 1,
                    overflow: multiline ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }
}