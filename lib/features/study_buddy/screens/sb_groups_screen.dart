// ============================================================
//  StudyBuddy — sb_groups_screen.dart   (FIXED)
//
//  Fixes applied:
//  ① group_id extraction: handles nested {id,name} object AND
//    plain string/int — was converting object to "{id:x}" string
//    which never matched g.id, so joined state always reset.
//  ② userId extraction: same fix for nested user object.
//  ③ Create group: sends active=true so Django doesn't filter
//    it out (was only 3 showing because inactive default).
//  ④ Joined state: after pop-back _loadAll() re-queries DB
//    correctly now that group_id parses right.
//  ⑤ Members: userId/userName extracted robustly from both
//    flat and nested API shapes.
//  ⑥ Sessions section removed — will be DB-driven later.
// ============================================================

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api_client.dart';
import '../models/sb_constants.dart';
import '../widgets/sb_widgets.dart';

// ─────────────────────────────────────────────────────────────
//  EXTENSION
// ─────────────────────────────────────────────────────────────
extension _LetExt<T> on T {
  R let<R>(R Function(T) fn) => fn(this);
}

// ─────────────────────────────────────────────────────────────
//  HELPER — safely extract an id string from a field that may
//  be a plain String/int OR a nested Map like {"id":1,"name":"…"}
// ─────────────────────────────────────────────────────────────
String _extractId(dynamic value) {
  if (value == null) return '';
  if (value is Map) {
    // Nested object — pull the id field from inside it
    return (value['id'] ?? value['uuid'] ?? '').toString();
  }
  return value.toString();
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
        _cachedId = val;
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
              ?.toString();
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
  final String groupId;   // ← always a clean id string now
  final String userId;    // ← always a clean id string now
  final String userName;
  final String userDegree;
  final bool isOnline;
  final bool isAdmin;

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
    // ── user id ───────────────────────────────────────────
    // API may return: user: {id:1, full_name:"…"} OR user_id: 1
    final userRaw = json['user'];
    final String userId;
    String userName = 'Member';
    String userDegree = '';

    if (userRaw is Map<String, dynamic>) {
      userId     = _extractId(userRaw['id'] ?? userRaw['uuid']);
      userName   = userRaw['full_name'] as String?
          ?? userRaw['name'] as String?
          ?? userRaw['username'] as String?
          ?? 'Member';
      userDegree = userRaw['degree'] as String?
          ?? userRaw['program'] as String?
          ?? '';
    } else {
      userId     = _extractId(json['user_id'] ?? json['userId']);
      userName   = json['full_name'] as String?
          ?? json['name'] as String?
          ?? 'Member';
      userDegree = json['degree'] as String?
          ?? json['program'] as String?
          ?? '';
    }

    // ── group id ──────────────────────────────────────────
    // API may return: group: {id:1, name:"…"} OR group_id: 1
    final groupRaw = json['group'];
    final String groupId;
    if (groupRaw is Map<String, dynamic>) {
      groupId = _extractId(groupRaw['id'] ?? groupRaw['uuid']);
    } else {
      groupId = _extractId(json['group_id'] ?? json['groupId'] ?? groupRaw);
    }

    dev.log('[GroupMemberRow] parsed → userId=$userId groupId=$groupId name=$userName');

    return GroupMemberRow(
      membershipId: (json['id'] ?? '').toString(),
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

    // creator_id may also be a nested object
    final creatorRaw = json['creator'] ?? json['creatorId'] ?? json['creator_id'];
    final creatorId  = creatorRaw is Map
        ? _extractId(creatorRaw['id'] ?? creatorRaw['uuid'])
        : creatorRaw?.toString();

    final subject = json['subject'] as String? ?? '';
    return GroupModel(
      id:          json['id']?.toString() ?? '',
      name:        json['name'] as String? ?? 'Study Group',
      subject:     subject,
      description: json['description'] as String? ?? '',
      memberCount: toInt(json['memberCount'] ?? json['member_count']),
      maxMembers:  toInt(json['maxMembers'] ?? json['max_members'])
          .let((v) => v > 0 ? v : 10),
      emoji:       _emojiForSubject(subject),
      creatorId:   creatorId,
      active:      json['active'] as bool? ?? true,
    );
  }

  bool get isFull => memberCount >= maxMembers;
}

