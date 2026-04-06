// ============================================================
//  StudyBuddy — sb_groups_screen.dart   (FULLY FIXED v2)
//
//  Changes in this version:
//  ① Removed `package:intl/intl.dart` — no more build crash.
//     All date formatting is now handled by _DateFmt helpers.
//  ② Unified Date + Time picker: single bottom-sheet shows
//     a month-calendar (top) and an analogue-style clock
//     face (bottom) — no split dialogs, consistent UI.
//  ③ My Groups tab: IDs are now .trim()-normalised on both
//     sides and we fall back to re-fetching membership after
//     every join/leave so the set is always accurate.
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api_client.dart';
import '../models/sb_constants.dart';
import '../widgets/sb_widgets.dart';

// ─────────────────────────────────────────────────────────────
//  DATE FORMATTING  (replaces intl / DateFormat)
// ─────────────────────────────────────────────────────────────
class _DateFmt {
  static const _wd  = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  static const _mon = ['Jan','Feb','Mar','Apr','May','Jun',
                       'Jul','Aug','Sep','Oct','Nov','Dec'];
  static const _monFull = ['January','February','March','April','May','June',
                            'July','August','September','October','November','December'];

  /// "EEE, d MMM y  •  h:mm a"   e.g. "Tue, 6 May 2025  •  2:30 PM"
  static String sessionLong(DateTime dt) {
    final (h, m, ap) = _hma(dt);
    return '${_wd[dt.weekday-1]}, ${dt.day} ${_mon[dt.month-1]} ${dt.year}  •  $h:$m $ap';
  }

  /// "EEE, d MMM  •  h:mm a"
  static String sessionShort(DateTime dt) {
    final (h, m, ap) = _hma(dt);
    return '${_wd[dt.weekday-1]}, ${dt.day} ${_mon[dt.month-1]}  •  $h:$m $ap';
  }

  /// "h:mm a"
  static String timeOnly(DateTime dt) {
    final (h, m, ap) = _hma(dt);
    return '$h:$m $ap';
  }

  /// "d MMM  h:mm a"
  static String shortWithTime(DateTime dt) {
    final (h, m, ap) = _hma(dt);
    return '${dt.day} ${_mon[dt.month-1]}  $h:$m $ap';
  }

  /// "Month Year"  for calendar header
  static String monthYear(DateTime dt) =>
      '${_monFull[dt.month-1]} ${dt.year}';

  static (String, String, String) _hma(DateTime dt) {
    final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    return (
      h12.toString(),
      dt.minute.toString().padLeft(2, '0'),
      dt.hour >= 12 ? 'PM' : 'AM',
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EXTENSION
// ─────────────────────────────────────────────────────────────
extension _LetExt<T> on T {
  R let<R>(R Function(T) fn) => fn(this);
}

// ─────────────────────────────────────────────────────────────
//  HELPER — safely extract an id string
// ─────────────────────────────────────────────────────────────
String _extractId(dynamic value) {
  if (value == null) return '';
  if (value is Map) return (value['id'] ?? value['uuid'] ?? '').toString().trim();
  return value.toString().trim();
}

// ─────────────────────────────────────────────────────────────
//  CURRENT USER
// ─────────────────────────────────────────────────────────────
class _CurrentUser {
  static String? _cachedId;

  static const _prefKeys = [
    'current_user_id', 'user_id', 'userId',
    'auth_user_id', 'sb_user_id', 'uid',
  ];

  static Future<String?> getId() async {
    if (_cachedId != null) return _cachedId;
    final prefs = await SharedPreferences.getInstance();
    for (final key in _prefKeys) {
      final val = prefs.getString(key);
      if (val != null && val.isNotEmpty) {
        dev.log('[CurrentUser] found id under prefs key "$key": $val');
        _cachedId = val.trim();
        return _cachedId;
      }
    }
    for (final path in [
      '/api/v1/auth/me/',
      '/api/v1/users/me/',
      '/api/v1/profile/me/',
      '/api/v1/study-buddy/me/',
    ]) {
      try {
        final res = await ApiClient.get(path);
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          final id = (body['id'] ?? body['user_id'] ?? body['userId'] ?? body['uuid'])
              ?.toString()
              .trim();
          if (id != null && id.isNotEmpty) {
            dev.log('[CurrentUser] got id from $path: $id');
            _cachedId = id;
            await prefs.setString('current_user_id', id);
            return _cachedId;
          }
        }
      } catch (_) {}
    }
    dev.log('[CurrentUser] WARNING: could not resolve user id');
    return null;
  }

  static void clearCache() => _cachedId = null;
}

// ─────────────────────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────────────────────
class GroupMemberRow {
  final String membershipId;
  final String groupId;
  final String userId;
  final String userName;
  final String userDegree;
  final bool   isOnline;
  final bool   isAdmin;

  const GroupMemberRow({
    required this.membershipId,
    required this.groupId,
    required this.userId,
    required this.userName,
    required this.userDegree,
    required this.isOnline,
    required this.isAdmin,
  });

  factory GroupMemberRow.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];
    final String userId;
    String userName   = 'Member';
    String userDegree = '';

    if (userRaw is Map<String, dynamic>) {
      userId     = _extractId(userRaw['id'] ?? userRaw['uuid']);
      userName   = userRaw['full_name'] as String?
          ?? userRaw['name'] as String?
          ?? userRaw['username'] as String?
          ?? 'Member';
      userDegree = userRaw['degree'] as String? ?? userRaw['program'] as String? ?? '';
    } else {
      userId     = _extractId(json['user_id'] ?? json['userId']);
      userName   = json['full_name'] as String?
          ?? json['name'] as String?
          ?? 'Member';
      userDegree = json['degree'] as String? ?? json['program'] as String? ?? '';
    }

    final groupRaw = json['group'];
    final String groupId;
    if (groupRaw is Map<String, dynamic>) {
      groupId = _extractId(groupRaw['id'] ?? groupRaw['uuid']);
    } else {
      groupId = _extractId(json['group_id'] ?? json['groupId'] ?? groupRaw);
    }

    dev.log('[GroupMemberRow] parsed → userId=$userId groupId=$groupId name=$userName');
    return GroupMemberRow(
      membershipId: (json['id'] ?? '').toString().trim(),
      groupId:      groupId,
      userId:       userId,
      userName:     userName,
      userDegree:   userDegree,
      isOnline:     json['is_online'] as bool? ?? false,
      isAdmin:      json['is_admin'] as bool? ?? json['role'] == 'admin',
    );
  }
}

class GroupModel {
  final String  id;
  final String  name;
  final String  subject;
  final String  description;
  final int     memberCount;
  final int     maxMembers;
  final String  emoji;
  final String? creatorId;
  final bool    active;

  const GroupModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.description,
    required this.memberCount,
    required this.maxMembers,
    required this.emoji,
    this.creatorId,
    this.active = true,
  });

  static String _emojiForSubject(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math') || s.contains('calc')) return '📐';
    if (s.contains('cs') || s.contains('computer') || s.contains('algo')) return '💻';
    if (s.contains('chem')) return '⚗️';
    if (s.contains('phys')) return '🔭';
    if (s.contains('bio')) return '🧬';
    if (s.contains('econ') || s.contains('finance')) return '📊';
    return '📚';
  }

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }
    final creatorRaw = json['creatorId'] ?? json['creator_id'] ?? json['creator'];
    final creatorId  = creatorRaw is Map
        ? _extractId(creatorRaw['id'] ?? creatorRaw['uuid'])
        : creatorRaw?.toString().trim();

    final subject = json['subject'] as String? ?? '';
    return GroupModel(
      id:          (json['id']?.toString() ?? '').trim(),
      name:        json['name'] as String? ?? 'Study Group',
      subject:     subject,
      description: json['description'] as String? ?? '',
      memberCount: toInt(json['memberCount'] ?? json['member_count']),
      maxMembers:  toInt(json['maxMembers']  ?? json['max_members'])
          .let((v) => v > 0 ? v : 10),
      emoji:       _emojiForSubject(subject),
      creatorId:   creatorId,
      active:      json['active'] as bool? ?? true,
    );
  }

  bool get isFull => memberCount >= maxMembers;
}

