// ============================================================
//  StudyBuddy — study_buddy_home.dart  (API-connected)
//
//  Changes from previous version:
//    • Fixed module counts: falls back to results.length when
//      the endpoint returns a plain list instead of {count: N}
//    • Dashboard stats: added /dashboard/ fallback that derives
//      counts from the list endpoints if dashboard returns 0s
//    • Removed "Upcoming Sessions" section entirely
//    • "Ask for Help" renamed → "Ask your Buddy for Help 🤖"
//      with a bot badge so users know it's AI-powered
//
//  Navigation wiring (bottom nav — see main shell):
//    ✅  Tab 0 (🏠 Home)    → StudyBuddyHome
//    ✅  Tab 1 (🛒 Market)  → CampusMarketHome
//    ✅  Tab 2 (🏠 Housing) → HousingHubHome
//    ✅  Tab 3 (🎉 Events)  → EventBoardHome
//
//  Required imports in your bottom-nav shell:
//    import '../../study_buddy/study_buddy.dart';
//    import '../../campus_market/campus_market.dart';
//    import '../../housing_hub/housing.dart';
//    import '../../event_board/event.dart';
// ============================================================

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';

import '../../../core/api_client.dart';

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
  
  

  const _DashboardData({
    this.sessionsBooked = 0,
    this.myGroups       = 0,
    
   
  });

  factory _DashboardData.fromJson(Map<String, dynamic> json) => _DashboardData(
        sessionsBooked : json['sessions_booked'] as int? ?? 0,
        myGroups       : json['my_groups']        as int? ?? 0,
        
      );

  /// Returns true when all four fields came back as 0 — likely means
  /// the endpoint doesn't populate these fields yet, so we fall back
  /// to deriving them from the individual list endpoints.
  bool get isAllZero =>
      sessionsBooked == 0 &&
      myGroups       == 0 ;
}

// ─────────────────────────────────────────────────────────────
//  API SERVICE
// ─────────────────────────────────────────────────────────────
class _StudyBuddyApi {
  static const _base = '/api/v1/study-buddy';

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

