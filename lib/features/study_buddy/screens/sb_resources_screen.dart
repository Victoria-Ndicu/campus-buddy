// ============================================================
//  StudyBuddy — sb_resources_screen.dart  (API-connected)
//
//  Now uses ApiClient (lib/core/api_client.dart) for all
//  requests — automatic token refresh, same pattern as
//  profile_screen.dart.
//
//  GET  /api/study/resources/?type=&search=  → resource list
//  POST /api/study/resources/                → upload resource
//
//  Screen stack:
//    SBResourcesScreen
//      └─ SBUploadResourceScreen   (tap "+ Upload")
// ============================================================

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';

import '../../../core/api_client.dart';   // ← same shared client as profile_screen
import '../models/sb_constants.dart';
import '../widgets/sb_widgets.dart';

// ─────────────────────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────────────────────
class ResourceModel {
  final String id;
  final String name;
  final String course;
  final String type;      // pdf | notes | video | past_paper | link
  final String meta;      // e.g. "2.4 MB" or "45 min"
  final String stat;      // e.g. "234 downloads"
  final String emoji;
  final Color  iconBg;

  const ResourceModel({
    required this.id,
    required this.name,
    required this.course,
    required this.type,
    required this.meta,
    required this.stat,
    required this.emoji,
    required this.iconBg,
  });

  static String _emojiForType(String type) {
    switch (type.toLowerCase()) {
      case 'video':      return '🎬';
      case 'notes':      return '📝';
      case 'past_paper':
      case 'past paper': return '📊';
      case 'link':       return '🔗';
      default:           return '📄';   // pdf / fallback
    }
  }

  static Color _bgForType(String type) {
    switch (type.toLowerCase()) {
      case 'video':      return const Color(0xFFFFF0F0);
      case 'notes':      return const Color(0xFFEDFAF5);
      case 'past_paper':
      case 'past paper': return const Color(0xFFFFF4E6);
      case 'link':       return const Color(0xFFF5F0FF);
      default:           return SBColors.brandPale;
    }
  }

  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    final type       = json['type'] as String? ??
                       json['resource_type'] as String? ?? 'pdf';
    final fileSize   = json['file_size'] as String? ?? json['size'] as String? ?? '';
    final duration   = json['duration'] as String? ?? '';
    final downloads  = json['downloads'] as int? ?? json['download_count'] as int? ?? 0;
    final views      = json['views'] as int? ?? json['view_count'] as int? ?? 0;

    // Build human-friendly meta string
    String meta = '';
    if (fileSize.isNotEmpty) meta = fileSize;
    if (duration.isNotEmpty) meta = duration;

    // Build stat string
    String stat;
    if (type.toLowerCase() == 'video') {
      stat = '$views views';
    } else {
      stat = '$downloads downloads';
    }

    final course = json['course'] as String? ??
                   json['course_code'] as String? ?? '';

