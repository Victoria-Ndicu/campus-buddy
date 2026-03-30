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
//  GET    /api/v1/events/                  → list events (with ?date= filter)
//  GET    /api/v1/events/<uuid>/           → event detail
//  POST   /api/v1/events/<uuid>/rsvp/      → RSVP
//  DELETE /api/v1/events/<uuid>/rsvp/      → cancel RSVP
//  GET    /api/v1/events/reminders/        → list reminders
//  POST   /api/v1/events/reminders/        → create reminder
//  DELETE /api/v1/events/reminders/        → delete reminder (via body {eventId})
//  POST   /api/v1/events/<uuid>/save/      → save event
//  DELETE /api/v1/events/<uuid>/save/      → unsave event
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
//  SHARED MODELS
// ─────────────────────────────────────────────────────────────
class _CalEvent {
  final String id;
  final String name;
  final String time;       // e.g. "2:00 PM"
  final String date;       // e.g. "Feb 18 · 2:00 PM"
  final String meta;       // location + organiser
  final String category;
  final Color  catColor;
  final Color  stripe;
  final int    day;        // day-of-month number
  final String dayLabel;   // e.g. "TUE"
  final int    attendingCount;
  final bool   isRsvped;
  final bool   isSaved;
  final bool   hasReminder;

  const _CalEvent({
    required this.id,
    required this.name,
    this.time          = '',
    this.date          = '',
    this.meta          = '',
    this.category      = '',
    this.catColor      = EBColors.brand,
    this.stripe        = EBColors.brand,
    this.day           = 0,
    this.dayLabel      = '',
    this.attendingCount = 0,
    this.isRsvped      = false,
    this.isSaved       = false,
    this.hasReminder   = false,
  });

  _CalEvent copyWith({bool? isRsvped, bool? isSaved, bool? hasReminder,
      int? attendingCount}) => _CalEvent(
    id:             id,
    name:           name,
    time:           time,
    date:           date,
    meta:           meta,
    category:       category,
    catColor:       catColor,
    stripe:         stripe,
    day:            day,
    dayLabel:       dayLabel,
    attendingCount: attendingCount ?? this.attendingCount,
    isRsvped:       isRsvped      ?? this.isRsvped,
    isSaved:        isSaved       ?? this.isSaved,
    hasReminder:    hasReminder   ?? this.hasReminder,
  );

  Color get _catCol {
    final c = category.toLowerCase();
    if (c.contains('academic') || c.contains('tech')) return EBColors.blue;
    if (c.contains('sport'))                          return EBColors.green;
    if (c.contains('cultural') || c.contains('arts'))return EBColors.pink;
    if (c.contains('career'))                         return EBColors.amber;
    return EBColors.brand;
  }

  factory _CalEvent.fromJson(Map<String, dynamic> raw) {
    final j = (raw['event'] is Map<String, dynamic>
        ? raw['event'] : raw) as Map<String, dynamic>;

    String str(String k) => j[k]?.toString() ?? '';
    bool   boo(String k) {
      final v = j[k];
      if (v is bool) return v;
      if (v is int)  return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
      return false;
    }
    int    num_(String k) => (j[k] as num?)?.toInt() ?? 0;

    // Parse day-of-month from date string (fallback 0)
    int parsedDay = 0;
    final dateStr = str('date');
    final match = RegExp(r'\b(\d{1,2})\b').firstMatch(dateStr);
    if (match != null) parsedDay = int.tryParse(match.group(1)!) ?? 0;

    // Day label from date (Mon, Tue … or from server)
    String parsedLabel = str('dayLabel');

    final catStr = str('category');
    Color catCol = EBColors.brand;
    {
      final c = catStr.toLowerCase();
      if (c.contains('academic') || c.contains('tech')) catCol = EBColors.blue;
      else if (c.contains('sport'))                     catCol = EBColors.green;
      else if (c.contains('cultural') || c.contains('arts')) catCol = EBColors.pink;
      else if (c.contains('career'))                    catCol = EBColors.amber;
    }

    return _CalEvent(
      id:             str('id'),
      name:           str('title').isEmpty ? str('name') : str('title'),
      time:           str('time'),
      date:           dateStr,
      meta:           str('meta').isEmpty ? str('location') : str('meta'),
      category:       catStr,
      catColor:       catCol,
      stripe:         catCol,
      day:            num_('day').isNaN ? parsedDay : num_('day') == 0 ? parsedDay : num_('day'),
      dayLabel:       parsedLabel,
      attendingCount: num_('attendingCount'),
      isRsvped:       boo('isRsvped'),
      isSaved:        boo('isSaved'),
      hasReminder:    boo('hasReminder'),
    );
  }
}

class _Reminder {
  final String id;
  final String eventId;
  final String eventName;
  final String reminderTime;
  final String meta;

  const _Reminder({
    required this.id,
    required this.eventId,
    required this.eventName,
    this.reminderTime = '',
    this.meta         = '',
  });

  factory _Reminder.fromJson(Map<String, dynamic> j) => _Reminder(
    id:           j['id']?.toString()           ?? '',
    eventId:      j['eventId']?.toString()      ?? '',
    eventName:    j['eventName']?.toString()    ?? '',
    reminderTime: j['reminderTime']?.toString() ?? '',
    meta:         j['meta']?.toString()         ?? '',
  );
}

