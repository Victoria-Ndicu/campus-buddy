// ============================================================
//  StudyBuddy — sb_tutors_screen.dart  (API-connected)
//
//  GET /api/study/tutors/?subject=&search=  → tutor list
//  POST /api/study/bookings/                → create booking
//  POST /api/study/tutors/                  → upsert tutor profile
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/sb_constants.dart';
import '../widgets/sb_widgets.dart';

// ── API config ────────────────────────────────────────────────
const String _kBaseUrl = 'https://campusbuddybackend-production.up.railway.app/api/v1/study-buddy/';

// ── Auth helper (plug in your token source) ───────────────────
Map<String, String> get _headers => {
      'Content-Type': 'application/json',
      // 'Authorization': 'Bearer ${AuthService.instance.token}',
    };

// ── Tutor model ───────────────────────────────────────────────
class TutorModel {
  final String id;
  final String name;
  final String subject;
  final String qualification;
  final double hourlyRate;
  final double rating;
  final int reviewCount;
  final int sessionCount;
  final List<String> tags;
  final bool isOnline;
  final String emoji;
  final List<Color> gradient;
  final String bio;
  final String responseRate;
  final List<bool> availability; // Mon–Sun

  const TutorModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.qualification,
    required this.hourlyRate,
    required this.rating,
    required this.reviewCount,
    required this.sessionCount,
    required this.tags,
    required this.isOnline,
    required this.emoji,
    required this.gradient,
    required this.bio,
    required this.responseRate,
    required this.availability,
  });

  /// Cycle through a small set of gradients based on index
  static List<Color> _gradientForIndex(int i) {
    const gradients = [
      [Color(0xFF667EEA), Color(0xFF4A5FCC)],
      [Color(0xFF3ECF8E), Color(0xFF0D9488)],
      [Color(0xFFF5A623), Color(0xFFE67E22)],
      [Color(0xFFFF6B6B), Color(0xFFC0392B)],
      [Color(0xFFAA96DA), Color(0xFF7C6FC4)],
      [Color(0xFF56CCF2), Color(0xFF2F80ED)],
    ];
    return gradients[i % gradients.length];
  }

  static String _emojiForSubject(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math') || s.contains('calculus') || s.contains('stat')) return '👩‍🎓';
    if (s.contains('cs') || s.contains('computer') || s.contains('python') || s.contains('code')) return '👨‍💻';
    if (s.contains('chem')) return '👩‍🔬';
    if (s.contains('econ') || s.contains('finance') || s.contains('business')) return '👨‍🏫';
    if (s.contains('phys')) return '🔭';
    if (s.contains('bio')) return '🧬';
    return '📚';
  }

  factory TutorModel.fromJson(Map<String, dynamic> json, int index) {
    // Tags: prefer specializations list, else split subject string
    List<String> tags = [];
    if (json['specializations'] is List) {
      tags = (json['specializations'] as List).map((e) => e.toString()).toList();
    } else if (json['subjects'] is List) {
      tags = (json['subjects'] as List).map((e) => e.toString()).toList();
    } else if (json['subject'] is String) {
      tags = (json['subject'] as String).split(',').map((e) => e.trim()).take(3).toList();
    }

    // Availability: look for a boolean list or default all true
    List<bool> avail = List.filled(7, true);
    if (json['availability'] is List) {
      final raw = json['availability'] as List;
      avail = List.generate(7, (i) => i < raw.length ? (raw[i] == true) : false);
    }

    final subject = json['subject'] as String? ?? json['subjects']?[0] ?? 'General';

    return TutorModel(
      id:           json['id']?.toString() ?? '',
      name:         json['name'] as String? ?? json['user']?['full_name'] as String? ?? 'Tutor',
      subject:      subject,
      qualification: json['qualification'] as String? ?? json['university'] as String? ?? '',
      hourlyRate:   (json['hourly_rate'] ?? json['rate'] ?? 0).toDouble(),
      rating:       (json['rating'] ?? json['average_rating'] ?? 0.0).toDouble(),
      reviewCount:  (json['review_count'] ?? json['reviews_count'] ?? 0) as int,
      sessionCount: (json['session_count'] ?? json['total_sessions'] ?? 0) as int,
      tags:         tags.isEmpty ? [subject] : tags,
      isOnline:     json['is_online'] as bool? ?? json['online'] as bool? ?? false,
      emoji:        _emojiForSubject(subject),
      gradient:     _gradientForIndex(index),
      bio:          json['bio'] as String? ?? json['about'] as String? ?? '',
      responseRate: json['response_rate'] as String? ?? '—',
      availability: avail,
    );
  }
}

