// ============================================================
//  StudyBuddy — sb_tutors_screen.dart  (API-connected)
//
//  GET  /api/v1/study-buddy/tutors/    → tutor list
//  GET  /api/v1/study-buddy/bookings/  → student's bookings (for conflict check)
//  POST /api/v1/study-buddy/bookings/  → create booking
// ============================================================

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api_client.dart';
import '../models/sb_constants.dart';
import '../widgets/sb_widgets.dart';

// ─────────────────────────────────────────────────────────────
//  TUTOR MODEL
// ─────────────────────────────────────────────────────────────
class TutorModel {
  final String id;
  final String name;
  final String subject;
  final double hourlyRate;
  final double rating;
  final int reviewCount;
  final List<String> tags;
  final bool isOnline;
  final String emoji;
  final List<Color> gradient;
  final String bio;
  final List<bool> availability;

  const TutorModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.hourlyRate,
    required this.rating,
    required this.reviewCount,
    required this.tags,
    required this.isOnline,
    required this.emoji,
    required this.gradient,
    required this.bio,
    required this.availability,
  });

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
    if (s.contains('cs') || s.contains('computer') || s.contains('python') ||
        s.contains('software') || s.contains('web') || s.contains('database')) return '👨‍💻';
    if (s.contains('chem')) return '👩‍🔬';
    if (s.contains('econ') || s.contains('finance') ||
        s.contains('accounting') || s.contains('business')) return '👨‍🏫';
    if (s.contains('law') || s.contains('legal') || s.contains('constitutional')) return '⚖️';
    if (s.contains('circuit') || s.contains('electr') || s.contains('signal')) return '⚡';
    if (s.contains('anatomy') || s.contains('physio') || s.contains('medical')) return '🩺';
    if (s.contains('research') || s.contains('sociology') || s.contains('spss')) return '📊';
    if (s.contains('bio')) return '🧬';
    return '📚';
  }

  factory TutorModel.fromJson(Map<String, dynamic> json, int index) {
    List<String> tags = [];
    if (json['subjects'] is List) {
      tags = (json['subjects'] as List).map((e) => e.toString()).toList();
    } else if (json['specializations'] is List) {
      tags = (json['specializations'] as List).map((e) => e.toString()).toList();
    } else if (json['subject'] is String) {
      tags = (json['subject'] as String).split(',').map((e) => e.trim()).take(3).toList();
    }

    final subject = tags.isNotEmpty ? tags.first : 'General';

    List<bool> avail = List.filled(7, true);
    if (json['availability'] is List) {
      final raw = json['availability'] as List;
      avail = List.generate(7, (i) => i < raw.length ? (raw[i] == true) : false);
    }

    final rawRate    = json['hourlyRate'] ?? json['hourly_rate'] ?? json['rate'] ?? 0;
    final rawRating  = json['rating'] ?? json['average_rating'] ?? 0.0;
    final rawReviews = json['review_count'] ?? json['reviewCount'] ?? json['reviews_count'] ?? 0;

    return TutorModel(
      id:          json['id']?.toString() ?? '',
      name:        json['name'] as String? ??
                   json['user']?['full_name'] as String? ??
                   json['user']?['username'] as String? ?? 'Tutor',
      subject:     subject,
      hourlyRate:  (rawRate is num) ? rawRate.toDouble() : double.tryParse(rawRate.toString()) ?? 0.0,
      rating:      (rawRating is num) ? rawRating.toDouble() : double.tryParse(rawRating.toString()) ?? 0.0,
      reviewCount: (rawReviews is int) ? rawReviews : int.tryParse(rawReviews.toString()) ?? 0,
      tags:        tags.isEmpty ? [subject] : tags,
      isOnline:    json['is_online'] as bool? ?? json['online'] as bool? ?? json['available'] as bool? ?? false,
      emoji:       _emojiForSubject(subject),
      gradient:    _gradientForIndex(index),
      bio:         json['bio'] as String? ?? json['about'] as String? ?? '',
      availability: avail,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BOOKING RECORD  — mirrors BookingSerializer camelCase output
// ─────────────────────────────────────────────────────────────
class _BookingRecord {
  final String tutorId;
  final DateTime scheduledAt;
  final int durationMin;
  final String status;

  const _BookingRecord({
    required this.tutorId,
    required this.scheduledAt,
    required this.durationMin,
    required this.status,
  });

  factory _BookingRecord.fromJson(Map<String, dynamic> j) {
    return _BookingRecord(
      tutorId:     j['tutorId']?.toString() ?? j['tutor_id']?.toString() ?? '',
      scheduledAt: DateTime.parse(j['scheduledAt'] ?? j['scheduled_at'] as String),
      durationMin: (j['durationMin'] ?? j['duration_min'] ?? 60) as int,
      status:      j['status'] as String? ?? 'pending',
    );
  }

  /// True if this booking overlaps with [slot] for [duration] minutes.
  bool conflictsWith(DateTime slot, {int duration = 60}) {
    if (status == 'cancelled') return false;
    final end     = scheduledAt.add(Duration(minutes: durationMin));
    final slotEnd = slot.add(Duration(minutes: duration));
    return scheduledAt.isBefore(slotEnd) && end.isAfter(slot);
  }
}

// ─────────────────────────────────────────────────────────────
//  API SERVICE
// ─────────────────────────────────────────────────────────────
class _TutorsApi {
  static const _base = '/api/v1/study-buddy';

  static Future<List<TutorModel>> fetchTutors() async {
    final res = await ApiClient.get('$_base/tutors/');
    dev.log('[SBTutors] GET tutors → ${res.statusCode}');
    dev.log('[SBTutors] body: ${res.body}');
    if (res.statusCode != 200) throw Exception('Failed to load tutors (${res.statusCode})');

    final body = jsonDecode(res.body);
    List<dynamic> results;
    if (body is Map<String, dynamic>) {
      results = (body['results'] ?? body['data'] ?? []) as List<dynamic>;
    } else if (body is List) {
      results = body;
    } else {
      results = [];
    }
    return results
        .asMap()
        .entries
        .map((e) => TutorModel.fromJson(e.value as Map<String, dynamic>, e.key))
        .toList();
  }

  /// Fetches the logged-in student's own bookings.
  /// Used client-side to detect slot conflicts for a given tutor.
  static Future<List<_BookingRecord>> fetchMyBookings() async {
    final res = await ApiClient.get('$_base/bookings/');
    dev.log('[SBTutors] GET bookings → ${res.statusCode}');
    if (res.statusCode != 200) return [];

    final body = jsonDecode(res.body);
    List<dynamic> results;
    if (body is Map<String, dynamic>) {
      results = (body['results'] ?? body['data'] ?? []) as List<dynamic>;
    } else if (body is List) {
      results = body;
    } else {
      results = [];
    }
    return results.map((e) => _BookingRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Creates a booking.
  /// tutor_id = Tutor.id (UUID from tutors table), NOT user_id.
  static Future<void> createBooking(Map<String, dynamic> payload) async {
    final res = await ApiClient.post('$_base/bookings/', body: payload);
    dev.log('[SBTutors] POST bookings → ${res.statusCode} | ${res.body}');
    if (res.statusCode != 201) {
      String msg = 'Booking failed (${res.statusCode})';
      try {
        final err = jsonDecode(res.body);
        if (err is Map) msg = err.values.first.toString();
      } catch (_) {}
      throw Exception(msg);
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────────────────────
String _formatKsh(double rate) {
  if (rate <= 0) return 'Free';
  final s = rate.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return 'KSh $s';
}

String _monthAbbr(int m) =>
    ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];

Future<void> _openWhatsApp(BuildContext context, String phone) async {
  final uri = Uri.parse('https://wa.me/$phone');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not open WhatsApp'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  1. BROWSE TUTORS
// ─────────────────────────────────────────────────────────────
class SBTutorsScreen extends StatefulWidget {
  const SBTutorsScreen({super.key});

  @override
  State<SBTutorsScreen> createState() => _SBTutorsScreenState();
}

class _SBTutorsScreenState extends State<SBTutorsScreen> {
  List<TutorModel>? _tutors;
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final data = await _TutorsApi.fetchTutors();
      if (mounted) setState(() { _tutors = data; _loading = false; });
    } catch (e, st) {
      dev.log('[SBTutors] fetch error: $e', stackTrace: st);
      if (mounted) setState(() {
        _error   = 'Could not load tutors. Pull down to retry.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SBColors.surface2,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: SBColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Find a Tutor',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: SBColors.text)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _fetch(),
        color: SBColors.brand,
        child: CustomScrollView(slivers: [
          const SliverToBoxAdapter(child: _HeroBanner()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(children: [
                _InfoPill('💰', 'Price Range', 'KSh 800 – 1,500/hr'),
                const SizedBox(width: 8),
                _InfoPill('⭐', 'Min Rating', '4.5 & above'),
                const SizedBox(width: 8),
                _InfoPill('📅', 'Available', 'Mon – Sat'),
              ]),
            ),
          ),
          SliverToBoxAdapter(child: _buildContent()),
        ]),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return Column(children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _SectionHeader('Loading tutors...'),
        ),
        ..._shimmerCards(),
      ]);
    }
    if (_error != null) return _ErrorState(message: _error!, onRetry: _fetch);

    final tutors = _tutors ?? [];
    if (tutors.isEmpty) return const _EmptyState();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: _SectionHeader(
            '${tutors.length} tutor${tutors.length == 1 ? '' : 's'} available'),
      ),
      ...tutors.map((t) => _TutorCard(
        tutor: t,
        onViewProfile: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => SBTutorProfileScreen(tutor: t))),
        onBook: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => SBBookingScreen(tutor: t))),
      )),
      const SizedBox(height: 24),
    ]);
  }

  List<Widget> _shimmerCards() => List.generate(3, (_) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    padding: const EdgeInsets.all(14),
    decoration: SBTheme.card,
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 54, height: 54,
          decoration: BoxDecoration(color: SBColors.border,
              borderRadius: BorderRadius.circular(16))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 120, height: 12,
            decoration: BoxDecoration(color: SBColors.border, borderRadius: BorderRadius.circular(6))),
        const SizedBox(height: 8),
        Container(width: 180, height: 10,
            decoration: BoxDecoration(color: SBColors.border, borderRadius: BorderRadius.circular(5))),
        const SizedBox(height: 8),
        Container(width: double.infinity, height: 10,
            decoration: BoxDecoration(color: SBColors.border, borderRadius: BorderRadius.circular(5))),
      ])),
    ]),
  ));
}

