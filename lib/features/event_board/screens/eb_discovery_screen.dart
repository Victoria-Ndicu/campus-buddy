import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import '../models/eb_constants.dart';
import '../widgets/eb_widgets.dart';
import '../../../core/api_client.dart';

// ─────────────────────────────────────────────────────────────
//  API ENDPOINTS
//
//  GET    /api/v1/events/                  → list / filter events
//  GET    /api/v1/events/<uuid>/           → event detail
//  POST   /api/v1/events/<uuid>/rsvp/      → RSVP
//  DELETE /api/v1/events/<uuid>/rsvp/      → cancel RSVP
//  POST   /api/v1/events/<uuid>/save/      → save event
//  DELETE /api/v1/events/<uuid>/save/      → unsave event
//
//  Query params supported:
//    category=academic|social|sports|career  (lowercase)
//   
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
//  DATE HELPERS
// ─────────────────────────────────────────────────────────────
class _DateHelper {
  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  /// Parse ISO 8601 → "Apr 15, 2:00 PM"
  static String format(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m  = dt.minute.toString().padLeft(2, '0');
      final s  = dt.hour < 12 ? 'AM' : 'PM';
      return '${_months[dt.month]} ${dt.day}, $h:$m $s';
    } catch (_) {
      return iso;
    }
  }

  /// Format a date range: "Apr 15, 2:00 PM – 4:00 PM"
  static String formatRange(String? startIso, String? endIso) {
    final start = format(startIso);
    if (endIso == null || endIso.isEmpty) return start;
    try {
      final dt = DateTime.parse(endIso).toLocal();
      final h  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m  = dt.minute.toString().padLeft(2, '0');
      final s  = dt.hour < 12 ? 'AM' : 'PM';
      return '$start – $h:$m $s';
    } catch (_) {
      return start;
    }
  }

  /// Returns true if the event's endAt (or startAt) is in the past
  static bool isPast(String? endIso, String? startIso) {
    final iso = endIso?.isNotEmpty == true ? endIso : startIso;
    if (iso == null || iso.isEmpty) return false;
    try {
      return DateTime.parse(iso).toLocal().isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────────────────────
class EBEventModel {
  final String id;
  final String emoji;
  final String title;
  final String date;
  final String rawStartAt;
  final String rawEndAt;
  final String location;
  final String organiser;
  final String category;
  final int    attendingCount;
  final bool   isRsvped;
  final bool   isSaved;
  final bool   isPast;
  final String description;
  final String entry;
  final String mode;
  final String? bannerUrl;

  const EBEventModel({
    required this.id,
    required this.title,
    this.emoji          = '🎉',
    this.date           = '',
    this.rawStartAt     = '',
    this.rawEndAt       = '',
    this.location       = '',
    this.organiser      = '',
    this.category       = '',
    this.attendingCount = 0,
    this.isRsvped       = false,
    this.isSaved        = false,
    this.isPast         = false,
    this.description    = '',
    this.entry          = 'Free Entry',
    this.mode           = 'In-Person',
    this.bannerUrl,
  });

  // ── Category → design tokens ──────────────────────────────
  Color get catColor {
    final c = category.toLowerCase();
    if (c.contains('academic') || c.contains('tech')) return EBColors.blue;
    if (c.contains('sport'))                          return EBColors.green;
    if (c.contains('career'))                         return EBColors.amber;
    return EBColors.brand;
  }

  Color get gradA {
    final c = category.toLowerCase();
    if (c.contains('sport'))                          return const Color(0xFFECFDF5);
    if (c.contains('career'))                         return const Color(0xFFFFFBEB);
    return const Color(0xFFEDE9FE);
  }

  Color get gradB {
    final c = category.toLowerCase();
    if (c.contains('sport'))                          return const Color(0xFF6EE7B7);
    if (c.contains('career'))                         return const Color(0xFFFDE68A);
    return const Color(0xFFC4B5FD);
  }

  Color get rsvpColor => catColor;

  factory EBEventModel.fromJson(Map<String, dynamic> raw) {
    Map<String, dynamic> j;
    if (raw['data'] is Map<String, dynamic>) {
      j = raw['data'] as Map<String, dynamic>;
    } else if (raw['event'] is Map<String, dynamic>) {
      j = raw['event'] as Map<String, dynamic>;
    } else {
      j = raw;
    }

    String str(String k) => j[k]?.toString() ?? '';

    bool boo(String k) {
      final v = j[k];
      if (v is bool)   return v;
      if (v is int)    return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
      return false;
    }

    int attendingCount() {
      final rsvp      = j['rsvpCount'];
      final attending = j['attendingCount'];
      if (rsvp      is num) return rsvp.toInt();
      if (attending is num) return attending.toInt();
      return 0;
    }

    final startAt = str('startAt');
    final endAt   = str('endAt');
    final displayDate = str('date').isNotEmpty
        ? str('date')
        : _DateHelper.formatRange(startAt, endAt);

    final organiser = str('organiserName').isNotEmpty
        ? str('organiserName')
        : str('organiser').isNotEmpty
            ? str('organiser')
            : str('organiserId');

    final past = _DateHelper.isPast(
      endAt.isNotEmpty   ? endAt   : null,
      startAt.isNotEmpty ? startAt : null,
    );

    return EBEventModel(
      id:             str('id'),
      title:          str('title'),
      emoji:          str('emoji').isEmpty ? '🎉' : str('emoji'),
      date:           displayDate,
      rawStartAt:     startAt,
      rawEndAt:       endAt,
      location:       str('location'),
      organiser:      organiser,
      category:       str('category'),
      attendingCount: attendingCount(),
      isRsvped:       boo('isRsvped'),
      isSaved:        boo('isSaved'),
      isPast:         past,
      description:    str('description'),
      entry:          str('entry').isEmpty ? 'Free Entry' : str('entry'),
      mode:           str('mode').isEmpty  ? 'In-Person'  : str('mode'),
      bannerUrl:      str('bannerUrl').isNotEmpty ? str('bannerUrl') : null,
    );
  }

  EBEventModel copyWith({
    bool? isRsvped,
    bool? isSaved,
    int?  attendingCount,
  }) => EBEventModel(
    id:             id,
    title:          title,
    emoji:          emoji,
    date:           date,
    rawStartAt:     rawStartAt,
    rawEndAt:       rawEndAt,
    location:       location,
    organiser:      organiser,
    category:       category,
    attendingCount: attendingCount ?? this.attendingCount,
    isRsvped:       isRsvped      ?? this.isRsvped,
    isSaved:        isSaved       ?? this.isSaved,
    isPast:         isPast,
    description:    description,
    entry:          entry,
    mode:           mode,
    bannerUrl:      bannerUrl,
  );
}

// ─────────────────────────────────────────────────────────────
//  DISCOVERY SCREEN
// ─────────────────────────────────────────────────────────────
class EBDiscoveryScreen extends StatefulWidget {
  const EBDiscoveryScreen({super.key});
  @override
  State<EBDiscoveryScreen> createState() => _EBDiscoveryScreenState();
}

class _EBDiscoveryScreenState extends State<EBDiscoveryScreen>
    with SingleTickerProviderStateMixin {

  late final TabController _tabController;

  int _catFilter  = 0;
  

  final _categories = [
    'All', '📚 Academic', '🎵 Social',
    '⚽ Sports', '🛠 Career',
  ];

  static const _catParams  = ['', 'academic', 'social', 'sports', 'career'];

  List<EBEventModel> _upcoming = [];
  List<EBEventModel> _past     = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    if (mounted) setState(() { _loading = true; _error = null; });

    try {
      final params = <String>[];
      if (_catFilter  != 0) params.add('category=${_catParams[_catFilter]}');
      final query = params.isEmpty ? '' : '?${params.join('&')}';

      final res = await ApiClient.get('/api/v1/events/$query');
      dev.log('[Discovery] GET /events$query → ${res.statusCode}');
      dev.log('[Discovery] body: ${res.body}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        List<dynamic> raw;
        if (decoded is List) {
          raw = decoded;
        } else if (decoded['data'] is List) {
          raw = decoded['data'] as List;
        } else if (decoded['results'] is List) {
          raw = decoded['results'] as List;
        } else {
          raw = [];
        }

        final events = raw
            .whereType<Map<String, dynamic>>()
            .map(EBEventModel.fromJson)
            .toList();

        final upcoming = events.where((e) => !e.isPast).toList();
        final past     = events.where((e) =>  e.isPast).toList();

        upcoming.sort((a, b) => a.rawStartAt.compareTo(b.rawStartAt));
        past.sort(   (a, b) => b.rawStartAt.compareTo(a.rawStartAt));

        setState(() {
          _upcoming = upcoming;
          _past     = past;
          _loading  = false;
        });
      } else {
        setState(() {
          _error   = 'Could not load events (${res.statusCode}).';
          _loading = false;
        });
      }
    } catch (e, s) {
      dev.log('[Discovery] error: $e', stackTrace: s);
      if (mounted) setState(() { _error = 'Network error. Pull to refresh.'; _loading = false; });
    }
  }

  Future<void> _toggleRsvp(EBEventModel event) async {
    final wasGoing = event.isRsvped;
    _mutate(event.id, isRsvped: !wasGoing, attendingDelta: wasGoing ? -1 : 1);

    try {
      final res = wasGoing
          ? await ApiClient.delete('/api/v1/events/${event.id}/rsvp/')
          : await ApiClient.post  ('/api/v1/events/${event.id}/rsvp/');

      dev.log('[Discovery] RSVP ${event.id} → ${res.statusCode}');

      final ok = res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204;
      if (!ok) {
        _mutate(event.id, isRsvped: wasGoing, attendingDelta: wasGoing ? 1 : -1);
        if (mounted) _snack('Could not update RSVP. Please try again.');
      } else {
        if (mounted) _snack(!wasGoing ? "✅ You're going to ${event.title}!" : 'RSVP cancelled');
      }
    } catch (_) {
      _mutate(event.id, isRsvped: wasGoing, attendingDelta: wasGoing ? 1 : -1);
      if (mounted) _snack('Network error. Please try again.');
    }
  }

  Future<void> _toggleSave(EBEventModel event) async {
    final wasSaved = event.isSaved;
    _mutate(event.id, isSaved: !wasSaved);

    try {
      final res = wasSaved
          ? await ApiClient.delete('/api/v1/events/${event.id}/save/')
          : await ApiClient.post  ('/api/v1/events/${event.id}/save/');

      dev.log('[Discovery] Save ${event.id} → ${res.statusCode}');

      final ok = res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204;
      if (!ok) {
        _mutate(event.id, isSaved: wasSaved);
        if (mounted) _snack('Could not save event.');
      } else {
        if (mounted) _snack(wasSaved ? 'Event unsaved.' : '❤️ Event saved!');
      }
    } catch (_) {
      _mutate(event.id, isSaved: wasSaved);
      if (mounted) _snack('Network error. Please try again.');
    }
  }

  void _mutate(String id, {bool? isRsvped, bool? isSaved, int attendingDelta = 0}) {
    if (!mounted) return;
    setState(() {
      _upcoming = _upcoming.map((e) => e.id == id
          ? e.copyWith(
              isRsvped:       isRsvped,
              isSaved:        isSaved,
              attendingCount: e.attendingCount + attendingDelta)
          : e).toList();
      _past = _past.map((e) => e.id == id
          ? e.copyWith(
              isRsvped:       isRsvped,
              isSaved:        isSaved,
              attendingCount: e.attendingCount + attendingDelta)
          : e).toList();
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: EBColors.brand,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EBColors.surface2,
      appBar: AppBar(
        backgroundColor: EBColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: EBColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('EventBoard', style: TextStyle(
            fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w900,
            color: EBColors.brandDark, fontStyle: FontStyle.italic)),
          Text(
            _loading
              ? 'Loading events…'
              : '${_upcoming.length} upcoming · ${_past.length} past',
            style: TextStyle(fontSize: 11, color: EBColors.text3)),
        ]),
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: EBColors.border, height: 1)),
      ),
      body: RefreshIndicator(
        color: EBColors.brand,
        onRefresh: _loadEvents,
        child: CustomScrollView(slivers: [

          // ── Category filter chips ──────────────────────
          SliverToBoxAdapter(
            child: SizedBox(height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 7),
                itemBuilder: (_, i) => EBChip(
                  label: _categories[i],
                  active: _catFilter == i,
                  onTap: () {
                    setState(() => _catFilter = i);
                    _loadEvents();
                  }),
              )),
          ),

          // ── Loading / Error ────────────────────────────
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Text(_error!, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: EBColors.text3)),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _loadEvents,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry')),
                ]),
              ),
            )
          else ...[

            // // ── Sort chips ─────────────────────────────────
            // SliverToBoxAdapter(
            //   child: SizedBox(height: 46,
            //     child: ListView.separated(
            //       scrollDirection: Axis.horizontal,
            //       padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            //       itemCount: _sorts.length,
            //       separatorBuilder: (_, __) => const SizedBox(width: 7),
            //       itemBuilder: (_, i) => EBChip(
            //         label: _sorts[i],
            //         active: _sortFilter == i,
            //         onTap: () {
            //           setState(() => _sortFilter = i);
            //           _loadEvents();
            //         }),
            //     )),
            // ),

            // ── Upcoming / Past tab bar ────────────────────
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                decoration: BoxDecoration(
                  color: EBColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EBColors.border)),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: EBColors.brand,
                    borderRadius: BorderRadius.circular(10)),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: EBColors.text2,
                  labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
                  tabs: [
                    Tab(text: 'Upcoming (${_upcoming.length})'),
                    Tab(text: 'Past (${_past.length})'),
                  ],
                ),
              ),
            ),

            // ── Tab content ────────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: _tabListHeight,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ── Upcoming list ─────────────────
                    _upcoming.isEmpty
                      ? _EmptyState(
                          emoji: '🗓',
                          message: 'No upcoming events',
                          sub: 'Check back soon or try a different category')
                      : ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _upcoming.length,
                          itemBuilder: (_, i) {
                            final ev = _upcoming[i];
                            return _EventCard(
                              event: ev,
                              onTap: () => _pushDetail(ev),
                              onRsvpTap: () => _toggleRsvp(ev),
                              onSaveTap: () => _toggleSave(ev),
                            );
                          }),

                    // ── Past list ─────────────────────
                    _past.isEmpty
                      ? _EmptyState(
                          emoji: '📜',
                          message: 'No past events',
                          sub: 'Events that have ended will appear here')
                      : ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _past.length,
                          itemBuilder: (_, i) {
                            final ev = _past[i];
                            return _EventCard(
                              event: ev,
                              isPastCard: true,
                              onTap: () => _pushDetail(ev),
                              onRsvpTap: () {},
                              onSaveTap: () => _toggleSave(ev),
                            );
                          }),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ]),
      ),
    );
  }

  double get _tabListHeight {
    final activeList = _tabController.index == 0
        ? _upcoming.length
        : _past.length;
    const cardHeight = 230.0;
    const minHeight  = 200.0;
    return (activeList * cardHeight).clamp(minHeight, double.infinity);
  }

  void _pushDetail(EBEventModel ev) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EBEventDetailScreen(
          eventId: ev.id,
          snapshot: ev,
        )),
    ).then((_) => _loadEvents());
  }
}