// ── API service ───────────────────────────────────────────────
class _TutorsApi {
  static Future<List<TutorModel>> fetchTutors({String? subject, String? search}) async {
    final params = <String, String>{};
    if (subject != null && subject.isNotEmpty) params['subject'] = subject;
    if (search  != null && search.isNotEmpty)  params['search']  = search;

    final uri = Uri.parse('$_kBaseUrl/tutors/').replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) throw Exception('Failed to load tutors (${res.statusCode})');

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (body['results'] ?? body) as List<dynamic>;
    return results
        .asMap()
        .entries
        .map((e) => TutorModel.fromJson(e.value as Map<String, dynamic>, e.key))
        .toList();
  }

  static Future<Map<String, dynamic>> createBooking(Map<String, dynamic> payload) async {
    final res = await http
        .post(Uri.parse('$_kBaseUrl/bookings/'),
            headers: _headers, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 201) throw Exception('Booking failed (${res.statusCode})');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}

// ─────────────────────────────────────────────────────────────
//  1. Browse Tutors
// ─────────────────────────────────────────────────────────────
class SBTutorsScreen extends StatefulWidget {
  const SBTutorsScreen({super.key});

  @override
  State<SBTutorsScreen> createState() => _SBTutorsScreenState();
}

class _SBTutorsScreenState extends State<SBTutorsScreen> {
  int _filter = 0;
  final _filters = ['All Subjects', 'Maths', 'Physics', 'CS', 'Economics', 'Chemistry'];

  String _searchQuery = '';
  late Future<List<TutorModel>> _tutorsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final subject = _filter == 0 ? null : _filters[_filter];
    _tutorsFuture = _TutorsApi.fetchTutors(
      subject: subject,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
  }

  void _applyFilter(int i) => setState(() {
        _filter = i;
        _load();
      });

  void _applySearch(String q) => setState(() {
        _searchQuery = q;
        _load();
      });

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
        title: const Text('Find a Tutor',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: SBColors.text)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 36, height: 36,
            decoration: BoxDecoration(color: SBColors.brand, borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Text('⚙️', style: TextStyle(fontSize: 16))),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Search bar ────────────────────────────────────
          SliverToBoxAdapter(
            child: SBSearchBar(
              hint: 'Search by subject, name...',
              onChanged: _applySearch,
            ),
          ),

          // ── Subject filter chips ──────────────────────────
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
                  onTap: () => _applyFilter(i),
                ),
              ),
            ),
          ),

          // ── Additional filter pills ───────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(children: [
                _FilterPill('💰', 'Price Range', '\$10 – \$50/hr'),
                const SizedBox(width: 8),
                _FilterPill('⭐', 'Min Rating', '4.0 & above'),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SBColors.border, width: 1.5),
                  ),
                  child: const Text('📅', style: TextStyle(fontSize: 14)),
                ),
              ]),
            ),
          ),

          // ── Results list ──────────────────────────────────
          SliverToBoxAdapter(
            child: FutureBuilder<List<TutorModel>>(
              future: _tutorsFuture,
              builder: (context, snap) {
                // Loading
                if (snap.connectionState == ConnectionState.waiting) {
                  return Column(children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: SBSectionLabel(title: 'Loading tutors...', action: 'Sort ↕'),
                    ),
                    ..._buildShimmerCards(),
                  ]);
                }

                // Error
                if (snap.hasError) {
                  return _ErrorState(onRetry: () => setState(() => _load()));
                }

                final tutors = snap.data ?? [];

                // Empty
                if (tutors.isEmpty) {
                  return const _EmptyState();
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: SBSectionLabel(
                          title: '${tutors.length} tutor${tutors.length == 1 ? '' : 's'} found',
                          action: 'Sort ↕'),
                    ),
                    ...tutors.map((t) => _TutorCard(
                          tutor: t,
                          onViewProfile: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => SBTutorProfileScreen(tutor: t))),
                          onBook: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => SBBookingScreen(tutor: t))),
                        )),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildShimmerCards() => List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(14),
          decoration: SBTheme.card,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                    color: SBColors.border, borderRadius: BorderRadius.circular(16))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 120, height: 12,
                    decoration: BoxDecoration(color: SBColors.border,
                        borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 8),
                Container(width: 180, height: 10,
                    decoration: BoxDecoration(color: SBColors.border,
                        borderRadius: BorderRadius.circular(5))),
                const SizedBox(height: 8),
                Container(width: double.infinity, height: 10,
                    decoration: BoxDecoration(color: SBColors.border,
                        borderRadius: BorderRadius.circular(5))),
              ]),
            ),
          ]),
        ),
      );
}