// ─────────────────────────────────────────────────────────────
//  SHARED API HELPERS  (mixin used by all three screens)
// ─────────────────────────────────────────────────────────────
mixin _EventActions<T extends StatefulWidget> on State<T> {
  // ── RSVP toggle ──────────────────────────────────────────
  // POST   /api/v1/events/<uuid>/rsvp/
  // DELETE /api/v1/events/<uuid>/rsvp/
  Future<bool> apiToggleRsvp(String eventId, {required bool wasGoing}) async {
    try {
      final res = wasGoing
          ? await ApiClient.delete('/api/v1/events/$eventId/rsvp/')
          : await ApiClient.post  ('/api/v1/events/$eventId/rsvp/');
      dev.log('[EventActions] RSVP $eventId → ${res.statusCode}');
      return res.statusCode == 200 ||
             res.statusCode == 201 ||
             res.statusCode == 204;
    } catch (e) {
      dev.log('[EventActions] RSVP error: $e');
      return false;
    }
  }

  // ── Save toggle ───────────────────────────────────────────
  // POST   /api/v1/events/<uuid>/save/
  // DELETE /api/v1/events/<uuid>/save/
  Future<bool> apiToggleSave(String eventId, {required bool wasSaved}) async {
    try {
      final res = wasSaved
          ? await ApiClient.delete('/api/v1/events/$eventId/save/')
          : await ApiClient.post  ('/api/v1/events/$eventId/save/');
      dev.log('[EventActions] Save $eventId → ${res.statusCode}');
      return res.statusCode == 200 ||
             res.statusCode == 201 ||
             res.statusCode == 204;
    } catch (e) {
      dev.log('[EventActions] Save error: $e');
      return false;
    }
  }

  // ── Add reminder ──────────────────────────────────────────
  // POST /api/v1/events/reminders/
  Future<bool> apiAddReminder(String eventId,
      {String reminderTime = '24h'}) async {
    try {
      final res = await ApiClient.post('/api/v1/events/reminders/', body: {
        'eventId':      eventId,
        'reminderTime': reminderTime,
      });
      dev.log('[EventActions] AddReminder $eventId → ${res.statusCode}');
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      dev.log('[EventActions] Reminder error: $e');
      return false;
    }
  }

  // ── Delete reminder ───────────────────────────────────────
  // DELETE /api/v1/events/reminders/  {eventId}
  Future<bool> apiDeleteReminder(String eventId) async {
    try {
      final res = await ApiClient.delete('/api/v1/events/reminders/',
          body: {'eventId': eventId});
      dev.log('[EventActions] DelReminder $eventId → ${res.statusCode}');
      return res.statusCode == 200 ||
             res.statusCode == 204 ||
             res.statusCode == 201;
    } catch (e) {
      dev.log('[EventActions] DelReminder error: $e');
      return false;
    }
  }

  void showSnack(String msg, {Color? bg}) {
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
}

// ═════════════════════════════════════════════════════════════
//  SCREEN 1 — CALENDAR
//  GET /api/v1/events/?date=YYYY-MM-DD  → events for selected day
//  + RSVP / Save / Reminder actions via mixin
// ═════════════════════════════════════════════════════════════
class EBCalendarScreen extends StatefulWidget {
  const EBCalendarScreen({super.key});
  @override
  State<EBCalendarScreen> createState() => _EBCalendarScreenState();
}

class _EBCalendarScreenState extends State<EBCalendarScreen>
    with _EventActions<EBCalendarScreen> {

  // ── Calendar state ────────────────────────────────────────
  int _selectedDay = 18;
  static const _today = 17;

  // Days that have events — populated from API response
  Set<int> _eventDays = {};

  // Events for the currently selected day
  List<_CalEvent> _dayEvents  = [];
  bool            _loadingDay = false;
  String?         _dayError;

  // Week strip days
  static const _weekDays   = [18, 19, 20, 21, 22];
  static const _weekLabels = ['TUE', 'WED', 'THU', 'FRI', 'SAT'];

  // ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadMonthEvents();   // populate dot indicators
    _loadDayEvents(18);   // load default selected day
  }

  // ─────────────────────────────────────────────────────────
  //  READ: GET /api/v1/events/?month=2026-02
  //  Used only to mark which days have events (dot indicators).
  // ─────────────────────────────────────────────────────────
  Future<void> _loadMonthEvents() async {
    try {
      final res = await ApiClient.get('/api/v1/events/?month=2026-02');
      dev.log('[Calendar] GET /events?month → ${res.statusCode}');
      if (!mounted || res.statusCode != 200) return;

      final decoded = jsonDecode(res.body);
      final raw = decoded is List
          ? decoded
          : (decoded['results'] as List?) ?? [];

      final days = raw
          .whereType<Map<String, dynamic>>()
          .map((j) => _CalEvent.fromJson(j).day)
          .where((d) => d > 0)
          .toSet();

      if (mounted) setState(() => _eventDays = days);
    } catch (e) {
      dev.log('[Calendar] loadMonthEvents error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  READ: GET /api/v1/events/?date=2026-02-<day>
  //  Fetches events for the selected day.
  // ─────────────────────────────────────────────────────────
  Future<void> _loadDayEvents(int day) async {
    if (!mounted) return;
    setState(() { _loadingDay = true; _dayError = null; });

    final dayStr = day.toString().padLeft(2, '0');
    try {
      final res = await ApiClient.get('/api/v1/events/?date=2026-02-$dayStr');
      dev.log('[Calendar] GET /events?date=2026-02-$dayStr → ${res.statusCode}');
      dev.log('[Calendar] body: ${res.body}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final raw = decoded is List
            ? decoded
            : (decoded['results'] as List?) ?? [];

        final events = raw
            .whereType<Map<String, dynamic>>()
            .map(_CalEvent.fromJson)
            .toList();

        setState(() {
          _dayEvents  = events;
          _loadingDay = false;
          // Add to dot set if we got results
          if (events.isNotEmpty) _eventDays.add(day);
        });
      } else {
        setState(() {
          _dayError   = 'Could not load events (${res.statusCode}).';
          _loadingDay = false;
        });
      }
    } catch (e, s) {
      dev.log('[Calendar] loadDayEvents error: $e', stackTrace: s);
      if (mounted) setState(() {
        _dayError   = 'Network error.';
        _loadingDay = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────
  //  RSVP toggle (optimistic)
  //  POST/DELETE /api/v1/events/<uuid>/rsvp/
  // ─────────────────────────────────────────────────────────
  Future<void> _toggleRsvp(_CalEvent ev) async {
    final wasGoing = ev.isRsvped;
    _mutateDayEvent(ev.id, isRsvped: !wasGoing,
        attendingDelta: wasGoing ? -1 : 1);

    final ok = await apiToggleRsvp(ev.id, wasGoing: wasGoing);
    if (!ok) {
      _mutateDayEvent(ev.id, isRsvped: wasGoing,
          attendingDelta: wasGoing ? 1 : -1);
      showSnack('Could not update RSVP. Please try again.');
    } else {
      showSnack(!wasGoing
          ? "✅ You're going to ${ev.name}!"
          : 'RSVP cancelled', bg: ev.catColor);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  Reminder toggle
  //  POST/DELETE /api/v1/events/reminders/
  // ─────────────────────────────────────────────────────────
  Future<void> _toggleReminder(_CalEvent ev) async {
    final hadReminder = ev.hasReminder;
    _mutateDayEvent(ev.id, hasReminder: !hadReminder);

    final ok = hadReminder
        ? await apiDeleteReminder(ev.id)
        : await apiAddReminder(ev.id);

    if (!ok) {
      _mutateDayEvent(ev.id, hasReminder: hadReminder);
      showSnack('Could not update reminder.');
    } else {
      showSnack(hadReminder ? 'Reminder removed.' : '🔔 Reminder set!');
    }
  }

  void _mutateDayEvent(String id, {
    bool? isRsvped, bool? isSaved, bool? hasReminder, int attendingDelta = 0,
  }) {
    if (!mounted) return;
    setState(() {
      _dayEvents = _dayEvents.map((e) => e.id == id
          ? e.copyWith(
              isRsvped:       isRsvped,
              isSaved:        isSaved,
              hasReminder:    hasReminder,
              attendingCount: e.attendingCount + attendingDelta)
          : e).toList();
    });
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
        title: const Text('Event Calendar', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w800, color: EBColors.text)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: EBColors.brandPale,
              borderRadius: BorderRadius.circular(11)),
            child: const Text('🗂', style: TextStyle(fontSize: 18))),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: EBColors.border, height: 1)),
      ),
      body: RefreshIndicator(
        color: EBColors.brand,
        onRefresh: () async {
          await _loadMonthEvents();
          await _loadDayEvents(_selectedDay);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Month header ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('February 2026', style: TextStyle(
                    fontSize: 18, fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700, color: EBColors.text)),
                  Row(children: [
                    _CalBtn('←'),
                    const SizedBox(width: 6),
                    _CalBtn('→'),
                  ]),
                ])),

            // ── Day-of-week headers ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: ['S','M','T','W','T','F','S'].map((d) =>
                  Expanded(child: Center(child: Text(d, style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: EBColors.text3))))).toList())),

            // ── Calendar grid ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: GridView.count(
                crossAxisCount: 7, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 3, crossAxisSpacing: 3,
                childAspectRatio: 1.0,
                children: List.generate(28, (i) {
                  final day     = i + 1;
                  final isToday = day == _today;
                  final isSel   = day == _selectedDay && !isToday;
                  final hasEvent= _eventDays.contains(day);
                  final isPast  = day < _today;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDay = day);
                      _loadDayEvents(day);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isToday  ? EBColors.brand
                             : isSel    ? EBColors.brandPale
                             : Colors.transparent,
                        borderRadius: BorderRadius.circular(9)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$day', style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: isToday  ? Colors.white
                                 : isPast   ? EBColors.text3
                                 : isSel    ? EBColors.brand
                                 : EBColors.text2)),
                          if (hasEvent)
                            Container(
                              width: 4, height: 4,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isToday
                                  ? Colors.white.withOpacity(0.7)
                                  : EBColors.brandLight)),
                        ]),
                    ),
                  );
                }),
              )),

            // ── Selected day strip ───────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: EBColors.brandPale,
                borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_dayLabel(_selectedDay), style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800,
                    color: EBColors.brand)),
                  _loadingDay
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: EBColors.brand))
                    : Text(
                        '${_dayEvents.length} event${_dayEvents.length != 1 ? "s" : ""}',
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: EBColors.brand)),
                ])),

            // ── Events for selected day ──────────────────
            if (_loadingDay)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()))
            else if (_dayError != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Text(_dayError!, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: EBColors.text3)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _loadDayEvents(_selectedDay),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry')),
                ]))
            else if (_dayEvents.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                decoration: EBTheme.cardSm,
                child: Column(
                  children: _dayEvents.map((ev) => _CalEventRow(
                    event: ev,
                    // RSVP  — POST/DELETE /api/v1/events/<uuid>/rsvp/
                    onRsvpTap: () => _toggleRsvp(ev),
                    // Reminder — POST/DELETE /api/v1/events/reminders/
                    onReminderTap: () => _toggleReminder(ev),
                  )).toList()))
            else
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                child: Center(child: Text('No events this day',
                  style: TextStyle(fontSize: 13, color: EBColors.text3)))),

            // ── Week strip ───────────────────────────────
            EBSectionLabel(title: '📅 This Week'),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _weekDays.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final d     = _weekDays[i];
                  final hasEv = _eventDays.contains(d);
                  final isSel = d == _selectedDay;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDay = d);
                      _loadDayEvents(d);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 52,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSel ? EBColors.brandPale : EBColors.surface3,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSel
                            ? EBColors.brandLight
                            : Colors.transparent,
                          width: 1.5)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_weekLabels[i], style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w800,
                            color: isSel ? EBColors.brand : EBColors.text3)),
                          Text('$d', style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900,
                            color: isSel ? EBColors.brand : EBColors.text2)),
                          if (hasEv)
                            Container(
                              width: 6, height: 6,
                              margin: const EdgeInsets.only(top: 3),
                              decoration: BoxDecoration(
                                color: isSel
                                  ? EBColors.brand
                                  : EBColors.brandLight,
                                shape: BoxShape.circle)),
                        ])));
                })),

            const SizedBox(height: 30),
          ])),
      ),
    );
  }

  String _dayLabel(int d) {
    const labels = {
      17: 'Monday, Feb 17',    18: 'Tuesday, Feb 18',
      19: 'Wednesday, Feb 19', 20: 'Thursday, Feb 20',
      21: 'Friday, Feb 21',    22: 'Saturday, Feb 22',
    };
    return labels[d] ?? 'February $d, 2026';
  }
}

