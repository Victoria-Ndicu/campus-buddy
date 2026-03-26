// ============================================================
//  StudyBuddy — study_buddy_home.dart  (API-connected)
//
//  Fetches live data from:
//    GET /api/dashboard/          → stats
//    GET /api/bookings/           → upcoming sessions
//    GET /api/tutors/             → tutors list (for count)
//    GET /api/groups/             → groups list (for count)
//  Uses DashboardView response to populate the stats strip.
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/sb_constants.dart';
import '../widgets/sb_widgets.dart';
import 'sb_tutors_screen.dart';
import 'sb_groups_screen.dart';
import 'sb_resources_screen.dart';
import 'sb_help_screen.dart';

// ── API config ────────────────────────────────────────────────
// Replace with your actual base URL (e.g. from an env/config file)
const String _kBaseUrl = 'https://campusbuddybackend-production.up.railway.app/api/study';

// ── Data models ───────────────────────────────────────────────
class _DashboardData {
  final int sessionsBooked;
  final int myGroups;
  final int savedFiles;
  final int openQuestions;

  const _DashboardData({
    this.sessionsBooked = 0,
    this.myGroups = 0,
    this.savedFiles = 0,
    this.openQuestions = 0,
  });

  factory _DashboardData.fromJson(Map<String, dynamic> json) => _DashboardData(
        sessionsBooked: json['sessions_booked'] ?? 0,
        myGroups: json['my_groups'] ?? 0,
        savedFiles: json['saved_files'] ?? 0,
        openQuestions: json['open_questions'] ?? 0,
      );
}

class _UpcomingSession {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final String tag;

  const _UpcomingSession({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.tag,
  });
}