    return ResourceModel(
      id:     json['id']?.toString() ?? '',
      name:   json['title'] as String? ?? json['name'] as String? ?? 'Resource',
      course: course,
      type:   type,
      meta:   [if (course.isNotEmpty) course, type, if (meta.isNotEmpty) meta]
                  .join('  ·  '),
      stat:   stat,
      emoji:  _emojiForType(type),
      iconBg: _bgForType(type),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  API SERVICE
// ─────────────────────────────────────────────────────────────
class _ResourcesApi {
  static const _base = '/api/v1/study-buddy';

  static Future<List<ResourceModel>> fetchResources({
    String? type,
    String? search,
  }) async {
    final params = <String, String>{};
    if (type   != null && type.isNotEmpty)   params['type']   = type;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final path  = query.isEmpty ? '$_base/resources/' : '$_base/resources/?$query';

    final res = await ApiClient.get(path);
    dev.log('[SBResources] GET $path → ${res.statusCode}');

    if (res.statusCode != 200) {
      throw Exception('Failed to load resources (${res.statusCode})');
    }

    final body    = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (body['results'] ?? body) as List<dynamic>;
    return results
        .map((e) => ResourceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> uploadResource(Map<String, dynamic> payload) async {
    final res = await ApiClient.post('$_base/resources/', body: payload);
    dev.log('[SBResources] POST upload → ${res.statusCode}');
    if (res.statusCode != 201) {
      throw Exception('Upload failed (${res.statusCode})');
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  1. RESOURCE LIBRARY
//
//  State pattern mirrors profile_screen.dart:
//    _loading / _error / _resources  (atomic setState)
// ─────────────────────────────────────────────────────────────
class SBResourcesScreen extends StatefulWidget {
  const SBResourcesScreen({super.key});

  @override
  State<SBResourcesScreen> createState() => _SBResourcesScreenState();
}

class _SBResourcesScreenState extends State<SBResourcesScreen> {
  int    _filter      = 0;
  String _searchQuery = '';

  List<ResourceModel>? _resources;
  bool    _loading = true;
  String? _error;

  // Maps filter index → API type param (empty = all)
  static const _filters    = ['All', 'PDFs', 'Notes', 'Past Papers', 'Videos', 'Links'];
  static const _filterKeys = ['',    'pdf',  'notes', 'past_paper',  'video',  'link'];

  @override
  void initState() {
    super.initState();
    _fetchResources();
  }

  Future<void> _fetchResources() async {
    if (mounted) setState(() { _loading = true; _error = null; });

    try {
      final typeKey = _filterKeys[_filter];
      final data    = await _ResourcesApi.fetchResources(
        type:   typeKey.isEmpty ? null : typeKey,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (mounted) setState(() { _resources = data; _loading = false; });
    } catch (e, st) {
      dev.log('[SBResources] _fetchResources error: $e', stackTrace: st);
      if (mounted) {
        setState(() {
          _error   = 'Could not load resources. Check your connection.';
          _loading = false;
        });
      }
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: SBColors.brandDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

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
        title: const Text('Resources', style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700, color: SBColors.text)),
        actions: [
          GestureDetector(
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SBUploadResourceScreen()));
              // Reload after returning from upload screen
              _fetchResources();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: SBColors.brand, borderRadius: BorderRadius.circular(10)),
              child: const Text('+ Upload', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _fetchResources(),
        color: SBColors.brand,
        child: CustomScrollView(
          slivers: [
            // ── Search bar ──────────────────────────────────
            SliverToBoxAdapter(
              child: SBSearchBar(
                hint: 'Search by subject, course, type...',
                onChanged: (q) {
                  setState(() => _searchQuery = q);
                  _fetchResources();
                },
              ),
            ),

            // ── Type filter chips ───────────────────────────
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
                    onTap: () {
                      setState(() => _filter = i);
                      _fetchResources();
                    },
                  ),
                ),
              ),
            ),

            // ── Content ────────────────────────────────────
            SliverToBoxAdapter(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Loading state — shimmer cards
    if (_loading) {
      return Column(children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SBSectionLabel(title: 'Loading resources...', action: 'See all'),
        ),
        ..._shimmerCards(),
      ]);
    }

    // Error state (same pattern as _NameBlock)
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(children: [
          const Text('⚠️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: SBColors.text2)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _fetchResources,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                  color: SBColors.brand, borderRadius: BorderRadius.circular(12)),
              child: const Text('Retry', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ]),
      );
    }

    final resources = _resources ?? [];

    if (resources.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(children: const [
          Text('📭', style: TextStyle(fontSize: 40)),
          SizedBox(height: 12),
          Text('No resources found', style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: SBColors.text)),
          SizedBox(height: 4),
          Text('Try a different filter or upload one!',
              style: TextStyle(fontSize: 12, color: SBColors.text3)),
        ]),
      );
    }

    // Extract unique course codes for pills
    final courses = resources.map((r) => r.course).where((c) => c.isNotEmpty).toSet().take(5).toList();

    return Column(children: [
      // Course pills
      if (courses.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Wrap(spacing: 8, children: courses
              .map((c) => _CoursePill(c))
              .toList()),
        ),

      // Section header
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SBSectionLabel(
          title: 'Trending This Week 🔥 (${resources.length})',
          action: 'See all'),
      ),

      // Resource cards
      ...resources.map((r) => _ResourceCard(
        emoji:  r.emoji,
        iconBg: r.iconBg,
        name:   r.name,
        meta:   r.meta,
        course: r.course,
        stat:   r.stat,
      )),
      const SizedBox(height: 24),
    ]);
  }

  List<Widget> _shimmerCards() => List.generate(4, (_) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: SBTheme.card,
    child: Row(children: [
      Container(width: 44, height: 44,
          decoration: BoxDecoration(color: SBColors.border,
              borderRadius: BorderRadius.circular(12))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: double.infinity, height: 12,
            decoration: BoxDecoration(color: SBColors.border,
                borderRadius: BorderRadius.circular(6))),
        const SizedBox(height: 6),
        Container(width: 160, height: 10,
            decoration: BoxDecoration(color: SBColors.border,
                borderRadius: BorderRadius.circular(5))),
        const SizedBox(height: 6),
        Container(width: 60, height: 18,
            decoration: BoxDecoration(color: SBColors.border,
                borderRadius: BorderRadius.circular(9))),
      ])),
    ]),
  ));
}

