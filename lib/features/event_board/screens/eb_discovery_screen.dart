import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/eb_constants.dart';
import '../widgets/eb_widgets.dart';
import '../../../core/api_client.dart';

// ─────────────────────────────────────────────────────────────
//  API ENDPOINTS (all under /api/v1/events/)
//
//  GET    /api/v1/events/                  → list / filter events
//  GET    /api/v1/events/<uuid>/           → event detail
//  POST   /api/v1/events/uploads/banner/   → upload banner image
//  POST   /api/v1/events/<uuid>/rsvp/      → RSVP
//  DELETE /api/v1/events/<uuid>/rsvp/      → cancel RSVP
//  GET    /api/v1/events/reminders/        → list reminders
//  POST   /api/v1/events/reminders/        → create reminder
//  POST   /api/v1/events/<uuid>/save/      → save event
//  DELETE /api/v1/events/<uuid>/save/      → unsave event
//  POST   /api/v1/events/<uuid>/broadcast/ → broadcast event
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────────────────────
class EBEventModel {
  final String id;
  final String emoji;
  final String title;
  final String date;
  final String location;
  final String organiser;
  final String category;
  final int    attendingCount;
  final bool   isRsvped;
  final bool   isSaved;
  final String description;
  final String entry;
  final String mode;

  const EBEventModel({
    required this.id,
    required this.title,
    this.emoji          = '🎉',
    this.date           = '',
    this.location       = '',
    this.organiser      = '',
    this.category       = '',
    this.attendingCount = 0,
    this.isRsvped       = false,
    this.isSaved        = false,
    this.description    = '',
    this.entry          = 'Free Entry',
    this.mode           = 'In-Person',
  });

  // Map category string → design tokens
  Color get catColor {
    final c = category.toLowerCase();
    if (c.contains('academic') || c.contains('tech')) return EBColors.blue;
    if (c.contains('sport'))                          return EBColors.green;
    if (c.contains('cultural') || c.contains('arts'))return EBColors.pink;
    if (c.contains('career'))                         return EBColors.amber;
    return EBColors.brand;
  }

  Color get gradA {
    final c = category.toLowerCase();
    if (c.contains('sport'))                          return const Color(0xFFECFDF5);
    if (c.contains('cultural') || c.contains('arts'))return const Color(0xFFFDF2F8);
    if (c.contains('career'))                         return const Color(0xFFFFFBEB);
    return const Color(0xFFEDE9FE);
  }

  Color get gradB {
    final c = category.toLowerCase();
    if (c.contains('sport'))                          return const Color(0xFF6EE7B7);
    if (c.contains('cultural') || c.contains('arts'))return const Color(0xFFFBCFE8);
    if (c.contains('career'))                         return const Color(0xFFFDE68A);
    return const Color(0xFFC4B5FD);
  }

  Color get rsvpColor => catColor;

  factory EBEventModel.fromJson(Map<String, dynamic> raw) {
    // Unwrap nested envelope if present
    final j = (raw['event'] is Map<String, dynamic>
        ? raw['event']
        : raw) as Map<String, dynamic>;

    String str(String k)  => j[k]?.toString() ?? '';
    bool   boo(String k)  {
      final v = j[k];
      if (v is bool)   return v;
      if (v is int)    return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
      return false;
    }
    int num_(String k) => (j[k] as num?)?.toInt() ?? 0;

    return EBEventModel(
      id:             str('id'),
      title:          str('title'),
      emoji:          str('emoji').isEmpty ? '🎉' : str('emoji'),
      date:           str('date'),
      location:       str('location'),
      organiser:      str('organiser'),
      category:       str('category'),
      attendingCount: num_('attendingCount'),
      isRsvped:       boo('isRsvped'),
      isSaved:        boo('isSaved'),
      description:    str('description'),
      entry:          str('entry').isEmpty ? 'Free Entry' : str('entry'),
      mode:           str('mode').isEmpty ? 'In-Person' : str('mode'),
    );
  }

