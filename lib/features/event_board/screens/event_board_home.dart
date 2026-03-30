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
import 'eb_reminders_screen.dart';

// ─────────────────────────────────────────────────────────────
//  BASE URL prefix for all event endpoints
//  urls.py: path("api/v1/events/", include("events.urls"))
// ─────────────────────────────────────────────────────────────
//
//  GET    /api/v1/events/                  → list all events
//  GET    /api/v1/events/<uuid>/           → event detail
//  POST   /api/v1/events/uploads/banner/   → upload banner image
//  POST   /api/v1/events/<uuid>/rsvp/      → RSVP to event
//  DELETE /api/v1/events/<uuid>/rsvp/      → cancel RSVP
//  GET    /api/v1/events/reminders/        → list reminders
//  POST   /api/v1/events/reminders/        → create reminder
//  POST   /api/v1/events/<uuid>/save/      → save event
//  DELETE /api/v1/events/<uuid>/save/      → unsave event
//  POST   /api/v1/events/<uuid>/broadcast/ → broadcast event

// ─────────────────────────────────────────────────────────────
//  EVENT MODEL
// ─────────────────────────────────────────────────────────────
class EBEvent {
  final String id;
  final String title;
  final String category;
  final String date;
  final String location;
  final String emoji;
  final int attendingCount;
  final bool isRsvped;
  final bool isSaved;

  const EBEvent({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.location,
    this.emoji          = '🎉',
    this.attendingCount = 0,
    this.isRsvped       = false,
    this.isSaved        = false,
  });

  factory EBEvent.fromJson(Map<String, dynamic> j) => EBEvent(
    id:             j['id']?.toString()             ?? '',
    title:          j['title']?.toString()          ?? '',
    category:       j['category']?.toString()       ?? '',
    date:           j['date']?.toString()           ?? '',
    location:       j['location']?.toString()       ?? '',
    emoji:          j['emoji']?.toString()          ?? '🎉',
    attendingCount: (j['attendingCount'] as num?)?.toInt() ?? 0,
    isRsvped:       j['isRsvped']  as bool?         ?? false,
    isSaved:        j['isSaved']   as bool?         ?? false,
  );
}

// ─────────────────────────────────────────────────────────────
//  REMINDER MODEL
// ─────────────────────────────────────────────────────────────
class EBReminder {
  final String id;
  final String eventId;
  final String reminderTime;

  const EBReminder({
    required this.id,
    required this.eventId,
    required this.reminderTime,
  });

  factory EBReminder.fromJson(Map<String, dynamic> j) => EBReminder(
    id:           j['id']?.toString()           ?? '',
    eventId:      j['eventId']?.toString()      ?? '',
    reminderTime: j['reminderTime']?.toString() ?? '',
  );
}

// ─────────────────────────────────────────────────────────────
//  EventBoardHome
// ─────────────────────────────────────────────────────────────
class EventBoardHome extends StatefulWidget {
  const EventBoardHome({super.key});
  @override
  State<EventBoardHome> createState() => _EventBoardHomeState();
}

class _EventBoardHomeState extends State<EventBoardHome> {
  // ── State ─────────────────────────────────────────────────
  List<EBEvent>    _events       = [];
  List<EBReminder> _reminders    = [];
  bool             _loadingEvents    = true;
  bool             _loadingReminders = true;
  String?          _eventsError;

  // Featured event RSVP is derived from _events once loaded;
  // used before load as an optimistic toggle placeholder.
  bool _featuredGoing = false;
  int  _navSelected   = 0;

  // ── Convenience getters ───────────────────────────────────
  EBEvent? get _featured =>
      _events.isNotEmpty ? _events.first : null;

  List<EBEvent> get _upcoming =>
      _events.length > 1 ? _events.sublist(1) : [];

