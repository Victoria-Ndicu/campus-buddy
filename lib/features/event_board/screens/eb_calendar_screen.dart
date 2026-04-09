import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import '../models/eb_constants.dart';
import '../widgets/eb_widgets.dart';
import '../../../core/api_client.dart';

// ─────────────────────────────────────────────────────────────
//  API ENDPOINTS
//
//  GET  /api/v1/events/?month=YYYY-MM          → dot indicators
//  GET  /api/v1/events/?date=YYYY-MM-DD        → events for a day
//  GET  /api/v1/events/?from_date=YYYY-MM-DD&to_date=YYYY-MM-DD → range
//  POST /api/v1/events/<uuid>/rsvp/            → { status: "going"|"not_going" }
//  POST /api/v1/events/reminders/              → { event_id, remind_at }
//  DELETE /api/v1/events/reminders/            → { event_id }
//  POST /api/v1/events/<uuid>/save/            → toggle saved
//  DELETE /api/v1/events/<uuid>/save/          → toggle saved
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
//  FILTER TAG ENUM
// ─────────────────────────────────────────────────────────────
enum _CalFilter { none, thisWeek, thisMonth, thisWeekend }

extension _CalFilterLabel on _CalFilter {
  String get label {
    switch (this) {
      case _CalFilter.thisWeek:    return 'This Week';
      case _CalFilter.thisMonth:   return 'This Month';
      case _CalFilter.thisWeekend: return 'This Weekend';
      case _CalFilter.none:        return '';
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────────────────────
String _fmt12h(DateTime dt) {
  final h  = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final m  = dt.minute.toString().padLeft(2, '0');
  final ap = dt.hour >= 12 ? 'PM' : 'AM';
  return '$h:$m $ap';
}

String _fmtDateDisplay(DateTime dt) {
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}  ·  ${_fmt12h(dt)}';
}

String _toIsoDate(DateTime dt) {
  final y  = dt.year.toString().padLeft(4, '0');
  final m  = dt.month.toString().padLeft(2, '0');
  final d  = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

// ─────────────────────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────────────────────
class _CalEvent {
  final String   id;
  final String   name;
  final String   time;
  final String   date;
  final String   meta;
  final String   category;
  final Color    catColor;
  final DateTime? startDt;   // parsed DateTime for accurate grouping
  final int      attendingCount;
  final bool     isRsvped;
  final bool     isSaved;
  final bool     hasReminder;

  const _CalEvent({
    required this.id,
    required this.name,
    this.time           = '',
    this.date           = '',
    this.meta           = '',
    this.category       = '',
    this.catColor       = EBColors.brand,
    this.startDt,
    this.attendingCount = 0,
    this.isRsvped       = false,
    this.isSaved        = false,
    this.hasReminder    = false,
  });

  /// Day-of-month for the calendar grid (local time)
  int get day => startDt?.day ?? 0;

  _CalEvent copyWith({
    bool? isRsvped,
    bool? isSaved,
    bool? hasReminder,
    int?  attendingCount,
  }) => _CalEvent(
    id:             id,
    name:           name,
    time:           time,
    date:           date,
    meta:           meta,
    category:       category,
    catColor:       catColor,
    startDt:        startDt,
    attendingCount: attendingCount ?? this.attendingCount,
    isRsvped:       isRsvped       ?? this.isRsvped,
    isSaved:        isSaved        ?? this.isSaved,
    hasReminder:    hasReminder    ?? this.hasReminder,
  );

  static Color _colorFor(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('academic') || c.contains('tech')) return EBColors.blue;
    if (c.contains('sport'))                          return EBColors.green;
    if (c.contains('career'))                         return EBColors.amber;
    if (c.contains('cultural') || c.contains('arts')) return EBColors.pink;
    return EBColors.brand;
  }

  factory _CalEvent.fromJson(Map<String, dynamic> raw) {
    // Unwrap nested event if present
    final Map<String, dynamic> j =
        (raw['data'] is Map<String, dynamic>
            ? raw['data'] as Map<String, dynamic>
            : raw['event'] is Map<String, dynamic>
                ? raw['event'] as Map<String, dynamic>
                : raw);

    String str(String k) => j[k]?.toString() ?? '';

    bool boo(String k) {
      final v = j[k];
      if (v is bool)   return v;
      if (v is int)    return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
      return false;
    }

    int num_(String k) => (j[k] as num?)?.toInt() ?? 0;

    // ── Parse startAt (camelCase or snake_case) ──────────
    final startAtRaw = str('startAt').isNotEmpty
        ? str('startAt')
        : str('start_at');

    DateTime? dt;
    try {
      if (startAtRaw.isNotEmpty) dt = DateTime.parse(startAtRaw).toLocal();
    } catch (_) {}

    final parsedTime = dt != null ? _fmt12h(dt)         : str('time');
    final parsedDate = dt != null ? _fmtDateDisplay(dt) : str('date');

    // ── RSVP ─────────────────────────────────────────────
    final userRsvp = str('userRsvp');
    final isRsvped = userRsvp == 'going' || userRsvp == 'waitlist' || boo('isRsvped');

    // ── Attending count ───────────────────────────────────
    final attending = num_('rsvpCount') != 0
        ? num_('rsvpCount')
        : num_('rsvp_count') != 0
            ? num_('rsvp_count')
            : num_('attendingCount');

    final catStr = str('category');

    return _CalEvent(
      id:             str('id'),
      name:           str('title').isNotEmpty ? str('title') : str('name'),
      time:           parsedTime,
      date:           parsedDate,
      meta:           str('location').isNotEmpty ? str('location') : str('meta'),
      category:       catStr,
      catColor:       _CalEvent._colorFor(catStr),
      startDt:        dt,
      attendingCount: attending,
      isRsvped:       isRsvped,
      isSaved:        boo('isSaved'),
      hasReminder:    boo('hasReminder'),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  API ACTIONS MIXIN
// ─────────────────────────────────────────────────────────────
mixin _EventActions<T extends StatefulWidget> on State<T> {

  Future<bool> apiToggleRsvp(String id, {required bool wasGoing}) async {
    try {
      final res = await ApiClient.post(
        '/api/v1/events/$id/rsvp/',
        body: {'status': wasGoing ? 'not_going' : 'going'},
      );
      dev.log('[Cal] RSVP $id → ${res.statusCode}');
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      dev.log('[Cal] RSVP error: $e');
      return false;
    }
  }

  Future<bool> apiToggleSave(String id, {required bool wasSaved}) async {
    try {
      final res = wasSaved
          ? await ApiClient.delete('/api/v1/events/$id/save/')
          : await ApiClient.post  ('/api/v1/events/$id/save/');
      dev.log('[Cal] Save $id → ${res.statusCode}');
      return res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204;
    } catch (e) {
      dev.log('[Cal] Save error: $e');
      return false;
    }
  }

  Future<bool> apiAddReminder(String id, {DateTime? remindAt}) async {
    try {
      final at = (remindAt ?? DateTime.now().add(const Duration(hours: 24)))
          .toUtc()
          .toIso8601String();
      final res = await ApiClient.post(
        '/api/v1/events/reminders/',
        body: {'event_id': id, 'remind_at': at},
      );
      dev.log('[Cal] AddReminder $id → ${res.statusCode}');
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      dev.log('[Cal] AddReminder error: $e');
      return false;
    }
  }

  Future<bool> apiDeleteReminder(String id) async {
    try {
      final res = await ApiClient.delete(
        '/api/v1/events/reminders/',
        body: {'event_id': id},
      );
      dev.log('[Cal] DelReminder $id → ${res.statusCode}');
      return res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204;
    } catch (e) {
      dev.log('[Cal] DelReminder error: $e');
      return false;
    }
  }

  void showSnack(String msg, {Color? bg}) {
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
}

// ═════════════════════════════════════════════════════════════
//  CALENDAR SCREEN
// ═════════════════════════════════════════════════════════════
class EBCalendarScreen extends StatefulWidget {
  const EBCalendarScreen({super.key});

  @override
  State<EBCalendarScreen> createState() => _EBCalendarScreenState();
}

class _EBCalendarScreenState extends State<EBCalendarScreen>
    with _EventActions<EBCalendarScreen> {

  late DateTime _displayMonth;
  late DateTime _today;
  late DateTime _selectedDate; // full DateTime for precise matching

  // Map of "YYYY-MM-DD" → list of events (cache per day)
  final Map<String, List<_CalEvent>> _eventCache = {};

  // Days in the current display month that have events
  Set<int> _eventDays = {};

  List<_CalEvent> _dayEvents  = [];
  bool            _loadingDay = false;
  String?         _dayError;

  _CalFilter _activeFilter = _CalFilter.none;

  // ── Filter result state ──────────────────────────────────
  List<_CalEvent> _filterEvents  = [];
  bool            _loadingFilter = false;
  String?         _filterError;

  // ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _today        = DateTime.now();
    _displayMonth = DateTime(_today.year, _today.month, 1);
    _selectedDate = DateTime(_today.year, _today.month, _today.day);
    _loadMonthDots();
    _loadDayEvents(_selectedDate);
  }

  // ─────────────────────────────────────────────────────────
  //  MONTH NAVIGATION
  // ─────────────────────────────────────────────────────────
  void _changeMonth(int delta) {
    final next = DateTime(
        _displayMonth.year, _displayMonth.month + delta, 1);
    // Set selected date to 1st of new month, or today if current month
    final newSel = (next.year == _today.year && next.month == _today.month)
        ? DateTime(_today.year, _today.month, _today.day)
        : DateTime(next.year, next.month, 1);

    setState(() {
      _displayMonth  = next;
      _selectedDate  = newSel;
      _eventDays     = {};
      _dayEvents     = [];
      _dayError      = null;
      _activeFilter  = _CalFilter.none;
      _filterEvents  = [];
      _filterError   = null;
    });
    _loadMonthDots();
    _loadDayEvents(newSel);
  }

  // ─────────────────────────────────────────────────────────
  //  DATE SELECTION — updates selected date and loads events
  // ─────────────────────────────────────────────────────────
  void _selectDate(int day) {
    final date = DateTime(_displayMonth.year, _displayMonth.month, day);
    setState(() {
      _selectedDate = date;
      _activeFilter = _CalFilter.none;
      _filterEvents = [];
      _filterError  = null;
    });
    _loadDayEvents(date);
  }

  // ─────────────────────────────────────────────────────────
  //  GET /api/v1/events/?month=YYYY-MM
  //  Populates dot markers for the whole month.
  // ─────────────────────────────────────────────────────────
  Future<void> _loadMonthDots() async {
    final monthStr =
        '${_displayMonth.year}-${_displayMonth.month.toString().padLeft(2, '0')}';
    try {
      final res = await ApiClient.get('/api/v1/events/?month=$monthStr');
      dev.log('[Cal] GET /events?month=$monthStr → ${res.statusCode}');
      if (!mounted || res.statusCode != 200) return;

      final decoded = jsonDecode(res.body);
      final raw = decoded is List
          ? decoded as List
          : (decoded['results'] as List?) ?? [];

      final days = raw
          .whereType<Map<String, dynamic>>()
          .map((j) => _CalEvent.fromJson(j))
          .where((e) =>
              e.startDt != null &&
              e.startDt!.year  == _displayMonth.year &&
              e.startDt!.month == _displayMonth.month)
          .map((e) => e.startDt!.day)
          .toSet();

      if (mounted) setState(() => _eventDays = days);
    } catch (e) {
      dev.log('[Cal] loadMonthDots error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  GET /api/v1/events/?date=YYYY-MM-DD
  //  Loads events for a specific DateTime (uses cache).
  // ─────────────────────────────────────────────────────────
  Future<void> _loadDayEvents(DateTime date) async {
    if (!mounted) return;

    final dateKey = _toIsoDate(date);

    // Serve from cache if available
    if (_eventCache.containsKey(dateKey)) {
      setState(() {
        _dayEvents  = _eventCache[dateKey]!;
        _loadingDay = false;
        _dayError   = null;
      });
      return;
    }

    setState(() { _loadingDay = true; _dayError = null; });

    try {
      final res = await ApiClient.get('/api/v1/events/?date=$dateKey');
      dev.log('[Cal] GET /events?date=$dateKey → ${res.statusCode}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final raw = decoded is List
            ? decoded as List
            : (decoded['results'] as List?) ?? [];

        final events = raw
            .whereType<Map<String, dynamic>>()
            .map(_CalEvent.fromJson)
            .where((e) {
              // Double-check: only events matching this exact local date
              if (e.startDt == null) return true; // include if no date info
              return e.startDt!.year  == date.year  &&
                     e.startDt!.month == date.month &&
                     e.startDt!.day   == date.day;
            })
            .toList()
          ..sort((a, b) {
            if (a.startDt == null) return 1;
            if (b.startDt == null) return -1;
            return a.startDt!.compareTo(b.startDt!);
          });

        // Cache the result
        _eventCache[dateKey] = events;

        if (mounted) {
          setState(() {
            _dayEvents  = events;
            _loadingDay = false;
            if (events.isNotEmpty) _eventDays.add(date.day);
          });
        }
      } else {
        if (mounted) setState(() {
          _dayError   = 'Could not load events (${res.statusCode}).';
          _loadingDay = false;
        });
      }
    } catch (e, s) {
      dev.log('[Cal] loadDayEvents error: $e', stackTrace: s);
      if (mounted) setState(() {
        _dayError   = 'Network error. Please try again.';
        _loadingDay = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────
  //  FILTER: This Week / This Month / This Weekend
  //  GET /api/v1/events/?from_date=...&to_date=...
  // ─────────────────────────────────────────────────────────
  Future<void> _applyFilter(_CalFilter filter) async {
    if (_activeFilter == filter) {
      // Toggle off
      setState(() {
        _activeFilter = _CalFilter.none;
        _filterEvents = [];
        _filterError  = null;
      });
      return;
    }

    setState(() {
      _activeFilter  = filter;
      _loadingFilter = true;
      _filterError   = null;
      _filterEvents  = [];
    });

    late DateTime from;
    late DateTime to;
    final now = _today;

    switch (filter) {
      case _CalFilter.thisWeek:
        // Monday → Sunday of the current ISO week
        final weekday = now.weekday; // 1=Mon, 7=Sun
        from = DateTime(now.year, now.month, now.day - (weekday - 1));
        to   = from.add(const Duration(days: 6));
        break;

      case _CalFilter.thisMonth:
        from = DateTime(now.year, now.month, 1);
        to   = DateTime(now.year, now.month + 1, 0); // last day of month
        break;

      case _CalFilter.thisWeekend:
        // Next or current Saturday & Sunday
        final daysToSat = (6 - now.weekday + 7) % 7;
        final sat = DateTime(now.year, now.month, now.day + daysToSat);
        from = sat;
        to   = sat.add(const Duration(days: 1)); // Sat + Sun
        break;

      case _CalFilter.none:
        return;
    }

    final fromStr = _toIsoDate(from);
    final toStr   = _toIsoDate(to);

    try {
      final res = await ApiClient.get(
          '/api/v1/events/?from_date=${fromStr}T00:00:00Z&to_date=${toStr}T23:59:59Z');
      dev.log('[Cal] GET /events?from=$fromStr&to=$toStr → ${res.statusCode}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final raw = decoded is List
            ? decoded as List
            : (decoded['results'] as List?) ?? [];

        final events = raw
            .whereType<Map<String, dynamic>>()
            .map(_CalEvent.fromJson)
            .toList()
          ..sort((a, b) {
            if (a.startDt == null) return 1;
            if (b.startDt == null) return -1;
            return a.startDt!.compareTo(b.startDt!);
          });

        setState(() {
          _filterEvents  = events;
          _loadingFilter = false;
        });
      } else {
        setState(() {
          _filterError   = 'Could not load events (${res.statusCode}).';
          _loadingFilter = false;
        });
      }
    } catch (e) {
      dev.log('[Cal] filter error: $e');
      if (mounted) setState(() {
        _filterError   = 'Network error. Please try again.';
        _loadingFilter = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────
  //  OPTIMISTIC MUTATIONS
  // ─────────────────────────────────────────────────────────
  Future<void> _toggleRsvp(_CalEvent ev, {bool fromFilter = false}) async {
    final wasGoing = ev.isRsvped;
    _mutate(ev.id, isRsvped: !wasGoing,
        attendingDelta: wasGoing ? -1 : 1, fromFilter: fromFilter);
    final ok = await apiToggleRsvp(ev.id, wasGoing: wasGoing);
    if (!ok) {
      _mutate(ev.id, isRsvped: wasGoing,
          attendingDelta: wasGoing ? 1 : -1, fromFilter: fromFilter);
      showSnack('Could not update RSVP. Please try again.');
    } else {
      showSnack(
        wasGoing ? 'RSVP cancelled' : "✅ You're going to ${ev.name}!",
        bg: ev.catColor,
      );
    }
  }

  Future<void> _toggleReminder(_CalEvent ev, {bool fromFilter = false}) async {
    final had = ev.hasReminder;
    _mutate(ev.id, hasReminder: !had, fromFilter: fromFilter);
    final ok = had
        ? await apiDeleteReminder(ev.id)
        : await apiAddReminder(ev.id);
    if (!ok) {
      _mutate(ev.id, hasReminder: had, fromFilter: fromFilter);
      showSnack('Could not update reminder.');
    } else {
      showSnack(had ? 'Reminder removed.' : '🔔 Reminder set!');
    }
  }

  Future<void> _toggleSave(_CalEvent ev, {bool fromFilter = false}) async {
    final wasSaved = ev.isSaved;
    _mutate(ev.id, isSaved: !wasSaved, fromFilter: fromFilter);
    final ok = await apiToggleSave(ev.id, wasSaved: wasSaved);
    if (!ok) {
      _mutate(ev.id, isSaved: wasSaved, fromFilter: fromFilter);
      showSnack('Could not save event.');
    } else {
      showSnack(wasSaved ? 'Event unsaved.' : '❤️ Event saved!');
    }
  }

  void _mutate(String id, {
    bool? isRsvped,
    bool? isSaved,
    bool? hasReminder,
    int   attendingDelta = 0,
    bool  fromFilter     = false,
  }) {
    if (!mounted) return;

    _CalEvent patch(_CalEvent e) => e.id == id
        ? e.copyWith(
            isRsvped:       isRsvped,
            isSaved:        isSaved,
            hasReminder:    hasReminder,
            attendingCount: e.attendingCount + attendingDelta)
        : e;

    setState(() {
      if (fromFilter) {
        _filterEvents = _filterEvents.map(patch).toList();
      } else {
        _dayEvents = _dayEvents.map(patch).toList();
        // Also update cache
        final key = _toIsoDate(_selectedDate);
        if (_eventCache.containsKey(key)) {
          _eventCache[key] = _eventCache[key]!.map(patch).toList();
        }
      }
    });
  }

  // ─────────────────────────────────────────────────────────
  //  DATE HELPERS
  // ─────────────────────────────────────────────────────────
  int get _daysInMonth =>
      DateUtils.getDaysInMonth(_displayMonth.year, _displayMonth.month);

  /// Sunday-based offset (0 = Sun column)
  int get _firstWeekdayOffset {
    final wd = DateTime(_displayMonth.year, _displayMonth.month, 1).weekday;
    return wd % 7;
  }

  bool _isToday(int day) =>
      _displayMonth.year  == _today.year  &&
      _displayMonth.month == _today.month &&
      day                 == _today.day;

  bool _isSelected(int day) =>
      _displayMonth.year  == _selectedDate.year  &&
      _displayMonth.month == _selectedDate.month &&
      day                 == _selectedDate.day;

  bool _isPastDay(int day) =>
      DateTime(_displayMonth.year, _displayMonth.month, day)
          .isBefore(DateTime(_today.year, _today.month, _today.day));

  bool _isUpcoming(int day) =>
      !_isPastDay(day) && !_isToday(day);

  /// 7-day strip starting from today (or from 1st of displayed month)
  List<DateTime> get _weekStrip {
    final base = (_displayMonth.year == _today.year &&
                  _displayMonth.month == _today.month)
        ? _today
        : DateTime(_displayMonth.year, _displayMonth.month, 1);
    return List.generate(7, (i) =>
        DateTime(base.year, base.month, base.day + i));
  }

  String _monthLabel() {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December',
    ];
    return '${months[_displayMonth.month - 1]} ${_displayMonth.year}';
  }

  String _dayLabel(DateTime date) {
    const weekdays = [
      'Monday','Tuesday','Wednesday','Thursday',
      'Friday','Saturday','Sunday',
    ];
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _shortWeekday(DateTime dt) {
    const labels = ['MON','TUE','WED','THU','FRI','SAT','SUN'];
    return labels[dt.weekday - 1];
  }

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // When a filter is active, show filter results instead of day events
    final showingFilter = _activeFilter != _CalFilter.none;

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
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: EBColors.text)),
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
          _eventCache.clear();
          await _loadMonthDots();
          await _loadDayEvents(_selectedDate);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Month header + nav ───────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_monthLabel(), style: const TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                        color: EBColors.text)),
                    Row(children: [
                      _NavBtn(label: '←', onTap: () => _changeMonth(-1)),
                      const SizedBox(width: 6),
                      _NavBtn(label: '→', onTap: () => _changeMonth(1)),
                    ]),
                  ])),

              // ── Filter tags row ──────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    _CalFilterTag(
                      label:    'This Week',
                      active:   _activeFilter == _CalFilter.thisWeek,
                      onTap:    () => _applyFilter(_CalFilter.thisWeek),
                      icon:     '📆',
                    ),
                    const SizedBox(width: 8),
                    _CalFilterTag(
                      label:    'This Month',
                      active:   _activeFilter == _CalFilter.thisMonth,
                      onTap:    () => _applyFilter(_CalFilter.thisMonth),
                      icon:     '🗓',
                    ),
                    const SizedBox(width: 8),
                    _CalFilterTag(
                      label:    'Weekend',
                      active:   _activeFilter == _CalFilter.thisWeekend,
                      onTap:    () => _applyFilter(_CalFilter.thisWeekend),
                      icon:     '🎉',
                    ),
                  ])),

              // ── Day-of-week headers ──────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: ['S','M','T','W','T','F','S']
                      .map((d) => Expanded(
                          child: Center(child: Text(d, style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: EBColors.text3)))))
                      .toList())),

              // ── Calendar grid ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap:     true,
                  physics:        const NeverScrollableScrollPhysics(),
                  mainAxisSpacing:  3,
                  crossAxisSpacing: 3,
                  childAspectRatio: 1.0,
                  children: [
                    // Empty offset cells
                    ...List.generate(
                        _firstWeekdayOffset,
                        (_) => const SizedBox.shrink()),

                    // Day cells
                    ...List.generate(_daysInMonth, (i) {
                      final day      = i + 1;
                      final isToday  = _isToday(day);
                      final isSel    = _isSelected(day) && !isToday;
                      final hasEv    = _eventDays.contains(day);
                      final isPast   = _isPastDay(day);
                      final upcoming = _isUpcoming(day);

                      return GestureDetector(
                        onTap: () => _selectDate(day),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isToday ? EBColors.brand
                                 : isSel   ? EBColors.brandPale
                                 : Colors.transparent,
                            borderRadius: BorderRadius.circular(9)),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('$day', style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isToday ? Colors.white
                                         : isPast  ? EBColors.text3
                                         : isSel   ? EBColors.brand
                                         : EBColors.text2)),

                                  // Dot marker for dates with events
                                  if (hasEv)
                                    Container(
                                      width: 4, height: 4,
                                      margin: const EdgeInsets.only(top: 2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isToday
                                            ? Colors.white.withOpacity(0.9)
                                            : upcoming
                                                ? EBColors.brand
                                                : EBColors.brandLight)),
                                ]),

                              // Upcoming ring: subtle border for future event days
                              if (hasEv && upcoming && !isToday && !isSel)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                        color: EBColors.brandLight,
                                        width: 1.2))),
                            ])));
                    }),
                  ])),

              // ── Selected day label ───────────────────────
              if (!showingFilter)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                      color: EBColors.brandPale,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_dayLabel(_selectedDate), style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: EBColors.brand)),
                      _loadingDay
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: EBColors.brand))
                          : Text(
                              '${_dayEvents.length} event${_dayEvents.length != 1 ? "s" : ""}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: EBColors.brand)),
                    ])),

              // ── Filter header ────────────────────────────
              if (showingFilter)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                      color: EBColors.brandPale,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _activeFilter.label,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: EBColors.brand)),
                      _loadingFilter
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: EBColors.brand))
                          : Text(
                              '${_filterEvents.length} event${_filterEvents.length != 1 ? "s" : ""}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: EBColors.brand)),
                    ])),

              // ── Day event list ───────────────────────────
              if (!showingFilter) ...[
                if (_loadingDay)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator(
                        color: EBColors.brand)))

                else if (_dayError != null)
                  _ErrorRetry(
                    message: _dayError!,
                    onRetry: () => _loadDayEvents(_selectedDate))

                else if (_dayEvents.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    decoration: EBTheme.cardSm,
                    child: Column(
                      children: _dayEvents.map((ev) => _CalEventRow(
                        event:         ev,
                        onRsvpTap:     () => _toggleRsvp(ev),
                        onReminderTap: () => _toggleReminder(ev),
                        onSaveTap:     () => _toggleSave(ev),
                      )).toList()))

                else
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(
                        'No events on ${_dayLabel(_selectedDate)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, color: EBColors.text3)))),
              ],

              // ── Filter event list ────────────────────────
              if (showingFilter) ...[
                if (_loadingFilter)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator(
                        color: EBColors.brand)))

                else if (_filterError != null)
                  _ErrorRetry(
                    message: _filterError!,
                    onRetry: () => _applyFilter(_activeFilter))

                else if (_filterEvents.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    decoration: EBTheme.cardSm,
                    child: Column(
                      children: _filterEvents.map((ev) => _CalEventRow(
                        event:         ev,
                        onRsvpTap:     () => _toggleRsvp(ev, fromFilter: true),
                        onReminderTap: () => _toggleReminder(ev, fromFilter: true),
                        onSaveTap:     () => _toggleSave(ev, fromFilter: true),
                        showDate: true, // show date label in filter view
                      )).toList()))

                else
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(
                        'No events for ${_activeFilter.label}',
                        style: const TextStyle(
                            fontSize: 13, color: EBColors.text3)))),
              ],

              // ── This-week horizontal strip ───────────────
              EBSectionLabel(title: '📅 This Week'),
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _weekStrip.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final dt    = _weekStrip[i];
                    final d     = dt.day;
                    final hasEv = dt.month == _displayMonth.month &&
                                  _eventDays.contains(d);
                    final isSel = dt.year  == _selectedDate.year  &&
                                  dt.month == _selectedDate.month &&
                                  d        == _selectedDate.day;
                    final isTdy = dt.year  == _today.year  &&
                                  dt.month == _today.month &&
                                  d        == _today.day;

                    return GestureDetector(
                      onTap: () {
                        // If strip day is in a different month, navigate there
                        if (dt.month != _displayMonth.month ||
                            dt.year  != _displayMonth.year) {
                          setState(() {
                            _displayMonth = DateTime(dt.year, dt.month, 1);
                            _eventDays    = {};
                            _dayEvents    = [];
                          });
                          _loadMonthDots();
                        }
                        setState(() {
                          _selectedDate = DateTime(dt.year, dt.month, d);
                          _activeFilter = _CalFilter.none;
                          _filterEvents = [];
                        });
                        _loadDayEvents(DateTime(dt.year, dt.month, d));
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 52,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isTdy
                              ? EBColors.brand.withOpacity(0.15)
                              : isSel
                                  ? EBColors.brandPale
                                  : EBColors.surface3,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel
                                ? EBColors.brandLight
                                : isTdy
                                    ? EBColors.brand.withOpacity(0.4)
                                    : Colors.transparent,
                            width: 1.5)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_shortWeekday(dt), style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isSel || isTdy
                                    ? EBColors.brand
                                    : EBColors.text3)),
                            Text('$d', style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isSel || isTdy
                                    ? EBColors.brand
                                    : EBColors.text2)),
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
            ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  FILTER TAG CHIP