  EBEventModel copyWith({
    bool? isRsvped, bool? isSaved, int? attendingCount,
  }) => EBEventModel(
    id:             id,
    title:          title,
    emoji:          emoji,
    date:           date,
    location:       location,
    organiser:      organiser,
    category:       category,
    attendingCount: attendingCount ?? this.attendingCount,
    isRsvped:       isRsvped      ?? this.isRsvped,
    isSaved:        isSaved       ?? this.isSaved,
    description:    description,
    entry:          entry,
    mode:           mode,
  );
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 1 — Event Discovery (Browse)
//  GET /api/v1/events/?category=<cat>&sort=<sort>
// ─────────────────────────────────────────────────────────────
class EBDiscoveryScreen extends StatefulWidget {
  const EBDiscoveryScreen({super.key});
  @override
  State<EBDiscoveryScreen> createState() => _EBDiscoveryScreenState();
}

class _EBDiscoveryScreenState extends State<EBDiscoveryScreen> {
  // ── Filter/sort state ─────────────────────────────────────
  int _catFilter  = 0;
  int _sortFilter = 0;

  final _categories = ['All', '📚 Academic', '🎵 Social', '⚽ Sports', '🎭 Cultural', '🛠 Career'];
  final _sorts      = ['🗓 Upcoming', '🔥 Popular', '📍 Nearby', '📅 Today'];

  // Category values sent to the API (index-aligned with _categories)
  static const _catParams = ['', 'Academic', 'Social', 'Sports', 'Cultural', 'Career'];
  // Sort values sent to the API (index-aligned with _sorts)
  static const _sortParams = ['upcoming', 'popular', 'nearby', 'today'];

  // ── Data state ────────────────────────────────────────────
  List<EBEventModel> _events      = [];
  bool               _loading     = true;
  String?            _error;
  bool               _featuredGoing = false;

  EBEventModel? get _featured => _events.isNotEmpty ? _events.first : null;
  List<EBEventModel> get _listEvents =>
      _events.length > 1 ? _events.sublist(1) : [];

  // ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  // ─────────────────────────────────────────────────────────
  //  READ: GET /api/v1/events/
  //  Query params: category=<cat>&sort=<sort>
  // ─────────────────────────────────────────────────────────
  Future<void> _loadEvents() async {
    if (mounted) setState(() { _loading = true; _error = null; });

    try {
      // Build query string from active filters
      final params = <String>[];
      if (_catFilter  != 0) params.add('category=${_catParams[_catFilter]}');
      if (_sortFilter != 0) params.add('sort=${_sortParams[_sortFilter]}');
      final query = params.isEmpty ? '' : '?${params.join('&')}';

      final res = await ApiClient.get('/api/v1/events/$query');
      dev.log('[Discovery] GET /events$query → ${res.statusCode}');
      dev.log('[Discovery] body: ${res.body}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final raw = decoded is List
            ? decoded
            : (decoded['results'] as List?) ?? [];

        final events = raw
            .whereType<Map<String, dynamic>>()
            .map(EBEventModel.fromJson)
            .toList();

        setState(() {
          _events        = events;
          _loading       = false;
          _featuredGoing = events.isNotEmpty ? events.first.isRsvped : false;
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

  // ─────────────────────────────────────────────────────────
  //  UPDATE: RSVP toggle
  //  POST   /api/v1/events/<uuid>/rsvp/
  //  DELETE /api/v1/events/<uuid>/rsvp/
  // ─────────────────────────────────────────────────────────
  Future<void> _toggleRsvp(EBEventModel event) async {
    final wasGoing = event.isRsvped;
    _mutate(event.id, isRsvped: !wasGoing,
        attendingDelta: wasGoing ? -1 : 1);
    if (_featured?.id == event.id) {
      setState(() => _featuredGoing = !wasGoing);
    }

    try {
      final res = wasGoing
          ? await ApiClient.delete('/api/v1/events/${event.id}/rsvp/')
          : await ApiClient.post  ('/api/v1/events/${event.id}/rsvp/');

      dev.log('[Discovery] RSVP ${event.id} → ${res.statusCode}');

      final ok = res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204;
      if (!ok) {
        _mutate(event.id, isRsvped: wasGoing, attendingDelta: wasGoing ? 1 : -1);
        if (_featured?.id == event.id) setState(() => _featuredGoing = wasGoing);
        if (mounted) _snack('Could not update RSVP. Please try again.');
      } else {
        if (mounted) _snack(!wasGoing ? "✅ You're going to ${event.title}!" : 'RSVP cancelled');
      }
    } catch (_) {
      _mutate(event.id, isRsvped: wasGoing, attendingDelta: wasGoing ? 1 : -1);
      if (_featured?.id == event.id) setState(() => _featuredGoing = wasGoing);
      if (mounted) _snack('Network error. Please try again.');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  UPDATE: Save toggle
  //  POST   /api/v1/events/<uuid>/save/
  //  DELETE /api/v1/events/<uuid>/save/
  // ─────────────────────────────────────────────────────────
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

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: EBColors.brand,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      ));
  }

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EBColors.surface2,
      appBar: AppBar(
        backgroundColor: EBColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
            size: 18, color: EBColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('EventBoard', style: TextStyle(
            fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w900,
            color: EBColors.brandDark, fontStyle: FontStyle.italic)),
          Text(
            _loading
              ? 'Loading events…'
              : '${_events.length} upcoming events',
            style: TextStyle(fontSize: 11, color: EBColors.text3)),
        ]),
        titleSpacing: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: EBColors.brandPale,
              borderRadius: BorderRadius.circular(11)),
            child: const Text('🔍', style: TextStyle(fontSize: 18))),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: EBColors.brand,
              borderRadius: BorderRadius.circular(11)),
            child: const Text('🔔', style: TextStyle(fontSize: 18))),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: EBColors.border, height: 1)),
      ),
      body: RefreshIndicator(
        color: EBColors.brand,
        onRefresh: _loadEvents,
        child: CustomScrollView(slivers: [

          // ── Category chips ─────────────────────────────
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
                    _loadEvents(); // re-fetch with new category filter
                  }),
              )),
          ),

          // ── Featured event banner ──────────────────────
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
                    label: const Text('Retry'),
                  ),
                ]),
              ),
            )
          else ...[
            if (_featured != null)
              SliverToBoxAdapter(
                child: _FeaturedBanner(
                  event: _featured!,
                  going: _featuredGoing,
                  // POST/DELETE /api/v1/events/<uuid>/rsvp/
                  onRsvpTap: () => _toggleRsvp(_featured!),
                  // POST/DELETE /api/v1/events/<uuid>/save/
                  onSaveTap: () => _toggleSave(_featured!),
                ),
              ),

            // ── Sort chips ─────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(height: 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  itemCount: _sorts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 7),
                  itemBuilder: (_, i) => EBChip(
                    label: _sorts[i],
                    active: _sortFilter == i,
                    onTap: () {
                      setState(() => _sortFilter = i);
                      _loadEvents(); // re-fetch with new sort
                    }),
                )),
            ),

            // ── Event list ────────────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  if (i >= _listEvents.length) {
                    return const SizedBox(height: 100);
                  }
                  final ev = _listEvents[i];
                  return _EventCard(
                    event: ev,
                    // GET /api/v1/events/<uuid>/ happens inside detail screen
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                        builder: (_) => EBEventDetailScreen(
                          eventId: ev.id,
                          // Pass snapshot so detail screen can show
                          // data immediately while it fetches fresh copy
                          snapshot: ev,
                        ))).then((_) => _loadEvents()), // refresh on return
                    // POST/DELETE /api/v1/events/<uuid>/rsvp/
                    onRsvpTap: () => _toggleRsvp(ev),
                    // POST/DELETE /api/v1/events/<uuid>/save/
                    onSaveTap: () => _toggleSave(ev),
                  );
                },
                childCount: _listEvents.length + 1,
              ),
            ),
          ],
        ]),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: EBColors.brand,
        foregroundColor: Colors.white,
        icon: const Text('🎉', style: TextStyle(fontSize: 18)),
        label: const Text('Create Event',
          style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const EBCreateEventScreen()))
            .then((_) => _loadEvents()),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  FEATURED BANNER
// ─────────────────────────────────────────────────────────────
class _FeaturedBanner extends StatelessWidget {
  final EBEventModel event;
  final bool going;
  final VoidCallback onRsvpTap;
  final VoidCallback onSaveTap;

