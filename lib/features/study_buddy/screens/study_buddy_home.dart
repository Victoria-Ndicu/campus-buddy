// ============================================================
//  StudyBuddy — study_buddy_home.dart  (API-connected)
//
//  Now uses ApiClient (lib/core/api_client.dart) for all
//  requests — automatic token refresh, no more surprise
//  logouts. Same pattern as profile_screen.dart.
//
//  Fetches live data from:
//    GET /api/study/dashboard/    → stats
//    GET /api/study/bookings/     → upcoming sessions
//    GET /api/study/tutors/       → tutors list (for count)
//    GET /api/study/groups/       → groups list (for count)
//    GET /api/study/resources/    → resources list (for count)
// ============================================================

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';

import '../../../core/api_client.dart';   // ← same shared client as profile_screen

import '../models/sb_constants.dart';
import '../widgets/sb_widgets.dart';
import 'sb_tutors_screen.dart';
import 'sb_groups_screen.dart';
import 'sb_resources_screen.dart';
import 'sb_help_screen.dart';

// ─────────────────────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────────────────────
class _DashboardData {
  final int sessionsBooked;
  final int myGroups;
  final int savedFiles;
  final int openQuestions;

  const _DashboardData({
    this.sessionsBooked  = 0,
    this.myGroups        = 0,
    this.savedFiles      = 0,
    this.openQuestions   = 0,
  });

  factory _DashboardData.fromJson(Map<String, dynamic> json) => _DashboardData(
        sessionsBooked : json['sessions_booked']  ?? 0,
        myGroups       : json['my_groups']         ?? 0,
        savedFiles     : json['saved_files']       ?? 0,
        openQuestions  : json['open_questions']    ?? 0,
      );
}

class _UpcomingSession {
  final String emoji;
  final String title;
  final String subtitle;
  final Color  color;
  final String tag;

  const _UpcomingSession({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.tag,
  });
}

// ─────────────────────────────────────────────────────────────
//  API SERVICE  — thin wrapper; all HTTP goes through ApiClient
// ─────────────────────────────────────────────────────────────
class _StudyBuddyApi {
  // Base path — ApiClient already knows the host.
  static const _base = '/api/v1/study-buddy';

  // ── helpers ──────────────────────────────────────────────
  /// Pull `count` from a paginated DRF response.
  static int _count(Map<String, dynamic> body) => body['count'] as int? ?? 0;

  static String _formatBookingSubtitle(Map<String, dynamic> b) {
    final parts = <String>[];
    if (b['tutor_name'] != null) parts.add('With ${b['tutor_name']}');
    if (b['location']   != null) parts.add(b['location'] as String);
    if (b['scheduled_at'] != null) {
      try {
        final dt   = DateTime.parse(b['scheduled_at'] as String).toLocal();
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final day  = days[dt.weekday - 1];
        final h    = dt.hour > 12 ? dt.hour - 12 : dt.hour;
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        parts.add('$day, $h:${dt.minute.toString().padLeft(2, '0')} $ampm');
      } catch (_) {}
    }
    return parts.join(' · ');
  }