// ─────────────────────────────────────────────────────────────
class _CalFilterTag extends StatelessWidget {
  final String       label;
  final bool         active;
  final VoidCallback onTap;
  final String       icon;

  const _CalFilterTag({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon = '',
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? EBColors.brand : EBColors.surface3,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? EBColors.brand : EBColors.border,
          width: 1.2)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon.isNotEmpty) ...[
            Text(icon, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: active ? Colors.white : EBColors.text2)),
        ])));
}

// ─────────────────────────────────────────────────────────────
//  CALENDAR EVENT ROW
// ─────────────────────────────────────────────────────────────
class _CalEventRow extends StatelessWidget {
  final _CalEvent    event;
  final VoidCallback onRsvpTap;
  final VoidCallback onReminderTap;
  final VoidCallback onSaveTap;
  final bool         showDate; // shows date in filter/range view

  const _CalEventRow({
    required this.event,
    required this.onRsvpTap,
    required this.onReminderTap,
    required this.onSaveTap,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context) {
    final attendingStr = event.isRsvped
        ? "You're going ✓"
        : '${event.attendingCount} attending';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colour stripe
          Container(
            width: 4, height: 60,
            margin: const EdgeInsets.only(right: 11, top: 2),
            decoration: BoxDecoration(
              color: event.catColor,
              borderRadius: BorderRadius.circular(2))),

          // Time column
          SizedBox(
            width: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.time, style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: EBColors.text3)),
                if (showDate && event.startDt != null)
                  Text(
                    '${event.startDt!.day}/${event.startDt!.month}',
                    style: TextStyle(fontSize: 10, color: EBColors.text3)),
              ])),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + save
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(event.name, style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: EBColors.text))),
                    GestureDetector(
                      onTap: onSaveTap,
                      child: Text(
                        event.isSaved ? '❤️' : '🤍',
                        style: const TextStyle(fontSize: 14))),
                  ]),
                const SizedBox(height: 2),
                Text(event.meta, style: TextStyle(
                    fontSize: 11, color: EBColors.text3)),
                const SizedBox(height: 4),

                // Category + attending
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: event.catColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(7)),
                    child: Text(event.category, style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: event.catColor))),
                  const SizedBox(width: 8),
                  Text(attendingStr, style: TextStyle(
                      fontSize: 10, color: EBColors.text3)),
                ]),
                const SizedBox(height: 6),

                // Action buttons
                Row(children: [
                  // RSVP
                  GestureDetector(
                    onTap: onRsvpTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: event.isRsvped
                            ? EBColors.greenPale
                            : EBColors.brandPale,
                        borderRadius: BorderRadius.circular(7)),
                      child: Text(
                        event.isRsvped ? '✅ Going' : 'RSVP →',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: event.isRsvped
                                ? EBColors.green
                                : EBColors.brand)))),
                  const SizedBox(width: 8),
                  // Reminder
                  GestureDetector(
                    onTap: onReminderTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: event.hasReminder
                            ? EBColors.amberPale
                            : EBColors.surface3,
                        borderRadius: BorderRadius.circular(7)),
                      child: Text(
                        event.hasReminder ? '🔔 On' : '🔔 Remind',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: event.hasReminder
                                ? EBColors.amber
                                : EBColors.text3)))),
                ]),
              ])),
        ]));
  }
}

// ─────────────────────────────────────────────────────────────
//  ERROR + RETRY WIDGET
// ─────────────────────────────────────────────────────────────
class _ErrorRetry extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(children: [
      Text(message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: EBColors.text3)),
      const SizedBox(height: 8),
      TextButton.icon(
          onPressed: onRetry,
          icon:  const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Retry')),
    ]));
}

// ─────────────────────────────────────────────────────────────
//  NAV BUTTON  (← →)
// ─────────────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final String       label;
  final VoidCallback onTap;
  const _NavBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: EBColors.brandPale,
        borderRadius: BorderRadius.circular(8)),
      child: Center(child: Text(label, style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: EBColors.brand)))));
}