  const _FeaturedBanner({
    required this.event,
    required this.going,
    required this.onRsvpTap,
    required this.onSaveTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [EBColors.brand, EBColors.brandDark],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(children: [
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.8, -0.8), radius: 1.0,
            colors: [Colors.white.withOpacity(0.12), Colors.transparent])))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('🔥 FEATURED EVENT', style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w800,
            color: Colors.white.withOpacity(0.72), letterSpacing: 1.5)),
          const SizedBox(height: 6),
          Text(event.title, style: const TextStyle(
            fontSize: 17, fontStyle: FontStyle.italic,
            color: Colors.white, height: 1.3)),
          const SizedBox(height: 5),
          Text('📅 ${event.date}  —  📍 ${event.location}',
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('+${event.attendingCount} attending',
              style: TextStyle(
                fontSize: 11, color: Colors.white.withOpacity(0.75))),
            Row(children: [
              // Save — POST/DELETE /api/v1/events/<uuid>/save/
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
                      color: Colors.white.withOpacity(0.35))),
                  child: Center(child: Text(
                    event.isSaved ? '❤️' : '🤍',
                    style: const TextStyle(fontSize: 15))))),
              // RSVP — POST/DELETE /api/v1/events/<uuid>/rsvp/
              GestureDetector(
                onTap: onRsvpTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: going
                      ? Colors.white.withOpacity(0.35)
                      : Colors.white.withOpacity(0.20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(10)),
                  child: Text(going ? '✅ Going' : 'RSVP →',
                    style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800,
                      color: Colors.white)))),
            ]),
          ]),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 2 — Event Detail
//  GET    /api/v1/events/<uuid>/           → fetch fresh detail
//  POST   /api/v1/events/<uuid>/rsvp/      → RSVP
//  DELETE /api/v1/events/<uuid>/rsvp/      → cancel RSVP
//  POST   /api/v1/events/<uuid>/save/      → save
//  DELETE /api/v1/events/<uuid>/save/      → unsave
//  POST   /api/v1/events/<uuid>/broadcast/ → broadcast
//  POST   /api/v1/events/reminders/        → set reminder
// ─────────────────────────────────────────────────────────────
class EBEventDetailScreen extends StatefulWidget {
  /// UUID of the event to load
  final String eventId;
  /// Optional snapshot so the screen renders immediately
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

  @override
  void initState() {
    super.initState();
    // Show snapshot immediately, then refresh from server
    if (widget.snapshot != null) {
      _event   = widget.snapshot;
      _loading = false;
    }
    _fetchDetail();
  }