class GroupSession {
  final String   id;
  final String   title;
  final String   description;
  final String   location;
  final DateTime scheduledAt;
  final int      durationMin;
  final String   proposedByName;
  final String   proposedById;

  const GroupSession({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.scheduledAt,
    required this.durationMin,
    required this.proposedByName,
    required this.proposedById,
  });

  factory GroupSession.fromJson(Map<String, dynamic> json) => GroupSession(
    id:             (json['id'] ?? '').toString(),
    title:          json['title'] as String? ?? 'Session',
    description:    json['description'] as String? ?? '',
    location:       json['location'] as String? ?? '',
    scheduledAt:    DateTime.tryParse(
        (json['scheduledAt'] ?? json['scheduled_at'] ?? '').toString())
        ?? DateTime.now().add(const Duration(hours: 1)),
    durationMin:    json['durationMin'] as int? ?? json['duration_min'] as int? ?? 60,
    proposedByName: json['proposedByName'] as String? ?? 'Member',
    proposedById:   (json['proposedById'] ?? json['proposed_by_id'] ?? '').toString(),
  );
}

class GroupMessage {
  final String   id;
  final String   authorId;
  final String   authorName;
  final String   body;
  final DateTime createdAt;

  const GroupMessage({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) => GroupMessage(
    id:         (json['id'] ?? '').toString(),
    authorId:   (json['authorId'] ?? json['author_id'] ?? '').toString(),
    authorName: json['authorName'] as String? ?? json['author_name'] as String? ?? 'Member',
    body:       json['body'] as String? ?? '',
    createdAt:  DateTime.tryParse(
        (json['createdAt'] ?? json['created_at'] ?? '').toString())
        ?? DateTime.now(),
  );
}

// ─────────────────────────────────────────────────────────────
//  API SERVICE
// ─────────────────────────────────────────────────────────────
class _GroupsApi {
  static const _base = '/api/v1/study-buddy';

  static Future<List<GroupModel>> fetchAllGroups() async {
    final List<dynamic> all = [];
    String? next = '$_base/groups/?page_size=100';

    while (next != null) {
      final res = await ApiClient.get(next);
      dev.log('[Groups] GET $next → ${res.statusCode}');
      if (res.statusCode != 200) throw Exception('Groups fetch failed (${res.statusCode})');

      final body = jsonDecode(res.body);
      if (body is List) {
        all.addAll(body);
        next = null;
      } else if (body is Map) {
        final results = body['results'] ?? body['data'];
        if (results is List) all.addAll(results);
        final n = body['next'];
        next = (n is String && n.isNotEmpty) ? n : null;
      } else {
        next = null;
      }
    }
    dev.log('[Groups] fetched ${all.length} groups total');
    return all.map((e) => GroupModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<GroupMemberRow>> fetchMembershipsForUser(String userId) async {
    for (final path in [
      '$_base/group-members/?user=$userId&page_size=200',
      '$_base/group-members/?user_id=$userId&page_size=200',
    ]) {
      try {
        final res = await ApiClient.get(path);
        dev.log('[Groups] user memberships GET $path → ${res.statusCode}');
        if (res.statusCode == 200) {
          final rows = _parseRows(jsonDecode(res.body));
          dev.log('[Groups] parsed ${rows.length} membership rows for user $userId');
          for (final r in rows) dev.log('[Groups]   → groupId=${r.groupId}');
          return rows;
        }
      } catch (e) {
        dev.log('[Groups] user membership error $path: $e');
      }
    }
    return [];
  }

  static Future<List<GroupMemberRow>> fetchMembershipsForGroup(String groupId) async {
    for (final path in [
      '$_base/group-members/?group=$groupId&page_size=200',
      '$_base/group-members/?group_id=$groupId&page_size=200',
      '$_base/groups/$groupId/members/?page_size=200',
    ]) {
      try {
        final res = await ApiClient.get(path);
        dev.log('[Groups] group members GET $path → ${res.statusCode}');
        if (res.statusCode == 200) {
          final rows = _parseRows(jsonDecode(res.body));
          dev.log('[Groups] parsed ${rows.length} members for group $groupId');
          return rows;
        }
      } catch (e) {
        dev.log('[Groups] group member error $path: $e');
      }
    }
    return [];
  }

  static List<GroupMemberRow> _parseRows(dynamic body) {
    List<dynamic> raw;
    if (body is List) {
      raw = body;
    } else if (body is Map) {
      raw = ((body['results'] ?? body['data'] ?? body['members']) as List? ?? []);
    } else {
      raw = [];
    }
    return raw.map((m) => GroupMemberRow.fromJson(m as Map<String, dynamic>)).toList();
  }

  static Future<_JoinResult> joinGroup(String id) async {
    final res = await ApiClient.post('$_base/groups/$id/join/');
    dev.log('[Groups] POST join $id → ${res.statusCode}: ${res.body}');
    if (res.statusCode == 200 || res.statusCode == 201) return _JoinResult.success;
    if (res.statusCode == 400 || res.statusCode == 409) {
      final body = res.body.toLowerCase();
      if (body.contains('full') || body.contains('max') ||
          body.contains('capacity') || body.contains('maximum')) {
        return _JoinResult.groupFull;
      }
      if (body.contains('already')) return _JoinResult.success;
    }
    throw Exception('Join failed (${res.statusCode}): ${res.body}');
  }

  static Future<void> leaveGroup(String id) async {
    final res = await ApiClient.post('$_base/groups/$id/leave/');
    dev.log('[Groups] POST leave $id → ${res.statusCode}');
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Leave failed (${res.statusCode})');
    }
  }

  static Future<void> createGroup(Map<String, dynamic> payload) async {
    final res = await ApiClient.post('$_base/groups/', body: payload);
    dev.log('[Groups] POST create → ${res.statusCode}: ${res.body}');
    if (res.statusCode != 201) throw Exception('Create failed (${res.statusCode}): ${res.body}');
  }

  static Future<void> deleteGroup(String id) async {
    final res = await ApiClient.delete('$_base/groups/$id/');
    dev.log('[Groups] DELETE $id → ${res.statusCode}');
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Delete failed (${res.statusCode})');
    }
  }