// ── API service ───────────────────────────────────────────────
class _StudyBuddyApi {
  /// Add your auth token header here, e.g. from a shared auth service.
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        // 'Authorization': 'Bearer $token',
      };

  static Future<_DashboardData> fetchDashboard() async {
    final res = await http
        .get(Uri.parse('$_kBaseUrl/dashboard/'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return _DashboardData.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Dashboard fetch failed (${res.statusCode})');
  }

  static Future<List<_UpcomingSession>> fetchUpcomingSessions() async {
    final res = await http
        .get(Uri.parse('$_kBaseUrl/bookings/'), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('Bookings fetch failed (${res.statusCode})');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    // StandardPagination wraps results in {"count":…, "results":[…]}
    final results = (body['results'] ?? []) as List<dynamic>;

    return results.take(3).map((item) {
      final booking = item as Map<String, dynamic>;

      // Determine if it's a tutor session or group session
      final bool isGroup = booking['group'] != null;
      final String status = booking['status'] ?? 'confirmed';

      return _UpcomingSession(
        emoji: isGroup ? '👥' : '📅',
        title: booking['title'] ?? (isGroup ? 'Study Group Session' : 'Tutor Session'),
        subtitle: _formatBookingSubtitle(booking),
        color: isGroup ? SBColors.green : SBColors.brand,
        tag: _statusLabel(status),
      );
    }).toList();
  }

  static String _formatBookingSubtitle(Map<String, dynamic> b) {
    final parts = <String>[];
    if (b['tutor_name'] != null) parts.add('With ${b['tutor_name']}');
    if (b['location'] != null) parts.add(b['location'] as String);
    if (b['scheduled_at'] != null) {
      try {
        final dt = DateTime.parse(b['scheduled_at'] as String).toLocal();
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final day = days[dt.weekday - 1];
        final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        parts.add('$day, $hour:${dt.minute.toString().padLeft(2, '0')} $ampm');
      } catch (_) {}
    }
    return parts.join(' · ');
  }

  static String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Today';
      case 'pending':
        return 'Pending';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  static Future<int> fetchTutorCount() async {
    final res = await http
        .get(Uri.parse('$_kBaseUrl/tutors/'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['count'] ?? 0;
    }
    return 0;
  }

  static Future<int> fetchGroupCount() async {
    final res = await http
        .get(Uri.parse('$_kBaseUrl/groups/'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['count'] ?? 0;
    }
    return 0;
  }

  static Future<int> fetchResourceCount() async {
    final res = await http
        .get(Uri.parse('$_kBaseUrl/resources/'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['count'] ?? 0;
    }
    return 0;
  }
}

// ── Screen ────────────────────────────────────────────────────
class StudyBuddyHome extends StatefulWidget {
  const StudyBuddyHome({super.key});

  @override
  State<StudyBuddyHome> createState() => _StudyBuddyHomeState();
}

class _StudyBuddyHomeState extends State<StudyBuddyHome> {
  // Futures loaded in parallel
  late Future<_DashboardData> _dashboardFuture;
  late Future<List<_UpcomingSession>> _sessionsFuture;
  late Future<int> _tutorCountFuture;
  late Future<int> _groupCountFuture;
  late Future<int> _resourceCountFuture;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() {
    _dashboardFuture = _StudyBuddyApi.fetchDashboard();
    _sessionsFuture = _StudyBuddyApi.fetchUpcomingSessions();
    _tutorCountFuture = _StudyBuddyApi.fetchTutorCount();
    _groupCountFuture = _StudyBuddyApi.fetchGroupCount();
    _resourceCountFuture = _StudyBuddyApi.fetchResourceCount();
  }

  void _refresh() => setState(() => _loadAll());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SBColors.surface2,
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _loadAll()),
        color: SBColors.brand,
        child: CustomScrollView(
          slivers: [
            // ── Gradient app-bar ───────────────────────────
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              stretch: true,
              backgroundColor: SBColors.brand,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _refresh,
                  tooltip: 'Refresh',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [SBColors.brand, SBColors.brandDark],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'ACADEMIC SUPPORT',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 1.5),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'StudyBuddy',
                                  style: TextStyle(
                                      fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tutors · Groups · Resources · Help',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white.withOpacity(0.8)),
                                ),
                              ],
                            ),
                          ),
                          const Text('📚', style: TextStyle(fontSize: 52)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Stats strip ────────────────────────────────
            SliverToBoxAdapter(
              child: FutureBuilder<_DashboardData>(
                future: _dashboardFuture,
                builder: (context, snap) {
                  final data = snap.data;
                  return _StatsStrip(
                    sessionsBooked: data?.sessionsBooked,
                    myGroups: data?.myGroups,
                    savedFiles: data?.savedFiles,
                    openQuestions: data?.openQuestions,
                    isLoading: snap.connectionState == ConnectionState.waiting,
                    hasError: snap.hasError,
                  );
                },
              ),
            ),

            // ── Module cards grid ──────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              sliver: SliverToBoxAdapter(
                child: const Text(
                  'Academic Modules',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700, color: SBColors.text),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  // ── Find Tutors: shows live count ──────
                  FutureBuilder<int>(
                    future: _tutorCountFuture,
                    builder: (context, snap) => _ModuleCard(
                      emoji: '👩‍🏫',
                      title: 'Find Tutors',
                      subtitle: snap.hasData
                          ? '${snap.data} tutors available'
                          : snap.connectionState == ConnectionState.waiting
                              ? 'Loading...'
                              : '— tutors available',
                      gradient: const [Color(0xFF667EEA), Color(0xFF4A5FCC)],
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SBTutorsScreen())),
                    ),
                  ),
                  // ── Study Groups: shows live count ─────
                  FutureBuilder<int>(
                    future: _groupCountFuture,
                    builder: (context, snap) => _ModuleCard(
                      emoji: '👥',
                      title: 'Study Groups',
                      subtitle: snap.hasData
                          ? '${snap.data} active groups'
                          : snap.connectionState == ConnectionState.waiting
                              ? 'Loading...'
                              : '— active groups',
                      gradient: const [Color(0xFF3ECF8E), Color(0xFF0D9488)],
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SBGroupsScreen())),
                    ),
                  ),
                  // ── Resources: shows live count ────────
                  FutureBuilder<int>(
                    future: _resourceCountFuture,
                    builder: (context, snap) => _ModuleCard(
                      emoji: '📁',
                      title: 'Resources',
                      subtitle: snap.hasData
                          ? '${snap.data}+ study materials'
                          : snap.connectionState == ConnectionState.waiting
                              ? 'Loading...'
                              : '— study materials',
                      gradient: const [Color(0xFFF5A623), Color(0xFFE67E22)],
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SBResourcesScreen())),
                    ),
                  ),
                  _ModuleCard(
                    emoji: '❓',
                    title: 'Ask for Help',
                    subtitle: 'Get answers fast',
                    gradient: const [Color(0xFFFF6B6B), Color(0xFFC0392B)],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SBHelpScreen())),
                  ),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
              ),
            ),

            // ── Upcoming sessions ──────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: SBSectionLabel(title: 'Upcoming Sessions', action: 'See all'),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<List<_UpcomingSession>>(
                future: _sessionsFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const _SessionsShimmer();
                  }
                  if (snap.hasError) {
                    return _ErrorTile(
                      message: 'Could not load sessions',
                      onRetry: _refresh,
                    );
                  }
                  final sessions = snap.data ?? [];
                  if (sessions.isEmpty) {
                    return const _EmptySessionsTile();
                  }
                  return Column(
                    children: [
                      ...sessions.map(
                        (s) => _UpcomingCard(
                          emoji: s.emoji,
                          title: s.title,
                          subtitle: s.subtitle,
                          color: s.color,
                          tag: s.tag,
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Stats strip  (accepts nullable values → shows skeleton)
// ─────────────────────────────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  final int? sessionsBooked, myGroups, savedFiles, openQuestions;
  final bool isLoading, hasError;

  const _StatsStrip({
    this.sessionsBooked,
    this.myGroups,
    this.savedFiles,
    this.openQuestions,
    this.isLoading = false,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SBColors.border),
      ),
      child: Row(
        children: [
          _Stat(_display(sessionsBooked), 'Sessions\nBooked', '📅', isLoading),
          _Vline(),
          _Stat(_display(myGroups), 'My\nGroups', '👥', isLoading),
          _Vline(),
          _Stat(_display(savedFiles), 'Saved\nFiles', '📌', isLoading),
          _Vline(),
          _Stat(_display(openQuestions), 'Open\nQuestions', '💬', isLoading),
        ],
      ),
    );
  }

  String _display(int? v) {
    if (hasError) return '–';
    if (v == null) return '·';
    return '$v';
  }
}

class _Stat extends StatelessWidget {
  final String value, label, emoji;
  final bool loading;
  const _Stat(this.value, this.label, this.emoji, this.loading);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          loading
              ? Container(
                  width: 20, height: 14,
                  decoration: BoxDecoration(
                    color: SBColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              : Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: SBColors.brand)),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: SBColors.text3, height: 1.35)),
        ]),
      );
}