  // ─────────────────────────────────────────────────────────
  //  LIFECYCLE
  // ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadEvents();
    _loadReminders();
  }

  // ─────────────────────────────────────────────────────────
  //  READ: GET /api/v1/events/
  // ─────────────────────────────────────────────────────────
  Future<void> _loadEvents() async {
    if (mounted) setState(() { _loadingEvents = true; _eventsError = null; });
    try {
      final res = await ApiClient.get('/api/v1/events/');
      dev.log('[EventBoard] GET /events → ${res.statusCode}');
      dev.log('[EventBoard] body: ${res.body}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        // Accept both a bare list and a {results: [...]} paginated wrapper
        final raw = decoded is List
            ? decoded
            : (decoded['results'] as List?) ?? [];

        final events = raw
            .whereType<Map<String, dynamic>>()
            .map(EBEvent.fromJson)
            .toList();

        setState(() {
          _events        = events;
          _loadingEvents = false;
          // Sync featured going state with server value
          if (events.isNotEmpty) _featuredGoing = events.first.isRsvped;
        });
      } else {
        setState(() {
          _eventsError  = 'Could not load events (${res.statusCode}).';
          _loadingEvents = false;
        });
      }
    } catch (e, s) {
      dev.log('[EventBoard] _loadEvents error: $e', stackTrace: s);
      if (mounted) {
        setState(() {
          _eventsError  = 'Network error. Pull to refresh.';
          _loadingEvents = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  //  READ: GET /api/v1/events/reminders/
  // ─────────────────────────────────────────────────────────
  Future<void> _loadReminders() async {
    if (mounted) setState(() => _loadingReminders = true);
    try {
      final res = await ApiClient.get('/api/v1/events/reminders/');
      dev.log('[EventBoard] GET /reminders → ${res.statusCode}');

      if (!mounted) return;
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final raw = decoded is List
            ? decoded
            : (decoded['results'] as List?) ?? [];

        setState(() {
          _reminders        = raw
              .whereType<Map<String, dynamic>>()
              .map(EBReminder.fromJson)
              .toList();
          _loadingReminders = false;
        });
      } else {
        setState(() => _loadingReminders = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingReminders = false);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  UPDATE: RSVP toggle
  //  POST   /api/v1/events/<uuid>/rsvp/   → RSVP
  //  DELETE /api/v1/events/<uuid>/rsvp/   → cancel
  // ─────────────────────────────────────────────────────────
  Future<void> _toggleRsvp(EBEvent event) async {
    // Optimistic update
    final wasGoing = event.isRsvped;
    _updateEventInList(event.id, isRsvped: !wasGoing,
        attendingDelta: wasGoing ? -1 : 1);

    // Special case: featured event toggle state
    if (_featured?.id == event.id) {
      setState(() => _featuredGoing = !wasGoing);
    }

    try {
      final res = wasGoing
          ? await ApiClient.delete('/api/v1/events/${event.id}/rsvp/')
          : await ApiClient.post('/api/v1/events/${event.id}/rsvp/');

      dev.log('[EventBoard] RSVP ${event.id} → ${res.statusCode}');

      if (res.statusCode != 200 && res.statusCode != 201 &&
          res.statusCode != 204) {
        // Revert on failure
        _updateEventInList(event.id, isRsvped: wasGoing,
            attendingDelta: wasGoing ? 1 : -1);
        if (_featured?.id == event.id) {
          setState(() => _featuredGoing = wasGoing);
        }
        if (mounted) _snack('Could not update RSVP. Please try again.');
      } else {
        if (mounted) {
          _snack(!wasGoing
              ? "✅ You're going to ${event.title}!"
              : 'RSVP cancelled');
        }
      }
    } catch (_) {
      // Revert on network error
      _updateEventInList(event.id, isRsvped: wasGoing,
          attendingDelta: wasGoing ? 1 : -1);
      if (_featured?.id == event.id) setState(() => _featuredGoing = wasGoing);
      if (mounted) _snack('Network error. Please try again.');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  UPDATE: Save / unsave toggle
  //  POST   /api/v1/events/<uuid>/save/
  //  DELETE /api/v1/events/<uuid>/save/
  // ─────────────────────────────────────────────────────────
  Future<void> _toggleSave(EBEvent event) async {
    final wasSaved = event.isSaved;
    _updateEventInList(event.id, isSaved: !wasSaved);

    try {
      final res = wasSaved
          ? await ApiClient.delete('/api/v1/events/${event.id}/save/')
          : await ApiClient.post('/api/v1/events/${event.id}/save/');

      dev.log('[EventBoard] Save ${event.id} → ${res.statusCode}');

      if (res.statusCode != 200 && res.statusCode != 201 &&
          res.statusCode != 204) {
        _updateEventInList(event.id, isSaved: wasSaved);
        if (mounted) _snack('Could not save event. Please try again.');
      } else {
        if (mounted) _snack(wasSaved ? 'Event unsaved.' : '🤍 Event saved!');
      }
    } catch (_) {
      _updateEventInList(event.id, isSaved: wasSaved);
      if (mounted) _snack('Network error. Please try again.');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  CREATE: Add a reminder
  //  POST /api/v1/events/reminders/
  // ─────────────────────────────────────────────────────────
  Future<void> _addReminder(String eventId, String reminderTime) async {
    try {
      final res = await ApiClient.post('/api/v1/events/reminders/', body: {
        'eventId':      eventId,
        'reminderTime': reminderTime,
      });
      dev.log('[EventBoard] POST /reminders → ${res.statusCode}');
      if (res.statusCode == 201 || res.statusCode == 200) {
        await _loadReminders(); // refresh reminder count
        if (mounted) _snack('🔔 Reminder set!');
      } else {
        if (mounted) _snack('Could not set reminder.');
      }
    } catch (_) {
      if (mounted) _snack('Network error. Please try again.');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  Helper: mutate a single event in the list immutably
  // ─────────────────────────────────────────────────────────
  void _updateEventInList(String id, {bool? isRsvped, bool? isSaved, int attendingDelta = 0}) {
    if (!mounted) return;
    setState(() {
      _events = _events.map((e) {
        if (e.id != id) return e;
        return EBEvent(
          id:             e.id,
          title:          e.title,
          category:       e.category,
          date:           e.date,
          location:       e.location,
          emoji:          e.emoji,
          attendingCount: e.attendingCount + attendingDelta,
          isRsvped:       isRsvped ?? e.isRsvped,
          isSaved:        isSaved  ?? e.isSaved,
        );
      }).toList();
    });
  }

  void _snack(String msg, {Color? bg}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: bg ?? EBColors.brand,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      ));
  }

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────

  // Derive stats from live data
  List<_Stat> get _stats => [
    _Stat('🗓', '${_events.length}',    'Upcoming'),
    _Stat('✅', '${_events.where((e) => e.isRsvped).length}', 'My RSVPs'),
    _Stat('🔔', '${_reminders.length}', 'Reminders'),
    _Stat('🏷', '${_events.map((e) => e.category).toSet().length}', 'Categories'),
  ];

  @override
  Widget build(BuildContext context) {
    final modules = [
      _Mod('🗓', 'Browse Events',  '${_events.length} upcoming events',
          EBColors.brand, EBColors.brandDark, const EBDiscoveryScreen()),
      _Mod('📅', 'Event Calendar', 'Feb 2026',
          EBColors.blue, const Color(0xFF4A5FCC), const EBCalendarScreen()),
      _Mod('🎟', 'My RSVPs', '${_events.where((e) => e.isRsvped).length} confirmed',
          EBColors.green, const Color(0xFF059669), const EBRsvpScreen()),
      _Mod('🔔', 'Reminders', '${_reminders.length} upcoming',
          EBColors.amber, const Color(0xFFD97706), const EBRemindersScreen()),
    ];

    return Scaffold(
      backgroundColor: EBColors.surface2,
      body: RefreshIndicator(
        color: EBColors.brand,
        onRefresh: () async {
          await Future.wait([_loadEvents(), _loadReminders()]);
        },
        child: CustomScrollView(slivers: [

          // ── App Bar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: EBColors.brandDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [EBColors.brand, EBColors.brandDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(children: [
                  Positioned(top: -40, right: -30,
                    child: Container(width: 160, height: 160,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08)))),
                  Positioned(bottom: 20, left: 16, right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('EventBoard', style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w900,
                          color: Colors.white, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text(
                          _loadingEvents
                            ? 'Loading events…'
                            : 'University of Nairobi · ${_events.length} upcoming events',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.75))),
                        const SizedBox(height: 14),
                        // Live stat row
                        Row(
                          children: _stats.map<Widget>((s) =>
                            Expanded(child: Column(children: [
                              _loadingEvents
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                                : Text(s.value, style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white)),
                              Text(s.label, style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.65))),
                            ]))).toList(),
                        ),
                      ],
                    )),
                ]),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.notifications_none,
                  color: Colors.white.withOpacity(0.9)),
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute(
                    builder: (_) => const EBRemindersScreen())),
              ),
              const SizedBox(width: 4),
            ],
          ),

          // ── Module grid ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: GridView.count(
                crossAxisCount: 2, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12, crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: modules.map<Widget>((m) => _ModuleCard(
                  emoji: m.emoji, title: m.title, subtitle: m.subtitle,
                  colorA: m.colorA, colorB: m.colorB,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(context,
                      MaterialPageRoute(builder: (_) => m.screen));
                  },
                )).toList(),
              ),
            ),
          ),

          // ── Loading / error state ────────────────────────
          if (_loadingEvents)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_eventsError != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Text(_eventsError!, textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13, color: EBColors.text3)),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _loadEvents,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                  ),
                ]),
              ),
            )
          else ...[

            // ── Featured event ─────────────────────────────
            if (_featured != null)
              SliverToBoxAdapter(
                child: _FeaturedEventCard(
                  event: _featured!,
                  going: _featuredGoing,
                  // POST /api/v1/events/<uuid>/rsvp/
                  onRsvpTap: () => _toggleRsvp(_featured!),
                  // POST /api/v1/events/<uuid>/save/
                  onSaveTap: () => _toggleSave(_featured!),
                ),
              ),

            // ── Upcoming events ────────────────────────────
            SliverToBoxAdapter(
              child: EBSectionLabel(
                title: '🎉 Upcoming Events',
                action: 'See all →',
                onAction: () => Navigator.push(context,
                  MaterialPageRoute(
                    builder: (_) => const EBDiscoveryScreen())),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  if (i == _upcoming.length) {
                    return const SizedBox(height: 100);
                  }
                  final ev = _upcoming[i];
                  return _UpcomingEventCard(
                    event: ev,
                    // GET /api/v1/events/<uuid>/ (detail opens RSVP screen)
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                        builder: (_) => EBRsvpScreen(eventId: ev.id))),
                    // POST/DELETE /api/v1/events/<uuid>/rsvp/
                    onRsvpTap: () => _toggleRsvp(ev),
                    // POST/DELETE /api/v1/events/<uuid>/save/
                    onSaveTap: () => _toggleSave(ev),
                  );
                },
                childCount: _upcoming.length + 1,
              ),
            ),
          ],
        ]),
      ),

      // ── FAB — opens create (banner upload is inside create screen) ──
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: EBColors.brand,
        foregroundColor: Colors.white,
        icon: const Text('🎉', style: TextStyle(fontSize: 18)),
        label: const Text('Create Event',
          style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const EBCreateEventScreen())),
      ),

      // ── Bottom Nav ──────────────────────────────────────
      bottomNavigationBar: _EBBottomNav(
        selected: _navSelected,
        onTap: (i) {
          setState(() => _navSelected = i);
          switch (i) {
            case 1:
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const EBCalendarScreen())); break;
            case 2:
              // EBRsvpScreen shows GET /api/v1/events/?rsvped=true
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const EBRsvpScreen())); break;
            case 3:
              // EBRemindersScreen shows GET /api/v1/events/reminders/
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const EBRemindersScreen())); break;
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DATA CLASSES
// ─────────────────────────────────────────────────────────────
class _Stat { final String emoji, value, label; const _Stat(this.emoji, this.value, this.label); }
class _Mod  {
  final String emoji, title, subtitle;
  final Color colorA, colorB;
  final Widget screen;
  const _Mod(this.emoji, this.title, this.subtitle, this.colorA, this.colorB, this.screen);
}