  /// Mirrors _TutorsApi.fetchTutors() in sb_tutors_screen.dart exactly:
  ///   Map → (results ?? data ?? []).length
  ///   List → body.length
  static Future<int> fetchTutorCount() async {
    final res = await ApiClient.get('$_base/tutors/');
    dev.log('[StudyBuddy] GET $_base/tutors/ → ${res.statusCode}');
    if (res.statusCode != 200) return 0;
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic>) {
      final list = (body['results'] ?? body['data'] ?? []) as List<dynamic>;
      return list.length;
    }
    if (body is List) return (body as List).length;
    return 0;
  }

  /// Mirrors _GroupsApi.fetchAllGroups() in sb_groups_screen.dart exactly:
  ///   List → body.length
  ///   Map  → count field (DRF pagination) OR (results ?? data).length
  static Future<int> fetchGroupCount() async {
    final res = await ApiClient.get('$_base/groups/?page_size=100');
    dev.log('[StudyBuddy] GET $_base/groups/ → ${res.statusCode}');
    if (res.statusCode != 200) return 0;
    final body = jsonDecode(res.body);
    if (body is List) return (body as List).length;
    if (body is Map<String, dynamic>) {
      final c = body['count'];
      if (c is int) return c;
      final list = (body['results'] ?? body['data']) as List<dynamic>?;
      return list?.length ?? 0;
    }
    return 0;
  }

  /// Mirrors _ResourcesApi.fetchResources() in sb_resources_screen.dart exactly:
  ///   List → decoded.length
  ///   Map  → count field (DRF pagination) OR (results ?? data ?? []).length
  static Future<int> fetchResourceCount() async {
    final res = await ApiClient.get('$_base/resources/');
    dev.log('[StudyBuddy] GET $_base/resources/ → ${res.statusCode}');
    if (res.statusCode != 200) return 0;
    final decoded = jsonDecode(res.body);
    if (decoded is List) return (decoded as List).length;
    if (decoded is Map<String, dynamic>) {
      final c = decoded['count'];
      if (c is int) return c;
      final list = (decoded['results'] ?? decoded['data'] ?? []) as List<dynamic>;
      return list.length;
    }
    return 0;
  }

  /// Fetch bookings count (used as sessions_booked fallback).
  /// Same shape as bookings list in sb_tutors_screen.dart.
  static Future<int> fetchBookingCount() async {
    final res = await ApiClient.get('$_base/bookings/');
    dev.log('[StudyBuddy] GET $_base/bookings/ → ${res.statusCode}');
    if (res.statusCode != 200) return 0;
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic>) {
      final c = body['count'];
      if (c is int) return c;
      final list = (body['results'] ?? body['data'] ?? []) as List<dynamic>;
      return list.length;
    }
    if (body is List) return (body as List).length;
    return 0;
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN STATE
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

  Future<void> _fetchAll() async {
    if (mounted) {
      setState(() {
        _loadingDashboard = true;
        _loadingCounts    = true;
        _dashboardError   = null;
      });
    }

    await Future.wait([
      _fetchDashboard(),
      _fetchCounts(),
    ]);
  }

  Future<void> _fetchDashboard() async {
    try {
      var data = await _StudyBuddyApi.fetchDashboard();

      // ── Fallback: if all fields are 0, the /dashboard/ endpoint
      //    may not be populating stats yet. Derive them from the
      //    individual list endpoints instead.
      if (data.isAllZero) {
        dev.log('[StudyBuddy] Dashboard returned all-zeros — using list fallbacks');
        final bookings = await _StudyBuddyApi.fetchBookingCount();
        final groups   = await _StudyBuddyApi.fetchGroupCount();
        data = _DashboardData(
          sessionsBooked : bookings,
          myGroups       : groups,
         
        );
      }

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

  Future<void> _fetchCounts() async {
    try {
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
      if (mounted) setState(() => _loadingCounts = false);
    }
  }

  void _refresh() => _fetchAll();

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
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 1.5),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text('StudyBuddy',
                                    style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(
                                  'Tutors · Groups · Resources · AI Help',
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
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: SBColors.text),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
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

                  // ── Ask your Buddy for Help ──────────────
                  // Clearly labelled as a bot/AI so users know
                  // they're chatting with an AI assistant.
                  _ModuleCard(
                    emoji    : '🤖',
                    title    : 'Buddy AI Help',
                    subtitle : 'AI-powered study assistant',
                    gradient : const [Color(0xFFFF6B6B), Color(0xFFC0392B)],
                    onTap    : () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SBHelpScreen())),
                    badge    : 'BOT',
                  ),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount   : 2,
                  mainAxisSpacing  : 12,
                  crossAxisSpacing : 12,
                  childAspectRatio : 1.1,
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STATS STRIP
// ─────────────────────────────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  final int?  sessionsBooked, myGroups;
  final bool  isLoading, hasError;
  final VoidCallback onRetry;

  const _StatsStrip({
    this.sessionsBooked,
    this.myGroups,
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
          color        : Colors.white,
          borderRadius : BorderRadius.circular(18),
          border       : Border.all(color: SBColors.border),
        ),
        child: Row(children: [
          const Text('⚠️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Could not load stats.',
              style: TextStyle(fontSize: 12, color: SBColors.text3)),
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
        _Stat(_display(sessionsBooked), 'Sessions\nBooked',  '📅', isLoading),
        _Vline(),
        _Stat(_display(myGroups),       'My\nGroups',        '👥', isLoading),
      ]),
    );
  }

  String _display(int? v) => v == null ? '·' : '$v';
}

// ─────────────────────────────────────────────────────────────
//  SHARED SMALL WIDGETS
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
                  borderRadius: BorderRadius.circular(4)))
          : Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
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

/// Module card — now accepts an optional [badge] string that
/// floats a small pill in the top-right corner (used for 'BOT').
class _ModuleCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;
  final String? badge;

  const _ModuleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Stack(
      children: [
        SizedBox.expand(
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
                      child: Text(emoji,
                          style: const TextStyle(fontSize: 22))),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.8))),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Optional badge (e.g. 'BOT') ──────────────────
        if (badge != null)
          Positioned(
            top: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color        : Colors.white.withOpacity(0.25),
                borderRadius : BorderRadius.circular(20),
                border       : Border.all(
                    color: Colors.white.withOpacity(0.6), width: 1),
              ),
              child: Text(badge!,
                style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8)),
            ),
          ),
      ],
    ),
  );
}