  static String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':  return 'Today';
      case 'pending':    return 'Pending';
      case 'cancelled':  return 'Cancelled';
      default:           return status;
    }
  }

  // ── fetch calls ───────────────────────────────────────────
  static Future<_DashboardData> fetchDashboard() async {
    final res = await ApiClient.get('$_base/dashboard/');
    dev.log('[StudyBuddy] GET $_base/dashboard/ → ${res.statusCode}');
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body is Map<String, dynamic>) {
        return _DashboardData.fromJson(body);
      }
    }
    throw Exception('Dashboard fetch failed (${res.statusCode})');
  }

  static Future<List<_UpcomingSession>> fetchUpcomingSessions() async {
    final res = await ApiClient.get('$_base/bookings/');
    dev.log('[StudyBuddy] GET $_base/bookings/ → ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('Bookings fetch failed (${res.statusCode})');
    }

    final body    = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (body['results'] ?? []) as List<dynamic>;

    return results.take(3).map((item) {
      final b       = item as Map<String, dynamic>;
      final isGroup = b['group'] != null;
      final status  = b['status'] as String? ?? 'confirmed';

      return _UpcomingSession(
        emoji    : isGroup ? '👥' : '📅',
        title    : b['title'] ?? (isGroup ? 'Study Group Session' : 'Tutor Session'),
        subtitle : _formatBookingSubtitle(b),
        color    : isGroup ? SBColors.green : SBColors.brand,
        tag      : _statusLabel(status),
      );
    }).toList();
  }

  static Future<int> fetchTutorCount() async {
    final res = await ApiClient.get('$_base/tutors/');
    dev.log('[StudyBuddy] GET $_base/tutors/ → ${res.statusCode}');
    if (res.statusCode == 200) return _count(jsonDecode(res.body) as Map<String, dynamic>);
    return 0;
  }

  static Future<int> fetchGroupCount() async {
    final res = await ApiClient.get('$_base/groups/');
    dev.log('[StudyBuddy] GET $_base/groups/ → ${res.statusCode}');
    if (res.statusCode == 200) return _count(jsonDecode(res.body) as Map<String, dynamic>);
    return 0;
  }

  static Future<int> fetchResourceCount() async {
    final res = await ApiClient.get('$_base/resources/');
    dev.log('[StudyBuddy] GET $_base/resources/ → ${res.statusCode}');
    if (res.statusCode == 200) return _count(jsonDecode(res.body) as Map<String, dynamic>);
    return 0;
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN STATE
//
//  Mirrors the load / error / retry cycle in ProfileScreen:
//    • _loadingXxx   — shows skeleton/shimmer
//    • _xxxError     — surfaces message + retry button
//    • _xxx          — happy-path data
// ─────────────────────────────────────────────────────────────
class StudyBuddyHome extends StatefulWidget {
  const StudyBuddyHome({super.key});

  @override
  State<StudyBuddyHome> createState() => _StudyBuddyHomeState();
}

class _StudyBuddyHomeState extends State<StudyBuddyHome> {

  // ── Dashboard stats ───────────────────────────────────────
  _DashboardData? _dashboard;
  bool    _loadingDashboard = true;
  String? _dashboardError;

  // ── Upcoming sessions ─────────────────────────────────────
  List<_UpcomingSession>? _sessions;
  bool    _loadingSessions = true;
  String? _sessionsError;

  // ── Module counts ─────────────────────────────────────────
  int?    _tutorCount;
  int?    _groupCount;
  int?    _resourceCount;
  bool    _loadingCounts = true;

  // ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  // ── Parallel load — same atomic-setState discipline as ProfileScreen ──
  Future<void> _fetchAll() async {
    if (mounted) {
      setState(() {
        _loadingDashboard = true;
        _loadingSessions  = true;
        _loadingCounts    = true;
        _dashboardError   = null;
        _sessionsError    = null;
      });
    }

    // Fire all requests concurrently; handle each independently so a
    // failure in one doesn't kill the others (same pattern as ProfileScreen
    // handling 200 vs 401 vs error separately).
    await Future.wait([
      _fetchDashboard(),
      _fetchSessions(),
      _fetchCounts(),
    ]);
  }

  Future<void> _fetchDashboard() async {
    try {
      final data = await _StudyBuddyApi.fetchDashboard();
      if (mounted) setState(() { _dashboard = data; _loadingDashboard = false; });
    } catch (e, st) {
      dev.log('[StudyBuddy] _fetchDashboard error: $e', stackTrace: st);
      if (mounted) {
        setState(() {
          _dashboardError   = 'Could not load stats. Check your connection.';
          _loadingDashboard = false;
        });
      }
    }
  }

  Future<void> _fetchSessions() async {
    try {
      final data = await _StudyBuddyApi.fetchUpcomingSessions();
      if (mounted) setState(() { _sessions = data; _loadingSessions = false; });
    } catch (e, st) {
      dev.log('[StudyBuddy] _fetchSessions error: $e', stackTrace: st);
      if (mounted) {
        setState(() {
          _sessionsError   = 'Could not load sessions.';
          _loadingSessions = false;
        });
      }
    }
  }

  Future<void> _fetchCounts() async {
    try {
      // Still concurrent within counts group
      final results = await Future.wait([
        _StudyBuddyApi.fetchTutorCount(),
        _StudyBuddyApi.fetchGroupCount(),
        _StudyBuddyApi.fetchResourceCount(),
      ]);
      if (mounted) {
        setState(() {
          _tutorCount    = results[0];
          _groupCount    = results[1];
          _resourceCount = results[2];
          _loadingCounts = false;
        });
      }
    } catch (e, st) {
      dev.log('[StudyBuddy] _fetchCounts error: $e', stackTrace: st);
      // Non-critical: cards just show '—' instead of crashing
      if (mounted) setState(() => _loadingCounts = false);
    }
  }

  void _refresh() => _fetchAll();

  // ── helpers ───────────────────────────────────────────────
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

  String _countLabel(int? value, String suffix) {
    if (_loadingCounts) return 'Loading...';
    if (value == null)  return '— $suffix';
    return '$value $suffix';
  }

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SBColors.surface2,
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        color: SBColors.brand,
        child: CustomScrollView(
          slivers: [

            // ── Gradient app-bar ────────────────────────────
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              stretch: true,
              backgroundColor: SBColors.brand,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'ACADEMIC SUPPORT',
                                    style: TextStyle(
                                      fontSize: 9, fontWeight: FontWeight.w700,
                                      color: Colors.white, letterSpacing: 1.5),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text('StudyBuddy',
                                  style: TextStyle(
                                    fontSize: 26, fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(
                                  'Tutors · Groups · Resources · Help',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8)),
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

            // ── Stats strip ─────────────────────────────────
            SliverToBoxAdapter(
              child: _StatsStrip(
                sessionsBooked : _dashboard?.sessionsBooked,
                myGroups       : _dashboard?.myGroups,
                savedFiles     : _dashboard?.savedFiles,
                openQuestions  : _dashboard?.openQuestions,
                isLoading      : _loadingDashboard,
                hasError       : _dashboardError != null,
                onRetry        : _fetchDashboard,
              ),
            ),

            // ── Module cards grid ────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              sliver: SliverToBoxAdapter(
                child: const Text(
                  'Academic Modules',
                  style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700,
                    color: SBColors.text),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  _ModuleCard(
                    emoji    : '👩‍🏫',
                    title    : 'Find Tutors',
                    subtitle : _countLabel(_tutorCount, 'tutors available'),
                    gradient : const [Color(0xFF667EEA), Color(0xFF4A5FCC)],
                    onTap    : () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SBTutorsScreen())),
                  ),
                  _ModuleCard(
                    emoji    : '👥',
                    title    : 'Study Groups',
                    subtitle : _countLabel(_groupCount, 'active groups'),
                    gradient : const [Color(0xFF3ECF8E), Color(0xFF0D9488)],
                    onTap    : () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SBGroupsScreen())),
                  ),
                  _ModuleCard(
                    emoji    : '📁',
                    title    : 'Resources',
                    subtitle : _countLabel(_resourceCount, 'study materials'),
                    gradient : const [Color(0xFFF5A623), Color(0xFFE67E22)],
                    onTap    : () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SBResourcesScreen())),
                  ),
                  _ModuleCard(
                    emoji    : '❓',
                    title    : 'Ask for Help',
                    subtitle : 'Get answers fast',
                    gradient : const [Color(0xFFFF6B6B), Color(0xFFC0392B)],
                    onTap    : () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SBHelpScreen())),
                  ),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount   : 2,
                  mainAxisSpacing  : 12,
                  crossAxisSpacing : 12,
                  childAspectRatio : 1.05,
                ),
              ),
            ),

            // ── Upcoming sessions ────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: SBSectionLabel(title: 'Upcoming Sessions', action: 'See all'),
            ),
            SliverToBoxAdapter(
              child: _buildSessions(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sessions section builder — mirrors _NameBlock in ProfileScreen ──
  Widget _buildSessions() {
    // Loading state
    if (_loadingSessions) return const _SessionsShimmer();

    // Error state — shows message + retry (same as _NameBlock)
    if (_sessionsError != null) {
      return _ErrorTile(message: _sessionsError!, onRetry: _fetchSessions);
    }

    final sessions = _sessions ?? [];
    if (sessions.isEmpty) return const _EmptySessionsTile();

    return Column(
      children: [
        ...sessions.map((s) => _UpcomingCard(
          emoji    : s.emoji,
          title    : s.title,
          subtitle : s.subtitle,
          color    : s.color,
          tag      : s.tag,
        )),
        const SizedBox(height: 28),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STATS STRIP
//  Now accepts onRetry so a failed dashboard can be retried
//  without pulling the whole screen down.
// ─────────────────────────────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  final int?  sessionsBooked, myGroups, savedFiles, openQuestions;
  final bool  isLoading, hasError;
  final VoidCallback onRetry;

  const _StatsStrip({
    this.sessionsBooked,
    this.myGroups,
    this.savedFiles,
    this.openQuestions,
    this.isLoading = false,
    this.hasError  = false,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return Container(
        margin  : const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding : const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color         : Colors.white,
          borderRadius  : BorderRadius.circular(18),
          border        : Border.all(color: SBColors.border),
        ),
        child: Row(children: [
          const Text('⚠️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Could not load stats.',
              style: const TextStyle(fontSize: 12, color: SBColors.text3)),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry',
              style: TextStyle(fontSize: 12, color: SBColors.brand)),
          ),
        ]),
      );
    }

    return Container(
      margin  : const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding : const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color        : Colors.white,
        borderRadius : BorderRadius.circular(18),
        border       : Border.all(color: SBColors.border),
      ),
      child: Row(children: [
        _Stat(_display(sessionsBooked), 'Sessions\nBooked',   '📅', isLoading),
        _Vline(),
        _Stat(_display(myGroups),       'My\nGroups',         '👥', isLoading),
        _Vline(),
        _Stat(_display(savedFiles),     'Saved\nFiles',       '📌', isLoading),
        _Vline(),
        _Stat(_display(openQuestions),  'Open\nQuestions',    '💬', isLoading),
      ]),
    );
  }

  String _display(int? v) => v == null ? '·' : '$v';
}