  static Future<List<GroupSession>> fetchSessions(String groupId) async {
    final res = await ApiClient.get('$_base/groups/$groupId/sessions/');
    dev.log('[Groups] sessions GET → ${res.statusCode}');
    if (res.statusCode != 200) return [];
    final body = jsonDecode(res.body);
    final List raw = body is Map
        ? ((body['data'] ?? body['results'] ?? []) as List)
        : (body as List? ?? []);
    return raw.map((e) => GroupSession.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<GroupSession> createSession(
      String groupId, Map<String, dynamic> payload) async {
    final res = await ApiClient.post('$_base/groups/$groupId/sessions/', body: payload);
    dev.log('[Groups] POST session → ${res.statusCode}: ${res.body}');
    if (res.statusCode != 201) {
      throw Exception('Create session failed (${res.statusCode}): ${res.body}');
    }
    final body = jsonDecode(res.body);
    final data = body is Map ? (body['data'] ?? body) : body;
    return GroupSession.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deleteSession(String groupId, String sessionId) async {
    final res = await ApiClient.delete('$_base/groups/$groupId/sessions/$sessionId/');
    dev.log('[Groups] DELETE session → ${res.statusCode}');
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Delete session failed (${res.statusCode})');
    }
  }

  static Future<List<GroupMessage>> fetchMessages(
      String groupId, {String? sinceId}) async {
    final path = sinceId != null
        ? '$_base/groups/$groupId/messages/?since_id=$sinceId'
        : '$_base/groups/$groupId/messages/';
    final res = await ApiClient.get(path);
    dev.log('[Groups] messages GET → ${res.statusCode}');
    if (res.statusCode != 200) return [];
    final body = jsonDecode(res.body);
    final List raw = body is Map
        ? ((body['data'] ?? body['results'] ?? []) as List)
        : (body as List? ?? []);
    return raw.map((e) => GroupMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<GroupMessage> postMessage(String groupId, String text) async {
    final res = await ApiClient.post('$_base/groups/$groupId/messages/',
        body: {'body': text});
    dev.log('[Groups] POST message → ${res.statusCode}');
    if (res.statusCode != 201) {
      throw Exception('Post failed (${res.statusCode}): ${res.body}');
    }
    final body = jsonDecode(res.body);
    final data = body is Map ? (body['data'] ?? body) : body;
    return GroupMessage.fromJson(data as Map<String, dynamic>);
  }
}

enum _JoinResult { success, groupFull }

// ─────────────────────────────────────────────────────────────
//  UNIFIED DATE + TIME PICKER  (replaces showDatePicker / showTimePicker)
//  Shows a month calendar + analogue clock in one bottom sheet.
// ─────────────────────────────────────────────────────────────

/// Opens the unified picker and returns the chosen [DateTime] or null.
Future<DateTime?> _pickDateTime(
  BuildContext context, {
  DateTime? initial,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DateTimePickerSheet(initial: initial),
  );
}

class _DateTimePickerSheet extends StatefulWidget {
  final DateTime? initial;
  const _DateTimePickerSheet({this.initial});
  @override
  State<_DateTimePickerSheet> createState() => _DateTimePickerSheetState();
}

class _DateTimePickerSheetState extends State<_DateTimePickerSheet> {
  late DateTime _month;     // which month is visible in the calendar
  DateTime? _selectedDate;
  late int  _hour;          // 1-12
  late int  _minute;        // 0-59
  late bool _isAm;
  bool _showClock = false;  // toggle between calendar view and clock view

  @override
  void initState() {
    super.initState();
    final init = widget.initial ?? DateTime.now().add(const Duration(days: 1));
    _month        = DateTime(init.year, init.month);
    _selectedDate = DateTime(init.year, init.month, init.day);
    final h24     = init.hour;
    _isAm         = h24 < 12;
    _hour         = h24 % 12 == 0 ? 12 : h24 % 12;
    _minute       = init.minute;
  }

  DateTime get _picked {
    final d = _selectedDate!;
    final h24 = _isAm ? (_hour % 12) : (_hour % 12 + 12);
    return DateTime(d.year, d.month, d.day, h24, _minute);
  }

  void _prevMonth() => setState(() =>
      _month = DateTime(_month.year, _month.month - 1));

  void _nextMonth() => setState(() =>
      _month = DateTime(_month.year, _month.month + 1));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // drag handle
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: SBColors.border, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),

        // ── Header ───────────────────────────────────────
        Row(children: [
          Text('Select Date & Time',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: SBColors.text)),
          const Spacer(),
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 20, color: SBColors.text2)),
        ]),
        const SizedBox(height: 8),

        // ── Tab toggle: Calendar / Clock ─────────────────
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: SBColors.surface2,
              borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            _TabBtn(label: '📅  Date',  active: !_showClock,
                onTap: () => setState(() => _showClock = false)),
            _TabBtn(label: '🕐  Time',  active: _showClock,
                onTap: () => setState(() => _showClock = true)),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Calendar / Clock body ────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _showClock
              ? _ClockFace(
                  key: const ValueKey('clock'),
                  hour:   _hour,
                  minute: _minute,
                  isAm:   _isAm,
                  onHourChanged:   (h) => setState(() => _hour   = h),
                  onMinuteChanged: (m) => setState(() => _minute = m),
                  onAmPmChanged:   (a) => setState(() => _isAm   = a),
                )
              : _CalendarGrid(
                  key:          const ValueKey('calendar'),
                  month:        _month,
                  selected:     _selectedDate,
                  onPrev:       _prevMonth,
                  onNext:       _nextMonth,
                  onSelect:     (d) => setState(() => _selectedDate = d),
                ),
        ),

        const SizedBox(height: 16),

        // ── Summary pill ─────────────────────────────────
        if (_selectedDate != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
                color: SBColors.brandPale,
                borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.event, size: 14, color: SBColors.brand),
              const SizedBox(width: 6),
              Text(
                _DateFmt.sessionLong(_picked),
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: SBColors.brand),
              ),
            ]),
          ),

        const SizedBox(height: 16),

        // ── Confirm ──────────────────────────────────────
        GestureDetector(
          onTap: _selectedDate == null
              ? null
              : () => Navigator.pop(context, _picked),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _selectedDate == null
                  ? SBColors.border
                  : SBColors.brand,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _selectedDate == null ? 'Pick a date first' : 'Confirm',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _selectedDate == null ? SBColors.text3 : Colors.white),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Tab button inside the picker ──────────────────────────────
class _TabBtn extends StatelessWidget {
  final String label;
  final bool   active;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))]
                : []),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? SBColors.brand : SBColors.text3)),
        ),
      ),
    ),
  );
}

// ── Calendar grid ─────────────────────────────────────────────
class _CalendarGrid extends StatelessWidget {
  final DateTime  month;
  final DateTime? selected;
  final VoidCallback onPrev, onNext;
  final ValueChanged<DateTime> onSelect;

  const _CalendarGrid({
    super.key,
    required this.month,
    required this.selected,
    required this.onPrev,
    required this.onNext,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay  = DateTime(month.year, month.month, 1);
    final daysInMon = DateTime(month.year, month.month + 1, 0).day;
    // weekday: Mon=1…Sun=7. We want Mon-first grid.
    final startPad  = (firstDay.weekday - 1) % 7;
    final today     = DateTime.now();
    const headers   = ['M','T','W','T','F','S','S'];

    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Month navigation
      Row(children: [
        _NavBtn(icon: Icons.chevron_left, onTap: onPrev),
        Expanded(
          child: Center(
            child: Text(_DateFmt.monthYear(month),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: SBColors.text)),
          ),
        ),
        _NavBtn(icon: Icons.chevron_right, onTap: onNext),
      ]),
      const SizedBox(height: 10),
      // Day-of-week headers
      Row(children: headers.map((h) => Expanded(
        child: Center(child: Text(h,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: SBColors.text3))),
      )).toList()),
      const SizedBox(height: 6),
      // Grid
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
        itemCount: startPad + daysInMon,
        itemBuilder: (_, i) {
          if (i < startPad) return const SizedBox.shrink();
          final day     = i - startPad + 1;
          final date    = DateTime(month.year, month.month, day);
          final isToday = date.year  == today.year
                       && date.month == today.month
                       && date.day   == today.day;
          final isSel   = selected != null
                       && date.year  == selected!.year
                       && date.month == selected!.month
                       && date.day   == selected!.day;
          final isPast  = date.isBefore(DateTime(today.year, today.month, today.day));

          return GestureDetector(
            onTap: isPast ? null : () => onSelect(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isSel
                    ? SBColors.brand
                    : isToday
                        ? SBColors.brandPale
                        : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSel || isToday ? FontWeight.w700 : FontWeight.normal,
                    color: isSel
                        ? Colors.white
                        : isPast
                            ? SBColors.border
                            : isToday
                                ? SBColors.brand
                                : SBColors.text,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ]);
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
          color: SBColors.surface2,
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 18, color: SBColors.brand),
    ),
  );
}