// ── Filter pill (unchanged) ───────────────────────────────────
class _FilterPill extends StatelessWidget {
  final String icon, label, value;
  const _FilterPill(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SBColors.border, width: 1.5),
          ),
          child: Row(children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontSize: 9, color: SBColors.text3)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, color: SBColors.text)),
              ]),
            ),
          ]),
        ),
      );
}

// ── Tutor card (now data-driven, same visual) ─────────────────
class _TutorCard extends StatelessWidget {
  final TutorModel tutor;
  final VoidCallback onViewProfile, onBook;

  const _TutorCard({
    required this.tutor,
    required this.onViewProfile,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onViewProfile,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(14),
          decoration: SBTheme.card,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: tutor.gradient),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                    child: Text(tutor.emoji, style: const TextStyle(fontSize: 24))),
              ),
              if (tutor.isOnline)
                Positioned(
                  bottom: 2, right: 2,
                  child: Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: SBColors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tutor.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: SBColors.text)),
                const SizedBox(height: 2),
                Text(
                  [tutor.subject, if (tutor.qualification.isNotEmpty) tutor.qualification]
                      .join(' · '),
                  style: const TextStyle(fontSize: 11, color: SBColors.text2),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 5, runSpacing: 5,
                  children: tutor.tags.take(3).map<Widget>((t) => SBTag(t)).toList(),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      tutor.hourlyRate > 0
                          ? '\$${tutor.hourlyRate.toStringAsFixed(0)}/hr'
                          : 'Free',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: SBColors.brand),
                    ),
                    Text(
                      tutor.rating > 0
                          ? '⭐ ${tutor.rating.toStringAsFixed(1)}  (${tutor.reviewCount} reviews)'
                          : 'No reviews yet',
                      style: const TextStyle(fontSize: 11, color: SBColors.accent),
                    ),
                  ]),
                  const Spacer(),
                  GestureDetector(
                    onTap: onBook,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: SBColors.brand,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Book',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      );
}

