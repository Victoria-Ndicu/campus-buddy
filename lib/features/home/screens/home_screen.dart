// ============================================================
//  CampusBuddy — home_screen.dart  (API-INTEGRATED)
//  lib/features/home/screens/home_screen.dart
//
//  Changes from previous version:
//  ─────────────────────────────────────────────────────────
//  • REMOVED  Quick Actions section entirely
//  • REMOVED  Near Campus (HousingStrip) section
//  • REMOVED  Upcoming Events strip section
//  • RENAMED  "Recent Activity" → "🔔 Notifications"
//  • FETCHES  profile name from GET /api/v1/profiles/me/
//  • FETCHES  live stat counts from study / market /
//             housing / events APIs
//  • FETCHES  featured event from GET /api/v1/events/
//             (prefers is_featured=true, falls back to first)
//  • FETCHES  notifications from GET /api/v1/profiles/notifications/
//  • RSVP     calls POST /api/v1/events/{id}/rsvp/
//  • Mark-read calls POST /api/v1/profiles/notifications/{id}/read/
//
//  Navigation wiring (unchanged):
//   ✅  Bottom nav tab 1 (📚 Study)  → StudyBuddyHome
//   ✅  Bottom nav tab 2 (🛒 Market) → CampusMarketHome
//   ✅  Bottom nav tab 3 (🏠 Housing)→ HousingHubHome
//   ✅  Bottom nav tab 4 (🎉 Events) → EventBoardHome
//   ✅  👤 Profile icon              → ProfileScreen
//   ✅  Module tiles                 → their respective screens
//   ✅  Stat chips                   → their respective screens
//   ✅  Search quick-jump            → their respective screens
//   ✅  Notification rows            → module screen by category
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../study_buddy/study_buddy.dart';
import '../../campus_market/campus_market.dart';
import '../../housing_hub/housing.dart';
import '../../event_board/event.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../core/api_client.dart';

// ─────────────────────────────────────────────────────────────
//  BRAND COLOURS
// ─────────────────────────────────────────────────────────────
class _C {
  static const brand      = Color(0xFF667EEA);
  static const brandD     = Color(0xFF4A5FCC);
  static const brandPale  = Color(0xFFEEF1FD);
  static const terra      = Color(0xFFE07A5F);
  static const terraD     = Color(0xFFC4674E);
  static const violet     = Color(0xFF7C3AED);
  static const violetPale = Color(0xFFF5F3FF);
  static const green      = Color(0xFF10B981);
  static const greenPale  = Color(0xFFECFDF5);
  static const amber      = Color(0xFFF59E0B);
  static const red        = Color(0xFFCC1616);
  static const coral      = Color(0xFFEF4444);
  static const offWhite   = Color(0xFFF5F4F0);
  static const surf       = Color(0xFFFFFFFF);
  static const text       = Color(0xFF1A1A2E);
  static const text2      = Color(0xFF555577);
  static const text3      = Color(0xFF9999BB);
  static const border     = Color(0xFFE1E5F7);
  static const shimmer    = Color(0xFFE8EAF6);
}

// ─────────────────────────────────────────────────────────────
//  API MODELS
// ─────────────────────────────────────────────────────────────

/// Parses a notification from /api/v1/profile/notifications/
class _ApiNotification {
  final String id;
  final String title;
  final String body;
  final String timeDisplay;
  final String category; // 'study' | 'market' | 'housing' | 'events' | other
  bool isRead;

  _ApiNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeDisplay,
    required this.category,
    required this.isRead,
  });

  factory _ApiNotification.fromJson(Map<String, dynamic> j) {
    return _ApiNotification(
      id:          j['id']?.toString() ?? '',
      title:       j['title']?.toString() ??
                   j['message']?.toString() ??
                   'Notification',
      body:        j['body']?.toString() ??
                   j['description']?.toString() ?? '',
      timeDisplay: _relativeTime(j['created_at']?.toString() ?? ''),
      category:    (j['category'] ?? j['module'] ?? j['type'] ?? '').toString().toLowerCase(),
      isRead:      j['is_read'] as bool? ?? j['read'] as bool? ?? false,
    );
  }

  static String _relativeTime(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt   = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1)  return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours   < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  String get emoji {
    switch (category) {
      case 'study':   return '📚';
      case 'market':  return '🛒';
      case 'housing': return '🏠';
      case 'events':  return '🎉';
      default:        return '🔔';
    }
  }

  Color get iconBg {
    switch (category) {
      case 'study':   return _C.brandPale;
      case 'market':  return const Color(0xFFFDF0EC);
      case 'housing': return _C.greenPale;
      case 'events':  return _C.violetPale;
      default:        return const Color(0xFFFFFBEB);
    }
  }

  Color get dotColor {
    switch (category) {
      case 'study':   return _C.brand;
      case 'market':  return _C.terra;
      case 'housing': return _C.green;
      case 'events':  return _C.violet;
      default:        return _C.amber;
    }
  }

  String get sourceLabel {
    switch (category) {
      case 'study':   return 'StudyBuddy';
      case 'market':  return 'CampusMarket';
      case 'housing': return 'HousingHub';
      case 'events':  return 'EventBoard';
      default:        return 'CampusBuddy';
    }
  }
}