class DiscussionPost {
  final String   author;
  final String   message;
  final DateTime postedAt;
  DiscussionPost({required this.author, required this.message, required this.postedAt});
}

// ─────────────────────────────────────────────────────────────
//  API SERVICE
// ─────────────────────────────────────────────────────────────
class _GroupsApi {
  static const _base = '/api/v1/study-buddy';

  // ── Groups ───────────────────────────────────────────────

  static Future<List<GroupModel>> fetchAllGroups() async {
    final List<dynamic> all = [];
    String? next = '$_base/groups/?page_size=100';

    while (next != null) {
      final res = await ApiClient.get(next);
      dev.log('[Groups] GET $next → ${res.statusCode}');
      if (res.statusCode != 200) throw Exception('Groups fetch failed (${res.statusCode})');

      final body = jsonDecode(res.body);
      if (body is List) {
        all.addAll(body); next = null;
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

  // ── Group Members ────────────────────────────────────────

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
          for (final r in rows) {
            dev.log('[Groups]   → groupId=${r.groupId} userId=${r.userId}');
          }
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

  // ── Join / Leave ─────────────────────────────────────────

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

  // ── Create / Delete Group ────────────────────────────────

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
}

enum _JoinResult { success, groupFull }

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
      final groupsFuture      = _GroupsApi.fetchAllGroups();
      final membershipsFuture = _currentUserId != null
          ? _GroupsApi.fetchMembershipsForUser(_currentUserId!)
          : Future.value(<GroupMemberRow>[]);

      final results     = await Future.wait([groupsFuture, membershipsFuture]);
      final groups      = results[0] as List<GroupModel>;
      final memberships = results[1] as List<GroupMemberRow>;

      final joinedIds = memberships.map((m) => m.groupId).toSet();
      dev.log('[Groups] ${groups.length} groups, user joined ${joinedIds.length}: $joinedIds');

      // Log all group ids for comparison
      for (final g in groups) dev.log('[Groups] group id=${g.id} name=${g.name}');

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

  bool _isJoined(GroupModel g) => _joinedGroupIds.contains(g.id);

  List<GroupModel> get _displayedGroups {
    if (_filter == 1) return _allGroups.where((g) => _joinedGroupIds.contains(g.id)).toList();
    return _allGroups;
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
      // Re-confirm actual DB state
      if (_currentUserId != null) {
        final updated = await _GroupsApi.fetchMembershipsForUser(_currentUserId!);
        if (mounted) setState(() => _joinedGroupIds = updated.map((m) => m.groupId).toSet());
      }
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
              decoration: BoxDecoration(color: SBColors.brand, borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text('+',
                  style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w700))),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        color: SBColors.brand,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => SBChip(
                    label: _filters[i],
                    active: _filter == i,
                    onTap: () => setState(() => _filter = i),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildContent()),
          ],
        ),
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
              _filter == 1 ? 'My Groups (${groups.length})' : 'All Groups (${groups.length})',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SBColors.text),
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
            _loadAll(); // re-fetch on pop — now works because group_id parses correctly
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
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
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
            decoration: BoxDecoration(color: SBColors.border, borderRadius: BorderRadius.circular(7))),
        Container(width: 60, height: 22,
            decoration: BoxDecoration(color: SBColors.border, borderRadius: BorderRadius.circular(8))),
      ]),
      const SizedBox(height: 8),
      Container(width: double.infinity, height: 10,
          decoration: BoxDecoration(color: SBColors.border, borderRadius: BorderRadius.circular(5))),
      const SizedBox(height: 6),
      Container(width: 220, height: 10,
          decoration: BoxDecoration(color: SBColors.border, borderRadius: BorderRadius.circular(5))),
    ]),
  ));
}

// ─────────────────────────────────────────────────────────────
//  GROUP CARD  (unchanged visually)
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SBColors.text))),
          if (group.subject.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: SBColors.brandPale, borderRadius: BorderRadius.circular(8)),
              child: Text(group.subject,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SBColors.brand)),
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
                  color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: const Text('Full',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.red)),
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
                    : group.isFull ? Colors.grey.withOpacity(0.1) : SBColors.brandPale,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isJoined ? SBColors.green : group.isFull ? Colors.grey : SBColors.brand,
                    width: 1.5),
              ),
              child: isLoading
                  ? SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: isJoined ? SBColors.green : SBColors.brand))
                  : Text(
                      isJoined ? '✓ Joined' : group.isFull ? 'Full' : 'Join',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: isJoined ? SBColors.green : group.isFull ? Colors.grey : SBColors.brand)),
            ),
          ),
        ]),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  2. GROUP DETAIL SCREEN