// ── Empty / error states ──────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(40),
        child: Column(children: [
          const Text('🔍', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          const Text('No tutors found',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: SBColors.text)),
          const SizedBox(height: 4),
          const Text('Try a different subject or search term',
              style: TextStyle(fontSize: 12, color: SBColors.text3)),
        ]),
      );
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(40),
        child: Column(children: [
          const Text('⚠️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          const Text('Could not load tutors',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: SBColors.text)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                  color: SBColors.brand, borderRadius: BorderRadius.circular(12)),
              child: const Text('Retry',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
//  2. Tutor Profile  (data-driven)
// ─────────────────────────────────────────────────────────────
class SBTutorProfileScreen extends StatelessWidget {
  final TutorModel tutor;

  const SBTutorProfileScreen({super.key, required this.tutor});

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SBColors.surface2,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [SBColors.brand, SBColors.brandDark],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(children: [
                    Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: tutor.gradient),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3), width: 2),
                        ),
                        child: Center(
                          child: Text(tutor.emoji,
                              style: const TextStyle(fontSize: 30)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tutor.name,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                              const SizedBox(height: 4),
                              Text(
                                tutor.qualification.isNotEmpty
                                    ? '${tutor.subject} · ${tutor.qualification}'
                                    : tutor.subject,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.75)),
                              ),
                              const SizedBox(height: 6),
                              Row(children: [
                                Text(
                                  tutor.rating > 0
                                      ? '★' * tutor.rating.round()
                                      : '—',
                                  style: const TextStyle(
                                      color: SBColors.accent, fontSize: 13),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  tutor.rating > 0
                                      ? '${tutor.rating.toStringAsFixed(1)} · ${tutor.reviewCount} reviews'
                                      : 'No reviews yet',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ]),
                            ]),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      _ActionBtn('💬', 'Message'),
                      const SizedBox(width: 8),
                      _ActionBtn('🤝', 'Follow'),
                      const SizedBox(width: 8),
                      _ActionBtn('↗', 'Share'),
                    ]),
                  ]),
                ),
              ),
            ),
          ),

          // ── Stats row ─────────────────────────────────────
          SliverToBoxAdapter(
            child: _StatsRow([
              ('${tutor.reviewCount}', 'Reviews'),
              ('${tutor.sessionCount}', 'Sessions'),
              (tutor.responseRate, 'Response'),
            ]),
          ),

          // ── Detail sections ───────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),

                if (tutor.tags.isNotEmpty)
                  _ProfileSection(
                    label: 'Subjects',
                    child: Wrap(
                      spacing: 6, runSpacing: 6,
                      children: tutor.tags.map<Widget>((t) => SBTag(t)).toList(),
                    ),
                  ),

                _ProfileSection(
                  label: 'Rate & Qualifications',
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.8,
                    children: [
                      _InfoBox('Hourly Rate',
                          tutor.hourlyRate > 0
                              ? '\$${tutor.hourlyRate.toStringAsFixed(0)}/hr'
                              : 'Free'),
                      _InfoBox('Qualification',
                          tutor.qualification.isNotEmpty ? tutor.qualification : '—'),
                      _InfoBox('Subject', tutor.subject),
                      _InfoBox('Status', tutor.isOnline ? 'Online now' : 'Offline'),
                    ],
                  ),
                ),

                _ProfileSection(
                  label: 'Availability This Week',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      7,
                      (i) => _AvailChip(
                        _dayLabels[i],
                        i < tutor.availability.length
                            ? tutor.availability[i]
                            : false,
                      ),
                    ),
                  ),
                ),

                if (tutor.bio.isNotEmpty)
                  _ProfileSection(
                    label: 'About',
                    child: Text(
                      tutor.bio,
                      style: const TextStyle(
                          fontSize: 13, color: SBColors.text2, height: 1.6),
                    ),
                  ),

                const SizedBox(height: 8),
              ]),
            ),
          ),

          // ── Book button ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SBPrimaryButton(
                label: '📅  Book a Session',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SBBookingScreen(tutor: tutor))),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String icon, label;
  const _ActionBtn(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Center(
            child: Text('$icon  $label',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      );
}

class _StatsRow extends StatelessWidget {
  final List<(String, String)> items;
  const _StatsRow(this.items);
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SBColors.border),
        ),
        child: Row(
          children: items.indexed.map(((int, (String, String)) e) {
            final (i, (val, lbl)) = e;
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    right: i < items.length - 1
                        ? const BorderSide(color: SBColors.border)
                        : BorderSide.none,
                  ),
                ),
                child: Column(children: [
                  Text(val,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: SBColors.brand)),
                  const SizedBox(height: 2),
                  Text(lbl,
                      style: const TextStyle(fontSize: 10, color: SBColors.text3)),
                ]),
              ),
            );
          }).toList(),
        ),
      );
}

class _ProfileSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _ProfileSection({required this.label, required this.child});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: SBColors.text3,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          child,
        ]),
      );
}

class _InfoBox extends StatelessWidget {
  final String label, value;
  const _InfoBox(this.label, this.value);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SBColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: SBColors.text3)),
            Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: SBColors.text)),
          ],
        ),
      );
}

class _AvailChip extends StatelessWidget {
  final String day;
  final bool available;
  const _AvailChip(this.day, this.available);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: available ? SBColors.green.withOpacity(0.1) : SBColors.surface3,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(day,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: available ? SBColors.green : SBColors.text3)),
      );
}

// ─────────────────────────────────────────────────────────────
//  3. Booking Screen  (posts to /api/study/bookings/)
// ─────────────────────────────────────────────────────────────
class SBBookingScreen extends StatefulWidget {
  final TutorModel tutor;
  const SBBookingScreen({super.key, required this.tutor});

  @override
  State<SBBookingScreen> createState() => _SBBookingScreenState();
}