/// Parses a single event from /api/v1/events/ results list.
class _ApiFeaturedEvent {
  final String id;
  final String title;
  final String dateDisplay;
  final String location;
  final int    attendingCount;
  bool isGoing;

  _ApiFeaturedEvent({
    required this.id,
    required this.title,
    required this.dateDisplay,
    required this.location,
    required this.attendingCount,
    this.isGoing = false,
  });

  factory _ApiFeaturedEvent.fromJson(Map<String, dynamic> j) {
    // ── Date formatting ──────────────────────────────────
    String dateDisplay = '';
    final rawDate = j['date']?.toString() ??
                    j['start_date']?.toString() ??
                    j['start_time']?.toString() ?? '';
    if (rawDate.isNotEmpty) {
      try {
        final dt     = DateTime.parse(rawDate).toLocal();
        const months = ['Jan','Feb','Mar','Apr','May','Jun',
                         'Jul','Aug','Sep','Oct','Nov','Dec'];
        const wdays  = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
        final h      = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
        final ampm   = dt.hour >= 12 ? 'PM' : 'AM';
        final mm     = dt.minute.toString().padLeft(2, '0');
        dateDisplay  = '${wdays[dt.weekday - 1]}, '
                       '${months[dt.month - 1]} ${dt.day} · $h:$mm $ampm';
      } catch (_) {
        dateDisplay = rawDate;
      }
    }

    return _ApiFeaturedEvent(
      id:             j['id']?.toString() ?? '',
      title:          j['title']?.toString() ?? 'Upcoming Event',
      dateDisplay:    dateDisplay,
      location:       j['location']?.toString() ??
                      j['venue']?.toString() ?? '',
      attendingCount: (j['attendees_count'] ??
                       j['rsvp_count'] ??
                       j['going_count'] ?? 0) as int,
      isGoing:        j['user_rsvp']   as bool? ??
                      j['is_attending'] as bool? ??
                      j['is_going']    as bool? ?? false,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MODULE VISUAL CONFIG  (badges are computed from live counts)
// ─────────────────────────────────────────────────────────────
class _ModuleCfg {
  final String emoji, name, sub, countSuffix;
  final Color  colorA, colorB;
  final int    navTab;
  const _ModuleCfg(this.emoji, this.name, this.sub, this.countSuffix,
      this.colorA, this.colorB, this.navTab);
}

const _kModules = [
  _ModuleCfg('📚', 'StudyBuddy',   'Tutors · Groups · Q&A',   'groups',
      _C.brand,  _C.brandD,               1),
  _ModuleCfg('🛒', 'CampusMarket', 'Buy · Sell · Donate',      'listings',
      _C.terra,  _C.terraD,               2),
  _ModuleCfg('🏠', 'HousingHub',   'Rooms · Roommates · Map',  'alerts',
      _C.green,  Color(0xFF0D9488),        3),
  _ModuleCfg('🎉', 'EventBoard',   'Events · RSVP · Calendar', 'events',
      _C.violet, Color(0xFF5B21B6),        4),
];

// ─────────────────────────────────────────────────────────────
//  HOME SCREEN ROOT
// ─────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  // ── Profile ──────────────────────────────────────────────
  String _profileName    = '';
  bool   _profileLoading = true;

  // ── Live stat counts ─────────────────────────────────────
  String _studyCount   = '–';
  String _marketCount  = '–';
  String _housingCount = '–';
  String _eventsCount  = '–';

  // ── Featured event ────────────────────────────────────────
  _ApiFeaturedEvent? _featuredEvent;
  bool _featuredLoading = true;

  // ── Notifications ─────────────────────────────────────────
  List<_ApiNotification> _notifications    = [];
  bool                   _notifsLoading    = true;
  int                    _unreadCount      = 0;

  // ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    await Future.wait([
      _fetchProfile(),
      _fetchStudyCount(),
      _fetchMarketCount(),
      _fetchHousingCount(),
      _fetchEventsCount(),
      _fetchFeaturedEvent(),
      _fetchNotifications(),
    ]);
  }

  // ── API FETCH METHODS ──────────────────────────────────────

  Future<void> _fetchProfile() async {
    try {
      final res = await ApiClient.get('/api/v1/profile/me/');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final j    = jsonDecode(res.body) as Map<String, dynamic>;
        final full = j['full_name']?.toString();
        final computed = '${j['first_name'] ?? ''} ${j['last_name'] ?? ''}'.trim();
        setState(() {
          _profileName    = (full?.isNotEmpty == true ? full! : computed).isNotEmpty
              ? (full?.isNotEmpty == true ? full! : computed)
              : 'Student';
          _profileLoading = false;
        });
      } else {
        setState(() => _profileLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _profileLoading = false);
    }
  }

  /// Helper: extract count from typical DRF paginated response.
  static int _extractCount(dynamic decoded) {
    if (decoded is Map) {
      final c = decoded['count'];
      if (c != null) return c as int;
      final r = decoded['results'];
      if (r is List) return r.length;
    }
    if (decoded is List) return decoded.length;
    return 0;
  }

  Future<void> _fetchStudyCount() async {
    try {
      final res = await ApiClient.get('api/study-buddy/groups/');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final count = _extractCount(jsonDecode(res.body));
        setState(() => _studyCount = count.toString());
      }
    } catch (_) {}
  }

  Future<void> _fetchMarketCount() async {
    try {
      final res = await ApiClient.get('/api/v1/market/listings/');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final count = _extractCount(jsonDecode(res.body));
        setState(() => _marketCount = count.toString());
      }
    } catch (_) {}
  }

  Future<void> _fetchHousingCount() async {
    try {
      final res = await ApiClient.get('/api/v1/housing/alerts/');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final count = _extractCount(jsonDecode(res.body));
        setState(() => _housingCount = count.toString());
      }
    } catch (_) {}
  }

  Future<void> _fetchEventsCount() async {
    try {
      final res = await ApiClient.get('/api/v1/events/');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final count = _extractCount(jsonDecode(res.body));
        setState(() => _eventsCount = count.toString());
      }
    } catch (_) {}
  }

  Future<void> _fetchFeaturedEvent() async {
    try {
      final res = await ApiClient.get('/api/v1/events/');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List<dynamic> results = decoded is Map
            ? ((decoded['results'] as List?) ?? [])
            : (decoded is List ? decoded : []);

        if (results.isNotEmpty) {
          // Prefer an event explicitly flagged as featured
          final raw = results.firstWhere(
            (e) => e is Map && (e['is_featured'] == true || e['featured'] == true),
            orElse: () => results.first,
          ) as Map<String, dynamic>;
          setState(() {
            _featuredEvent    = _ApiFeaturedEvent.fromJson(raw);
            _featuredLoading  = false;
          });
        } else {
          setState(() => _featuredLoading = false);
        }
      } else {
        setState(() => _featuredLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _featuredLoading = false);
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      final res = await ApiClient.get('/api/v1/profile/notifications/');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List<dynamic> raw = decoded is Map
            ? ((decoded['results'] as List?) ?? [])
            : (decoded is List ? decoded : []);

        final notifs = raw
            .map((n) => _ApiNotification.fromJson(n as Map<String, dynamic>))
            .toList();
        setState(() {
          _notifications = notifs;
          _unreadCount   = notifs.where((n) => !n.isRead).length;
          _notifsLoading = false;
        });
      } else {
        setState(() => _notifsLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _notifsLoading = false);
    }
  }

  // ── RSVP featured event ──────────────────────────────────
  Future<void> _rsvpFeaturedEvent() async {
    if (_featuredEvent == null) return;
    HapticFeedback.mediumImpact();
    // Optimistic toggle
    setState(() => _featuredEvent!.isGoing = !_featuredEvent!.isGoing);
    final going = _featuredEvent!.isGoing;
    _snack(going
        ? '✅ You\'re going to ${_featuredEvent!.title}!'
        : 'RSVP cancelled',
        color: _C.violet);
    try {
      await ApiClient.post('/api/v1/events/${_featuredEvent!.id}/rsvp/');
    } catch (_) {
      // Leave optimistic state — UX over strict consistency
    }
  }

  // ── Mark single notification read ─────────────────────────
  Future<void> _markNotificationRead(int i) async {
    final notif = _notifications[i];
    if (notif.isRead) {
      _snack('Already read', color: _C.text3);
      return;
    }
    // Optimistic
    setState(() {
      notif.isRead = true;
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    });
    // Route to relevant module
    _routeByCategory(notif.category);
    // Fire API in background
    ApiClient.post('/api/v1/profiles/notifications/${notif.id}/read/')
        .catchError((_) {});
  }

  // ── Mark ALL notifications read ───────────────────────────
  void _markAllNotificationsRead() {
    final unread = _notifications.where((n) => !n.isRead).toList();
    setState(() {
      for (final n in _notifications) n.isRead = true;
      _unreadCount = 0;
    });
    for (final n in unread) {
      ApiClient.post('/api/v1/profiles/notifications/${n.id}/read/')
          .catchError((_) {});
    }
  }

  void _routeByCategory(String cat) {
    switch (cat) {
      case 'study':   _openStudyBuddy();   break;
      case 'market':  _openCampusMarket(); break;
      case 'housing': _openHousingHub();   break;
      case 'events':  _openEventBoard();   break;
    }
  }

  // ── Navigation helpers ────────────────────────────────────
  void _openStudyBuddy() {
    HapticFeedback.mediumImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => StudyBuddyHome()));
  }

  void _openCampusMarket() {
    HapticFeedback.mediumImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => CampusMarketHome()));
  }

  void _openHousingHub() {
    HapticFeedback.mediumImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => HousingHubHome()));
  }

  void _openEventBoard() {
    HapticFeedback.mediumImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => EventBoardHome()));
  }

  void _openProfile() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    ).then((_) => _fetchProfile()); // refresh name after edit
  }

  void _handleTab(int tab, {String label = ''}) {
    switch (tab) {
      case 1: _openStudyBuddy();   break;
      case 2: _openCampusMarket(); break;
      case 3: _openHousingHub();   break;
      case 4: _openEventBoard();   break;
      default:
        if (label.isNotEmpty) _snack('Opening $label…');
    }
  }

  void _goTab(int tab) => setState(() => _navIndex = tab);

  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color ?? _C.brandD,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
  }

  void _showNotificationsSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationSheet(
        notifications: _notifications,
        onMarkAll: () {
          _markAllNotificationsRead();
          // Sheet rebuilds via its own setState after callback
        },
      ),
    );
  }

  void _openSearch() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (_) => _SearchDialog(
        onNavigate: (tab, label) {
          switch (tab) {
            case 1: _openStudyBuddy();   break;
            case 2: _openCampusMarket(); break;
            case 3: _openHousingHub();   break;
            case 4: _openEventBoard();   break;
            default: _goTab(tab); _snack('Opening $label…');
          }
        },
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.offWhite,
      extendBody: true,
      body: RefreshIndicator(
        color: _C.brand,
        onRefresh: _fetchAll,
        child: CustomScrollView(
          slivers: [

            // 1. Header with live profile name
            SliverToBoxAdapter(
              child: _Header(
                profileName:    _profileName,
                profileLoading: _profileLoading,
                unreadCount:    _unreadCount,
                onSearch:        _openSearch,
                onNotifications: _showNotificationsSheet,
                onProfile:       _openProfile,
              ),
            ),

            // 2. Quick stats — live counts
            SliverToBoxAdapter(
              child: _QuickStatsRow(
                studyCount:   _studyCount,
                marketCount:  _marketCount,
                housingCount: _housingCount,
                eventsCount:  _eventsCount,
                onTap: (tab) => _handleTab(tab),
              ),
            ),

            // 3. Module grid — badges use live counts
            _sec('🧭 Explore Modules', showMore: false),
            SliverToBoxAdapter(
              child: _ModuleGrid(
                counts: [
                  _studyCount,
                  _marketCount,
                  _housingCount,
                  _eventsCount,
                ],
                onTap: (tab, name) => _handleTab(tab, label: name),
              ),
            ),

            // 4. Featured event (API)
            if (_featuredLoading)
              const SliverToBoxAdapter(child: _FeaturedSkeleton()),
            if (!_featuredLoading && _featuredEvent != null)
              SliverToBoxAdapter(
                child: _FeaturedEventCard(
                  event:    _featuredEvent!,
                  onRsvp:   _rsvpFeaturedEvent,
                  onDetail: _openEventBoard,
                ),
              ),

            // 5. Notifications feed
            _sec('🔔 Notifications',
                moreLabel: 'See all →',
                onMore: _showNotificationsSheet),
            SliverToBoxAdapter(
              child: _notifsLoading
                  ? const _NotifsSkeleton()
                  : _notifications.isEmpty
                      ? const _EmptyNotifs()
                      : _NotificationsFeed(
                          notifications: _notifications,
                          onTap: _markNotificationRead,
                        ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        selected: _navIndex,
        onTap: (i) {
          HapticFeedback.selectionClick();
          if (i == 1) { _openStudyBuddy();   return; }
          if (i == 2) { _openCampusMarket(); return; }
          if (i == 3) { _openHousingHub();   return; }
          if (i == 4) { _openEventBoard();   return; }
          _goTab(i);
        },
      ),
    );
  }

  SliverToBoxAdapter _sec(String label,
      {String moreLabel = 'See all →',
      bool showMore = true,
      VoidCallback? onMore}) =>
      SliverToBoxAdapter(
        child: _SectionLabel(label,
            moreLabel: moreLabel,
            showMore: showMore,
            onMore: onMore),
      );
}

// ─────────────────────────────────────────────────────────────
//  1. HEADER  (profile name now dynamic)
// ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String      profileName;
  final bool        profileLoading;
  final int         unreadCount;
  final VoidCallback onSearch, onNotifications, onProfile;

  const _Header({
    required this.profileName,
    required this.profileLoading,
    required this.unreadCount,
    required this.onSearch,
    required this.onNotifications,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        height: 250,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8096F0), _C.brand, _C.brandD],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: CustomPaint(
            painter: _TopoPainter(),
            child: const SizedBox.expand()),
      ),
      Positioned(
        bottom: 0, left: 0, right: 0,
        child: CustomPaint(
            size: const Size(double.infinity, 52),
            painter: _WavePainter()),
      ),
      Positioned.fill(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _LogoPill(),
                    _HeaderIcons(
                      unreadCount:     unreadCount,
                      onNotifications: onNotifications,
                      onProfile:       onProfile,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Hello,',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.65))),
                const SizedBox(height: 2),
                // ── Live profile name ─────────────────────
                profileLoading
                    ? _ShimmerLine(width: 140, height: 24)
                    : Text('$profileName 👋',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3)),
                const SizedBox(height: 14),
                _SearchBarWidget(onTap: onSearch),
              ],
            ),
          ),
        ),
      ),
    ]);
  }
}