// ─────────────────────────────────────────────────────────────
//  HERO BANNER
// ─────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [SBColors.brand, SBColors.brandDark],
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(
        color: SBColors.brand.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8),
      )],
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
          child: const Text('🎓  STUDY BUDDY',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                  color: Colors.white, letterSpacing: 1)),
        ),
        const SizedBox(height: 8),
        const Text('Schedule a\nTutoring Session',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                color: Colors.white, height: 1.2)),
        const SizedBox(height: 6),
        Text('Connect with top-rated tutors\nand ace your exams 🚀',
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8), height: 1.5)),
      ])),
      const SizedBox(width: 12),
      const Text('📚', style: TextStyle(fontSize: 52)),
    ]),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(title, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
  );
}

class _InfoPill extends StatelessWidget {
  final String icon, label, value;
  const _InfoPill(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SBColors.border, width: 1.5)),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 5),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 8, color: SBColors.text3)),
          Text(value, style: const TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600, color: SBColors.text),
              overflow: TextOverflow.ellipsis),
        ])),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  TUTOR CARD
// ─────────────────────────────────────────────────────────────
class _TutorCard extends StatelessWidget {
  final TutorModel tutor;
  final VoidCallback onViewProfile, onBook;
  const _TutorCard({required this.tutor, required this.onViewProfile, required this.onBook});

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
            child: Center(child: Text(tutor.emoji, style: const TextStyle(fontSize: 24))),
          ),
          if (tutor.isOnline)
            Positioned(bottom: 2, right: 2,
              child: Container(width: 12, height: 12,
                decoration: BoxDecoration(color: SBColors.green, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2)))),
        ]),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tutor.name, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: SBColors.text)),
          const SizedBox(height: 2),
          Text(tutor.tags.take(2).join(' · '),
              style: const TextStyle(fontSize: 11, color: SBColors.text2),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_formatKsh(tutor.hourlyRate)}/hr',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: SBColors.brand)),
              if (tutor.rating > 0)
                Text('⭐ ${tutor.rating.toStringAsFixed(1)}  (${tutor.reviewCount} reviews)',
                    style: const TextStyle(fontSize: 11, color: SBColors.accent)),
            ]),
            const Spacer(),
            GestureDetector(
              onTap: onBook,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                    color: SBColors.brand, borderRadius: BorderRadius.circular(10)),
                child: const Text('Book', style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ]),
        ])),
      ]),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(40),
    child: Column(children: [
      Text('🔍', style: TextStyle(fontSize: 40)),
      SizedBox(height: 12),
      Text('No tutors found',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: SBColors.text)),
      SizedBox(height: 4),
      Text('Pull down to refresh', style: TextStyle(fontSize: 12, color: SBColors.text3)),
    ]),
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(children: [
      const Text('⚠️', style: TextStyle(fontSize: 40)),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: SBColors.text2)),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: onRetry,
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