// ─────────────────────────────────────────────────────────────
//  COURSE PILL
// ─────────────────────────────────────────────────────────────
class _CoursePill extends StatelessWidget {
  final String label;
  const _CoursePill(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
        color: SBColors.brandPale, borderRadius: BorderRadius.circular(10)),
    child: Text(label, style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700, color: SBColors.brand)),
  );
}

// ─────────────────────────────────────────────────────────────
//  RESOURCE CARD
// ─────────────────────────────────────────────────────────────
class _ResourceCard extends StatelessWidget {
  final String emoji, name, meta, course, stat;
  final Color  iconBg;

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
        decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
        const SizedBox(height: 3),
        Text(meta, style: const TextStyle(fontSize: 11, color: SBColors.text3)),
        const SizedBox(height: 4),
        if (course.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
                color: SBColors.brandPale, borderRadius: BorderRadius.circular(6)),
            child: Text(course, style: const TextStyle(
                fontSize: 9, fontWeight: FontWeight.w700, color: SBColors.brand)),
          ),
      ])),
      const SizedBox(width: 10),
      const Icon(Icons.download_outlined, color: SBColors.brand, size: 22),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────
//  2. UPLOAD RESOURCE
// ─────────────────────────────────────────────────────────────
class SBUploadResourceScreen extends StatefulWidget {
  const SBUploadResourceScreen({super.key});

  @override
  State<SBUploadResourceScreen> createState() => _SBUploadResourceScreenState();
}

class _SBUploadResourceScreenState extends State<SBUploadResourceScreen> {
  int    _typeIdx    = 0;
  String _visibility = 'Public';
  bool   _loading    = false;

  final _titleCtrl  = TextEditingController();
  final _courseCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();

  static const _types    = ['📄 PDF', '📝 Notes', '📊 Past Paper', '🎬 Video', '🔗 Link'];
  static const _typeKeys = ['pdf',    'notes',    'past_paper',     'video',    'link'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _courseCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a resource title')));
      return;
    }
    setState(() => _loading = true);
    try {
      await _ResourcesApi.uploadResource({
        'title':       _titleCtrl.text.trim(),
        'course':      _courseCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'type':        _typeKeys[_typeIdx],
        'visibility':  _visibility.toLowerCase(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('📁  Resource shared successfully!'),
        backgroundColor: SBColors.brand,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e, st) {
      dev.log('[SBResources] _submit error: $e', stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Upload failed: ${e.toString()}'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
        title: const Text('Share a Resource', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: SBColors.text)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _loading ? null : _submit,
              child: Center(
                child: _loading
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: SBColors.brand))
                    : const Text('Post', style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.brand)),
              ),
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
              child: Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📤', style: TextStyle(fontSize: 34)),
                  const SizedBox(height: 8),
                  const Text('Tap to upload a file', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
                  const SizedBox(height: 4),
                  const Text('PDF, Word, Images, Videos',
                      style: TextStyle(fontSize: 11, color: SBColors.text3)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, children: ['PDF', 'DOC', 'PPT', 'IMG', 'MP4']
                    .map<Widget>((f) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: SBColors.border),
                      ),
                      child: Text(f, style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700, color: SBColors.text2)),
                    )).toList()),
                ],
              )),
            ),
          ),
          const SizedBox(height: 16),

          // Type selector
          const Text('RESOURCE TYPE', style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: SBColors.text3, letterSpacing: 1)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8,
            children: List.generate(_types.length, (i) => SBChip(
              label: _types[i],
              active: _typeIdx == i,
              onTap: () => setState(() => _typeIdx = i),
            )),
          ),
          const SizedBox(height: 16),

          SBFormField(label: 'Resource Title', controller: _titleCtrl),
          const SizedBox(height: 12),
          SBFormField(label: 'Course Code', controller: _courseCtrl),
          const SizedBox(height: 12),
          SBFormField(label: 'Description (optional)', controller: _descCtrl, multiline: true),
          const SizedBox(height: 16),

          // Visibility
          const Text('VISIBILITY', style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: SBColors.text3, letterSpacing: 1)),
          const SizedBox(height: 10),
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
                  child: Center(child: Text(opt, style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: _visibility == key ? SBColors.brand : SBColors.text2))),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 20),

          // Submit
          GestureDetector(
            onTap: _loading ? null : _submit,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: _loading ? SBColors.brand.withOpacity(0.6) : SBColors.brand,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: SBColors.brand.withOpacity(0.3),
                    blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: Center(
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('📤  Share Resource', style: TextStyle(
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