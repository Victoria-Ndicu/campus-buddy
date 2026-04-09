import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/eb_constants.dart';
import '../widgets/eb_widgets.dart';
import '../../../core/api_client.dart';
import 'eb_discovery_screen.dart';
import 'eb_calendar_screen.dart';
import 'eb_rsvp_screen.dart';
import 'eb_create_event.dart';

// ─────────────────────────────────────────────────────────────
//  API ENDPOINTS
//  GET  /api/v1/events/               → list all events
//  POST /api/v1/events/<uuid>/rsvp/   → { status: "going"|"not_going" }
//  POST /api/v1/events/<uuid>/save/   → save event
//  DELETE /api/v1/events/<uuid>/save/ → unsave event
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
//  DATE HELPER  (mirrors EBDiscoveryScreen's _DateHelper exactly)
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
      return iso ?? '';
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

  /// Returns true if the event's endAt (or startAt) is in the past.
  /// Identical to _DateHelper.isPast() in EBDiscoveryScreen.
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
//  EVENT MODEL
// ─────────────────────────────────────────────────────────────
class EBEvent {
  final String  id;
  final String  title;
  final String  category;
  final String  date;
  final String  location;
  final String  emoji;
  final String? startAt;
  final String? endAt;
  final int     attendingCount;
  final bool    isRsvped;
  final bool    isSaved;
  // Computed once at parse time using the same logic as EBDiscoveryScreen
  final bool    isPast;

  const EBEvent({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.location,
    this.emoji          = '🎉',
    this.startAt,
    this.endAt,
    this.attendingCount = 0,
    this.isRsvped       = false,
    this.isSaved        = false,
    this.isPast         = false,
  });

  /// Inverse of isPast — mirrors discovery screen's split logic
  bool get isUpcoming => !isPast;

  factory EBEvent.fromJson(Map<String, dynamic> j) {
    final userRsvp = j['userRsvp']?.toString() ?? j['user_rsvp']?.toString();
    final isRsvped = userRsvp == 'going' || userRsvp == 'waitlist'
        || (j['isRsvped'] as bool? ?? false);

    final attending = (j['rsvpCount']      as num?)?.toInt()
        ?? (j['rsvp_count']     as num?)?.toInt()
        ?? (j['attendingCount'] as num?)?.toInt()
        ?? 0;

    final startAtRaw = j['startAt']?.toString() ?? j['start_at']?.toString();
    final endAtRaw   = j['endAt']?.toString()   ?? j['end_at']?.toString();

    // Build display date the same way the discovery screen does
    String dateDisplay = j['date']?.toString() ?? '';
    if (dateDisplay.isEmpty) {
      dateDisplay = _DateHelper.formatRange(startAtRaw, endAtRaw);
    }

    // Use the same isPast logic as EBDiscoveryScreen:
    // prefer endAt, fall back to startAt
    final past = _DateHelper.isPast(
      endAtRaw?.isNotEmpty   == true ? endAtRaw   : null,
      startAtRaw?.isNotEmpty == true ? startAtRaw : null,
    );

    return EBEvent(
      id:             j['id']?.toString()       ?? '',
      title:          j['title']?.toString()    ?? '',
      category:       j['category']?.toString() ?? '',
      date:           dateDisplay,
      location:       j['location']?.toString() ?? '',
      emoji:          j['emoji']?.toString()    ?? '🎉',
      startAt:        startAtRaw,
      endAt:          endAtRaw,
      attendingCount: attending,
      isRsvped:       isRsvped,
      isSaved:        j['isSaved'] as bool?     ?? false,
      isPast:         past,
    );
  }

  EBEvent copyWith({bool? isRsvped, bool? isSaved, int? attendingCount}) =>
      EBEvent(
        id:             id,
        title:          title,
        category:       category,
        date:           date,
        location:       location,
        emoji:          emoji,
        startAt:        startAt,
        endAt:          endAt,
        attendingCount: attendingCount ?? this.attendingCount,
        isRsvped:       isRsvped       ?? this.isRsvped,
        isSaved:        isSaved        ?? this.isSaved,
        isPast:         isPast,
      );
}

// ─────────────────────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────────────────────
class EventBoardHome extends StatefulWidget {
  const EventBoardHome({super.key});

  @override
  State<EventBoardHome> createState() => _EventBoardHomeState();
}

class _EventBoardHomeState extends State<EventBoardHome> {
  List<EBEvent> _events      = [];
  bool          _loading     = true;
  String?       _error;
  int           _navSelected = 0;