  // ─────────────────────────────────────────────────────────
  //  READ: GET /api/v1/events/<uuid>/
  // ─────────────────────────────────────────────────────────
  Future<void> _fetchDetail() async {
    // Don't show spinner if we already have snapshot data
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
        setState(() {
          _error   = 'Network error.';
          _loading = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  //  UPDATE: RSVP toggle
  //  POST   /api/v1/events/<uuid>/rsvp/
  //  DELETE /api/v1/events/<uuid>/rsvp/
  // ─────────────────────────────────────────────────────────
  Future<void> _toggleRsvp() async {
    if (_event == null) return;
    final wasGoing = _event!.isRsvped;
    setState(() => _event = _event!.copyWith(
      isRsvped: !wasGoing,
      attendingCount: _event!.attendingCount + (wasGoing ? -1 : 1)));

    try {
      final res = wasGoing
          ? await ApiClient.delete('/api/v1/events/${widget.eventId}/rsvp/')
          : await ApiClient.post  ('/api/v1/events/${widget.eventId}/rsvp/');

      dev.log('[Detail] RSVP → ${res.statusCode}');

      final ok = res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204;
      if (!ok) {
        // revert
        setState(() => _event = _event!.copyWith(
          isRsvped: wasGoing,
          attendingCount: _event!.attendingCount + (wasGoing ? 1 : -1)));
        if (mounted) _snack('Could not update RSVP.');
      } else {
        if (mounted) _snack(!wasGoing ? "✅ You're going!" : 'RSVP cancelled',
          bg: _event?.rsvpColor);
      }
    } catch (_) {
      setState(() => _event = _event!.copyWith(
        isRsvped: wasGoing,
        attendingCount: _event!.attendingCount + (wasGoing ? 1 : -1)));
      if (mounted) _snack('Network error. Please try again.');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  UPDATE: Save toggle
  //  POST   /api/v1/events/<uuid>/save/
  //  DELETE /api/v1/events/<uuid>/save/
  // ─────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────
  //  CREATE: Set reminder
  //  POST /api/v1/events/reminders/
  // ─────────────────────────────────────────────────────────
  Future<void> _setReminder() async {
    if (_event == null) return;
    try {
      final res = await ApiClient.post('/api/v1/events/reminders/', body: {
        'eventId':      widget.eventId,
        // Default: 24 hours before the event
        'reminderTime': '24h',
      });
      dev.log('[Detail] Reminder → ${res.statusCode}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) _snack('🔔 Reminder set for ${_event!.title}!');
      } else {
        if (mounted) _snack('Could not set reminder.');
      }
    } catch (_) {
      if (mounted) _snack('Network error. Please try again.');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  CREATE: Broadcast event
  //  POST /api/v1/events/<uuid>/broadcast/
  // ─────────────────────────────────────────────────────────
  Future<void> _broadcast() async {
    try {
      final res = await ApiClient.post(
        '/api/v1/events/${widget.eventId}/broadcast/');
      dev.log('[Detail] Broadcast → ${res.statusCode}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) _snack('📢 Event broadcasted to all students!');
      } else {
        if (mounted) _snack('Could not broadcast event.');
      }
    } catch (_) {
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      ));
  }

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Full-screen error (no snapshot available)
    if (_error != null && _event == null) {
      return Scaffold(
        backgroundColor: EBColors.surface2,
        appBar: AppBar(
          backgroundColor: EBColors.surface, elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: EBColors.text),
            onPressed: () => Navigator.pop(context)),
        ),
        body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: TextStyle(
              fontSize: 13, color: EBColors.text3)),
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

        // ── Hero header ─────────────────────────────────
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
              child: const Icon(Icons.arrow_back_ios_new,
                size: 16, color: EBColors.text))),
          actions: [
            // Set reminder — POST /api/v1/events/reminders/
            GestureDetector(
              onTap: _setReminder,
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8, right: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(11)),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('🔔', style: TextStyle(fontSize: 18))))),
            // Save — POST/DELETE /api/v1/events/<uuid>/save/
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
                  child: const Center(
                    child: CircularProgressIndicator()))
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [e.gradA, e.gradB],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight)),
                  child: Stack(children: [
                    Center(child: Text(e.emoji,
                      style: const TextStyle(fontSize: 80))),
                    Positioned(bottom: 0, left: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 30, 16, 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.65)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: e.catColor,
                                borderRadius: BorderRadius.circular(8)),
                              child: Text(e.category,
                                style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w800,
                                  color: Colors.white))),
                            const SizedBox(height: 6),
                            Text(e.title, style: const TextStyle(
                              fontSize: 18, fontStyle: FontStyle.italic,
                              color: Colors.white, height: 1.3)),
                          ],
                        ),
                      )),
                  ])),
          ),
        ),

        // ── Body ────────────────────────────────────────
        SliverToBoxAdapter(
          child: e == null
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()))
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Date / location + RSVP button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.date, style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: EBColors.text)),
                          Text(e.location, style: TextStyle(
                            fontSize: 12, color: EBColors.text3)),
                        ]),
                      // RSVP — POST/DELETE /api/v1/events/<uuid>/rsvp/
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
                              color: Colors.white)))),
                    ])),

                const SizedBox(height: 14),
                EBFormField(label: 'Organised by', value: e.organiser),
                EBFormField(label: 'Attending',
                  value: '${e.attendingCount} people confirmed'),
                EBFormField(label: 'Entry', value: e.entry),
                EBFormField(label: 'Mode', value: e.mode),
                EBFormField(label: 'About', value: e.description.isNotEmpty
                  ? e.description
                  : 'No description provided.',
                  multiline: true),

                // Broadcast row (organiser action)
                // POST /api/v1/events/<uuid>/broadcast/
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: GestureDetector(
                    onTap: _broadcast,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: EBColors.brandPale,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: EBColors.brandLight, width: 1.5)),
                      child: Row(children: [
                        const Text('📢',
                          style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Broadcast Event', style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: EBColors.brand)),
                            const SizedBox(height: 2),
                            Text('Notify all students about this event.',
                              style: TextStyle(
                                fontSize: 11, color: EBColors.text2)),
                          ])),
                        Icon(Icons.chevron_right_rounded,
                          size: 18, color: EBColors.brand),
                      ]),
                    ),
                  ),
                ),

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
//  SCREEN 3 — Create Event
//  POST /api/v1/events/           → create event (Publish)
//  POST /api/v1/events/uploads/banner/ → upload banner image
// ─────────────────────────────────────────────────────────────
class EBCreateEventScreen extends StatefulWidget {
  const EBCreateEventScreen({super.key});
  @override
  State<EBCreateEventScreen> createState() => _EBCreateEventScreenState();
}

