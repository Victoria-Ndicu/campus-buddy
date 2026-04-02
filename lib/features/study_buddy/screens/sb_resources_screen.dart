// ============================================================
//  
//StudyBuddy — sb_resources_screen.dart
//
//  Read-only. Resources are curated by admins.
//  GET /api/v1/study-buddy/resources/?resource_type=&search=
// ============================================================

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api_client.dart';
import '../models/sb_constants.dart';
import '../widgets/sb_widgets.dart';

// ─────────────────────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────────────────────
class ResourceModel {
  final String id;
  final String name;
  final String subject;
  final String topic;
  final String type;
  final String stat;
  final String fileUrl;
  final String emoji;
  final Color  iconBg;

  const ResourceModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.topic,
    required this.type,
    required this.stat,
    required this.fileUrl,
    required this.emoji,
    required this.iconBg,
  });

  static String _emojiForType(String type) {
    switch (type.toLowerCase()) {
      case 'video': return '🎬';
      case 'doc':   return '📝';
      case 'link':  return '🔗';
      default:      return '📄';
    }
  }

  static Color _bgForType(String type) {
    switch (type.toLowerCase()) {
      case 'video': return const Color(0xFFFFF0F0);
      case 'doc':   return const Color(0xFFEDFAF5);
      case 'link':  return const Color(0xFFF5F0FF);
      default:      return SBColors.brandPale;
    }
  }

  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    // Accept both camelCase (serializer output) and snake_case (fallback)
    final type      = (json['resourceType'] ?? json['resource_type'] ?? 'pdf').toString();
    final downloads = json['downloadCount'] ?? json['download_count'] ?? 0;
    final fileUrl   = (json['fileUrl'] ?? json['file_url'] ?? '').toString();

    return ResourceModel(
      id:      (json['id'] ?? '').toString(),
      name:    (json['title'] ?? 'Resource').toString(),
      subject: (json['subject'] ?? '').toString(),
      topic:   (json['topic'] ?? '').toString(),
      type:    type,
      stat:    '$downloads downloads',
      fileUrl: fileUrl,
      emoji:   _emojiForType(type),
      iconBg:  _bgForType(type),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  API SERVICE
// ─────────────────────────────────────────────────────────────
class _ResourcesApi {
  // ✅ Update _base to match your Django URL prefix exactly.
  //    Run: python3 manage.py show_urls | grep resource
  static const _base = '/api/v1/study-buddy';

  static Future<List<ResourceModel>> fetchResources({
    String? resourceType,
    String? search,
  }) async {
    final params = <String, String>{};
    if (resourceType != null && resourceType.isNotEmpty)
      params['resource_type'] = resourceType;
    if (search != null && search.isNotEmpty)
      params['search'] = search;

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final path = query.isEmpty
        ? '$_base/resources/'
        : '$_base/resources/?$query';

    final res = await ApiClient.get(path);

    // ── Debug logs — remove once confirmed working ──
    dev.log('[SBResources] GET $path → ${res.statusCode}');
    dev.log('[SBResources] BODY: ${res.body}');

    if (res.statusCode != 200) {
      throw Exception('Failed to load resources (${res.statusCode})');
    }

    // ✅ Handle both:
    //   paginated  → {"count": 15, "results": [...]}
    //   plain list → [...]
    final decoded = jsonDecode(res.body);
    final List<dynamic> results;
    if (decoded is List) {
      results = decoded;
    } else if (decoded is Map<String, dynamic>) {
      results = (decoded['results'] ?? decoded['data'] ?? []) as List<dynamic>;
    } else {
      results = [];
    }

    dev.log('[SBResources] Parsed ${results.length} resources');

    return results
        .map((e) => ResourceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN
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

  // ✅ Filter labels → resource_type values that match your DB TYPE_CHOICES
  static const _filters    = ['All', 'PDFs', 'Docs', 'Videos', 'Links', 'Other'];
  static const _filterKeys = ['',    'pdf',  'doc',  'video',  'link',  'other'];

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
        resourceType: typeKey.isEmpty ? null : typeKey,
        search:       _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (mounted) setState(() { _resources = data; _loading = false; });
    } catch (e, st) {
      dev.log('[SBResources] fetch error: $e', stackTrace: st);
      if (mounted) setState(() {
        _error   = 'Could not load resources.\n\n${e.toString()}';
        _loading = false;
      });
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
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: SBColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Resources', style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700, color: SBColors.text)),
        // No upload button — resources are admin-managed
      ),
      body: RefreshIndicator(
        onRefresh: () async => _fetchResources(),
        color: SBColors.brand,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SBSearchBar(
                hint: 'Search by subject or topic...',
                onChanged: (q) {
                  setState(() => _searchQuery = q);
                  _fetchResources();
                },
              ),
            ),

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

            SliverToBoxAdapter(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return Column(children: [
        const SizedBox(height: 12),
        ..._shimmerCards(),
      ]);
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(children: [
          const Text('⚠️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: SBColors.text2)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _fetchResources,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                  color: SBColors.brand,
                  borderRadius: BorderRadius.circular(12)),
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
          Text('Try a different filter or search term.',
              style: TextStyle(fontSize: 12, color: SBColors.text3)),
        ]),
      );
    }

    final subjects = resources
        .map((r) => r.subject)
        .where((s) => s.isNotEmpty)
        .toSet()
        .take(5)
        .toList();

    return Column(children: [
      if (subjects.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Wrap(
            spacing: 8, runSpacing: 8,
            children: subjects.map((s) => _SubjectPill(s)).toList(),
          ),
        ),

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SBSectionLabel(
          title: '${resources.length} resource${resources.length == 1 ? '' : 's'} available',
          action: '',
        ),
      ),

      ...resources.map((r) => _ResourceCard(resource: r)),
      const SizedBox(height: 24),
    ]);
  }

  List<Widget> _shimmerCards() => List.generate(4, (_) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: SBTheme.card,
    child: Row(children: [
      Container(width: 44, height: 44,
          decoration: BoxDecoration(
              color: SBColors.border,
              borderRadius: BorderRadius.circular(12))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: double.infinity, height: 12,
            decoration: BoxDecoration(
                color: SBColors.border,
                borderRadius: BorderRadius.circular(6))),
        const SizedBox(height: 6),
        Container(width: 160, height: 10,
            decoration: BoxDecoration(
                color: SBColors.border,
                borderRadius: BorderRadius.circular(5))),
      ])),
    ]),
  ));
}

