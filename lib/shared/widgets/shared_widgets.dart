import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Search Bar ───────────────────────────────────────────────
class SBSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;

  const SBSearchBar({super.key, required this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withOpacity(0.09),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: AppColors.text3, size: 20),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          filled: false,
        ),
        style: const TextStyle(fontSize: 13, color: AppColors.text),
      ),
    );
  }
}

// ─── Filter Chip Row ──────────────────────────────────────────
class SBFilterRow extends StatefulWidget {
  final List<String> options;
  final int initialSelected;
  final ValueChanged<int>? onSelected;

  const SBFilterRow({
    super.key,
    required this.options,
    this.initialSelected = 0,
    this.onSelected,
  });

  @override
  State<SBFilterRow> createState() => _SBFilterRowState();
}

class _SBFilterRowState extends State<SBFilterRow> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(widget.options.length, (i) {
          final active = i == _selected;
          return GestureDetector(
            onTap: () {
              setState(() => _selected = i);
              widget.onSelected?.call(i);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.brand : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? AppColors.brand : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: Text(
                widget.options[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.text2,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionLabel({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.brand,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Primary Button ───────────────────────────────────────────
class SBPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final IconData? icon;

  const SBPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color ?? AppColors.brand,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (color ?? AppColors.brand).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info Card Box ────────────────────────────────────────────
class InfoBox extends StatelessWidget {
  final String label;
  final String value;

  const InfoBox({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.text3)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
        ],
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────
class StatsRow extends StatelessWidget {
  final List<Map<String, String>> stats;

  const StatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: stats.asMap().entries.map((e) {
          final isLast = e.key == stats.length - 1;
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: isLast
                      ? BorderSide.none
                      : const BorderSide(color: AppColors.border),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                children: [
                  Text(
                    e.value['value']!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.value['label']!,
                    style: const TextStyle(fontSize: 10, color: AppColors.text3),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Tag Chip ─────────────────────────────────────────────────
class TagChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;

  const TagChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.brandPale,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.brand,
        ),
      ),
    );
  }
}

// ─── Form Field Card ─────────────────────────────────────────
class FormFieldCard extends StatelessWidget {
  final String label;
  final Widget child;
  final bool isActive;

  const FormFieldCard({
    super.key,
    required this.label,
    required this.child,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive ? AppColors.brandPale : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? AppColors.brand : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.text3,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
