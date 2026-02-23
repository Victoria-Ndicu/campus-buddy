import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class AnswerThreadScreen extends StatelessWidget {
  final Map<String, dynamic> question;
  const AnswerThreadScreen({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: AppBar(
        title: const Text('Question Thread'),
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Original question hero
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brand, AppColors.brandDark],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                        child: Center(child: Text(question['emoji'], style: const TextStyle(fontSize: 16))),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(question['user'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                          Text('${question['time']} · ${question['course']}', style: const TextStyle(fontSize: 10, color: Colors.white60)),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white20, borderRadius: BorderRadius.circular(8)),
                        child: const Text('⏰ Urgent', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(question['question'], style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.5)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: (question['tags'] as List<String>).map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white20, borderRadius: BorderRadius.circular(8)),
                      child: Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                    )).toList(),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '💬 ${question['answers']} Answers',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text2),
              ),
            ),

            // Best answer
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.green, width: 2),
                boxShadow: [BoxShadow(color: AppColors.green.withOpacity(0.12), blurRadius: 12, offset: const Offset(0,4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.brand, AppColors.brandDark]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('👨‍🏫', style: TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('James M.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFEDFAF5), borderRadius: BorderRadius.circular(6)),
                                  child: const Text('✓ Best Answer', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.green)),
                                ),
                              ],
                            ),
                            const Text('30 mins ago · Tutor · Math Specialist', style: TextStyle(fontSize: 10, color: AppColors.text3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'L\'Hôpital\'s Rule is valid when you have an indeterminate form (0/0 or ±∞/∞). First verify you have one of these forms, then differentiate numerator and denominator separately (not as a quotient!), then take the limit again. Repeat if still indeterminate.',
                    style: TextStyle(fontSize: 13, color: AppColors.text, height: 1.6),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border(left: BorderSide(color: AppColors.brand, width: 3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('📌 Key condition:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.brand)),
                        SizedBox(height: 4),
                        Text('Both f and g must be differentiable near the point, and g\'(x) ≠ 0 near that point.', style: TextStyle(fontSize: 12, color: AppColors.text2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('👍', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      const Text('24', style: TextStyle(fontSize: 12, color: AppColors.brand, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 16),
                      const Text('💬 Reply', style: TextStyle(fontSize: 12, color: AppColors.text3)),
                      const Spacer(),
                      const Text('↗ Share', style: TextStyle(fontSize: 12, color: AppColors.text3)),
                    ],
                  ),
                ],
              ),
            ),

            // Second answer
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: AppColors.brand.withOpacity(0.07), blurRadius: 10, offset: const Offset(0,3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF3ECF8E), Color(0xFF0D9488)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('👩‍🔬', style: TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 10),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                        Text('Amara O.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                        Text('45 mins ago', style: TextStyle(fontSize: 10, color: AppColors.text3)),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'I uploaded a worked example PDF from our class last semester – it covers exactly this. Check Resources for "MATH201 Limits Examples 2023" it really helped me!',
                    style: TextStyle(fontSize: 13, color: AppColors.text, height: 1.6),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.brandPale, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: const [
                        Text('📄', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('MATH201 Limits Examples 2023.pdf', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brand)),
                          Text('Shared resource · Tap to view', style: TextStyle(fontSize: 10, color: AppColors.text3)),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      Text('👍', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 4),
                      Text('11', style: TextStyle(fontSize: 12, color: AppColors.text3)),
                      SizedBox(width: 16),
                      Text('💬 Reply', style: TextStyle(fontSize: 12, color: AppColors.text3)),
                      Spacer(),
                      Text('↗ Share', style: TextStyle(fontSize: 12, color: AppColors.text3)),
                    ],
                  ),
                ],
              ),
            ),

            // Reply box
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.brand, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('YOUR ANSWER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.brand, letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  const Text('Share what you know to help...', style: TextStyle(fontSize: 13, color: AppColors.text3)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _AttachBtn(icon: Icons.attach_file, label: 'File'),
                      const SizedBox(width: 6),
                      _AttachBtn(icon: Icons.link, label: 'Link'),
                      const SizedBox(width: 6),
                      _AttachBtn(icon: Icons.menu_book_outlined, label: 'Resource'),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(10)),
                        child: const Text('Post', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  const _AttachBtn({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.surface3, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.text2),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.text2)),
      ]),
    );
  }
}