// ═════════════════════════════════════════════════════════════
//  SCREEN 2 — MY RSVPs
//  GET    /api/v1/events/?rsvped=true   → my RSVP'd events
//  POST   /api/v1/events/<uuid>/rsvp/   → restore RSVP
//  DELETE /api/v1/events/<uuid>/rsvp/   → cancel RSVP
// ═════════════════════════════════════════════════════════════
class EBRsvpScreen extends StatefulWidget {
  /// Optional event UUID — if provided, show that event's hero at the top.
  final String? eventId;
  const EBRsvpScreen({super.key, this.eventId});
  @override
  State<EBRsvpScreen> createState() => _EBRsvpScreenState();
}

class _EBRsvpScreenState extends State<EBRsvpScreen>
    with _EventActions<EBRsvpScreen> {

  List<_CalEvent> _rsvps       = [];
  _CalEvent?      _heroEvent;
  bool            _loading     = true;
  String?         _error;

  @override
  void initState() {
    super.initState();
    _loadRsvps();
    if (widget.eventId != null) _loadHeroEvent(widget.eventId!);
  }

  // ─────────────────────────────────────────────────────────
  //  READ: GET /api/v1/events/?rsvped=true
  // ─────────────────────────────────────────────────────────
  Future<void> _loadRsvps() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient.get('/api/v1/events/?rsvped=true');
      dev.log('[RSVPs] GET /events?rsvped=true → ${res.statusCode}');
      dev.log('[RSVPs] body: ${res.body}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final raw = decoded is List
            ? decoded
            : (decoded['results'] as List?) ?? [];

        setState(() {
          _rsvps  = raw.whereType<Map<String, dynamic>>()
              .map(_CalEvent.fromJson).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error   = 'Could not load RSVPs (${res.statusCode}).';
          _loading = false;
        });
      }
    } catch (e, s) {
      dev.log('[RSVPs] error: $e', stackTrace: s);
      if (mounted) setState(() {
        _error   = 'Network error. Pull to refresh.';
        _loading = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────
  //  READ: GET /api/v1/events/<uuid>/  — hero event detail
  // ─────────────────────────────────────────────────────────
  Future<void> _loadHeroEvent(String id) async {
    try {
      final res = await ApiClient.get('/api/v1/events/$id/');
      dev.log('[RSVPs] GET /events/$id/ → ${res.statusCode}');
      if (!mounted || res.statusCode != 200) return;
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic> && mounted) {
        setState(() => _heroEvent = _CalEvent.fromJson(decoded));
      }
    } catch (e) {
      dev.log('[RSVPs] loadHeroEvent error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  RSVP toggle (cancel / restore)
  //  POST/DELETE /api/v1/events/<uuid>/rsvp/
  // ─────────────────────────────────────────────────────────
  Future<void> _toggleRsvp(_CalEvent ev) async {
    final wasGoing = ev.isRsvped;
    _mutate(ev.id, isRsvped: !wasGoing,
        attendingDelta: wasGoing ? -1 : 1);

    final ok = await apiToggleRsvp(ev.id, wasGoing: wasGoing);
    if (!ok) {
      _mutate(ev.id, isRsvped: wasGoing,
          attendingDelta: wasGoing ? 1 : -1);
      showSnack('Could not update RSVP. Please try again.');
    } else {
      showSnack(wasGoing ? 'RSVP cancelled for ${ev.name}' : 'RSVP restored!',
        bg: wasGoing ? Colors.grey : ev.catColor);
    }
  }

  void _mutate(String id, {bool? isRsvped, int attendingDelta = 0}) {
    if (!mounted) return;
    setState(() {
      _rsvps = _rsvps.map((e) => e.id == id
          ? e.copyWith(
              isRsvped: isRsvped,
              attendingCount: e.attendingCount + attendingDelta)
          : e).toList();
    });
  }

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final hero = _heroEvent ?? (_rsvps.isNotEmpty ? _rsvps.first : null);

    return Scaffold(
      backgroundColor: EBColors.surface2,
      appBar: AppBar(
        backgroundColor: EBColors.surface, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
            size: 18, color: EBColors.text),
          onPressed: () => Navigator.pop(context)),
        title: const Text('My RSVPs', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w800, color: EBColors.text)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: EBColors.border, height: 1)),
      ),
      body: RefreshIndicator(
        color: EBColors.brand,
        onRefresh: _loadRsvps,
        child: CustomScrollView(slivers: [

          // ── Hero banner ────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [EBColors.brand, EBColors.brandDark],
                  begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: Stack(children: [
                Center(child: Text(
                  hero != null && hero.category.contains('Sport') ? '⚽'
                    : hero != null && hero.category.contains('Cultural') ? '🎭'
                    : '🎓',
                  style: const TextStyle(fontSize: 80))),
                Positioned(bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent,
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
                            color: hero?.catColor ?? EBColors.brand,
                            borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            hero?.category.isNotEmpty == true
                              ? hero!.category : '📚 Academic',
                            style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w800,
                              color: Colors.white))),
                        const SizedBox(height: 6),
                        Text(
                          hero?.name ?? 'My Upcoming Events',
                          style: const TextStyle(
                            fontSize: 17, fontStyle: FontStyle.italic,
                            color: Colors.white, height: 1.3)),
                      ]))),
              ])),
          ),

          // ── Hero event detail row ──────────────────────
          if (hero != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: EBTheme.cardSm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('📅 ${hero.date}', style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: EBColors.text)),
                            Text(hero.meta, style: TextStyle(
                              fontSize: 11, color: EBColors.text3)),
                          ]),
                        // RSVP — POST/DELETE /api/v1/events/<uuid>/rsvp/
                        GestureDetector(
                          onTap: () => _toggleRsvp(hero),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: hero.isRsvped
                                ? EBColors.greenPale : EBColors.brandPale,
                              borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              hero.isRsvped ? '✅ Going' : 'RSVP →',
                              style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800,
                                color: hero.isRsvped
                                  ? EBColors.green : EBColors.brand)))),
                      ]),
                    const SizedBox(height: 10),
                    Text('${hero.attendingCount} people confirmed',
                      style: TextStyle(
                        fontSize: 12, color: EBColors.text3)),
                  ])),
            ),

          // ── RSVP list ─────────────────────────────────
          SliverToBoxAdapter(
            child: EBSectionLabel(
              title: _loading
                ? 'My RSVPs'
                : 'My RSVPs (${_rsvps.length} Upcoming)')),

          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator())))
          else if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Text(_error!, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: EBColors.text3)),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _loadRsvps,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry')),
                ])))
          else if (_rsvps.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text("You haven't RSVP'd to any events yet.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: EBColors.text3)))))
          else
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                decoration: EBTheme.cardSm,
                child: Column(
                  children: _rsvps.map((ev) => _RsvpRow(
                    event: ev,
                    // POST/DELETE /api/v1/events/<uuid>/rsvp/
                    onToggle: () => _toggleRsvp(ev),
                  )).toList()))),

          // ── Static attendee list ───────────────────────
          SliverToBoxAdapter(child: EBSectionLabel(title: 'Attendees')),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              decoration: EBTheme.cardSm,
              child: Column(children: [
                _AttendeeRow(emoji: '👩‍💻', name: 'Sarah K.',
                  sub: 'BSc CS',       color: EBColors.brandLight),
                Divider(color: EBColors.border, height: 1),
                _AttendeeRow(emoji: '👨‍🔬', name: 'James M.',
                  sub: 'BSc Mech Eng', color: EBColors.blue),
                Divider(color: EBColors.border, height: 1),
                _AttendeeRow(emoji: '👩‍🎓', name: 'Aisha O.',
                  sub: 'BSc Civil',    color: EBColors.pink),
                Divider(color: EBColors.border, height: 1),
                _AttendeeRow(emoji: '👨‍🏫', name: 'David L.',
                  sub: 'BA Econ',      color: EBColors.coral),
                Padding(
                  padding: const EdgeInsets.all(9),
                  child: Center(child: Text(
                    '+ ${hero != null ? (hero.attendingCount - 4).clamp(0, 9999) : 77} more attendees',
                    style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w700, color: EBColors.brand)))),
              ]))),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