  // Mirrors discovery screen: upcoming sorted ascending by startAt,
  // past sorted descending by startAt
  List<EBEvent> get _upcoming =>
      (_events.where((e) => e.isUpcoming).toList()
        ..sort((a, b) => (a.startAt ?? '').compareTo(b.startAt ?? '')));

  List<EBEvent> get _past =>
      (_events.where((e) => e.isPast).toList()
        ..sort((a, b) => (b.startAt ?? '').compareTo(a.startAt ?? '')));

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  // ─────────────────────────────────────────────────────────
  //  GET /api/v1/events/
  // ─────────────────────────────────────────────────────────
  Future<void> _loadEvents() async {
    if (mounted) setState(() { _loading = true; _error = null; });

    try {
      final res = await ApiClient.get('/api/v1/events/');
      dev.log('[Home] GET /events → ${res.statusCode}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        // Support all three response shapes used across the app
        final raw = decoded is List
            ? decoded
            : (decoded['results'] as List?)
                ?? (decoded['data']    as List?)
                ?? [];

        final events = (raw as List)
            .whereType<Map<String, dynamic>>()
            .map(EBEvent.fromJson)
            .toList();

        setState(() { _events = events; _loading = false; });
      } else {
        setState(() {
          _error   = 'Could not load events (${res.statusCode}).';
          _loading = false;
        });
      }
    } catch (e, s) {
      dev.log('[Home] error: $e', stackTrace: s);
      if (mounted) setState(() {
        _error   = 'Network error. Pull to refresh.';
        _loading = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────
  //  POST /api/v1/events/<uuid>/rsvp/
  // ─────────────────────────────────────────────────────────
  Future<void> _toggleRsvp(EBEvent event) async {
    final wasGoing = event.isRsvped;
    _mutate(event.id, isRsvped: !wasGoing, attendingDelta: wasGoing ? -1 : 1);

    try {
      final res = await ApiClient.post(
        '/api/v1/events/${event.id}/rsvp/',
        body: {'status': wasGoing ? 'not_going' : 'going'},
      );
      dev.log('[Home] RSVP ${event.id} → ${res.statusCode}');

      final ok = res.statusCode == 200 || res.statusCode == 201;
      if (!ok) {
        _mutate(event.id, isRsvped: wasGoing, attendingDelta: wasGoing ? 1 : -1);
        _snack('Could not update RSVP. Please try again.');
      } else {
        _snack(wasGoing ? 'RSVP cancelled' : "✅ You're going to ${event.title}!");
      }
    } catch (_) {
      _mutate(event.id, isRsvped: wasGoing, attendingDelta: wasGoing ? 1 : -1);
      _snack('Network error. Please try again.');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  POST/DELETE /api/v1/events/<uuid>/save/
  // ─────────────────────────────────────────────────────────
  Future<void> _toggleSave(EBEvent event) async {
    final wasSaved = event.isSaved;
    _mutate(event.id, isSaved: !wasSaved);

    try {
      final res = wasSaved
          ? await ApiClient.delete('/api/v1/events/${event.id}/save/')
          : await ApiClient.post  ('/api/v1/events/${event.id}/save/');
      dev.log('[Home] Save ${event.id} → ${res.statusCode}');

      final ok = res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204;
      if (!ok) {
        _mutate(event.id, isSaved: wasSaved);
        _snack('Could not save event.');
      } else {
        _snack(wasSaved ? 'Event unsaved.' : '❤️ Event saved!');
      }
    } catch (_) {
      _mutate(event.id, isSaved: wasSaved);
      _snack('Network error. Please try again.');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────────────────
  void _mutate(String id, {bool? isRsvped, bool? isSaved, int attendingDelta = 0}) {
    if (!mounted) return;
    setState(() {
      _events = _events.map((e) => e.id == id
          ? e.copyWith(
              isRsvped:       isRsvped,
              isSaved:        isSaved,
              attendingCount: e.attendingCount + attendingDelta)
          : e).toList();
    });
  }

  void _snack(String msg, {Color? bg}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content:         Text(msg),
        backgroundColor: bg ?? EBColors.brand,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  void _openCreateEvent() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EBCreateEventScreen()),
    ).then((_) => _loadEvents());
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  List<_Stat> get _stats => [
    _Stat('🗓', '${_upcoming.length}',                               'Upcoming'),
    _Stat('✅', '${_events.where((e) => e.isRsvped).length}',        'My RSVPs'),
    _Stat('❤️', '${_events.where((e) => e.isSaved).length}',         'Saved'),
    _Stat('🏷',  '${_events.map((e) => e.category).toSet().length}', 'Categories'),
  ];

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final modules = [
      _Mod(
        emoji:    '🗓',
        title:    'Browse Events',
        subtitle: _loading ? 'Loading…' : '${_upcoming.length} upcoming · ${_past.length} past',
        colorA: EBColors.brand,
        colorB: EBColors.brandDark,
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(context,
            MaterialPageRoute(builder: (_) => const EBDiscoveryScreen()),
          ).then((_) => _loadEvents());
        },
      ),
      _Mod(
        emoji:    '📅',
        title:    'Event Calendar',
        subtitle: 'View by date',
        colorA: EBColors.blue,
        colorB: const Color(0xFF4A5FCC),
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(context,
            MaterialPageRoute(builder: (_) => const EBCalendarScreen()));
        },
      ),
      _Mod(
        emoji:    '🎟',
        title:    'My RSVPs',
        subtitle: _loading
            ? 'Loading…'
            : '${_events.where((e) => e.isRsvped).length} confirmed',
        colorA: EBColors.green,
        colorB: const Color(0xFF059669),
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(context,
            MaterialPageRoute(builder: (_) => const EBRsvpScreen(eventId: '')));
        },
      ),
      _Mod(
        emoji:    '🎉',
        title:    'Create Event',
        subtitle: 'Host something new',
        colorA: EBColors.amber,
        colorB: const Color(0xFFD97706),
        onTap:  _openCreateEvent,
      ),
    ];

    return Scaffold(
      backgroundColor: EBColors.surface2,

      appBar: AppBar(
        backgroundColor: EBColors.surface,
        elevation:       0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: EBColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EventBoard', style: TextStyle(
              fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w900,
              color: EBColors.brandDark, fontStyle: FontStyle.italic)),
            Text(
              _loading
                  ? 'Loading events…'
                  : '${_upcoming.length} upcoming · ${_past.length} past',
              style: TextStyle(fontSize: 11, color: EBColors.text3)),
          ],
        ),
        titleSpacing: 0,
        actions: [
          IconButton(
            tooltip:   'Refresh',
            onPressed: _loading ? null : _loadEvents,
            icon: _loading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: EBColors.brand))
                : const Icon(Icons.refresh_rounded, color: EBColors.brand, size: 22),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: EBColors.border, height: 1)),
      ),

      body: RefreshIndicator(
        color:     EBColors.brand,
        onRefresh: _loadEvents,
        child: CustomScrollView(slivers: [

          // ── Hero card ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin:  const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [EBColors.brand, EBColors.brandDark],
                  begin:  Alignment.topLeft,
                  end:    Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Good ${_greeting()} 👋',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.70))),
                          const SizedBox(height: 3),
                          const Text("What's happening\non campus?",
                            style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w900,
                              color: Colors.white, height: 1.25)),
                        ]),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14)),
                        child: const Text('🎓',
                          style: TextStyle(fontSize: 22))),
                    ]),

                  const SizedBox(height: 14),

                  _loading
                    ? const SizedBox(
                        height: 40,
                        child: Center(child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)))
                    : Row(
                        children: _stats.map<Widget>((s) => Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(s.value, style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w900,
                                color: Colors.white)),
                              const SizedBox(height: 2),
                              Text(s.label, style: TextStyle(
                                fontSize: 9,
                                color: Colors.white.withOpacity(0.65))),
                            ]))).toList()),
                ]),
            )),

          // ── Section label ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('What do you want to do?',
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800,
                      color: EBColors.text)),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const EBDiscoveryScreen()))
                        .then((_) => _loadEvents()),
                    child: Text('Browse all →',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: EBColors.brand))),
                ]))),

          // ── Module grid ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: GridView.count(
                crossAxisCount:   2,
                shrinkWrap:       true,
                physics:          const NeverScrollableScrollPhysics(),
                mainAxisSpacing:  12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: modules.map(_ModuleCard.fromMod).toList()))),

          // ── Upcoming preview ──────────────────────────────
          if (!_loading && _upcoming.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Upcoming Events',
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        color: EBColors.text)),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (_) => const EBDiscoveryScreen()))
                            .then((_) => _loadEvents()),
                      child: Text('See all →',
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: EBColors.brand))),
                  ]))),

            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final ev = _upcoming.take(3).toList()[i];
                  return _UpcomingEventRow(
                    event:      ev,
                    onRsvpTap:  () => _toggleRsvp(ev),
                    onSaveTap:  () => _toggleSave(ev),
                  );
                },
                childCount: _upcoming.take(3).length,
              )),
          ],

          // ── Error state ───────────────────────────────────
          if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Text(_error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: EBColors.text3)),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _loadEvents,
                    icon:  const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry')),
                ]))),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ]),
      ),

      // ── Bottom Nav ────────────────────────────────────────
      bottomNavigationBar: _BottomNav(
        selected: _navSelected,
        onTap: (i) {
          setState(() => _navSelected = i);
          switch (i) {
            case 1:
              Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EBCalendarScreen()));
              break;
            case 2:
              Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EBRsvpScreen(eventId: '')));
              break;
            case 3:
              _openCreateEvent();
              break;
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  UPCOMING EVENT ROW
// ─────────────────────────────────────────────────────────────
class _UpcomingEventRow extends StatelessWidget {
  final EBEvent      event;
  final VoidCallback onRsvpTap;
  final VoidCallback onSaveTap;