// ─────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String emoji;
  final String message;
  final String sub;
  const _EmptyState({required this.emoji, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: const TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text(message, style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700, color: EBColors.text)),
        const SizedBox(height: 4),
        Text(sub, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: EBColors.text3)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EVENT CARD
// ─────────────────────────────────────────────────────────────
class _EventCard extends StatelessWidget {
  final EBEventModel event;
  final VoidCallback onTap;
  final VoidCallback onRsvpTap;
  final VoidCallback onSaveTap;
  final bool isPastCard;

  const _EventCard({
    required this.event,
    required this.onTap,
    required this.onRsvpTap,
    required this.onSaveTap,
    this.isPastCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final e = event;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isPastCard ? 0.72 : 1.0,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: EBTheme.card,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Banner
            Container(
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [e.gradA, e.gradB],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18))),
              child: Stack(children: [
                // Banner image with loading + error fallback
                if (e.bannerUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Image.network(
                      e.bannerUrl!,
                      width: double.infinity,
                      height: 110,
                      fit: BoxFit.cover,
                      // Show shimmer/gradient while loading
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: double.infinity,
                          height: 110,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [e.gradA, e.gradB],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight)),
                          child: Center(child: Text(e.emoji,
                            style: const TextStyle(fontSize: 52))));
                      },
                      // Show emoji on network/decode error
                      errorBuilder: (_, __, ___) =>
                        Container(
                          width: double.infinity,
                          height: 110,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [e.gradA, e.gradB],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight)),
                          child: Center(child: Text(e.emoji,
                            style: const TextStyle(fontSize: 52)))),
                    ))
                else
                  Center(child: Text(e.emoji, style: const TextStyle(fontSize: 52))),

                // Past overlay
                if (isPastCard)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.30),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18))),
                    child: const Center(
                      child: Text('PAST EVENT', style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w900,
                        color: Colors.white, letterSpacing: 2)))),

                // Category badge
                Positioned(top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPastCard ? Colors.grey : e.catColor,
                      borderRadius: BorderRadius.circular(8)),
                    child: Text(e.category, style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: Colors.white)))),

                // Date badge
                Positioned(bottom: 8, right: 44,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(7)),
                    child: Text(e.date, style: const TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w800,
                      color: Colors.white)))),

                // Save button
                Positioned(top: 8, right: 8,
                  child: GestureDetector(
                    onTap: onSaveTap,
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: e.isSaved
                          ? Colors.red.withOpacity(0.85)
                          : Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle),
                      child: Center(child: Text(
                        e.isSaved ? '❤️' : '🤍',
                        style: const TextStyle(fontSize: 12)))))),
              ])),

            // Body
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.title, maxLines: 2,
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800,
                    color: isPastCard ? EBColors.text2 : EBColors.text,
                    height: 1.3)),
                const SizedBox(height: 3),
                Text('${e.location} · ${e.entry} · ${e.organiser}',
                  style: TextStyle(fontSize: 11, color: EBColors.text3)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      _MiniAvatarStack(),
                      const SizedBox(width: 6),
                      Text('+${e.attendingCount} attending',
                        style: TextStyle(fontSize: 11, color: EBColors.text3)),
                    ]),
                    if (!isPastCard)
                      EBRsvpButton(
                        going: e.isRsvped,
                        color: e.rsvpColor,
                        onTap: onRsvpTap)
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: EBColors.surface2,
                          borderRadius: BorderRadius.circular(8)),
                        child: Text('Ended', style: TextStyle(
                          fontSize: 11, color: EBColors.text3,
                          fontWeight: FontWeight.w600))),
                  ],
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MINI AVATAR STACK
// ─────────────────────────────────────────────────────────────
class _MiniAvatarStack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const avs = [
      ('SK', EBColors.brandLight),
      ('JM', EBColors.brandDark),
      ('AO', EBColors.blue),
    ];
    return SizedBox(width: 42, height: 20,
      child: Stack(children: List.generate(avs.length, (i) => Positioned(
        left: i * 14.0,
        child: Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: avs[i].$2,
            border: Border.all(color: Colors.white, width: 1.5)),
          child: Center(child: Text(avs[i].$1, style: const TextStyle(
            fontSize: 6, fontWeight: FontWeight.w800,
            color: Colors.white))))))));
  }
}