//  SCREEN 3 — REMINDERS
//  GET    /api/v1/events/reminders/        → list reminders
//  POST   /api/v1/events/reminders/        → add reminder
//  DELETE /api/v1/events/reminders/        → remove reminder
//  PATCH  /api/v1/events/reminders/ (via preferences body) → update notification prefs
// ═════════════════════════════════════════════════════════════
class EBRemindersScreen extends StatefulWidget {
  const EBRemindersScreen({super.key});
  @override
  State<EBRemindersScreen> createState() => _EBRemindersScreenState();
}

class _EBRemindersScreenState extends State<EBRemindersScreen>
    with _EventActions<EBRemindersScreen> {

  List<_Reminder> _reminders    = [];
  List<_CalEvent> _rsvpEvents   = [];
  _Reminder?      _urgentReminder; // first reminder < 24h away
  bool            _loadingRem   = true;
  bool            _loadingRsvp  = true;
  String?         _error;

  // Notification preferences — toggled locally and PATCH'd to server
  bool _remind24h   = true;
  bool _remind1h    = true;
  bool _organiserUp = true;
  bool _nearby      = false;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _loadRsvpEvents();
  }

  // ─────────────────────────────────────────────────────────
  //  READ: GET /api/v1/events/reminders/
  // ─────────────────────────────────────────────────────────
  Future<void> _loadReminders() async {
    if (mounted) setState(() { _loadingRem = true; _error = null; });
    try {
      final res = await ApiClient.get('/api/v1/events/reminders/');
      dev.log('[Reminders] GET /reminders → ${res.statusCode}');
      dev.log('[Reminders] body: ${res.body}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final raw = decoded is List
            ? decoded
            : (decoded['results'] as List?) ?? [];

        final reminders = raw
            .whereType<Map<String, dynamic>>()
            .map(_Reminder.fromJson)
            .toList();

        setState(() {
          _reminders      = reminders;
          _loadingRem     = false;
          // First reminder is shown as the urgent banner
          _urgentReminder = reminders.isNotEmpty ? reminders.first : null;
        });
      } else {
        setState(() {
          _error      = 'Could not load reminders (${res.statusCode}).';
          _loadingRem = false;
        });
      }
    } catch (e, s) {
      dev.log('[Reminders] error: $e', stackTrace: s);
      if (mounted) setState(() {
        _error      = 'Network error.';
        _loadingRem = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────
  //  READ: GET /api/v1/events/?rsvped=true
  //  Reuse for "My RSVPs" list inside this screen
  // ─────────────────────────────────────────────────────────
  Future<void> _loadRsvpEvents() async {
    if (mounted) setState(() => _loadingRsvp = true);
    try {
      final res = await ApiClient.get('/api/v1/events/?rsvped=true');
      dev.log('[Reminders] GET /events?rsvped=true → ${res.statusCode}');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final raw = decoded is List
            ? decoded
            : (decoded['results'] as List?) ?? [];

        setState(() {
          _rsvpEvents  = raw.whereType<Map<String, dynamic>>()
              .map(_CalEvent.fromJson).toList();
          _loadingRsvp = false;
        });
      } else {
        setState(() => _loadingRsvp = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingRsvp = false);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  DELETE reminder
  //  DELETE /api/v1/events/reminders/  {eventId}
  // ─────────────────────────────────────────────────────────
  Future<void> _removeReminder(_Reminder r) async {
    // Optimistic remove
    setState(() => _reminders.remove(r));

    final ok = await apiDeleteReminder(r.eventId);
    if (!ok) {
      setState(() => _reminders.insert(0, r)); // revert
      showSnack('Could not remove reminder.');
    } else {
      showSnack('Reminder removed.');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  UPDATE: notification preferences
  //  PATCH /api/v1/events/reminders/
  // ─────────────────────────────────────────────────────────
  Future<void> _updatePref(String key, bool value) async {
    try {
      await ApiClient.patch('/api/v1/events/reminders/', body: {
        key: value,
      });
      dev.log('[Reminders] PATCH prefs $key=$value');
    } catch (e) {
      dev.log('[Reminders] pref update error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  RSVP cancel from this screen
  //  DELETE /api/v1/events/<uuid>/rsvp/
  // ─────────────────────────────────────────────────────────
  Future<void> _toggleRsvp(_CalEvent ev) async {
    final wasGoing = ev.isRsvped;
    setState(() {
      _rsvpEvents = _rsvpEvents.map((e) => e.id == ev.id
          ? e.copyWith(isRsvped: !wasGoing) : e).toList();
    });

    final ok = await apiToggleRsvp(ev.id, wasGoing: wasGoing);
    if (!ok) {
      setState(() {
        _rsvpEvents = _rsvpEvents.map((e) => e.id == ev.id
            ? e.copyWith(isRsvped: wasGoing) : e).toList();
      });
      showSnack('Could not update RSVP.');
    } else {
      showSnack(wasGoing
          ? 'RSVP cancelled for ${ev.name}' : 'RSVP restored!');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EBColors.surface2,
      appBar: AppBar(
        backgroundColor: EBColors.surface, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
            size: 18, color: EBColors.text),
          onPressed: () => Navigator.pop(context)),
        title: const Text('My RSVPs & Reminders', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w800, color: EBColors.text)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: EBColors.brandPale,
              borderRadius: BorderRadius.circular(11)),
            child: const Text('⚙️', style: TextStyle(fontSize: 18))),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: EBColors.border, height: 1)),
      ),
      body: RefreshIndicator(
        color: EBColors.brand,
        onRefresh: () async {
          await Future.wait([_loadReminders(), _loadRsvpEvents()]);
        },
        child: CustomScrollView(slivers: [

          // ── Urgent reminder banner ─────────────────────
          SliverToBoxAdapter(
            child: _loadingRem
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()))
              : _urgentReminder != null
                ? _UrgentBanner(
                    reminder: _urgentReminder!,
                    // DELETE /api/v1/events/reminders/
                    onDismiss: () => _removeReminder(_urgentReminder!))
                : _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [
                        Text(_error!, textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13, color: EBColors.text3)),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _loadReminders,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Retry')),
                      ]))
                  : const SizedBox.shrink(),
          ),

          // ── My RSVPs ───────────────────────────────────
          SliverToBoxAdapter(
            child: EBSectionLabel(
              title: _loadingRsvp
                ? 'My RSVPs'
                : 'My RSVPs (${_rsvpEvents.length} Upcoming)')),

          if (_loadingRsvp)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(
                  strokeWidth: 2))))
          else if (_rsvpEvents.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: EBTheme.cardSm,
                  child: Center(child: Text("No upcoming RSVPs.",
                    style: TextStyle(
                      fontSize: 13, color: EBColors.text3))))))
          else
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                decoration: EBTheme.cardSm,
                child: Column(
                  children: _rsvpEvents.map((ev) => _RsvpRow(
                    event: ev,
                    // POST/DELETE /api/v1/events/<uuid>/rsvp/
                    onToggle: () => _toggleRsvp(ev),
                  )).toList()))),

          // ── Notification settings ──────────────────────
          SliverToBoxAdapter(
            child: EBSectionLabel(title: 'Notification Settings')),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              decoration: EBTheme.cardSm,
              child: Column(children: [
                EBToggleRow(
                  label: '⏰ 24-hour reminders',
                  subtitle: 'Day before event starts',
                  value: _remind24h,
                  onChanged: (v) {
                    setState(() => _remind24h = v);
                    // PATCH /api/v1/events/reminders/
                    _updatePref('remind24h', v);
                  }),
                Divider(color: EBColors.border, height: 1),
                EBToggleRow(
                  label: '⏰ 1-hour reminders',
                  subtitle: '1 hour before event starts',
                  value: _remind1h,
                  onChanged: (v) {
                    setState(() => _remind1h = v);
                    _updatePref('remind1h', v);
                  }),
                Divider(color: EBColors.border, height: 1),
                EBToggleRow(
                  label: '📣 Organiser updates',
                  subtitle: 'When organiser sends an update',
                  value: _organiserUp,
                  onChanged: (v) {
                    setState(() => _organiserUp = v);
                    _updatePref('organiserUpdates', v);
                  }),
                Divider(color: EBColors.border, height: 1),
                EBToggleRow(
                  label: '🆕 New nearby events',
                  subtitle: 'Events within 1km of campus',
                  value: _nearby,
                  onChanged: (v) {
                    setState(() => _nearby = v);
                    _updatePref('nearbyEvents', v);
                  }),
              ]))),

          // ── Recent notifications feed ──────────────────
          SliverToBoxAdapter(
            child: EBSectionLabel(title: 'Recent Notifications')),
          SliverToBoxAdapter(
            child: Column(
              children: _reminders.isEmpty
                ? [Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(child: Text('No recent notifications.',
                      style: TextStyle(
                        fontSize: 13, color: EBColors.text3))))]
                : _reminders.map((r) => _NotifCard(
                    emoji:  '⏰',
                    bg:     EBColors.brandPale,
                    title:  'Reminder: ${r.eventName}',
                    sub:    r.reminderTime.isNotEmpty
                              ? '${r.reminderTime} reminder · ${r.meta}'
                              : r.meta,
                    unread: _reminders.indexOf(r) == 0,
                    // DELETE /api/v1/events/reminders/
                    onDismiss: () => _removeReminder(r),
                  )).toList())),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  URGENT REMINDER BANNER