// ── Analogue clock face ───────────────────────────────────────
class _ClockFace extends StatefulWidget {
  final int  hour, minute;
  final bool isAm;
  final ValueChanged<int>  onHourChanged, onMinuteChanged;
  final ValueChanged<bool> onAmPmChanged;

  const _ClockFace({
    super.key,
    required this.hour,
    required this.minute,
    required this.isAm,
    required this.onHourChanged,
    required this.onMinuteChanged,
    required this.onAmPmChanged,
  });

  @override
  State<_ClockFace> createState() => _ClockFaceState();
}

class _ClockFaceState extends State<_ClockFace> {
  bool _pickingHour = true; // true = dragging hours, false = minutes

  void _handleClockTap(Offset local, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angle  = math.atan2(local.dy - center.dy, local.dx - center.dx);
    // atan2 gives -π..π with 0 at 3 o'clock; shift to 12 o'clock = 0
    final deg    = ((angle * 180 / math.pi) + 90 + 360) % 360;

    if (_pickingHour) {
      int h = (deg / 30).round() % 12;
      if (h == 0) h = 12;
      widget.onHourChanged(h);
    } else {
      int m = (deg / 6).round() % 60;
      widget.onMinuteChanged(m);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Digital readout + AM/PM
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _DigitBox(
          value:   widget.hour.toString().padLeft(2, '0'),
          active:  _pickingHour,
          onTap:   () => setState(() => _pickingHour = true),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(':', style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w700, color: SBColors.text)),
        ),
        _DigitBox(
          value:   widget.minute.toString().padLeft(2, '0'),
          active:  !_pickingHour,
          onTap:   () => setState(() => _pickingHour = false),
        ),
        const SizedBox(width: 12),
        // AM / PM toggle
        Column(mainAxisSize: MainAxisSize.min, children: [
          _AmPmBtn(label: 'AM', active:  widget.isAm, onTap: () => widget.onAmPmChanged(true)),
          const SizedBox(height: 4),
          _AmPmBtn(label: 'PM', active: !widget.isAm, onTap: () => widget.onAmPmChanged(false)),
        ]),
      ]),
      const SizedBox(height: 16),

      // Clock face
      LayoutBuilder(builder: (_, c) {
        final size = math.min(c.maxWidth, 240.0);
        return Center(
          child: GestureDetector(
            onTapUp: (d) => _handleClockTap(d.localPosition, Size(size, size)),
            onPanUpdate: (d) => _handleClockTap(d.localPosition, Size(size, size)),
            child: SizedBox(
              width: size, height: size,
              child: CustomPaint(
                painter: _ClockPainter(
                  hour:        widget.hour,
                  minute:      widget.minute,
                  pickingHour: _pickingHour,
                ),
              ),
            ),
          ),
        );
      }),

      const SizedBox(height: 10),
      Text(
        _pickingHour ? 'Tap to set hour' : 'Tap to set minute',
        style: const TextStyle(fontSize: 11, color: SBColors.text3),
      ),
    ]);
  }
}

class _DigitBox extends StatelessWidget {
  final String value;
  final bool   active;
  final VoidCallback onTap;
  const _DigitBox({required this.value, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: active ? SBColors.brand : SBColors.surface2,
          borderRadius: BorderRadius.circular(12)),
      child: Text(value,
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : SBColors.text)),
    ),
  );
}

class _AmPmBtn extends StatelessWidget {
  final String label;
  final bool   active;
  final VoidCallback onTap;
  const _AmPmBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: active ? SBColors.brand : SBColors.surface2,
          borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : SBColors.text3)),
    ),
  );
}

class _ClockPainter extends CustomPainter {
  final int  hour, minute;
  final bool pickingHour;

  const _ClockPainter({
    required this.hour,
    required this.minute,
    required this.pickingHour,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    canvas.drawCircle(center, radius,
        Paint()..color = const Color(0xFFF4F6F8));

    // Tick marks
    final tickPaint = Paint()
      ..color = SBColors.border
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 60; i++) {
      final angle = (i * 6 - 90) * math.pi / 180;
      final isMajor = i % 5 == 0;
      final outer   = center + Offset(
          math.cos(angle) * (radius - 4),
          math.sin(angle) * (radius - 4));
      final inner   = center + Offset(
          math.cos(angle) * (radius - (isMajor ? 14 : 8)),
          math.sin(angle) * (radius - (isMajor ? 14 : 8)));
      if (isMajor) {
        tickPaint.color = SBColors.text3;
        tickPaint.strokeWidth = 2;
      } else {
        tickPaint.color = SBColors.border;
        tickPaint.strokeWidth = 1.2;
      }
      canvas.drawLine(inner, outer, tickPaint);
    }

    // Hour numbers
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final pos   = center + Offset(
          math.cos(angle) * (radius - 26),
          math.sin(angle) * (radius - 26));
      tp.text = TextSpan(
        text: '$i',
        style: TextStyle(
          fontSize: 11,
          fontWeight: i == hour && pickingHour
              ? FontWeight.w800
              : FontWeight.normal,
          color: i == hour && pickingHour
              ? SBColors.brand
              : SBColors.text,
        ),
      );
      tp.layout();
      canvas.save();
      canvas.translate(pos.dx - tp.width / 2, pos.dy - tp.height / 2);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }

    // Active hand + dot
    final handAngle = pickingHour
        ? ((hour % 12) * 30 - 90) * math.pi / 180
        : (minute * 6 - 90) * math.pi / 180;

    final handEnd = center + Offset(
        math.cos(handAngle) * (radius - 30),
        math.sin(handAngle) * (radius - 30));

    canvas.drawLine(
      center, handEnd,
      Paint()
        ..color  = SBColors.brand
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Centre dot
    canvas.drawCircle(center, 5, Paint()..color = SBColors.brand);

    // Selected value highlight circle
    final selPos = pickingHour
        ? center + Offset(
            math.cos(handAngle) * (radius - 30),
            math.sin(handAngle) * (radius - 30))
        : handEnd;
    canvas.drawCircle(selPos, 12,
        Paint()..color = SBColors.brand.withOpacity(0.18));
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.hour != hour || old.minute != minute || old.pickingHour != pickingHour;
}

// ─────────────────────────────────────────────────────────────
//  1. BROWSE / MY GROUPS SCREEN
// ─────────────────────────────────────────────────────────────
class SBGroupsScreen extends StatefulWidget {
  const SBGroupsScreen({super.key});
  @override
  State<SBGroupsScreen> createState() => _SBGroupsScreenState();
}

class _SBGroupsScreenState extends State<SBGroupsScreen> {
  int _filter = 0;
  final _filters = ['All', 'My Groups'];

  List<GroupModel> _allGroups      = [];
  Set<String>      _joinedGroupIds = {};
  Set<String>      _loadingJoin    = {};
  bool    _loading = true;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _currentUserId = await _CurrentUser.getId();
    await _loadAll();
  }

  Future<void> _loadAll() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final groupsFuture = _GroupsApi.fetchAllGroups();
      final membershipsFuture = _currentUserId != null
          ? _GroupsApi.fetchMembershipsForUser(_currentUserId!)
          : Future.value(<GroupMemberRow>[]);

      final results     = await Future.wait([groupsFuture, membershipsFuture]);
      final groups      = results[0] as List<GroupModel>;
      final memberships = results[1] as List<GroupMemberRow>;

      // Normalise IDs with .trim() to avoid whitespace mismatches
      final joinedIds = memberships
          .map((m) => m.groupId.trim())
          .where((id) => id.isNotEmpty)
          .toSet();