// ─────────────────────────────────────────────────────────────
//  FEATURED EVENT CARD
//  Wires: POST/DELETE /api/v1/events/<uuid>/rsvp/
//         POST/DELETE /api/v1/events/<uuid>/save/
// ─────────────────────────────────────────────────────────────
class _FeaturedEventCard extends StatelessWidget {
  final EBEvent event;
  final bool going;
  final VoidCallback onRsvpTap;
  final VoidCallback onSaveTap;

  const _FeaturedEventCard({
    required this.event,
    required this.going,
    required this.onRsvpTap,
    required this.onSaveTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [EBColors.brand, EBColors.brandDark],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(children: [
        Positioned(right: 10, top: 0, bottom: 0,
          child: Text(event.emoji, style: TextStyle(
            fontSize: 72, color: Colors.white.withOpacity(0.12)))),
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.7, -0.8), radius: 1.0,
            colors: [
              Colors.white.withOpacity(0.12),
              Colors.transparent,
            ])))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('🔥 FEATURED EVENT', style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w800,
            color: Colors.white.withOpacity(0.72), letterSpacing: 1.5)),
          const SizedBox(height: 6),
          Text(event.title, style: const TextStyle(
            fontSize: 18, fontStyle: FontStyle.italic,
            color: Colors.white, height: 1.3)),
          const SizedBox(height: 6),
          Text('📅 ${event.date}  ·  📍 ${event.location}',
            style: TextStyle(
              fontSize: 11, color: Colors.white.withOpacity(0.75))),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('+${event.attendingCount} attending',
                style: TextStyle(
                  fontSize: 11, color: Colors.white.withOpacity(0.75))),
            ]),
            Row(children: [
              // Save button — POST/DELETE /api/v1/events/<uuid>/save/
              GestureDetector(
                onTap: onSaveTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 34, height: 34,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: event.isSaved
                      ? Colors.white.withOpacity(0.30)
                      : Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35)),
                  ),
                  child: Center(
                    child: Text(event.isSaved ? '🤍' : '🤍',
                      style: TextStyle(
                        fontSize: 14,
                        color: event.isSaved
                          ? Colors.white
                          : Colors.white.withOpacity(0.7)))),
                ),
              ),
              // RSVP button — POST/DELETE /api/v1/events/<uuid>/rsvp/
              GestureDetector(
                onTap: onRsvpTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: going
                      ? Colors.white.withOpacity(0.35)
                      : Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35)),
                  ),
                  child: Text(going ? '✅ Going' : 'RSVP →',
                    style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800,
                      color: Colors.white)),
                ),
              ),
            ]),
          ]),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MODULE CARD