// ─────────────────────────────────────────────────────────────
class _UrgentBanner extends StatelessWidget {
  final _Reminder reminder;
  final VoidCallback onDismiss;
  const _UrgentBanner({required this.reminder, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: EBColors.amber, width: 1.5),
        borderRadius: BorderRadius.circular(18)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('⏰', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Event in 24 hours!', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800,
              color: Color(0xFF92400E))),
            const SizedBox(height: 3),
            Text(reminder.eventName, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: EBColors.text)),
            const SizedBox(height: 2),
            Text(reminder.meta.isNotEmpty ? reminder.meta : reminder.reminderTime,
              style: TextStyle(fontSize: 11, color: EBColors.text2)),
            const SizedBox(height: 9),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: EBColors.amber,
                  borderRadius: BorderRadius.circular(9)),
                child: const Text('View Event', style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: Colors.white))),
              const SizedBox(width: 8),
              // Dismiss = DELETE /api/v1/events/reminders/
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF92400E).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(9)),
                  child: const Text('Dismiss', style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E))))),
            ]),
          ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  RSVP ROW  (used in both RSVP screen and Reminders screen)
// ─────────────────────────────────────────────────────────────
class _RsvpRow extends StatelessWidget {
  final _CalEvent event;
  final VoidCallback onToggle;
  const _RsvpRow({required this.event, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final Color goingBg  = event.isRsvped ? EBColors.greenPale  : EBColors.brandPale;
    final Color goingTxt = event.isRsvped ? EBColors.green      : EBColors.brand;
    final String dayLbl  = event.dayLabel.isNotEmpty ? event.dayLabel : 'EVT';
    final String dayNum  = event.day > 0 ? '${event.day}' : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(children: [
        // Colour stripe
        Container(
          width: 4,
          margin: const EdgeInsets.only(right: 11),
          decoration: BoxDecoration(
            color: event.stripe,
            borderRadius: BorderRadius.circular(2)),
          height: 50),
        // Day badge
        Container(
          width: 38,
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: goingBg,
            borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Text(dayLbl, style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w800,
              color: event.catColor)),
            Text(dayNum, style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w900,
              color: event.catColor)),
          ])),
        const SizedBox(width: 11),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.name, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800,
              color: EBColors.text)),
            const SizedBox(height: 2),
            Text('${event.time}${event.meta.isNotEmpty ? " · ${event.meta}" : ""}${event.hasReminder ? " · ⏰ Reminder set" : ""}',
              style: TextStyle(fontSize: 11, color: EBColors.text3)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: goingBg,
                borderRadius: BorderRadius.circular(7)),
              child: Text(
                event.isRsvped ? '✅ Going' : 'Not Going',
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w800,
                  color: goingTxt))),
          ])),
        // POST/DELETE /api/v1/events/<uuid>/rsvp/
        GestureDetector(
          onTap: onToggle,
          child: const Icon(Icons.more_vert,
            color: EBColors.text3, size: 20)),
      ]));
  }
}