// ─────────────────────────────────────────────────────────────
//  2. TUTOR PROFILE
//     • No Follow / Message / Share buttons
//     • WhatsApp + Book buttons pinned to bottom
// ─────────────────────────────────────────────────────────────
class SBTutorProfileScreen extends StatelessWidget {
  final TutorModel tutor;
  const SBTutorProfileScreen({super.key, required this.tutor});

  // Shared WhatsApp number for all showcase tutors (no leading +)
  static const _whatsapp = '254787065879';
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SBColors.surface2,
      // ── Pinned bottom bar ──────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _openWhatsApp(context, _whatsapp),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                      color: const Color(0xFF25D366).withOpacity(0.4),
                      blurRadius: 16, offset: const Offset(0, 6),
                    )],
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('💬', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text('WhatsApp', style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => SBBookingScreen(tutor: tutor))),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: SBColors.brand,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                      color: SBColors.brand.withOpacity(0.35),
                      blurRadius: 16, offset: const Offset(0, 6),
                    )],
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('📅', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text('Book Session', style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
      body: CustomScrollView(slivers: [
        // ── Gradient header ──────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
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
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                      ),
                      child: Center(child: Text(tutor.emoji,
                          style: const TextStyle(fontSize: 30))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tutor.name, style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(tutor.tags.take(2).join(' · '),
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75))),
                      const SizedBox(height: 6),
                      if (tutor.rating > 0) Row(children: [
                        Text('★' * tutor.rating.round(),
                            style: const TextStyle(color: SBColors.accent, fontSize: 13)),
                        const SizedBox(width: 6),
                        Text('${tutor.rating.toStringAsFixed(1)} · ${tutor.reviewCount} reviews',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ])),
                  ]),
                ]),
              ),
            ),
          ),
        ),

        // ── Stats row ────────────────────────────────────────
        SliverToBoxAdapter(
          child: _StatsRow([
            ('${tutor.reviewCount}', 'Reviews'),
            (_formatKsh(tutor.hourlyRate), 'Per Hour'),
            (tutor.isOnline ? '🟢 Yes' : '⚪ No', 'Available'),
          ]),
        ),

        // ── Sections ─────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          sliver: SliverList(delegate: SliverChildListDelegate([
            const SizedBox(height: 16),

            if (tutor.tags.isNotEmpty)
              _ProfileSection(
                label: 'Subjects',
                child: Wrap(spacing: 6, runSpacing: 6,
                    children: tutor.tags.map<Widget>((t) => SBTag(t)).toList()),
              ),

            _ProfileSection(
              label: 'Rate & Details',
              child: GridView.count(
                crossAxisCount: 2, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.8,
                children: [
                  _InfoBox('Hourly Rate', '${_formatKsh(tutor.hourlyRate)}/hr'),
                  _InfoBox('Rating',
                      tutor.rating > 0 ? '⭐ ${tutor.rating.toStringAsFixed(1)}' : '—'),
                  _InfoBox('Subject', tutor.subject),
                  _InfoBox('Status', tutor.isOnline ? '🟢 Available' : '⚪ Offline'),
                ],
              ),
            ),

            _ProfileSection(
              label: 'Availability This Week',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) => _AvailChip(
                  _dayLabels[i],
                  i < tutor.availability.length ? tutor.availability[i] : true,
                )),
              ),
            ),

            if (tutor.bio.isNotEmpty)
              _ProfileSection(
                label: 'About',
                child: Text(tutor.bio, style: const TextStyle(
                    fontSize: 13, color: SBColors.text2, height: 1.6)),
              ),

            const SizedBox(height: 16),
          ])),
        ),
      ]),
    );
  }
}