// ─────────────────────────────────────────────────────────────
//  EVENT DETAIL SCREEN
// ─────────────────────────────────────────────────────────────
class EBEventDetailScreen extends StatefulWidget {
  final String eventId;
  final EBEventModel? snapshot;

  const EBEventDetailScreen({
    super.key,
    required this.eventId,
    this.snapshot,
  });

  @override
  State<EBEventDetailScreen> createState() => _EBEventDetailScreenState();
}

class _EBEventDetailScreenState extends State<EBEventDetailScreen> {
  EBEventModel? _event;
  bool    _loading = true;
  String? _error;

  bool get _isPast => _event?.isPast ?? false;

  @override
  void initState() {
    super.initState();
    if (widget.snapshot != null) {
      _event   = widget.snapshot;
      _loading = false;
    }
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    if (_event == null && mounted) setState(() => _loading = true);

    try {
      final res = await ApiClient.get('/api/v1/events/${widget.eventId}/');
      dev.log('[Detail] GET /events/${widget.eventId}/ → ${res.statusCode}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          setState(() {
            _event   = EBEventModel.fromJson(decoded);
            _loading = false;
            _error   = null;
          });
        }
      } else {
        if (_event == null) {
          setState(() {
            _error   = 'Could not load event (${res.statusCode}).';
            _loading = false;
          });
        }
      }
    } catch (e, s) {
      dev.log('[Detail] error: $e', stackTrace: s);
      if (mounted && _event == null) {
        setState(() { _error = 'Network error.'; _loading = false; });
      }
    }
  }