// ─────────────────────────────────────────────────────────────
//  CALENDAR EVENT ROW
// ─────────────────────────────────────────────────────────────
class _CalEventRow extends StatelessWidget {
  final _CalEvent event;
  final VoidCallback onRsvpTap;
  final VoidCallback onReminderTap;
  const _CalEventRow({
    required this.event,
    required this.onRsvpTap,
    required this.onReminderTap,
  });

  @override
  Widget build(BuildContext context) {
    final attendingStr = event.isRsvped
        ? "You're going ✓"
        : '${event.attendingCount} attending';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 4, height: 60,
          margin: const EdgeInsets.only(right: 11),
          decoration: BoxDecoration(
            color: event.stripe,
            borderRadius: BorderRadius.circular(2))),
        SizedBox(
          width: 44,
          child: Text(event.time, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w800,
            color: EBColors.text3))),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.name, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800,
              color: EBColors.text)),
            const SizedBox(height: 2),
            Text(event.meta, style: TextStyle(
              fontSize: 11, color: EBColors.text3)),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: event.catColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(7)),
                child: Text(event.category, style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w800,
                  color: event.catColor))),
              const SizedBox(width: 8),
              Text(attendingStr, style: TextStyle(
                fontSize: 10, color: EBColors.text3)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              // RSVP — POST/DELETE /api/v1/events/<uuid>/rsvp/
              GestureDetector(
                onTap: onRsvpTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: event.isRsvped
                      ? EBColors.greenPale : EBColors.brandPale,
                    borderRadius: BorderRadius.circular(7)),
                  child: Text(
                    event.isRsvped ? '✅ Going' : 'RSVP →',
                    style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: event.isRsvped
                        ? EBColors.green : EBColors.brand)))),
              const SizedBox(width: 8),
              // Reminder — POST/DELETE /api/v1/events/reminders/
              GestureDetector(
                onTap: onReminderTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: event.hasReminder
                      ? EBColors.amberPale : EBColors.surface3,
                    borderRadius: BorderRadius.circular(7)),
                  child: Text(
                    event.hasReminder ? '🔔 On' : '🔔 Remind',
                    style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: event.hasReminder
                        ? EBColors.amber : EBColors.text3)))),
            ]),
          ])),
      ]));
  }
}

