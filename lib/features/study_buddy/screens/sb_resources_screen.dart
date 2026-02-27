// ============================================================
//  StudyBuddy — sb_resources_screen.dart
//
//  Screen stack:
//    SBResourcesScreen
//      └─ SBUploadResourceScreen   (tap "+ Upload")
// ============================================================

import 'package:flutter/material.dart';
import '../models/sb_constants.dart';
import '../widgets/sb_widgets.dart';

// ─────────────────────────────────────────────────────────────
//  1. Resource Library
// ─────────────────────────────────────────────────────────────
class SBResourcesScreen extends StatefulWidget {
  const SBResourcesScreen({super.key});

  @override
  State<SBResourcesScreen> createState() => _SBResourcesScreenState();
}

class _SBResourcesScreenState extends State<SBResourcesScreen> {
  int _filter = 0;
  final _filters = ['All', 'PDFs', 'Notes', 'Past Papers', 'Videos', 'Links'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SBColors.surface2,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: SBColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Resources',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: SBColors.text)),
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SBUploadResourceScreen())),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: SBColors.brand, borderRadius: BorderRadius.circular(10)),
              child: const Text('+ Upload',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
              child: SBSearchBar(hint: 'Search by subject, course, type...')),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => SBChip(
                  label: _filters[i],
                  active: _filter == i,
                  onTap: () => setState(() => _filter = i),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Wrap(spacing: 8, children: const [
                _CoursePill('MATH 201'),
                _CoursePill('CS 301'),
                _CoursePill('CHEM 202'),
              ]),
            ),
          ),
          SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SBSectionLabel(title: 'Trending This Week 🔥', action: 'See all'),
              )),
          SliverList(
            delegate: SliverChildListDelegate([
              _ResourceCard(
                emoji: '📄',
                iconBg: SBColors.brandPale,
                name: 'Calculus II – Integration Notes',
                meta: 'MATH 201  ·  PDF  ·  2.4 MB',
                course: 'MATH 201',
                stat: '234 downloads',
              ),
              _ResourceCard(
                emoji: '📊',
                iconBg: const Color(0xFFFFF4E6),
                name: 'Statistics Past Paper 2023',
                meta: 'MATH 201  ·  PDF  ·  1.8 MB',
                course: 'MATH 201',
                stat: '187 downloads',
              ),
              _ResourceCard(
                emoji: '🎬',
                iconBg: const Color(0xFFFFF0F0),
                name: 'Python OOP Lecture Recording',
                meta: 'CS 301  ·  Video  ·  45 min',
                course: 'CS 301',
                stat: '156 views',
              ),
              _ResourceCard(
                emoji: '📝',
                iconBg: const Color(0xFFEDFAF5),
                name: 'Organic Chemistry – Alkene Reactions',
                meta: 'CHEM 202  ·  Notes  ·  890 KB',
                course: 'CHEM 202',
                stat: '112 downloads',
              ),
              _ResourceCard(
                emoji: '📄',
                iconBg: SBColors.brandPale,
                name: 'Linear Algebra Cheat Sheet',
                meta: 'MATH 301  ·  PDF  ·  450 KB',
                course: 'MATH 301',
                stat: '98 downloads',
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ],
      ),
    );
  }
}

class _CoursePill extends StatelessWidget {
  final String label;
  const _CoursePill(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
        color: SBColors.brandPale, borderRadius: BorderRadius.circular(10)),
    child: Text(label,
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: SBColors.brand)),
  );
}

class _ResourceCard extends StatelessWidget {
  final String emoji, name, meta, course, stat;
  final Color iconBg;

  const _ResourceCard({
    required this.emoji,
    required this.iconBg,
    required this.name,
    required this.meta,
    required this.course,
    required this.stat,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: SBTheme.card,
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration:
            BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
          const SizedBox(height: 3),
          Text(meta,
              style: const TextStyle(fontSize: 11, color: SBColors.text3)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
                color: SBColors.brandPale, borderRadius: BorderRadius.circular(6)),
            child: Text(course,
                style: const TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700, color: SBColors.brand)),
          ),
        ]),
      ),
      const SizedBox(width: 10),
      const Icon(Icons.download_outlined, color: SBColors.brand, size: 22),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────
//  2. Upload Resource
// ─────────────────────────────────────────────────────────────
class SBUploadResourceScreen extends StatefulWidget {
  const SBUploadResourceScreen({super.key});

  @override
  State<SBUploadResourceScreen> createState() => _SBUploadResourceScreenState();
}

class _SBUploadResourceScreenState extends State<SBUploadResourceScreen> {
  int    _typeIdx    = 0;
  String _visibility = 'Public';

  static const _types = ['📄 PDF', '📝 Notes', '📊 Past Paper', '🎬 Video', '🔗 Link'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SBColors.surface2,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 18, color: SBColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Share a Resource',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: SBColors.text)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text('Post',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.brand)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Drop zone
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: SBColors.brandPale,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: SBColors.brandLight, width: 2),
              ),
              child: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('📤', style: TextStyle(fontSize: 34)),
                  const SizedBox(height: 8),
                  const Text('Tap to upload a file',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
                  const SizedBox(height: 4),
                  const Text('PDF, Word, Images, Videos',
                      style: TextStyle(fontSize: 11, color: SBColors.text3)),
                  const SizedBox(height: 10),
                  // FIX: typed as <Widget> to avoid List<dynamic> error
                  Wrap(spacing: 6, children: ['PDF','DOC','PPT','IMG','MP4'].map<Widget>((f) =>
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: SBColors.border),
                      ),
                      child: Text(f,
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700, color: SBColors.text2)),
                    )
                  ).toList()),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Type selector
          const Text('RESOURCE TYPE',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: SBColors.text3, letterSpacing: 1)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: List.generate(_types.length, (i) => SBChip(
              label: _types[i],
              active: _typeIdx == i,
              onTap: () => setState(() => _typeIdx = i),
            )),
          ),
          const SizedBox(height: 16),

          SBFormField(label: 'Resource Title', value: 'Calculus II – Integration Notes'),
          const SizedBox(height: 12),
          SBFormField(label: 'Course Code', value: 'MATH 201 – Calculus II'),
          const SizedBox(height: 12),
          SBFormField(
            label: 'Description (optional)',
            value: 'Detailed notes covering all integration techniques from our Thursday lecture.',
            multiline: true,
          ),
          const SizedBox(height: 16),

          // Visibility
          const Text('VISIBILITY',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: SBColors.text3, letterSpacing: 1)),
          const SizedBox(height: 10),
          // FIX: typed as <Widget> to avoid List<dynamic> error
          Row(children: ['🌍 Public', '👥 My Groups', '🔒 Private'].map<Widget>((opt) {
            final key = opt.split(' ').sublist(1).join(' ');
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _visibility = key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _visibility == key ? SBColors.brandPale : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _visibility == key ? SBColors.brand : SBColors.border,
                        width: _visibility == key ? 2 : 1.5),
                  ),
                  child: Center(
                    child: Text(opt,
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: _visibility == key ? SBColors.brand : SBColors.text2)),
                  ),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 20),

          // Submit
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('📁  Resource shared successfully!'),
                backgroundColor: SBColors.brand,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: SBColors.brand,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: SBColors.brand.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: const Center(
                child: Text('📤  Share Resource',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}