class _SBBookingScreenState extends State<SBBookingScreen> {
  int    _selDay  = 0;
  int    _selTime = 0;
  String _mode    = 'Online';
  bool   _loading = false;

  static const _days  = ['Mon\n14', 'Tue\n15', 'Wed\n16', 'Thu\n17', 'Fri\n18', 'Sat\n19'];
  static const _times = ['9:00 AM', '10:00 AM', '11:00 AM', '2:00 PM', '3:00 PM', '4:00 PM'];

  // Build an ISO datetime from selected day/time (rough demo — adjust to your date logic)
  String get _scheduledAt {
    final now = DateTime.now();
    final dayOffset = _selDay; // offset from today
    final hour = [9, 10, 11, 14, 15, 16][_selTime];
    final dt = DateTime(now.year, now.month, now.day + dayOffset, hour, 0);
    return dt.toIso8601String();
  }

  Future<void> _confirmBooking() async {
    setState(() => _loading = true);
    try {
      await _TutorsApi.createBooking({
        'tutor': widget.tutor.id,
        'scheduled_at': _scheduledAt,
        'mode': _mode.toLowerCase(),
        'status': 'pending',
      });
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Session Booked!',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: SBColors.text)),
            const SizedBox(height: 8),
            Text(
              'Your session with ${widget.tutor.name} has been confirmed.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: SBColors.text2),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Done',
                  style: TextStyle(
                      color: SBColors.brand, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tutor = widget.tutor;

    return Scaffold(
      backgroundColor: SBColors.surface2,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: SBColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Book a Session',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: SBColors.text)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Tutor summary card ──────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: SBTheme.card,
            child: Row(children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: tutor.gradient),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                    child: Text(tutor.emoji, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tutor.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SBColors.text)),
                Text('${tutor.subject} Tutor',
                    style: const TextStyle(fontSize: 11, color: SBColors.text2)),
                const SizedBox(height: 4),
                Text(
                  [
                    if (tutor.hourlyRate > 0)
                      '\$${tutor.hourlyRate.toStringAsFixed(0)}/hr',
                    if (tutor.rating > 0) '⭐ ${tutor.rating.toStringAsFixed(1)}',
                  ].join('  ·  '),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: SBColors.brand),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Date picker ─────────────────────────────────
          const _BookLabel('SELECT DATE'),
          const SizedBox(height: 10),
          SizedBox(
            height: 68,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => setState(() => _selDay = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 56,
                  decoration: BoxDecoration(
                    color: _selDay == i ? SBColors.brand : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _selDay == i ? SBColors.brand : SBColors.border,
                        width: 1.5),
                  ),
                  child: Center(
                    child: Text(_days[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _selDay == i ? Colors.white : SBColors.text2,
                            height: 1.5)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Time picker ─────────────────────────────────
          const _BookLabel('SELECT TIME'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: List.generate(
              _times.length,
              (i) => GestureDetector(
                onTap: () => setState(() => _selTime = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _selTime == i ? SBColors.brand : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _selTime == i ? SBColors.brand : SBColors.border,
                        width: 1.5),
                  ),
                  child: Text(_times[i],
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _selTime == i ? Colors.white : SBColors.text2)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Mode picker ─────────────────────────────────
          const _BookLabel('SESSION MODE'),
          const SizedBox(height: 10),
          Row(
            children: ['Online', 'In-person'].map((m) => Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _mode = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _mode == m ? SBColors.brand : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _mode == m ? SBColors.brand : SBColors.border,
                        width: 1.5),
                  ),
                  child: Center(
                    child: Text(m,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _mode == m ? Colors.white : SBColors.text2)),
                  ),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),

          // ── Total ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: SBColors.brandPale,
                borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Session Total',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: SBColors.text)),
                Text(
                  tutor.hourlyRate > 0
                      ? '\$${tutor.hourlyRate.toStringAsFixed(2)}'
                      : 'Free',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: SBColors.brand),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Confirm button ──────────────────────────────
          GestureDetector(
            onTap: _loading ? null : _confirmBooking,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: _loading
                    ? SBColors.brand.withOpacity(0.6)
                    : SBColors.brand,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: SBColors.brand.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('✅  Confirm Booking',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _BookLabel extends StatelessWidget {
  final String text;
  const _BookLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: SBColors.text3,
            letterSpacing: 1),
      );
}