//     Sessions section removed — will be a DB table later.
// ─────────────────────────────────────────────────────────────
class SBGroupDetailScreen extends StatefulWidget {
  final GroupModel group;
  final String?   currentUserId;
  const SBGroupDetailScreen({super.key, required this.group, this.currentUserId});
  @override
  State<SBGroupDetailScreen> createState() => _SBGroupDetailScreenState();
}

class _SBGroupDetailScreenState extends State<SBGroupDetailScreen> {
  bool _isJoined       = false;
  bool _isCreator      = false;
  bool _joining        = false;
  bool _deletingGroup  = false;

  List<GroupMemberRow> _members        = [];
  bool                 _membersLoading = true;

  final List<DiscussionPost> _posts = [];
  final _discussionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _discussionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await _loadMembers();
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
    final uid = widget.currentUserId;
    if (uid == null) return;
    final joined = _members.any((m) => m.userId == uid);
    dev.log('[Detail] _checkJoined uid=$uid joined=$joined memberUserIds=${_members.map((m)=>m.userId).toList()}');
    setState(() => _isJoined = joined);
  }

  void _checkCreator() {
    final uid = widget.currentUserId;
    final cid = widget.group.creatorId;
    dev.log('[Detail] uid=$uid creatorId=$cid');
    if (uid != null && cid != null) {
      setState(() => _isCreator = uid.trim() == cid.trim());
    }
  }

  Future<void> _toggleMembership() async {
    if (widget.currentUserId == null) { _snack('Could not identify your account.'); return; }
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
        title: const Text('Delete Group', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Delete "${widget.group.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
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
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: SBColors.text)),
        actions: _isCreator
            ? [
                _deletingGroup
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)))
                    : IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                        tooltip: 'Delete Group',
                        onPressed: _deleteGroup,
                      ),
              ]
            : [],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // ── Hero ─────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: SBTheme.brandGradient(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (g.subject.isNotEmpty)
                Text(g.subject.toUpperCase(),
                    style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.75),
                        fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 6),
              Text('${g.emoji}  ${g.name}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 8),
              if (g.description.isNotEmpty)
                Text(g.description,
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85), height: 1.5)),
            ]),
          ),

          // ── Stats ────────────────────────────────────────
          _StatsBar([
            ('${_membersLoading ? g.memberCount : _members.length}', 'Members'),
            ('${g.maxMembers}', 'Max'),
            (g.isFull ? 'Full' : 'Open', 'Status'),
          ]),

          // ── Members ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _membersLoading ? 'Members (loading…)' : 'Members (${_members.length})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SBColors.text),
                ),
                if (g.isFull)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('Full ${g.maxMembers}/${g.maxMembers}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _membersLoading
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2, color: SBColors.brand)))
                : _members.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: SBColors.border)),
                        child: const Column(children: [
                          Text('👥', style: TextStyle(fontSize: 28)),
                          SizedBox(height: 8),
                          Text('No members yet',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
                          SizedBox(height: 4),
                          Text('Be the first to join!',
                              style: TextStyle(fontSize: 11, color: SBColors.text3)),
                        ]),
                      )
                    : Column(
                        children: _members.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MemberRow(
                            name:     m.userName,
                            degree:   m.userDegree,
                            isOnline: m.isOnline,
                            isAdmin:  m.isAdmin,
                            isMe:     m.userId == widget.currentUserId,
                          ),
                        )).toList(),
                      ),
          ),

          // ── Sessions placeholder ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(children: [
              const Text('Upcoming Sessions',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SBColors.text)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: SBColors.brandPale, borderRadius: BorderRadius.circular(8)),
                child: const Text('Coming soon',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: SBColors.brand)),
              ),
            ]),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SBColors.border)),
            child: const Column(children: [
              Text('📅', style: TextStyle(fontSize: 28)),
              SizedBox(height: 8),
              Text('Sessions coming soon',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
              SizedBox(height: 4),
              Text('Group sessions will be available once the\nsessions table is set up.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: SBColors.text3, height: 1.5)),
            ]),
          ),

          // ── Discussion ────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Group Discussion',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SBColors.text)),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SBColors.border)),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                          color: SBColors.surface2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: SBColors.border)),
                      child: TextField(
                        controller: _discussionCtrl,
                        maxLines: 3, minLines: 1,
                        style: const TextStyle(fontSize: 13, color: SBColors.text),
                        decoration: const InputDecoration.collapsed(
                            hintText: 'Share something with the group…',
                            hintStyle: TextStyle(fontSize: 13, color: SBColors.text3)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      final text = _discussionCtrl.text.trim();
                      if (text.isEmpty) return;
                      setState(() {
                        _posts.insert(0, DiscussionPost(
                            author: 'You', message: text, postedAt: DateTime.now()));
                      });
                      _discussionCtrl.clear();
                    },
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                          color: SBColors.brand, borderRadius: BorderRadius.circular(12)),
                      child: const Center(
                          child: Icon(Icons.send_rounded, color: Colors.white, size: 18)),
                    ),
                  ),
                ]),
              ),
              if (_posts.isNotEmpty) const Divider(color: SBColors.border, height: 1),
              if (_posts.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(children: const [
                    Text('💬', style: TextStyle(fontSize: 28)),
                    SizedBox(height: 6),
                    Text('No messages yet. Start the conversation!',
                        style: TextStyle(fontSize: 12, color: SBColors.text3)),
                  ]),
                )
              else
                ..._posts.map((p) => _DiscussionTile(post: p)),
            ]),
          ),

          // ── Join / Leave CTA ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
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
                      color: (_isJoined ? SBColors.green : SBColors.brand).withOpacity(0.3),
                      blurRadius: 20, offset: const Offset(0, 6))],
                ),
                child: Center(
                  child: _joining
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          !_isJoined && g.isFull
                              ? '🚫 Group is Full (${g.maxMembers}/${g.maxMembers})'
                              : _isJoined
                                  ? "✅  You're a Member · Leave Group"
                                  : '👥  Join This Group',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  3. CREATE GROUP SCREEN
//     Now sends active: true so Django doesn't filter it out
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
        'active':      true,   // ← ensures group is visible in list queries
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: SBColors.text)),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: _loading ? null : _submit,
            child: Center(
              child: _loading
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: SBColors.brand))
                  : const Text('Save', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.brand)),
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
              color: _loading ? SBColors.brand.withOpacity(0.6) : SBColors.brand,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                  color: SBColors.brand.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: Center(
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('🚀  Create Group',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
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
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 36, height: 36,
      decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [SBColors.brand, SBColors.brandDark]),
          borderRadius: BorderRadius.all(Radius.circular(12))),
      child: Center(child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
      )),
    ),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
        if (isMe) ...[
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: SBColors.brandPale, borderRadius: BorderRadius.circular(5)),
            child: const Text('You',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: SBColors.brand)),
          ),
        ],
        if (isAdmin) ...[
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(5)),
            child: const Text('Admin',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.amber)),
          ),
        ],
      ]),
      if (degree.isNotEmpty)
        Text(degree, style: const TextStyle(fontSize: 11, color: SBColors.text3)),
    ])),
    if (isOnline)
      const Text('● Online', style: TextStyle(fontSize: 11, color: SBColors.green)),
  ]);
}

class _DiscussionTile extends StatelessWidget {
  final DiscussionPost post;
  const _DiscussionTile({required this.post});

  String _fmt(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: SBColors.brandPale, borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text(
          post.author.isNotEmpty ? post.author[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SBColors.brand),
        )),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(post.author,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: SBColors.text)),
          const Spacer(),
          Text(_fmt(post.postedAt),
              style: const TextStyle(fontSize: 10, color: SBColors.text3)),
        ]),
        const SizedBox(height: 3),
        Text(post.message,
            style: const TextStyle(fontSize: 12, color: SBColors.text2, height: 1.5)),
      ])),
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
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: SBColors.text)),
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
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: SBColors.text)),
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
          decoration: BoxDecoration(color: SBColors.brand, borderRadius: BorderRadius.circular(12)),
          child: const Text('Retry',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    ]),
  );
}