  const _UpcomingEventRow({
    required this.event,
    required this.onRsvpTap,
    required this.onSaveTap,
  });

  Color get _catColor {
    final c = event.category.toLowerCase();
    if (c.contains('academic') || c.contains('tech')) return EBColors.blue;
    if (c.contains('sport'))                          return EBColors.green;
    if (c.contains('career'))                         return EBColors.amber;
    return EBColors.brand;
  }

  Color get _catBg {
    final c = event.category.toLowerCase();
    if (c.contains('academic') || c.contains('tech')) return const Color(0xFFE3EEFF);
    if (c.contains('sport'))                          return const Color(0xFFE3FAF0);
    if (c.contains('career'))                         return const Color(0xFFFFF3E0);
    return EBColors.brandPale;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EBColors.border)),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _catBg,
              borderRadius: BorderRadius.circular(11)),
            child: Center(child: Text(
              event.emoji.isNotEmpty ? event.emoji : '🎉',
              style: const TextStyle(fontSize: 20)))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800,
                    color: EBColors.text)),
                const SizedBox(height: 2),
                Text(
                  '${event.date}${event.location.isNotEmpty ? " · ${event.location}" : ""}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: EBColors.text3)),
              ])),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: _catBg,
              borderRadius: BorderRadius.circular(7)),
            child: Text(
              event.category.isNotEmpty ? event.category : 'Event',
              style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w800,
                color: _catColor))),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRsvpTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: event.isRsvped ? EBColors.green : EBColors.brand,
                borderRadius: BorderRadius.circular(9)),
              child: Text(
                event.isRsvped ? '✅' : 'RSVP',
                style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w800,
                  color: Colors.white)))),
        ]));
  }
}