// ─────────────────────────────────────────────────────────────
//  SHARED SMALL WIDGETS  (unchanged visually)
// ─────────────────────────────────────────────────────────────
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
              borderRadius: BorderRadius.circular(4)),
          )
        : Text(value, style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700,
            color: SBColors.brand)),
      Text(label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 9, color: SBColors.text3, height: 1.35)),
    ]),
  );
}

class _Vline extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
    Container(width: 1, height: 40, color: SBColors.border);
}

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
          end  : Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color      : gradient[0].withOpacity(0.32),
            blurRadius : 16,
            offset     : const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment : CrossAxisAlignment.start,
        mainAxisAlignment  : MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color        : Colors.white.withOpacity(0.2),
              borderRadius : BorderRadius.circular(12)),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 3),
            Text(subtitle, style: TextStyle(
              fontSize: 11, color: Colors.white.withOpacity(0.8))),
          ]),
        ],
      ),
    ),
  );
}

class _UpcomingCard extends StatelessWidget {
  final String emoji, title, subtitle, tag;
  final Color  color;
  const _UpcomingCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin  : const EdgeInsets.fromLTRB(16, 0, 16, 10),
    padding : const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color        : Colors.white,
      borderRadius : BorderRadius.circular(16),
      border       : Border.all(color: SBColors.border),
    ),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color        : color.withOpacity(0.1),
          borderRadius : BorderRadius.circular(12)),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 20))),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(
            fontSize: 11, color: SBColors.text3)),
        ]),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color        : color.withOpacity(0.1),
          borderRadius : BorderRadius.circular(8)),
        child: Text(tag, style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      ),
    ]),
  );
}