      dev.log('[Groups] ${groups.length} groups, user joined ${joinedIds.length}: $joinedIds');
      for (final g in groups) {
        dev.log('[Groups] group id="${g.id}" name="${g.name}" inJoined=${joinedIds.contains(g.id)}');
      }

      if (mounted) setState(() {
        _allGroups      = groups;
        _joinedGroupIds = joinedIds;
        _loading        = false;
      });
    } catch (e, st) {
      dev.log('[Groups] _loadAll error: $e', stackTrace: st);
      if (mounted) setState(() {
        _error   = 'Could not load groups. Check your connection.';
        _loading = false;
      });
    }
  }

  bool _isJoined(GroupModel g) => _joinedGroupIds.contains(g.id.trim());

  List<GroupModel> get _displayedGroups {
    if (_filter == 1) {
      return _allGroups
          .where((g) => _joinedGroupIds.contains(g.id.trim()))
          .toList();
    }
    return _allGroups;
  }

  Future<void> _refreshMemberships() async {
    if (_currentUserId == null) return;
    final memberships = await _GroupsApi.fetchMembershipsForUser(_currentUserId!);
    final joinedIds = memberships
        .map((m) => m.groupId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    dev.log('[Groups] refreshed memberships: $joinedIds');
    if (mounted) setState(() => _joinedGroupIds = joinedIds);
  }

  Future<void> _toggleJoin(GroupModel g) async {
    if (_currentUserId == null) {
      _snack('Could not identify your account. Please re-login.');
      return;
    }
    final joining = !_isJoined(g);
    if (joining && g.isFull) { _snack('⚠️ Group is full — max ${g.maxMembers} members'); return; }

    setState(() {
      if (joining) _joinedGroupIds.add(g.id); else _joinedGroupIds.remove(g.id);
      _loadingJoin.add(g.id);
    });

    try {
      if (joining) {
        final result = await _GroupsApi.joinGroup(g.id);
        if (result == _JoinResult.groupFull) {
          if (mounted) setState(() => _joinedGroupIds.remove(g.id));
          _snack('⚠️ Maximum members reached (${g.maxMembers})');
          return;
        }
      } else {
        await _GroupsApi.leaveGroup(g.id);
      }
      // Always re-fetch from server to ensure accuracy
      await _refreshMemberships();
    } catch (e) {
      if (mounted) setState(() {
        if (joining) _joinedGroupIds.remove(g.id); else _joinedGroupIds.add(g.id);
      });
      _snack(joining ? 'Could not join group' : 'Could not leave group');
    } finally {
      if (mounted) setState(() => _loadingJoin.remove(g.id));
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SBColors.surface2,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: SBColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Study Groups',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: SBColors.text)),
        actions: [
          GestureDetector(
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SBCreateGroupScreen()));
              _loadAll();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: SBColors.brand, borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text('+',
                  style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w700))),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        color: SBColors.brand,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => SBChip(
                  label: _filters[i], active: _filter == i,
                  onTap: () => setState(() => _filter = i),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildContent()),
        ]),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return Column(children: [_heroBanner(null), ..._shimmerCards()]);
    if (_error != null) return _ErrorState(message: _error!, onRetry: _loadAll);

    final groups = _displayedGroups;
    return Column(children: [
      _heroBanner(_allGroups.length),
      if (groups.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _filter == 1
                  ? 'My Groups (${groups.length})'
                  : 'All Groups (${groups.length})',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: SBColors.text),
            ),
          ),
        ),
      if (groups.isEmpty)
        (_filter == 1 ? const _EmptyMyGroups() : const _EmptyState())
      else ...[
        ...groups.map((g) => _GroupCard(
          group:        g,
          isJoined:     _isJoined(g),
          isLoading:    _loadingJoin.contains(g.id),
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(
                builder: (_) => SBGroupDetailScreen(
                    group: g, currentUserId: _currentUserId)));
            _loadAll();
          },
          onJoinToggle: () => _toggleJoin(g),
        )),
        const SizedBox(height: 24),
      ],
    ]);
  }

  Widget _heroBanner(int? count) => Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [Color(0xFF3ECF8E), Color(0xFF0D9488)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        count != null && count > 0 ? '$count Active Study Groups' : 'Study Groups',
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      const SizedBox(height: 4),
      Text('Connect with peers studying the same subjects',
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85))),
    ]),
  );

  List<Widget> _shimmerCards() => List.generate(3, (_) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    padding: const EdgeInsets.all(14),
    decoration: SBTheme.card,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(width: 160, height: 14,
            decoration: BoxDecoration(
                color: SBColors.border, borderRadius: BorderRadius.circular(7))),
        Container(width: 60, height: 22,
            decoration: BoxDecoration(
                color: SBColors.border, borderRadius: BorderRadius.circular(8))),
      ]),
      const SizedBox(height: 8),
      Container(width: double.infinity, height: 10,
          decoration: BoxDecoration(
              color: SBColors.border, borderRadius: BorderRadius.circular(5))),
      const SizedBox(height: 6),
      Container(width: 220, height: 10,
          decoration: BoxDecoration(
              color: SBColors.border, borderRadius: BorderRadius.circular(5))),
    ]),
  ));
}

// ─────────────────────────────────────────────────────────────
//  GROUP CARD
// ─────────────────────────────────────────────────────────────
class _GroupCard extends StatelessWidget {
  final GroupModel group;
  final bool isJoined, isLoading;
  final VoidCallback onTap, onJoinToggle;

  const _GroupCard({
    required this.group, required this.isJoined, required this.isLoading,
    required this.onTap, required this.onJoinToggle,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: SBTheme.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text('${group.emoji}  ${group.name}',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: SBColors.text))),
          if (group.subject.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                  color: SBColors.brandPale, borderRadius: BorderRadius.circular(8)),
              child: Text(group.subject,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700, color: SBColors.brand)),
            ),
        ]),
        const SizedBox(height: 6),
        if (group.description.isNotEmpty)
          Text(group.description,
              style: const TextStyle(fontSize: 12, color: SBColors.text2, height: 1.5)),
        const SizedBox(height: 10),
        Row(children: [
          const Text('👥', style: TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text('${group.memberCount}/${group.maxMembers} members',
              style: TextStyle(
                  fontSize: 10,
                  color: group.isFull ? Colors.red : SBColors.text3,
                  fontWeight: group.isFull ? FontWeight.w700 : FontWeight.normal)),
          if (group.isFull) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6)),
              child: const Text('Full',
                  style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700, color: Colors.red)),
            ),
          ],
        ]),
        const SizedBox(height: 10),
        const Divider(color: SBColors.border, height: 1),
        const SizedBox(height: 10),
        Row(children: [
          const Spacer(),
          GestureDetector(
            onTap: (isLoading || (!isJoined && group.isFull)) ? null : onJoinToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isJoined
                    ? SBColors.green.withOpacity(0.1)
                    : group.isFull
                        ? Colors.grey.withOpacity(0.1)
                        : SBColors.brandPale,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isJoined
                        ? SBColors.green
                        : group.isFull ? Colors.grey : SBColors.brand,
                    width: 1.5),
              ),
              child: isLoading
                  ? SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: isJoined ? SBColors.green : SBColors.brand))
                  : Text(
                      isJoined ? '✓ Joined' : group.isFull ? 'Full' : 'Join',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: isJoined
                              ? SBColors.green
                              : group.isFull ? Colors.grey : SBColors.brand)),
            ),
          ),
        ]),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  2. GROUP DETAIL SCREEN