// ─────────────────────────────────────────────────────────────
//  SUBJECT PILL
// ─────────────────────────────────────────────────────────────
class _SubjectPill extends StatelessWidget {
  final String label;
  const _SubjectPill(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
        color: SBColors.brandPale,
        borderRadius: BorderRadius.circular(10)),
    child: Text(label, style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700, color: SBColors.brand)),
  );
}

// ─────────────────────────────────────────────────────────────
//  RESOURCE CARD
// ─────────────────────────────────────────────────────────────
class _ResourceCard extends StatelessWidget {
  final ResourceModel resource;
  const _ResourceCard({required this.resource});

  Future<void> _open(BuildContext context) async {
    final url = resource.fileUrl.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No link available for this resource.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Invalid resource link.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not open: $url'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => _open(context),
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: SBTheme.card,
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: resource.iconBg,
              borderRadius: BorderRadius.circular(12)),
          child: Center(
              child: Text(resource.emoji,
                  style: const TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 12),

        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(resource.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SBColors.text)),
            if (resource.topic.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(resource.topic,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: SBColors.text3)),
            ],
            const SizedBox(height: 5),
            Row(children: [
              if (resource.subject.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: SBColors.brandPale,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(resource.subject,
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: SBColors.brand)),
                ),
                const SizedBox(width: 6),
              ],
              Text(resource.stat,
                  style: const TextStyle(fontSize: 10, color: SBColors.text3)),
            ]),
          ],
        )),

        const SizedBox(width: 10),
        const Icon(Icons.open_in_new_outlined,
            color: SBColors.brand, size: 20),
      ]),
    ),
  );
}