class _SessionsShimmer extends StatelessWidget {
  const _SessionsShimmer();

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(2, (_) => Container(
      margin  : const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding : const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color        : Colors.white,
        borderRadius : BorderRadius.circular(16),
        border       : Border.all(color: SBColors.border),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color        : SBColors.border,
            borderRadius : BorderRadius.circular(12)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity, height: 12,
              decoration: BoxDecoration(
                color        : SBColors.border,
                borderRadius : BorderRadius.circular(6))),
            const SizedBox(height: 6),
            Container(
              width: 140, height: 10,
              decoration: BoxDecoration(
                color        : SBColors.border,
                borderRadius : BorderRadius.circular(5))),
          ],
        )),
      ]),
    )),
  );
}

class _EmptySessionsTile extends StatelessWidget {
  const _EmptySessionsTile();

  @override
  Widget build(BuildContext context) => Container(
    margin  : const EdgeInsets.fromLTRB(16, 0, 16, 28),
    padding : const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color        : Colors.white,
      borderRadius : BorderRadius.circular(16),
      border       : Border.all(color: SBColors.border),
    ),
    child: const Center(
      child: Column(children: [
        Text('📭', style: TextStyle(fontSize: 28)),
        SizedBox(height: 8),
        Text('No upcoming sessions',
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
        SizedBox(height: 4),
        Text('Book a tutor or join a study group',
          style: TextStyle(fontSize: 11, color: SBColors.text3)),
      ]),
    ),
  );
}

class _ErrorTile extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorTile({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
    margin  : const EdgeInsets.fromLTRB(16, 0, 16, 28),
    padding : const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color        : Colors.white,
      borderRadius : BorderRadius.circular(16),
      border       : Border.all(color: SBColors.border),
    ),
    child: Row(children: [
      const Text('⚠️', style: TextStyle(fontSize: 20)),
      const SizedBox(width: 10),
      Expanded(child: Text(message,
        style: const TextStyle(fontSize: 12, color: SBColors.text3))),
      TextButton(
        onPressed: onRetry,
        child: const Text('Retry',
          style: TextStyle(fontSize: 12, color: SBColors.brand)),
      ),
    ]),
  );
}