Future<void> _toggleRsvp() async {
    if (_event == null || _isPast) return;
    final wasGoing = _event!.isRsvped;
    
    // Determine the new status based on current state
    final newStatus = wasGoing ? 'not_going' : 'going';  // 👈 Always lowercase
    
    dev.log('[Detail] Toggling RSVP: $wasGoing -> $newStatus');
    
    // Optimistic update
    setState(() => _event = _event!.copyWith(
      isRsvped: !wasGoing,
      attendingCount: _event!.attendingCount + (wasGoing ? -1 : 1)));

    try {
      // IMPORTANT: Use POST for BOTH actions (DELETE is NOT supported)
      final res = await ApiClient.post(
        '/api/v1/events/${widget.eventId}/rsvp/',
        body: {'status': newStatus},  // 👈 Must be "going" or "not_going"
      );

      dev.log('[Detail] RSVP Response: ${res.statusCode}');
      dev.log('[Detail] Response body: ${res.body}');

      final ok = res.statusCode == 200 || res.statusCode == 201;
      
      if (!ok) {
        // Parse the error to show user
        String errorMsg = 'Could not update RSVP.';
        if (res.statusCode == 400) {
          try {
            final errorBody = jsonDecode(res.body);
            errorMsg = errorBody['detail'] ?? errorBody['message'] ?? 'Invalid RSVP status';
          } catch (_) {}
        }
        
        // Rollback optimistic update
        setState(() => _event = _event!.copyWith(
          isRsvped: wasGoing,
          attendingCount: _event!.attendingCount + (wasGoing ? 1 : -1)));
        if (mounted) _snack(errorMsg);
      } else {
        // Parse success message
        String successMsg = !wasGoing ? "✅ You're going!" : 'RSVP cancelled';
        try {
          final responseBody = jsonDecode(res.body);
          if (responseBody['message'] != null) {
            successMsg = responseBody['message'];
          }
        } catch (_) {}
        
        if (mounted) _snack(successMsg, bg: _event?.rsvpColor);
      }
    } catch (e) {
      dev.log('[Detail] Network error: $e');
      // Rollback optimistic update
      setState(() => _event = _event!.copyWith(
        isRsvped: wasGoing,
        attendingCount: _event!.attendingCount + (wasGoing ? 1 : -1)));
      if (mounted) _snack('Network error. Please try again.');
    }
}

  Future<void> _toggleSave() async {
    if (_event == null) return;
    final wasSaved = _event!.isSaved;
    setState(() => _event = _event!.copyWith(isSaved: !wasSaved));

    try {
      final res = wasSaved
          ? await ApiClient.delete('/api/v1/events/${widget.eventId}/save/')
          : await ApiClient.post  ('/api/v1/events/${widget.eventId}/save/');

      dev.log('[Detail] Save → ${res.statusCode}');

      final ok = res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204;
      if (!ok) {
        setState(() => _event = _event!.copyWith(isSaved: wasSaved));
        if (mounted) _snack('Could not save event.');
      } else {
        if (mounted) _snack(wasSaved ? 'Event unsaved.' : '❤️ Event saved!');
      }
    } catch (_) {
      setState(() => _event = _event!.copyWith(isSaved: wasSaved));
      if (mounted) _snack('Network error. Please try again.');
    }
  }

  void _snack(String msg, {Color? bg}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: bg ?? EBColors.brand,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _event == null) {
      return Scaffold(
        backgroundColor: EBColors.surface2,
        appBar: AppBar(
          backgroundColor: EBColors.surface, elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: EBColors.text),
            onPressed: () => Navigator.pop(context)),
        ),
        body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: TextStyle(fontSize: 13, color: EBColors.text3)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _fetchDetail,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry')),
          ],
        )),
      );
    }

    final e = _event;

    return Scaffold(
      backgroundColor: EBColors.surface2,
      body: CustomScrollView(slivers: [

        // ── Hero header ──────────────────────────────────
        SliverAppBar(
          expandedHeight: 200,
          pinned: false,
          backgroundColor: Colors.transparent,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.88),
                borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: EBColors.text))),
          // ── CHANGE: only the save heart remains; reminder icon removed ──
          actions: [
            GestureDetector(
              onTap: _toggleSave,
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8, right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(11)),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    e?.isSaved == true ? '❤️' : '🤍',
                    style: const TextStyle(fontSize: 18))))),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: e == null
              ? Container(color: EBColors.brandPale,
                  child: const Center(child: CircularProgressIndicator()))
              : _DetailHero(event: e, isPast: _isPast),
          ),
        ),

        // ── Body ─────────────────────────────────────────
        SliverToBoxAdapter(
          child: e == null
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()))
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Past notice banner
                if (_isPast)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300)),
                    child: Row(children: [
                      const Text('📅', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        'This event has already ended.',
                        style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600))),
                    ])),

                // Date / location + RSVP
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.date, style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: EBColors.text)),
                        Text(e.location, style: TextStyle(
                          fontSize: 12, color: EBColors.text3)),
                      ]),
                      if (!_isPast)
                        GestureDetector(
                          onTap: _toggleRsvp,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 11),
                            decoration: BoxDecoration(
                              color: e.isRsvped ? EBColors.green : e.rsvpColor,
                              borderRadius: BorderRadius.circular(12)),
                            child: Text(e.isRsvped ? '✅ Going' : 'RSVP →',
                              style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w800,
                                color: Colors.white))))
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: EBColors.surface2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: EBColors.border)),
                          child: Text('Ended', style: TextStyle(
                            fontSize: 13, color: EBColors.text3,
                            fontWeight: FontWeight.w700))),
                    ])),

                const SizedBox(height: 14),
                EBFormField(label: 'Organised by', value: e.organiser),
                EBFormField(label: 'Attending',
                  value: '${e.attendingCount} people confirmed'),
                EBFormField(label: 'Entry', value: e.entry),
                EBFormField(label: 'Mode', value: e.mode),
                EBFormField(label: 'About',
                  value: e.description.isNotEmpty
                    ? e.description
                    : 'No description provided.',
                  multiline: true),

                EBSectionLabel(title: "Who's Going"),
                _AttendeeList(count: e.attendingCount),
                const SizedBox(height: 40),
              ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DETAIL HERO
