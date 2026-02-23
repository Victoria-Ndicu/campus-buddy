import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'upload_resource_screen.dart';

class ResourceLibraryScreen extends StatelessWidget {
  const ResourceLibraryScreen({super.key});

  static final List<Map<String, dynamic>> _resources = [
    {
      'icon': '📄',
      'iconBg': Color(0xFFFFF0F0),
      'name': 'MATH201 – Calculus II Complete Notes',
      'meta': 'PDF · 4.2 MB · Uploaded by Sarah K.',
      'course': 'MATH 201',
    },
    {
      'icon': '📝',
      'iconBg': Color(0xFFF0FFF8),
      'name': 'CS301 2023 Final Exam Paper',
      'meta': 'PDF · 1.8 MB · Uploaded by James M.',
      'course': 'CS 301',
    },
    {
      'icon': '📖',
      'iconBg': Color(0xFFFFFAF0),
      'name': 'Economics Macro Study Guide – Semester 2',
      'meta': 'DOCX · 856 KB · Uploaded by David L.',
      'course': 'ECON 201',
    },
    {
      'icon': '🖼️',
      'iconBg': Color(0xFFF5F0FF),
      'name': 'Organic Chemistry – Reaction Mechanisms',
      'meta': 'PNG · 3.1 MB · Uploaded by Amara O.',
      'course': 'CHEM 302',
    },
    {
      'icon': '📄',
      'iconBg': Color(0xFFF0F4FF),
      'name': 'Physics I – Wave Mechanics Summary',
      'meta': 'PDF · 2.3 MB · Uploaded by Mike T.',
      'course': 'PHYS 101',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: AppBar(
        title: const Text('Resources'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_outlined, color: AppColors.brand),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadResourceScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            SBSearchBar(hint: 'Search by course code, topic, keyword...'),
            SBFilterRow(options: const ['All Types', '📄 Notes', '📝 Past Papers', '📖 Study Guides', '🖼️ Images']),
            SectionLabel(title: 'Recently Uploaded', actionLabel: 'See all'),
            const SizedBox(height: 4),
            ..._resources.map((r) => _ResourceCard(resource: r)),

            const SizedBox(height: 8),
            SectionLabel(title: 'Popular This Week', actionLabel: 'See all'),
            const SizedBox(height: 4),
            _ResourceCard(resource: {
              'icon': '📝',
              'iconBg': const Color(0xFFFFF0F0),
              'name': 'MATH201 Past Papers 2019–2023',
              'meta': 'PDF · 8.6 MB · 🔥 142 downloads',
              'course': 'MATH 201',
            }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadResourceScreen())),
        backgroundColor: AppColors.brand,
        child: const Icon(Icons.upload, color: Colors.white),
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final Map<String, dynamic> resource;
  const _ResourceCard({required this.resource});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.brand.withOpacity(0.07), blurRadius: 10, offset: const Offset(0,3))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: resource['iconBg'] as Color, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(resource['icon'], style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resource['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(resource['meta'], style: const TextStyle(fontSize: 11, color: AppColors.text3)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.brandPale, borderRadius: BorderRadius.circular(6)),
                  child: Text(resource['course'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.brand)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined, color: AppColors.brand, size: 22),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