class _LogoPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_C.red, Color(0xFFA80F0F)],
            ),
          ),
          child: const Center(
            child: Text('C',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1)),
          ),
        ),
        const SizedBox(width: 6),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            children: [
              TextSpan(text: 'Campus',
                  style: TextStyle(color: _C.red)),
              TextSpan(text: 'Buddy',
                  style: TextStyle(color: _C.brand)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _HeaderIcons extends StatelessWidget {
  final int          unreadCount;
  final VoidCallback onNotifications, onProfile;
  const _HeaderIcons({
    required this.unreadCount,
    required this.onNotifications,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _HIconBtn(
        onTap: onNotifications,
        child: Stack(clipBehavior: Clip.none, children: [
          const Text('🔔', style: TextStyle(fontSize: 18)),
          if (unreadCount > 0)
            Positioned(
              top: -4, right: -4,
              child: Container(
                width: 16, height: 16,
                decoration: BoxDecoration(
                    color: _C.coral,
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.brandD, width: 1.5)),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(width: 8),
      _HIconBtn(
        onTap: onProfile,
        child: const Text('👤', style: TextStyle(fontSize: 18)),
      ),
    ]);
  }
}

class _HIconBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HIconBtn({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _SearchBarWidget extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBarWidget({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 6))
          ],
        ),
        child: Row(children: [
          const Text('🔍', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Search tutors, rooms, events…',
                style: TextStyle(fontSize: 13, color: _C.text3)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: _C.brand,
                borderRadius: BorderRadius.circular(9)),
            child: const Row(children: [
              Text('⚙', style: TextStyle(fontSize: 11)),
              SizedBox(width: 4),
              Text('Filter',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  2. QUICK STATS ROW  (dynamic counts)
// ─────────────────────────────────────────────────────────────
class _QuickStatsRow extends StatelessWidget {
  final String studyCount, marketCount, housingCount, eventsCount;
  final ValueChanged<int> onTap;

  const _QuickStatsRow({
    required this.studyCount,
    required this.marketCount,
    required this.housingCount,
    required this.eventsCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (emoji: '📚', value: studyCount,   label: 'Study Groups',   color: _C.brand,  tab: 1),
      (emoji: '🛒', value: marketCount,  label: 'New Listings',   color: _C.terra,  tab: 2),
      (emoji: '🏠', value: housingCount, label: 'Housing Alerts', color: _C.green,  tab: 3),
      (emoji: '🎉', value: eventsCount,  label: 'Events Today',   color: _C.violet, tab: 4),
    ];

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (_, i) {
          final s = items[i];
          return GestureDetector(
            onTap: () => onTap(s.tab),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: _C.surf,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.border),
                boxShadow: [
                  BoxShadow(
                      color: _C.brand.withOpacity(0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(s.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 9),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    s.value == '–'
                        ? _ShimmerLine(width: 24, height: 18)
                        : Text(s.value,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: s.color,
                                height: 1)),
                    const SizedBox(height: 2),
                    Text(s.label,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _C.text3)),
                  ],
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label, moreLabel;
  final bool showMore;
  final VoidCallback? onMore;
  const _SectionLabel(this.label,
      {this.moreLabel = 'See all →',
      this.showMore = true,
      this.onMore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _C.text)),
          if (showMore)
            GestureDetector(
              onTap: onMore,
              child: Text(moreLabel,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _C.brand)),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  3. MODULE GRID  (badges show live counts)
// ─────────────────────────────────────────────────────────────
class _ModuleGrid extends StatelessWidget {
  final void Function(int tab, String name) onTap;
  /// Counts in order: [study, market, housing, events]
  final List<String> counts;
  const _ModuleGrid({required this.onTap, required this.counts});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
        children: List.generate(_kModules.length, (i) {
          final m     = _kModules[i];
          final count = counts.length > i ? counts[i] : '–';
          final badge = count == '–' ? '…' : '$count ${m.countSuffix}';
          return ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTap(m.navTab, m.name),
                splashColor:    Colors.white.withOpacity(0.15),
                highlightColor: Colors.white.withOpacity(0.08),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [m.colorA, m.colorB],
                    ),
                  ),
                  child: Stack(children: [
                    Positioned(
                      top: -22, right: -22,
                      child: Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.09)),
                      ),
                    ),
                    Positioned(
                      bottom: -14, left: -14,
                      child: Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.06)),
                      ),
                    ),
                    Positioned(
                      top: 0, right: 0,
                      child: Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Center(
                          child: Text('›',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(badge,
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                        const Spacer(),
                        Text(m.emoji,
                            style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 6),
                        Text(m.name,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.1)),
                        const SizedBox(height: 2),
                        Text(m.sub,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.72))),
                      ],
                    ),
                  ]),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  4. FEATURED EVENT CARD  (from API)
// ─────────────────────────────────────────────────────────────
class _FeaturedEventCard extends StatelessWidget {
  final _ApiFeaturedEvent event;
  final VoidCallback      onRsvp, onDetail;
  const _FeaturedEventCard({
    required this.event,
    required this.onRsvp,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.violet, Color(0xFF5B21B6)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onDetail,
            splashColor: Colors.white.withOpacity(0.1),
            child: Stack(children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.7, -0.8),
                      radius: 1.0,
                      colors: [
                        Colors.white.withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16, bottom: 10,
                child: Text('🎓',
                    style: TextStyle(
                        fontSize: 56,
                        color: Colors.white.withOpacity(0.12))),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🔥 FEATURED EVENT',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.72),
                            letterSpacing: 1.5)),
                    const SizedBox(height: 6),
                    Text(event.title,
                        style: const TextStyle(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            height: 1.3)),
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (event.dateDisplay.isNotEmpty)
                          '📅 ${event.dateDisplay}',
                        if (event.location.isNotEmpty)
                          '📍 ${event.location}',
                      ].join('  ·  '),
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.75)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          _AvatarStack(),
                          const SizedBox(width: 8),
                          Text('+${event.attendingCount} going',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.75))),
                        ]),
                        GestureDetector(
                          onTap: onRsvp,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: event.isGoing
                                  ? Colors.white.withOpacity(0.35)
                                  : Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.35)),
                            ),
                            child: Text(
                                event.isGoing ? '✅ Going' : 'RSVP →',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final _av = const [
    ('SK', Color(0xFF8B9EF0)),
    ('JM', Color(0xFF5B21B6)),
    ('AO', Color(0xFFA78BFA)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52, height: 24,
      child: Stack(
        children: List.generate(
          _av.length,
          (i) => Positioned(
            left: i * 18.0,
            child: Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _av[i].$2,
                border: Border.all(
                    color: Colors.white.withOpacity(0.4), width: 2),
              ),
              child: Center(
                child: Text(_av[i].$1,
                    style: const TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  5. NOTIFICATIONS FEED  (replaces Activity Feed)
// ─────────────────────────────────────────────────────────────
class _NotificationsFeed extends StatelessWidget {
  final List<_ApiNotification> notifications;
  final void Function(int) onTap;
  const _NotificationsFeed({
    required this.notifications,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _C.surf,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
              color: _C.brand.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: List.generate(notifications.length, (i) {
            final n      = notifications[i];
            final isLast = i == notifications.length - 1;
            return Material(
              color: n.isRead ? _C.surf : _C.offWhite,
              child: InkWell(
                onTap: () => onTap(i),
                child: Container(
                  decoration: isLast
                      ? null
                      : const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: _C.border))),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                            color: n.iconBg,
                            borderRadius: BorderRadius.circular(12)),
                        child: Center(
                          child: Text(n.emoji,
                              style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.title,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: n.isRead
                                        ? FontWeight.w600
                                        : FontWeight.w800,
                                    color: _C.text,
                                    height: 1.3)),
                            if (n.body.isNotEmpty &&
                                n.body != n.title) ...[
                              const SizedBox(height: 2),
                              Text(n.body,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: _C.text2)),
                            ],
                            const SizedBox(height: 3),
                            Text(
                              [
                                if (n.timeDisplay.isNotEmpty)
                                  n.timeDisplay,
                                n.sourceLabel,
                              ].join(' · '),
                              style: const TextStyle(
                                  fontSize: 10, color: _C.text3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: n.isRead ? _C.border : n.dotColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EMPTY / SKELETON STATES
// ─────────────────────────────────────────────────────────────

/// Pulsing shimmer placeholder used while loading
class _ShimmerLine extends StatelessWidget {
  final double width, height;
  const _ShimmerLine({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _FeaturedSkeleton extends StatelessWidget {
  const _FeaturedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      height: 148,
      decoration: BoxDecoration(
        color: _C.shimmer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: SizedBox(
          width: 28, height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: _C.brand,
          ),
        ),
      ),
    );
  }
}

class _NotifsSkeleton extends StatelessWidget {
  const _NotifsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surf,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: List.generate(3, (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  color: _C.shimmer,
                  borderRadius: BorderRadius.circular(12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _C.shimmer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    width: 120,
                    decoration: BoxDecoration(
                      color: _C.shimmer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        )),
      ),
    );
  }
}

class _EmptyNotifs extends StatelessWidget {
  const _EmptyNotifs();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: _C.surf,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
      ),
      child: Column(children: [
        Text('🔔', style: TextStyle(
            fontSize: 36,
            color: _C.text3.withOpacity(0.5))),
        const SizedBox(height: 10),
        const Text('All caught up!',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _C.text2)),
        const SizedBox(height: 4),
        const Text('No new notifications right now.',
            style: TextStyle(fontSize: 12, color: _C.text3)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  6. BOTTOM NAV
// ─────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.selected, required this.onTap});

  static const _items = [
    ('🏠', 'Home',    _C.brand),
    ('📚', 'Study',   _C.brand),
    ('🛒', 'Market',  _C.terra),
    ('🏘', 'Housing', _C.green),
    ('🎉', 'Events',  _C.violet),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _C.border)),
      ),
      padding: EdgeInsets.only(
          top: 10,
          bottom: MediaQuery.of(context).padding.bottom + 10,
          left: 4,
          right: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final active = i == selected;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? _items[i].$3.withOpacity(0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_items[i].$1,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 3),
                  Text(_items[i].$2,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? _items[i].$3
                              : _C.text3)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SEARCH DIALOG
// ─────────────────────────────────────────────────────────────
class _SearchDialog extends StatefulWidget {
  final void Function(int tab, String label) onNavigate;
  const _SearchDialog({required this.onNavigate});
  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final _ctrl = TextEditingController();
  final _suggestions = [
    (emoji: '📚', label: 'Find a Tutor',    tab: 1),
    (emoji: '🛒', label: 'Browse Market',   tab: 2),
    (emoji: '🏠', label: 'Search Rooms',    tab: 3),
    (emoji: '🎉', label: 'Upcoming Events', tab: 4),
  ];

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search tutors, rooms, events…',
              prefixIcon: const Icon(Icons.search, color: _C.brand),
              filled: true,
              fillColor: _C.brandPale,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Quick Jump',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _C.text2)),
          ),
          const SizedBox(height: 8),
          ..._suggestions.map((s) => ListTile(
                leading: Text(s.emoji,
                    style: const TextStyle(fontSize: 20)),
                title: Text(s.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: _C.text)),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 12, color: _C.text3),
                onTap: () {
                  Navigator.pop(context);
                  widget.onNavigate(s.tab, s.label);
                },
              )),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  NOTIFICATION BOTTOM SHEET
// ─────────────────────────────────────────────────────────────
class _NotificationSheet extends StatefulWidget {
  final List<_ApiNotification> notifications;
  final VoidCallback onMarkAll;
  const _NotificationSheet({
    required this.notifications,
    required this.onMarkAll,
  });
  @override
  State<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<_NotificationSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _C.surf,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: _C.border,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Notifications',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _C.text)),
            TextButton(
              onPressed: () {
                widget.onMarkAll();
                setState(() {});
              },
              child: const Text('Mark all read',
                  style: TextStyle(
                      color: _C.brand,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.notifications.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(children: const [
              Text('🔔', style: TextStyle(fontSize: 32)),
              SizedBox(height: 8),
              Text('No notifications yet.',
                  style: TextStyle(fontSize: 13, color: _C.text3)),
            ]),
          ),
        ...widget.notifications.map((n) => ListTile(
              leading: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                    color: n.iconBg,
                    borderRadius: BorderRadius.circular(12)),
                child: Center(
                    child: Text(n.emoji,
                        style: const TextStyle(fontSize: 16))),
              ),
              title: Text(n.title,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: n.isRead
                          ? FontWeight.w600
                          : FontWeight.w800,
                      color: _C.text)),
              subtitle: Text(
                [
                  if (n.timeDisplay.isNotEmpty) n.timeDisplay,
                  n.sourceLabel,
                ].join(' · '),
                style: const TextStyle(
                    fontSize: 10, color: _C.text3),
              ),
              trailing: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: n.isRead ? _C.border : n.dotColor),
              ),
              onTap: () => setState(() => n.isRead = true),
            )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CUSTOM PAINTERS
// ─────────────────────────────────────────────────────────────
class _TopoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (final r in [(80.0, 44.0), (55.0, 30.0), (32.0, 18.0)])
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(s.width * 0.187, s.height * 0.24),
              width: r.$1 * 2,
              height: r.$2 * 2),
          p);
    for (final r in [(95.0, 52.0), (66.0, 36.0), (38.0, 20.0)])
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(s.width * 0.827, s.height * 0.60),
              width: r.$1 * 2,
              height: r.$2 * 2),
          p);
    final t = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    void c(List<double> v) => canvas.drawPath(
        Path()
          ..moveTo(v[0], v[1])
          ..cubicTo(v[2], v[3], v[4], v[5], v[6], v[7]),
        t);
    c([0, s.height * .16, s.width * .213, s.height * .04,
       s.width * .48,  s.height * .22, s.width, s.height * .18]);
    c([0, s.height * .40, s.width * .187, s.height * .28,
       s.width * .453, s.height * .42, s.width, s.height * .40]);
    c([0, s.height * .66, s.width * .24,  s.height * .56,
       s.width * .493, s.height * .68, s.width, s.height * .64]);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawPath(
      Path()
        ..moveTo(0, s.height * .19)
        ..quadraticBezierTo(s.width * .213, s.height * 1.06,
            s.width * .507, s.height * .577)
        ..quadraticBezierTo(s.width * .795, s.height * .154,
            s.width, s.height * .962)
        ..lineTo(s.width, s.height)
        ..lineTo(0, s.height)
        ..close(),
      Paint()..color = _C.offWhite,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}