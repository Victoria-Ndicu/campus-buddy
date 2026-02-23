import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class PostQuestionScreen extends StatefulWidget {
  const PostQuestionScreen({super.key});

  @override
  State<PostQuestionScreen> createState() => _PostQuestionScreenState();
}

class _PostQuestionScreenState extends State<PostQuestionScreen> {
  int _urgencyIndex = 1;
  int _helpModeIndex = 0;
  final List<String> _tags = ['Calculus', 'Limits'];

  final List<Map<String, dynamic>> _urgency = [
    {'label': '😊 Not Urgent', 'color': AppColors.border, 'activeText': AppColors.text2},
    {'label': '⏰ Need Soon', 'color': Color(0xFFFFF4E6), 'activeText': Color(0xFFF5A623), 'activeBorder': Color(0xFFF5A623)},
    {'label': '🔥 Urgent', 'color': Color(0xFFFFF0F0), 'activeText': Color(0xFFFF6B6B), 'activeBorder': Color(0xFFFF6B6B)},
  ];

  final List<String> _helpModes = ['💬 Written Answer', '🎥 Video Call', '📚 Resource Link'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.brand),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Ask for Help'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Post', style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Text('Be specific and clear – better questions get better answers! 💡',
                  style: TextStyle(fontSize: 13, color: AppColors.text2)),
            ),

            // Question text
            FormFieldCard(
              label: 'Your Question',
              isActive: true,
              child: TextField(
                maxLines: 4,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Describe your question in detail...',
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.text3),
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                ),
                style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.6),
              ),
            ),

            FormFieldCard(label: 'Course Code',
                child: const Text('MATH 201 – Calculus II',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text))),

            // Tags
            FormFieldCard(
              label: 'Topic / Tags',
              child: Wrap(
                spacing: 6, runSpacing: 6,
                children: [
                  ..._tags.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(t, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      const Text('✕', style: TextStyle(fontSize: 10, color: Colors.white70)),
                    ]),
                  )),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border, width: 1.5)),
                      child: const Text('+ Add tag', style: TextStyle(fontSize: 11, color: AppColors.text2)),
                    ),
                  ),
                ],
              ),
            ),

            // Attach file
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1.5, style: BorderStyle.solid),
              ),
              child: Row(
                children: [
                  const Text('📎', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Attach a file (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                      Text('Add a photo, PDF or document to clarify your question', style: TextStyle(fontSize: 11, color: AppColors.text3)),
                    ]),
                  ),
                  const Text('Upload', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brand)),
                ],
              ),
            ),

            // Urgency
            FormFieldCard(
              label: 'Urgency',
              child: Row(
                children: List.generate(_urgency.length, (i) {
                  final active = i == _urgencyIndex;
                  final u = _urgency[i];
                  return GestureDetector(
                    onTap: () => setState(() => _urgencyIndex = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: active ? (u['color'] as Color) : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active && u.containsKey('activeBorder') ? (u['activeBorder'] as Color) : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        u['label'] as String,
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: active && u.containsKey('activeText') ? (u['activeText'] as Color) : AppColors.text2,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Help mode
            FormFieldCard(
              label: 'Prefer Help Via',
              child: Wrap(
                spacing: 6, runSpacing: 6,
                children: List.generate(_helpModes.length, (i) {
                  final active = i == _helpModeIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _helpModeIndex = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: active ? AppColors.brand : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: active ? AppColors.brand : AppColors.border, width: 1.5),
                      ),
                      child: Text(_helpModes[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.text2)),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 8),
            SBPrimaryButton(label: '🙋 Post Question', onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}