// ─────────────────────────────────────────────────────────────
class _DetailHero extends StatelessWidget {
  final EBEventModel event;
  final bool isPast;
  const _DetailHero({required this.event, required this.isPast});

  @override
  Widget build(BuildContext context) {
    final e = event;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPast
            ? [Colors.grey.shade300, Colors.grey.shade500]
            : [e.gradA, e.gradB],
          begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Stack(children: [
        // Banner image with loading + error fallback
        if (e.bannerUrl != null)
          Positioned.fill(
            child: Image.network(
              e.bannerUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                // Show gradient + emoji while loading
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPast
                        ? [Colors.grey.shade300, Colors.grey.shade500]
                        : [e.gradA, e.gradB],
                      begin: Alignment.topLeft, end: Alignment.bottomRight)),
                  child: Center(child: Text(e.emoji,
                    style: const TextStyle(fontSize: 80))));
              },
              errorBuilder: (_, __, ___) =>
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPast
                        ? [Colors.grey.shade300, Colors.grey.shade500]
                        : [e.gradA, e.gradB],
                      begin: Alignment.topLeft, end: Alignment.bottomRight)),
                  child: Center(child: Text(e.emoji,
                    style: const TextStyle(fontSize: 80)))),
            ))
        else
          Center(child: Text(e.emoji, style: const TextStyle(fontSize: 80))),

        Positioned(bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 30, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPast ? Colors.grey : e.catColor,
                      borderRadius: BorderRadius.circular(8)),
                    child: Text(e.category, style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white))),
                  if (isPast) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8)),
                      child: const Text('PAST', style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: 1))),
                  ],
                ]),
                const SizedBox(height: 6),
                Text(e.title, style: const TextStyle(
                  fontSize: 18, fontStyle: FontStyle.italic,
                  color: Colors.white, height: 1.3)),
              ],
            ),
          )),
      ]));
  }
}