// Profile sub-widgets
class _StatsRow extends StatelessWidget {
  final List<(String, String)> items;
  const _StatsRow(this.items);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SBColors.border)),
    child: Row(children: items.indexed.map(((int, (String, String)) e) {
      final (i, (val, lbl)) = e;
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(border: Border(
            right: i < items.length - 1
                ? const BorderSide(color: SBColors.border) : BorderSide.none,
          )),
          child: Column(children: [
            Text(val, style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: SBColors.brand)),
            const SizedBox(height: 2),
            Text(lbl, style: const TextStyle(fontSize: 10, color: SBColors.text3)),
          ]),
        ),
      );
    }).toList()),
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
      Text(label.toUpperCase(), style: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700, color: SBColors.text3, letterSpacing: 1)),
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
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SBColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: SBColors.text3)),
      Text(value, style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: SBColors.text)),
    ]),
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
    child: Text(day, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w600,
        color: available ? SBColors.green : SBColors.text3)),
  );
}

// ─────────────────────────────────────────────────────────────
//  3. BOOKING SCREEN
//
//  Logic:
//  1. On open → fetch student's bookings from GET /bookings/
//  2. Filter by this tutor's id + non-cancelled
//  3. For each slot on the selected date → check conflictsWith()
//  4. Booked slots show ✗ and are un-tappable (greyed out)
//  5. Payload sent to POST /bookings/:
//       tutor_id     = Tutor.id  (UUID from tutors table)
//       subject      = tutor.subject
//       scheduled_at = ISO 8601
//       duration_min = 60
//       notes        = ''
// ─────────────────────────────────────────────────────────────
class SBBookingScreen extends StatefulWidget {
  final TutorModel tutor;
  const SBBookingScreen({super.key, required this.tutor});
  @override
  State<SBBookingScreen> createState() => _SBBookingScreenState();
}