class _EBCreateEventScreenState extends State<EBCreateEventScreen> {
  String _category = 'Academic';
  String _mode     = 'In-Person';
  bool   _publishing = false;

  final _titleCtrl    = TextEditingController();
  final _dateCtrl     = TextEditingController();
  final _venueCtrl    = TextEditingController();
  final _attendeesCtrl= TextEditingController();
  final _descCtrl     = TextEditingController();

  static const _cats = [
    ('📚', 'Academic'), ('🎵', 'Social'), ('⚽', 'Sports'),
    ('🎭', 'Cultural'), ('🛠', 'Career'),
  ];
  static const _modes = ['In-Person', 'Online', 'Hybrid'];

  @override
  void dispose() {
    _titleCtrl.dispose(); _dateCtrl.dispose(); _venueCtrl.dispose();
    _attendeesCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  //  CREATE: POST /api/v1/events/
  //  (banner is uploaded separately via POST /api/v1/events/uploads/banner/
  //   then the returned URL is included in the event payload)
  // ─────────────────────────────────────────────────────────
  Future<void> _publish() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _snack('Please enter an event title.'); return;
    }

    setState(() => _publishing = true);

    try {
      final res = await ApiClient.post('/api/v1/events/', body: {
        'title':             title,
        'category':          _category,
        'date':              _dateCtrl.text.trim(),
        'location':          _venueCtrl.text.trim(),
        'mode':              _mode,
        'expectedAttendees': _attendeesCtrl.text.trim(),
        'description':       _descCtrl.text.trim(),
      });

      dev.log('[Create] POST /events/ → ${res.statusCode}');

      if (!mounted) return;

      if (res.statusCode == 201 || res.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Event published!'),
          backgroundColor: EBColors.brand));
      } else {
        final body = jsonDecode(res.body) as Map<String, dynamic>?;
        final msg  = body?['detail']?.toString()
            ?? body?['message']?.toString()
            ?? 'Could not publish event (${res.statusCode}).';
        _snack(msg);
      }
    } catch (e) {
      dev.log('[Create] error: $e');
      if (mounted) _snack('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: EBColors.brand,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EBColors.surface2,
      appBar: AppBar(
        backgroundColor: EBColors.surface, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: EBColors.text),
          onPressed: () => Navigator.pop(context)),
        title: const Text('Create Event', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w800, color: EBColors.text)),
        actions: [
          TextButton(
            onPressed: _publishing ? null : _publish,
            child: _publishing
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Publish', style: TextStyle(
                  fontWeight: FontWeight.w800, color: EBColors.brand))),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: EBColors.border, height: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text(
              'Create an event and invite your campus community 🎉',
              style: TextStyle(fontSize: 13, color: EBColors.text2))),

          // Banner upload hint
          // POST /api/v1/events/uploads/banner/
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: GestureDetector(
              // TODO: pick image → POST /api/v1/events/uploads/banner/
              // then store returned URL to include in publish payload
              onTap: () => _snack('Banner upload coming soon!'),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: EBColors.brandPale,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: EBColors.brandLight,
                    width: 1.5,
                    style: BorderStyle.solid)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🖼', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Text('Upload Event Banner',
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: EBColors.brand)),
                  ]),
              ),
            ),
          ),

          // Title
          _FormInput(label: 'Event Title',
            hint: 'e.g. Annual Science Fair 2026',
            controller: _titleCtrl),

          // Category grid
          EBSectionLabel(title: 'Category'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8, crossAxisSpacing: 8,
              childAspectRatio: 2.5,
              children: _cats.map<Widget>((c) => GestureDetector(
                onTap: () => setState(() => _category = c.$2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _category == c.$2
                      ? EBColors.brandPale : EBColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _category == c.$2
                        ? EBColors.brand : EBColors.border,
                      width: 1.5)),
                  child: Row(children: [
                    Text(c.$1, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(c.$2, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: _category == c.$2
                        ? EBColors.brand : EBColors.text2)),
                  ]),
                ),
              )).toList(),
            ),
          ),

          const SizedBox(height: 10),
          _FormInput(label: 'Date & Time',
            hint: 'e.g. Feb 22, 2026 · 8:00 AM',
            controller: _dateCtrl),
          _FormInput(label: 'Venue / Location',
            hint: 'e.g. Innovation Hub, UoN',
            controller: _venueCtrl),

          // Mode chips
          EBSectionLabel(title: 'Event Mode'),
          SizedBox(height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _modes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (_, i) => EBChip(
                label: _modes[i],
                active: _mode == _modes[i],
                onTap: () => setState(() => _mode = _modes[i])),
            )),

          const SizedBox(height: 10),
          _FormInput(label: 'Expected Attendees',
            hint: '50 – 200',
            controller: _attendeesCtrl,
            keyboardType: TextInputType.number),
          _FormInput(label: 'Description',
            hint: 'Describe the event, what attendees can expect…',
            controller: _descCtrl,
            multiline: true),

          const SizedBox(height: 10),
          // Auto-reminder notice
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EBColors.brandPale,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: EBColors.brandLight, width: 1.5)),
            child: Row(children: [
              const Text('🔔', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Auto-reminders enabled', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: EBColors.brand)),
                  const SizedBox(height: 2),
                  Text('Attendees get 24h and 1h reminders automatically.',
                    style: TextStyle(fontSize: 11, color: EBColors.text2)),
                ])),
            ]),
          ),

          // Publish — POST /api/v1/events/
          EBPrimaryButton(
            label: _publishing ? 'Publishing…' : '🎉 Publish Event',
            onTap: _publishing ? null : _publish,
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  REUSABLE FORM INPUT
// ─────────────────────────────────────────────────────────────
class _FormInput extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final bool multiline;
  final TextInputType keyboardType;

  const _FormInput({
    required this.label,
    required this.hint,
    required this.controller,
    this.multiline    = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700, color: EBColors.text2)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: multiline ? 4 : 1,
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: EBColors.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: EBColors.text3),
            filled: true,
            fillColor: EBColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: EBColors.border)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: EBColors.border)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: EBColors.brand, width: 2)),
          ),
        ),
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

  const _EventCard({
    required this.event,
    required this.onTap,
    required this.onRsvpTap,
    required this.onSaveTap,
  });

  @override
  Widget build(BuildContext context) {
    final e = event;
    return GestureDetector(
      onTap: onTap,
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18))),
            child: Stack(children: [
              Center(child: Text(e.emoji,
                style: const TextStyle(fontSize: 52))),
              Positioned(top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: e.catColor,
                    borderRadius: BorderRadius.circular(8)),
                  child: Text(e.category, style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w800,
                    color: Colors.white)))),
              Positioned(bottom: 8, right: 44,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(7)),
                  child: Text(e.date, style: const TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w800,
                    color: Colors.white)))),
              // Save — POST/DELETE /api/v1/events/<uuid>/save/
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title, maxLines: 2, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: EBColors.text, height: 1.3)),
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
                        style: TextStyle(
                          fontSize: 11, color: EBColors.text3)),
                    ]),
                    // RSVP — POST/DELETE /api/v1/events/<uuid>/rsvp/
                    EBRsvpButton(
                      going: e.isRsvped,
                      color: e.rsvpColor,
                      onTap: onRsvpTap),
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
//  MINI AVATAR STACK  (static decoration)
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
//  ATTENDEE LIST  (static, decorative — real list would come
//  from GET /api/v1/events/<uuid>/ attendees array)
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
                gradient: LinearGradient(
                  colors: [a.$4, a.$4.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(11)),
              child: Center(child: Text(a.$1,
                style: const TextStyle(fontSize: 16)))),
            const SizedBox(width: 10),
            Expanded(child: Text(a.$2, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: EBColors.text))),
            Text(a.$3, style: TextStyle(
              fontSize: 11, color: EBColors.text3)),
            const SizedBox(width: 8),
            Text('✓', style: TextStyle(
              fontSize: 16, color: EBColors.green)),
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