// ─────────────────────────────────────────────────────────────
//  ATTENDEE LIST  (decorative)
// ─────────────────────────────────────────────────────────────
class _AttendeeList extends StatelessWidget {
  final int count;
  const _AttendeeList({required this.count});

  @override
  Widget build(BuildContext context) {
    const attendees = [
      ('👩‍💻', 'Sarah K.',  'BSc CS',       EBColors.brandLight),
      ('👨‍🔬', 'James M.',  'BSc Mech Eng', EBColors.blue),
      ('👩‍🎓', 'Aisha O.',  'BSc Civil',    EBColors.pink),
      ('👨‍🏫', 'David L.',  'BA Econ',      EBColors.coral),
    ];
    final remainder = count > 4 ? count - 4 : 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: EBTheme.cardSm,
      child: Column(children: [
        ...attendees.map<Widget>((a) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [a.$4, a.$4.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(11)),
              child: Center(child: Text(a.$1, style: const TextStyle(fontSize: 16)))),
            const SizedBox(width: 10),
            Expanded(child: Text(a.$2, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: EBColors.text))),
            Text(a.$3, style: TextStyle(fontSize: 11, color: EBColors.text3)),
            const SizedBox(width: 8),
            Text('✓', style: TextStyle(fontSize: 16, color: EBColors.green)),
          ])),
        ),
        if (remainder > 0)
          Padding(
            padding: const EdgeInsets.all(9),
            child: Center(child: Text('+ $remainder more attendees',
              style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w700, color: EBColors.brand)))),
      ]),
    );
  }
}