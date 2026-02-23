import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class UploadResourceScreen extends StatefulWidget {
  const UploadResourceScreen({super.key});

  @override
  State<UploadResourceScreen> createState() => _UploadResourceScreenState();
}

class _UploadResourceScreenState extends State<UploadResourceScreen> {
  int _typeIndex = 0;
  int _visibilityIndex = 0;
  final List<String> _tags = ['Integration', 'Differentiation', 'Limits'];
  bool _fileUploaded = true; // Simulated uploaded state

  final List<String> _resourceTypes = ['📄 Lecture Notes', '📝 Past Paper', '📖 Study Guide', '📊 Summary'];
  final List<String> _visibility = ['🌍 Public', '👥 My Groups Only'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.brand),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Upload Resource'),
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

            // Upload area
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.brandPale,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.brandLight, width: 2, style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  const Text('📂', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  const Text('Tap to upload your file', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                  const SizedBox(height: 4),
                  const Text('Share notes, past papers, study guides and more with your peers',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.text3)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: ['PDF', 'DOC', 'DOCX', 'JPG', 'PNG'].map((f) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(f, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text2)),
                    )).toList(),
                  ),
                  const SizedBox(height: 8),
                  const Text('Max file size: 50 MB', style: TextStyle(fontSize: 10, color: AppColors.text3)),
                ],
              ),
            ),

            // File preview (simulated uploaded)
            if (_fileUploaded)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.brand, width: 1.5),
                  boxShadow: [BoxShadow(color: AppColors.brand.withOpacity(0.09), blurRadius: 10, offset: const Offset(0,3))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text('📄', style: TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MATH201_Calculus_Notes_Final.pdf',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          const Text('4.2 MB · PDF Document', style: TextStyle(fontSize: 11, color: AppColors.text3)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: const LinearProgressIndicator(
                              value: 1.0, minHeight: 4,
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation(AppColors.brand),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('✅', style: TextStyle(fontSize: 20)),
                  ],
                ),
              ),

            FormFieldCard(label: 'Resource Title', isActive: true,
                child: const Text('MATH201 – Calculus II Complete Notes',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text))),

            FormFieldCard(label: 'Course Code',
                child: const Text('MATH 201 – Calculus II',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text))),

            // Resource type
            FormFieldCard(
              label: 'Resource Type',
              child: Wrap(
                spacing: 6, runSpacing: 6,
                children: List.generate(_resourceTypes.length, (i) {
                  final active = i == _typeIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _typeIndex = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: active ? AppColors.brand : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: active ? AppColors.brand : AppColors.border, width: 1.5),
                      ),
                      child: Text(_resourceTypes[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.text2)),
                    ),
                  );
                }),
              ),
            ),

            // Tags
            FormFieldCard(
              label: 'Topic / Keywords',
              child: Wrap(
                spacing: 6, runSpacing: 6,
                children: [
                  ..._tags.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        const Text('✕', style: TextStyle(fontSize: 10, color: Colors.white70)),
                      ],
                    ),
                  )),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 1.5, style: BorderStyle.solid),
                      ),
                      child: const Text('+ Add tag', style: TextStyle(fontSize: 11, color: AppColors.text2, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),

            // Visibility
            FormFieldCard(
              label: 'Visibility',
              child: Row(
                children: List.generate(_visibility.length, (i) {
                  final active = i == _visibilityIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _visibilityIndex = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppColors.brand : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: active ? AppColors.brand : AppColors.border, width: 1.5),
                      ),
                      child: Text(_visibility[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.text2)),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 8),
            SBPrimaryButton(label: '📤 Share Resource', onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}