class _SBBookingScreenState extends State<SBBookingScreen> {
  int  _selDay  = 0;
  int? _selTime;
  bool _loading      = false;
  bool _slotsLoading = true;

  List<_BookingRecord> _existingBookings = [];

  late final List<DateTime> _dates;

  // (hour, displayLabel)
  static const _timeSlots = [
    (9,  '9:00 AM'),
    (10, '10:00 AM'),
    (11, '11:00 AM'),
    (14, '2:00 PM'),
    (15, '3:00 PM'),
    (16, '4:00 PM'),
  ];
  static const _dayNames = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dates = List.generate(6, (i) => DateTime(now.year, now.month, now.day + i));
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final all = await _TutorsApi.fetchMyBookings();
      if (mounted) {
        setState(() {
          _existingBookings = all
              .where((b) => b.tutorId == widget.tutor.id && b.status != 'cancelled')
              .toList();
          _slotsLoading = false;
        });
      }
    } catch (e) {
      dev.log('[SBBooking] loadBookings error: $e');
      if (mounted) setState(() => _slotsLoading = false);
    }
  }

  bool _isBooked(DateTime date, int hour) {
    final slot = DateTime(date.year, date.month, date.day, hour);
    return _existingBookings.any((b) => b.conflictsWith(slot));
  }

  DateTime get _selectedDate => _dates[_selDay];

  String get _scheduledAtIso {
    final (hour, _) = _timeSlots[_selTime!];
    return DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day, hour,
    ).toIso8601String();
  }

  Future<void> _confirm() async {
    if (_selTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a time slot'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      await _TutorsApi.createBooking({
        'tutor_id':     widget.tutor.id,
        'subject':      widget.tutor.subject,
        'scheduled_at': _scheduledAtIso,
        'duration_min': 60,
        'notes':        '',
      });

      if (!mounted) return;

      // Optimistically mark the slot as booked in UI
      final (hour, _) = _timeSlots[_selTime!];
      setState(() {
        _existingBookings.add(_BookingRecord(
          tutorId:     widget.tutor.id,
          scheduledAt: DateTime(
              _selectedDate.year, _selectedDate.month, _selectedDate.day, hour),
          durationMin: 60,
          status:      'pending',
        ));
        _selTime = null;
      });

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Session Booked!', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: SBColors.text)),
            const SizedBox(height: 8),
            Text('Your session with ${widget.tutor.name} has been confirmed.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: SBColors.text2)),
          ]),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: const Text('Done',
                  style: TextStyle(color: SBColors.brand, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } catch (e, st) {
      dev.log('[SBBooking] confirm error: $e', stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
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
    final tutor = widget.tutor;
    return Scaffold(
      backgroundColor: SBColors.surface2,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: SBColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Book a Session', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: SBColors.text)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Tutor card ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: SBTheme.card,
            child: Row(children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: tutor.gradient),
                  borderRadius: BorderRadius.circular(16)),
                child: Center(child: Text(tutor.emoji, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tutor.name, style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: SBColors.text)),
                Text(tutor.tags.take(2).join(' · '),
                    style: const TextStyle(fontSize: 11, color: SBColors.text2)),
                const SizedBox(height: 4),
                Text(
                  [
                    if (tutor.hourlyRate > 0) '${_formatKsh(tutor.hourlyRate)}/hr',
                    if (tutor.rating > 0) '⭐ ${tutor.rating.toStringAsFixed(1)}',
                  ].join('  ·  '),
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: SBColors.brand),
                ),
              ])),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Date ───────────────────────────────────────────
          const _BookLabel('SELECT DATE'),
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _dates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final d = _dates[i];
                final sel = _selDay == i;
                return GestureDetector(
                  onTap: () => setState(() { _selDay = i; _selTime = null; }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 58,
                    decoration: BoxDecoration(
                      color: sel ? SBColors.brand : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: sel ? SBColors.brand : SBColors.border, width: 1.5),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(_dayNames[d.weekday - 1], style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : SBColors.text3)),
                      const SizedBox(height: 2),
                      Text('${d.day}', style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : SBColors.text)),
                      Text(_monthAbbr(d.month), style: TextStyle(
                          fontSize: 9,
                          color: sel ? Colors.white.withOpacity(0.8) : SBColors.text3)),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // ── Time slots ─────────────────────────────────────
          Row(children: [
            const _BookLabel('SELECT TIME'),
            if (_slotsLoading) ...[
              const SizedBox(width: 8),
              const SizedBox(width: 10, height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: SBColors.brand)),
            ],
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _timeSlots.asMap().entries.map((entry) {
              final i = entry.key;
              final (hour, label) = entry.value;
              final booked   = !_slotsLoading && _isBooked(_selectedDate, hour);
              final selected = _selTime == i;

              final bgColor     = booked ? SBColors.surface3
                                : selected ? SBColors.brand : Colors.white;
              final borderColor = booked ? SBColors.border
                                : selected ? SBColors.brand : SBColors.border;
              final textColor   = booked ? SBColors.text3
                                : selected ? Colors.white : SBColors.text2;

              return GestureDetector(
                onTap: booked ? null : () => setState(() => _selTime = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(label, style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
                    if (booked) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.block, size: 11, color: textColor),
                    ],
                  ]),
                ),
              );
            }).toList(),
          ),

          if (!_slotsLoading && _existingBookings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                Icon(Icons.info_outline, size: 11, color: SBColors.text3.withOpacity(0.7)),
                const SizedBox(width: 4),
                Text('Greyed slots are already booked',
                    style: TextStyle(fontSize: 10, color: SBColors.text3.withOpacity(0.8))),
              ]),
            ),

          const SizedBox(height: 20),

          // ── Total ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: SBColors.brandPale, borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Session Total (1 hr)', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
              Text(
                tutor.hourlyRate > 0 ? _formatKsh(tutor.hourlyRate) : 'Free',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: SBColors.brand),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Confirm button ─────────────────────────────────
          GestureDetector(
            onTap: (_loading || _selTime == null) ? null : _confirm,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: (_loading || _selTime == null)
                    ? SBColors.brand.withOpacity(0.5) : SBColors.brand,
                borderRadius: BorderRadius.circular(16),
                boxShadow: (_selTime != null && !_loading) ? [BoxShadow(
                  color: SBColors.brand.withOpacity(0.3),
                  blurRadius: 20, offset: const Offset(0, 6),
                )] : [],
              ),
              child: Center(
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _selTime == null ? 'Select a time slot' : '✅  Confirm Booking',
                        style: const TextStyle(
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

class _BookLabel extends StatelessWidget {
  final String text;
  const _BookLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(
      fontSize: 10, fontWeight: FontWeight.w700, color: SBColors.text3, letterSpacing: 1));
}