// ─────────────────────────────────────────────────────────────
class SBGroupDetailScreen extends StatefulWidget {
  final GroupModel group;
  final String?   currentUserId;
  const SBGroupDetailScreen({super.key, required this.group, this.currentUserId});
  @override
  State<SBGroupDetailScreen> createState() => _SBGroupDetailScreenState();
}

class _SBGroupDetailScreenState extends State<SBGroupDetailScreen>
    with SingleTickerProviderStateMixin {

  bool _isJoined      = false;
  bool _isCreator     = false;
  bool _joining       = false;
  bool _deletingGroup = false;

  List<GroupMemberRow> _members        = [];
  bool                 _membersLoading = true;

  List<GroupSession> _sessions        = [];
  bool               _sessionsLoading = true;

  List<GroupMessage> _messages        = [];
  bool               _messagesLoading = true;
  bool               _sendingMessage  = false;
  String?            _lastMessageId;
  Timer?             _pollTimer;

  final _discussionCtrl  = TextEditingController();
  final _scrollCtrl      = ScrollController();

  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.index == 2) {
        _startPolling();
      } else {
        _pollTimer?.cancel();
      }
    });
    _loadAll();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _discussionCtrl.dispose();
    _scrollCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadMembers(),
      _loadSessions(),
      _loadMessages(),
    ]);
    if (mounted) {
      _checkJoined();
      _checkCreator();
    }
  }

  Future<void> _loadMembers() async {
    if (mounted) setState(() => _membersLoading = true);
    try {
      final rows = await _GroupsApi.fetchMembershipsForGroup(widget.group.id);
      dev.log('[Detail] loaded ${rows.length} members for group ${widget.group.id}');
      if (mounted) setState(() { _members = rows; _membersLoading = false; });
    } catch (e) {
      dev.log('[Detail] loadMembers error: $e');
      if (mounted) setState(() => _membersLoading = false);
    }
  }

  void _checkJoined() {
    final uid = widget.currentUserId?.trim();
    if (uid == null) return;
    final joined = _members.any((m) => m.userId.trim() == uid);
    dev.log('[Detail] _checkJoined uid=$uid joined=$joined');
    setState(() => _isJoined = joined);
  }

  void _checkCreator() {
    final uid = widget.currentUserId?.trim();
    final cid = widget.group.creatorId?.trim();
    dev.log('[Detail] _checkCreator uid=$uid creatorId=$cid');
    if (uid != null && cid != null && uid.isNotEmpty && cid.isNotEmpty) {
      setState(() => _isCreator = uid == cid);
    }
  }

  Future<void> _loadSessions() async {
    if (mounted) setState(() => _sessionsLoading = true);
    try {
      final sessions = await _GroupsApi.fetchSessions(widget.group.id);
      if (mounted) setState(() { _sessions = sessions; _sessionsLoading = false; });
    } catch (e) {
      dev.log('[Detail] loadSessions error: $e');
      if (mounted) setState(() => _sessionsLoading = false);
    }
  }

  // ── Unified date+time picker ──────────────────────────────
  Future<void> _proposeSession() async {
    final titleCtrl    = TextEditingController();
    final descCtrl     = TextEditingController();
    final locationCtrl = TextEditingController();
    DateTime? picked;
    int durationMin    = 60;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) {
        return Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              top: 20, left: 20, right: 20),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: SingleChildScrollView(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                const Text('Propose a Session',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: SBColors.text)),
                const Spacer(),
                IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, size: 20, color: SBColors.text2)),
              ]),
              const SizedBox(height: 16),
              SBFormField(label: 'Title *', controller: titleCtrl),
              const SizedBox(height: 12),
              SBFormField(label: 'Description', controller: descCtrl, multiline: true),
              const SizedBox(height: 12),
              SBFormField(label: 'Location / Link', controller: locationCtrl),
              const SizedBox(height: 12),

              // ── Unified date+time button ──────────────────
              GestureDetector(
                onTap: () async {
                  // We need to navigate away from this sheet temporarily.
                  // Close the proposal sheet, pick, then re-open is complex.
                  // Instead we push the picker as a full sheet over the top.
                  final result = await _pickDateTime(
                    ctx,
                    initial: picked ?? DateTime.now().add(const Duration(days: 1)),
                  );
                  if (result != null) setModal(() => picked = result);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                      color: SBColors.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: picked != null ? SBColors.brand : SBColors.border,
                          width: picked != null ? 1.5 : 1)),
                  child: Row(children: [
                    Icon(
                      picked != null
                          ? Icons.event_available_outlined
                          : Icons.calendar_today_outlined,
                      size: 16,
                      color: SBColors.brand,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      picked == null
                          ? 'Select date & time *'
                          : _DateFmt.sessionLong(picked!),
                      style: TextStyle(
                          fontSize: 13,
                          color: picked == null ? SBColors.text3 : SBColors.text,
                          fontWeight: picked != null ? FontWeight.w600 : FontWeight.normal),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, size: 16, color: SBColors.text3),
                  ]),
                ),
              ),
              const SizedBox(height: 12),

              // Duration
              Row(children: [
                const Text('Duration: ',
                    style: TextStyle(fontSize: 13, color: SBColors.text)),
                DropdownButton<int>(
                  value: durationMin,
                  underline: const SizedBox.shrink(),
                  style: const TextStyle(
                      fontSize: 13, color: SBColors.brand, fontWeight: FontWeight.w600),
                  items: [30, 45, 60, 90, 120].map((v) => DropdownMenuItem(
                    value: v,
                    child: Text('$v min'),
                  )).toList(),
                  onChanged: (v) => setModal(() => durationMin = v ?? 60),
                ),
              ]),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  if (titleCtrl.text.trim().isEmpty) {
                    _snack('Please enter a title'); return;
                  }
                  if (picked == null) {
                    _snack('Please select a date & time'); return;
                  }
                  Navigator.pop(ctx);
                  try {
                    final session = await _GroupsApi.createSession(
                        widget.group.id, {
                      'title':        titleCtrl.text.trim(),
                      'description':  descCtrl.text.trim(),
                      'location':     locationCtrl.text.trim(),
                      'scheduled_at': picked!.toUtc().toIso8601String(),
                      'duration_min': durationMin,
                    });
                    if (mounted) {
                      setState(() => _sessions = [..._sessions, session]
                          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)));
                      _snack('📅 Session proposed!');
                    }
                  } catch (e) {
                    _snack('Could not create session: $e');
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                      color: SBColors.brand, borderRadius: BorderRadius.circular(14)),
                  child: const Center(
                    child: Text('Propose Session',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ),
            ],
          )),
        );
      }),
    );
  }

  Future<void> _deleteSession(GroupSession s) async {
    try {
      await _GroupsApi.deleteSession(widget.group.id, s.id);
      if (mounted) {
        setState(() => _sessions.removeWhere((x) => x.id == s.id));
        _snack('Session removed');
      }
    } catch (e) {
      _snack('Could not remove session');
    }
  }

  Future<void> _loadMessages() async {
    if (mounted) setState(() => _messagesLoading = true);
    try {
      final msgs = await _GroupsApi.fetchMessages(widget.group.id);
      if (mounted) {
        setState(() {
          _messages        = msgs;
          _lastMessageId   = msgs.isNotEmpty ? msgs.last.id : null;
          _messagesLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      dev.log('[Detail] loadMessages error: $e');
      if (mounted) setState(() => _messagesLoading = false);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      try {
        final newMsgs = await _GroupsApi.fetchMessages(
            widget.group.id, sinceId: _lastMessageId);
        if (newMsgs.isNotEmpty && mounted) {
          setState(() {
            _messages.addAll(newMsgs);
            _lastMessageId = _messages.last.id;
          });
          _scrollToBottom();
        }
      } catch (_) {}
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _discussionCtrl.text.trim();
    if (text.isEmpty || _sendingMessage) return;
    if (!_isJoined) {
      _snack('Join the group to participate in discussion');
      return;
    }

    setState(() => _sendingMessage = true);
    _discussionCtrl.clear();
    try {
      final msg = await _GroupsApi.postMessage(widget.group.id, text);
      if (mounted) {
        setState(() {
          _messages.add(msg);
          _lastMessageId = msg.id;
        });
        _scrollToBottom();
      }
    } catch (e) {
      _snack('Could not send message');
      if (mounted) _discussionCtrl.text = text;
    } finally {
      if (mounted) setState(() => _sendingMessage = false);
    }
  }

  Future<void> _toggleMembership() async {
    if (widget.currentUserId == null) {
      _snack('Could not identify your account.');
      return;
    }
    if (!_isJoined && widget.group.isFull) {
      _snack('⚠️ Group is full — max ${widget.group.maxMembers} members');
      return;
    }

    setState(() => _joining = true);
    try {
      if (_isJoined) {
        await _GroupsApi.leaveGroup(widget.group.id);
      } else {
        final result = await _GroupsApi.joinGroup(widget.group.id);
        if (result == _JoinResult.groupFull) {
          _snack('⚠️ Maximum members reached (${widget.group.maxMembers})');
          return;
        }
      }
      await _loadMembers();
      _checkJoined();
    } catch (e) {
      _snack('Action failed: $e');
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Group',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Delete "${widget.group.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deletingGroup = true);
    try {
      await _GroupsApi.deleteGroup(widget.group.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Group deleted'),
          backgroundColor: SBColors.brandDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      _snack('Delete failed: $e');
    } finally {
      if (mounted) setState(() => _deletingGroup = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    return Scaffold(
      backgroundColor: SBColors.surface2,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: SBColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(g.name,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: SBColors.text)),
        actions: _isCreator
            ? [
                _deletingGroup
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.red)))
                    : IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 22),
                        tooltip: 'Delete Group',
                        onPressed: _deleteGroup,
                      ),
              ]
            : [],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: SBColors.brand,
          unselectedLabelColor: SBColors.text3,
          indicatorColor: SBColors.brand,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Members'),
            Tab(text: 'Sessions'),
            Tab(text: 'Discussion'),
          ],
        ),
      ),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: SBTheme.brandGradient(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (g.subject.isNotEmpty)
              Text(g.subject.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.75),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
            const SizedBox(height: 6),
            Text('${g.emoji}  ${g.name}',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            if (g.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(g.description,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
                      height: 1.5)),
            ],
          ]),
        ),

        _StatsBar([
          ('${_membersLoading ? g.memberCount : _members.length}', 'Members'),
          ('${g.maxMembers}', 'Max'),
          (g.isFull ? 'Full' : 'Open', 'Status'),
        ]),

        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildMembersTab(),
              _buildSessionsTab(),
              _buildDiscussionTab(),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: GestureDetector(
            onTap: (_joining || (!_isJoined && g.isFull)) ? null : _toggleMembership,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: !_isJoined && g.isFull
                    ? Colors.grey
                    : _isJoined ? SBColors.green : SBColors.brand,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: (_isJoined ? SBColors.green : SBColors.brand)
                        .withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6))],
              ),
              child: Center(
                child: _joining
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        !_isJoined && g.isFull
                            ? '🚫 Group is Full (${g.maxMembers}/${g.maxMembers})'
                            : _isJoined
                                ? "✅  You're a Member · Leave Group"
                                : '👥  Join This Group',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildMembersTab() {
    if (_membersLoading) {
      return const Center(child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(strokeWidth: 2, color: SBColors.brand)));
    }
    if (_members.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('👥', style: TextStyle(fontSize: 36)),
          SizedBox(height: 10),
          Text('No members yet',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: SBColors.text)),
          SizedBox(height: 4),
          Text('Be the first to join!',
              style: TextStyle(fontSize: 12, color: SBColors.text3)),
        ]),
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: _members.length,
      itemBuilder: (_, i) {
        final m = _members[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _MemberRow(
            name:     m.userName,
            degree:   m.userDegree,
            isOnline: m.isOnline,
            isAdmin:  m.isAdmin,
            isMe:     m.userId.trim() == widget.currentUserId?.trim(),
          ),
        );
      },
    );
  }

  Widget _buildSessionsTab() {
    return Column(children: [
      if (_isJoined)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: GestureDetector(
            onTap: _proposeSession,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: SBColors.brandPale, borderRadius: BorderRadius.circular(12)),
              child: const Center(
                child: Text('📅  Propose a Session',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: SBColors.brand)),
              ),
            ),
          ),
        ),
      Expanded(
        child: _sessionsLoading
            ? const Center(child: CircularProgressIndicator(
                strokeWidth: 2, color: SBColors.brand))
            : _sessions.isEmpty
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('📅', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: 10),
                      const Text('No upcoming sessions',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: SBColors.text)),
                      const SizedBox(height: 4),
                      Text(
                        _isJoined
                            ? 'Tap above to propose one!'
                            : 'Join the group to propose sessions',
                        style: const TextStyle(fontSize: 12, color: SBColors.text3),
                      ),
                    ]),
                  ))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _sessions.length,
                    itemBuilder: (_, i) => _SessionCard(
                      session:   _sessions[i],
                      canDelete: _isCreator ||
                          _sessions[i].proposedById == widget.currentUserId,
                      onDelete:  () => _deleteSession(_sessions[i]),
                    ),
                  ),
      ),
    ]);
  }

  Widget _buildDiscussionTab() {
    return Column(children: [
      Expanded(
        child: _messagesLoading
            ? const Center(child: CircularProgressIndicator(
                strokeWidth: 2, color: SBColors.brand))
            : _messages.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('💬', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 10),
                    const Text('No messages yet',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: SBColors.text)),
                    const SizedBox(height: 4),
                    Text(
                      _isJoined
                          ? 'Start the conversation!'
                          : 'Join the group to chat',
                      style: const TextStyle(
                          fontSize: 12, color: SBColors.text3),
                    ),
                  ]))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _MessageBubble(
                      message: _messages[i],
                      isMe:    _messages[i].authorId == widget.currentUserId,
                    ),
                  ),
      ),

      if (_isJoined)
        Container(
          padding: EdgeInsets.fromLTRB(
              12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 10),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: SBColors.border))),
          child: Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: SBColors.surface2,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: SBColors.border)),
                child: TextField(
                  controller: _discussionCtrl,
                  maxLines: 4, minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  style: const TextStyle(fontSize: 13, color: SBColors.text),
                  decoration: const InputDecoration.collapsed(
                      hintText: 'Message the group…',
                      hintStyle: TextStyle(fontSize: 13, color: SBColors.text3)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 42, height: 42,
                decoration: BoxDecoration(
                    color: _sendingMessage
                        ? SBColors.brand.withOpacity(0.5)
                        : SBColors.brand,
                    borderRadius: BorderRadius.circular(21)),
                child: _sendingMessage
                    ? const Center(child: SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)))
                    : const Center(child: Icon(
                        Icons.send_rounded, color: Colors.white, size: 18)),
              ),
            ),
          ]),
        )
      else
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: const Row(children: [
            Icon(Icons.lock_outline, size: 14, color: SBColors.text3),
            SizedBox(width: 6),
            Text('Join the group to participate',
                style: TextStyle(fontSize: 12, color: SBColors.text3)),
          ]),
        ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
