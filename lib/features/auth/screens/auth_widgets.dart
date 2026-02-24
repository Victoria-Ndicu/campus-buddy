import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// ── Underline Input Field ──────────────────────────────────────────────────

class UnderlineInputField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextEditingController? controller;

  const UnderlineInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.controller,
  });

  @override
  State<UnderlineInputField> createState() => _UnderlineInputFieldState();
}

class _UnderlineInputFieldState extends State<UnderlineInputField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(widget.icon, size: 18, color: AppColors.text3),
            const SizedBox(width: 10),
            Container(width: 1, height: 16, color: AppColors.text3.withOpacity(0.5)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: widget.controller,
                obscureText: widget.isPassword && _obscure,
                keyboardType: widget.keyboardType,
                style: const TextStyle(fontSize: 13, color: AppColors.text),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle:
                      const TextStyle(fontSize: 13, color: AppColors.text3),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            if (widget.isPassword)
              GestureDetector(
                onTap: () => setState(() => _obscure = !_obscure),
                child: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: AppColors.text3,
                ),
              ),
          ],
        ),
        const Divider(color: AppColors.brand, thickness: 1.5, height: 1),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Primary Button ─────────────────────────────────────────────────────────

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const PrimaryButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: AppColors.brand,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

// ── Title + Underline ──────────────────────────────────────────────────────

class ScreenTitle extends StatelessWidget {
  final String title;
  final double fontSize;
  final double underlineBottomSpacing;

  const ScreenTitle({
    super.key,
    required this.title,
    this.fontSize = 32,
    this.underlineBottomSpacing = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 48,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(height: underlineBottomSpacing),
      ],
    );
  }
}

// ── Home Indicator ─────────────────────────────────────────────────────────

class HomeIndicator extends StatelessWidget {
  const HomeIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Center(
        child: Container(
          width: 120,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

// ── Social Sign-in Buttons ─────────────────────────────────────────────────

class SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;

  const SocialButton({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
      ),
      child: Center(child: icon),
    );
  }
}

// ── Divider with text ──────────────────────────────────────────────────────

class OrDivider extends StatelessWidget {
  final String text;

  const OrDivider({super.key, this.text = 'or continue with'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFFDDDDDD))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
          ),
        ),
        Expanded(child: Container(height: 1, color: const Color(0xFFDDDDDD))),
      ],
    );
  }
}