// ─────────────────────────────────────────────────────────────
//  ATTENDEE ROW
// ─────────────────────────────────────────────────────────────
class _AttendeeRow extends StatelessWidget {
  final String emoji, name, sub;
  final Color color;
  const _AttendeeRow({
    required this.emoji, required this.name,
    required this.sub,   required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.6)]),
            borderRadius: BorderRadius.circular(11)),
          child: Center(child: Text(emoji,
            style: const TextStyle(fontSize: 16)))),
        const SizedBox(width: 10),
        Expanded(child: Text(name, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: EBColors.text))),
        Text(sub, style: TextStyle(fontSize: 11, color: EBColors.text3)),
        const SizedBox(width: 8),
        Text('✓', style: TextStyle(fontSize: 16, color: EBColors.green)),
      ]));
  }
}

// ─────────────────────────────────────────────────────────────
//  NOTIFICATION CARD
// ─────────────────────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final String emoji, title, sub;
  final Color bg;
  final bool unread;
  final VoidCallback onDismiss;
  const _NotifCard({
    required this.emoji,   required this.bg,
    required this.title,   required this.sub,
    required this.unread,  required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: unread ? EBColors.brandXp : EBColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unread
            ? EBColors.brandLight.withOpacity(0.5)
            : EBColors.border)),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(emoji,
            style: const TextStyle(fontSize: 18)))),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(
              fontSize: 12,
              fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
              color: EBColors.text, height: 1.3)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(
              fontSize: 10, color: EBColors.text3)),
          ])),
        // DELETE /api/v1/events/reminders/
        GestureDetector(
          onTap: onDismiss,
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.close_rounded,
              size: 14, color: EBColors.text3))),
        if (unread)
          Container(
            width: 8, height: 8,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: EBColors.brand, shape: BoxShape.circle)),
      ]));
  }
}

// ─────────────────────────────────────────────────────────────
//  CALENDAR NAV BUTTON
// ─────────────────────────────────────────────────────────────
class _CalBtn extends StatelessWidget {
  final String label;
  const _CalBtn(this.label);

  @override
  Widget build(BuildContext context) => Container(
    width: 28, height: 28,
    decoration: BoxDecoration(
      color: EBColors.brandPale,
      borderRadius: BorderRadius.circular(8)),
    child: Center(child: Text(label, style: TextStyle(
      fontSize: 13, fontWeight: FontWeight.w800,
      color: EBColors.brand))));
}