//  SESSION CARD
// ─────────────────────────────────────────────────────────────
class _SessionCard extends StatelessWidget {
  final GroupSession session;
  final bool         canDelete;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session, required this.canDelete, required this.onDelete,
  });

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final local   = session.scheduledAt.toLocal();
    final timeStr = _DateFmt.sessionShort(local);
    final isToday = _isToday(local);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isToday ? SBColors.brand : SBColors.border,
              width: isToday ? 1.5 : 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (isToday)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: SBColors.brand,
                  borderRadius: BorderRadius.circular(6)),
              child: const Text('TODAY',
                  style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          Expanded(
            child: Text(session.title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: SBColors.text)),
          ),
          if (canDelete)
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close, size: 16, color: SBColors.text3),
            ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.access_time, size: 12, color: SBColors.brand),
          const SizedBox(width: 4),
          Text(timeStr,
              style: const TextStyle(fontSize: 11, color: SBColors.brand,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          const Icon(Icons.timelapse, size: 12, color: SBColors.text3),
          const SizedBox(width: 4),
          Text('${session.durationMin} min',
              style: const TextStyle(fontSize: 11, color: SBColors.text3)),
        ]),
        if (session.location.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 12, color: SBColors.text3),
            const SizedBox(width: 4),
            Expanded(child: Text(session.location,
                style: const TextStyle(fontSize: 11, color: SBColors.text3),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ],
        if (session.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(session.description,
              style: const TextStyle(
                  fontSize: 11, color: SBColors.text2, height: 1.4),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 8),
        Text('Proposed by ${session.proposedByName}',
            style: const TextStyle(fontSize: 10, color: SBColors.text3)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MESSAGE BUBBLE
// ─────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final GroupMessage message;
  final bool         isMe;

  const _MessageBubble({required this.message, required this.isMe});

  String _fmt(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (dt.day == now.day) return _DateFmt.timeOnly(dt);
    return _DateFmt.shortWithTime(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [SBColors.brand, SBColors.brandDark]),
                  borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(
                message.authorName.isNotEmpty
                    ? message.authorName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
              )),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 2),
                    child: Text(message.authorName,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: SBColors.text2)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMe ? SBColors.brand : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(16),
                      topRight:    const Radius.circular(16),
                      bottomLeft:  Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: isMe ? null : Border.all(color: SBColors.border),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Text(message.body,
                      style: TextStyle(
                          fontSize: 13,
                          color: isMe ? Colors.white : SBColors.text,
                          height: 1.4)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 2, right: 2),
                  child: Text(_fmt(message.createdAt.toLocal()),
                      style: const TextStyle(fontSize: 9, color: SBColors.text3)),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  3. CREATE GROUP SCREEN
// ─────────────────────────────────────────────────────────────
class SBCreateGroupScreen extends StatefulWidget {
  const SBCreateGroupScreen({super.key});
  @override
  State<SBCreateGroupScreen> createState() => _SBCreateGroupScreenState();
}

class _SBCreateGroupScreenState extends State<SBCreateGroupScreen> {
  bool _loading = false;
  final _nameCtrl       = TextEditingController();
  final _subjectCtrl    = TextEditingController();
  final _descCtrl       = TextEditingController();
  final _maxMembersCtrl = TextEditingController(text: '10');

  @override
  void dispose() {
    _nameCtrl.dispose(); _subjectCtrl.dispose();
    _descCtrl.dispose(); _maxMembersCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty)    { _snack('Please enter a group name'); return; }
    if (_subjectCtrl.text.trim().isEmpty) { _snack('Please enter a subject');    return; }
    final maxMembers = int.tryParse(_maxMembersCtrl.text.trim());
    if (maxMembers == null || maxMembers < 1) { _snack('Max members must be ≥ 1'); return; }

    setState(() => _loading = true);
    try {
      await _GroupsApi.createGroup({
        'name':        _nameCtrl.text.trim(),
        'subject':     _subjectCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'max_members': maxMembers,
        'active':      true,
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('🚀 Group created!'),
        backgroundColor: SBColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      if (!mounted) return;
      _snack('Failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: SBColors.surface2,
    appBar: AppBar(
      backgroundColor: Colors.white, elevation: 0,
      leading: IconButton(
          icon: const Icon(Icons.close, size: 18, color: SBColors.text),
          onPressed: () => Navigator.pop(context)),
      title: const Text('Create Study Group',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: SBColors.text)),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: _loading ? null : _submit,
            child: Center(
              child: _loading
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: SBColors.brand))
                  : const Text('Save', style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: SBColors.brand)),
            ),
          ),
        ),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        SBFormField(label: 'Group Name *',  controller: _nameCtrl),
        const SizedBox(height: 12),
        SBFormField(label: 'Subject *',     controller: _subjectCtrl),
        const SizedBox(height: 12),
        SBFormField(label: 'Description',   controller: _descCtrl, multiline: true),
        const SizedBox(height: 12),
        SBFormField(label: 'Max Members',   controller: _maxMembersCtrl),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Maximum number of members allowed.',
              style: TextStyle(fontSize: 11, color: SBColors.text3)),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _loading ? null : _submit,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: _loading
                  ? SBColors.brand.withOpacity(0.6)
                  : SBColors.brand,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                  color: SBColors.brand.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6))],
            ),
            child: Center(
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('🚀  Create Group',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final List<(String, String)> items;
  const _StatsBar(this.items);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SBColors.border)),
    child: Row(
      children: items.indexed.map(((int, (String, String)) e) {
        final (i, (val, lbl)) = e;
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(border: Border(
              right: i < items.length - 1
                  ? const BorderSide(color: SBColors.border)
                  : BorderSide.none,
            )),
            child: Column(children: [
              Text(val, style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: SBColors.brand)),
              Text(lbl, style: const TextStyle(fontSize: 9, color: SBColors.text3)),
            ]),
          ),
        );
      }).toList(),
    ),
  );
}