// ─────────────────────────────────────────────────────────────
class _ModuleCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color colorA, colorB;
  final VoidCallback onTap;
  const _ModuleCard({
    required this.emoji, required this.title, required this.subtitle,
    required this.colorA, required this.colorB, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withOpacity(0.15),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(gradient: LinearGradient(
              colors: [colorA, colorB],
              begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Stack(children: [
              Positioned(top: -16, right: -16,
                child: Container(width: 72, height: 72,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1)))),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(height: 6),
                  Text(title, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w900,
                    color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(
                    fontSize: 10, color: Colors.white.withOpacity(0.75))),
                ],
              ),
              Positioned(top: 0, right: 0,
                child: Container(width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8)),
                  child: const Center(child: Text('›',
                    style: TextStyle(
                      fontSize: 16, color: Colors.white,
                      fontWeight: FontWeight.w900))))),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  UPCOMING EVENT CARD
//  Wires: POST/DELETE /api/v1/events/<uuid>/rsvp/
//         POST/DELETE /api/v1/events/<uuid>/save/
//  onTap  → GET /api/v1/events/<uuid>/ (via EBRsvpScreen)
// ─────────────────────────────────────────────────────────────
class _UpcomingEventCard extends StatelessWidget {
  final EBEvent event;
  final VoidCallback onTap;
  final VoidCallback onRsvpTap;
  final VoidCallback onSaveTap;