class _Vline extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: SBColors.border);
}

// ─────────────────────────────────────────────────────────────
//  Module card  (unchanged visually)
// ─────────────────────────────────────────────────────────────
class _ModuleCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.32),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
                ],
              ),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
//  Upcoming session row
// ─────────────────────────────────────────────────────────────
class _UpcomingCard extends StatelessWidget {
  final String emoji, title, subtitle, tag;
  final Color color;
  const _UpcomingCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SBColors.border),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: const TextStyle(fontSize: 11, color: SBColors.text3)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(tag,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
//  Loading shimmer for sessions
// ─────────────────────────────────────────────────────────────
class _SessionsShimmer extends StatelessWidget {
  const _SessionsShimmer();

  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(
          2,
          (_) => Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SBColors.border),
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: SBColors.border,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: double.infinity, height: 12,
                        decoration: BoxDecoration(
                          color: SBColors.border,
                          borderRadius: BorderRadius.circular(6),
                        )),
                    const SizedBox(height: 6),
                    Container(
                        width: 140, height: 10,
                        decoration: BoxDecoration(
                          color: SBColors.border,
                          borderRadius: BorderRadius.circular(5),
                        )),
                  ],
                ),
              ),
            ]),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
//  Empty / error states
// ─────────────────────────────────────────────────────────────
class _EmptySessionsTile extends StatelessWidget {
  const _EmptySessionsTile();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SBColors.border),
        ),
        child: const Center(
          child: Column(
            children: [
              Text('📭', style: TextStyle(fontSize: 28)),
              SizedBox(height: 8),
              Text('No upcoming sessions',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
              SizedBox(height: 4),
              Text('Book a tutor or join a study group',
                  style: TextStyle(fontSize: 11, color: SBColors.text3)),
            ],
          ),
        ),
      );
}

class _ErrorTile extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorTile({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SBColors.border),
        ),
        child: Row(children: [
          const Text('⚠️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 12, color: SBColors.text3)),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry', style: TextStyle(fontSize: 12, color: SBColors.brand)),
          ),
        ]),
      );
}