class _MemberRow extends StatelessWidget {
  final String name, degree;
  final bool isOnline, isAdmin, isMe;
  const _MemberRow({
    required this.name, required this.degree, required this.isOnline,
    this.isAdmin = false, this.isMe = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SBColors.border)),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [SBColors.brand, SBColors.brandDark]),
            borderRadius: BorderRadius.all(Radius.circular(12))),
        child: Center(child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        )),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(name,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
          if (isMe) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                  color: SBColors.brandPale,
                  borderRadius: BorderRadius.circular(5)),
              child: const Text('You',
                  style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700, color: SBColors.brand)),
            ),
          ],
          if (isAdmin) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(5)),
              child: const Text('Admin',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.amber)),
            ),
          ],
        ]),
        if (degree.isNotEmpty)
          Text(degree, style: const TextStyle(fontSize: 11, color: SBColors.text3)),
      ])),
      if (isOnline)
        const Text('● Online',
            style: TextStyle(fontSize: 11, color: SBColors.green)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────
//  EMPTY / ERROR STATES
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(40),
    child: Column(children: [
      Text('👥', style: TextStyle(fontSize: 40)),
      SizedBox(height: 12),
      Text('No groups found',
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: SBColors.text)),
      SizedBox(height: 4),
      Text('Create a new group to get started',
          style: TextStyle(fontSize: 12, color: SBColors.text3)),
    ]),
  );
}

class _EmptyMyGroups extends StatelessWidget {
  const _EmptyMyGroups();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(40),
    child: Column(children: [
      Text('📚', style: TextStyle(fontSize: 40)),
      SizedBox(height: 12),
      Text("You haven't joined any groups yet",
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: SBColors.text)),
      SizedBox(height: 4),
      Text('Switch to All to browse and join groups',
          style: TextStyle(fontSize: 12, color: SBColors.text3)),
    ]),
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(children: [
      const Text('⚠️', style: TextStyle(fontSize: 40)),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: SBColors.text2)),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: onRetry,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
              color: SBColors.brand, borderRadius: BorderRadius.circular(12)),
          child: const Text('Retry',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    ]),
  );
}