  const _UpcomingEventCard({
    required this.event,
    required this.onTap,
    required this.onRsvpTap,
    required this.onSaveTap,
  });

  // Map category string → colour
  static Color _catColor(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('academic') || c.contains('tech')) return EBColors.blue;
    if (c.contains('sport'))    return EBColors.green;
    if (c.contains('cultural') || c.contains('arts')) return EBColors.pink;
    return EBColors.brand;
  }

  static Color _gradA(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('sport'))    return const Color(0xFFECFDF5);
    if (c.contains('cultural')) return const Color(0xFFFDF2F8);
    return const Color(0xFFEDE9FE);
  }

  static Color _gradB(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('sport'))    return const Color(0xFF6EE7B7);
    if (c.contains('cultural')) return const Color(0xFFFBCFE8);
    return const Color(0xFFC4B5FD);
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _catColor(event.category);

    return GestureDetector(
      onTap: onTap,   // → detail screen which calls GET /api/v1/events/<uuid>/
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: EBTheme.card,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Banner ──
          Container(
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_gradA(event.category), _gradB(event.category)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18)),
            ),
            child: Stack(children: [
              Center(child: Text(event.emoji,
                style: const TextStyle(fontSize: 54))),
              // Category badge
              Positioned(top: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: catColor,
                    borderRadius: BorderRadius.circular(8)),
                  child: Text(event.category,
                    style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: Colors.white)))),
              // Date badge
              Positioned(top: 10, right: 48,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(7)),
                  child: Text(event.date,
                    style: const TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w800,
                      color: Colors.white)))),
              // Save button — POST/DELETE /api/v1/events/<uuid>/save/
              Positioned(top: 8, right: 8,
                child: GestureDetector(
                  onTap: onSaveTap,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: event.isSaved
                        ? Colors.red.withOpacity(0.85)
                        : Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle),
                    child: Center(child: Text(
                      event.isSaved ? '❤️' : '🤍',
                      style: const TextStyle(fontSize: 13)))))),
            ]),
          ),
          // ── Body ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: EBColors.text)),
                const SizedBox(height: 3),
                Text('📍 ${event.location}', style: TextStyle(
                  fontSize: 11, color: EBColors.text3)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${event.attendingCount} attending',
                      style: TextStyle(
                        fontSize: 11, color: EBColors.text3)),
                    // RSVP button — POST/DELETE /api/v1/events/<uuid>/rsvp/
                    EBRsvpButton(
                      going: event.isRsvped,
                      color: catColor,
                      onTap: onRsvpTap,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BOTTOM NAV
// ─────────────────────────────────────────────────────────────
class _EBBottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _EBBottomNav({required this.selected, required this.onTap});

  static const _items = [
    ('🗓', 'Events'),
    ('📅', 'Calendar'),
    ('🎟', 'My RSVPs'),
    ('🔔', 'Alerts'),
    ('👤', 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
              padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: active
                  ? EBColors.brand.withOpacity(0.10)
                  : Colors.transparent,
                borderRadius: BorderRadius.circular(12)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_items[i].$1,
                  style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 3),
                Text(_items[i].$2, style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w700,
                  color: active ? EBColors.brand : EBColors.text3)),
              ]),
            ),
          );
        }),
      ),
    );
  }
}