// ─────────────────────────────────────────────────────────────
//  DATA HELPERS
// ─────────────────────────────────────────────────────────────
class _Stat {
  final String emoji, value, label;
  const _Stat(this.emoji, this.value, this.label);
}

class _Mod {
  final String       emoji, title, subtitle;
  final Color        colorA, colorB;
  final VoidCallback onTap;
  const _Mod({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.colorA,
    required this.colorB,
    required this.onTap,
  });
}

// ─────────────────────────────────────────────────────────────
//  MODULE CARD
// ─────────────────────────────────────────────────────────────
class _ModuleCard extends StatelessWidget {
  final _Mod mod;
  const _ModuleCard(this.mod, {super.key});
  static _ModuleCard fromMod(_Mod m) => _ModuleCard(m);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:       mod.onTap,
          splashColor: Colors.white.withOpacity(0.15),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [mod.colorA, mod.colorB],
                begin:  Alignment.topLeft,
                end:    Alignment.bottomRight)),
            child: Stack(children: [
              Positioned(
                top: -18, right: -18,
                child: Container(
                  width: 76, height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.10)))),
              Positioned(
                top: 0, right: 0,
                child: Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color:        Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(8)),
                  child: const Center(child: Text('›', style: TextStyle(
                    fontSize: 18, color: Colors.white,
                    fontWeight: FontWeight.w900))))),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:  MainAxisAlignment.end,
                children: [
                  Text(mod.emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(height: 6),
                  Text(mod.title, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w900,
                    color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(mod.subtitle, style: TextStyle(
                    fontSize: 10, color: Colors.white.withOpacity(0.75))),
                ]),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BOTTOM NAV
// ─────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int               selected;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.selected, required this.onTap});

  static const _items = [
    ('🗓', 'Events'),
    ('📅', 'Calendar'),
    ('🎟', 'My RSVPs'),
    ('🎉', 'Create'),
    ('👤', 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12, offset: const Offset(0, -3))],
        border: Border(top: BorderSide(color: EBColors.border))),
      padding: EdgeInsets.only(
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final active = i == selected;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onTap(i); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? EBColors.brand.withOpacity(0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_items[i].$1, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 3),
                  Text(_items[i].$2, style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: active ? EBColors.brand : EBColors.text3)),
                ])));
        })));
  }
}