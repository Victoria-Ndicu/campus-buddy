// ============================================================
//  StudyBuddy — sb_groups_screen.dart  (API-connected)
//
//  Now uses ApiClient (lib/core/api_client.dart) for all
//  requests — automatic token refresh, same pattern as
//  profile_screen.dart.
//
//  GET  /api/study-buddy/groups/              → list groups
//  GET  /api/study-buddy/groups/?subject=     → filtered
//  POST /api/study-buddy/groups/              → create group
//  POST /api/study-buddy/groups/<id>/join/    → join group
//  POST /api/study-buddy/groups/<id>/leave/   → leave group
// ============================================================

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';

import '../../../core/api_client.dart';   // ← same shared client as profile_screen
import '../models/sb_constants.dart';
import '../widgets/sb_widgets.dart';

// ─────────────────────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────────────────────
class GroupModel {
  final String id;
  final String name;
  final String course;
  final String description;
  final String schedule;
  final String location;
  final int members;
  final int maxMembers;
  final bool isJoined;
  final String emoji;
  final List<MemberModel> memberList;
  final List<SessionModel> sessions;
  final int fileCount;

  const GroupModel({
    required this.id,
    required this.name,
    required this.course,
    required this.description,
    required this.schedule,
    required this.location,
    required this.members,
    required this.maxMembers,
    required this.isJoined,
    required this.emoji,
    required this.memberList,
    required this.sessions,
    required this.fileCount,
  });

  static String _emojiForCourse(String course) {
    final c = course.toLowerCase();
    if (c.contains('math') || c.contains('calc')) return '📐';
    if (c.contains('cs') || c.contains('computer') || c.contains('algo')) return '💻';
    if (c.contains('chem')) return '⚗️';
    if (c.contains('phys')) return '🔭';
    if (c.contains('bio')) return '🧬';
    if (c.contains('econ') || c.contains('finance')) return '📊';
    return '📚';
  }

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    final memberList = (json['members'] as List? ?? [])
        .map((m) => MemberModel.fromJson(m as Map<String, dynamic>))
        .toList();

    final sessions = (json['sessions'] as List? ?? [])
        .map((s) => SessionModel.fromJson(s as Map<String, dynamic>))
        .toList();

    final course = json['course'] as String? ??
        json['course_code'] as String? ??
        json['subject'] as String? ?? '';

    return GroupModel(
      id:          json['id']?.toString() ?? '',
      name:        json['name'] as String? ?? 'Study Group',
      course:      course,
      description: json['description'] as String? ?? '',
      schedule:    json['schedule'] as String? ?? json['meeting_time'] as String? ?? '—',
      location:    json['location'] as String? ?? json['meeting_place'] as String? ?? '—',
      members:     (json['member_count'] ?? json['members_count'] ?? memberList.length) as int,
      maxMembers:  (json['max_members'] ?? json['max_size'] ?? 20) as int,
      isJoined:    json['is_member'] as bool? ?? json['is_joined'] as bool? ?? false,
      emoji:       _emojiForCourse(course),
      memberList:  memberList,
      sessions:    sessions,
      fileCount:   (json['file_count'] ?? json['files_count'] ?? 0) as int,
    );
  }
}

class MemberModel {
  final String name, degree, emoji;
  final bool isOnline, isAdmin;

  const MemberModel({
    required this.name,
    required this.degree,
    required this.isOnline,
    required this.isAdmin,
    required this.emoji,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) => MemberModel(
    name:     json['name'] as String? ?? json['full_name'] as String? ??
              json['user']?['full_name'] as String? ?? 'Member',
    degree:   json['degree'] as String? ?? json['program'] as String? ?? '',
    isOnline: json['is_online'] as bool? ?? false,
    isAdmin:  json['is_admin'] as bool? ?? json['role'] == 'admin',
    emoji:    json['emoji'] as String? ?? '👤',
  );
}

class SessionModel {
  final String dayLabel, dateNum, title, subtitle;

  const SessionModel({
    required this.dayLabel,
    required this.dateNum,
    required this.title,
    required this.subtitle,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    DateTime? dt;
    try {
      if (json['scheduled_at'] != null) {
        dt = DateTime.parse(json['scheduled_at'] as String).toLocal();
      }
    } catch (_) {}

    const days     = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final dayLabel = dt != null ? days[dt.weekday - 1] : '—';
    final dateNum  = dt != null ? '${dt.day}' : '—';
    final timeStr  = dt != null
        ? '${dt.hour > 12 ? dt.hour - 12 : dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}'
        : '';

    final location = json['location'] as String? ?? json['meeting_place'] as String? ?? '';
    final subtitle = [if (timeStr.isNotEmpty) timeStr, if (location.isNotEmpty) location]
        .join(' · ');

    return SessionModel(
      dayLabel: dayLabel,
      dateNum:  dateNum,
      title:    json['title'] as String? ?? json['topic'] as String? ?? 'Study Session',
      subtitle: subtitle,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  API SERVICE
// ─────────────────────────────────────────────────────────────
class _GroupsApi {
  static const _base = '/api/v1/study-buddy';

  static Future<List<GroupModel>> fetchGroups({String? subject, String? search}) async {
    final params = <String, String>{};
    if (subject != null && subject.isNotEmpty) params['subject'] = subject;
    if (search  != null && search.isNotEmpty)  params['search']  = search;

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final path  = query.isEmpty ? '$_base/groups/' : '$_base/groups/?$query';

    final res = await ApiClient.get(path);
    dev.log('[SBGroups] GET $path → ${res.statusCode}');

    if (res.statusCode != 200) throw Exception('Failed to load groups (${res.statusCode})');

    final body    = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (body['results'] ?? body) as List<dynamic>;
    return results.map((e) => GroupModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> joinGroup(String id) async {
    final res = await ApiClient.post('$_base/groups/$id/join/');
    dev.log('[SBGroups] POST join $id → ${res.statusCode}');
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Join failed (${res.statusCode})');
    }
  }

  static Future<void> leaveGroup(String id) async {
    final res = await ApiClient.post('$_base/groups/$id/leave/');
    dev.log('[SBGroups] POST leave $id → ${res.statusCode}');
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Leave failed (${res.statusCode})');
    }
  }

  static Future<void> createGroup(Map<String, dynamic> payload) async {
    final res = await ApiClient.post('$_base/groups/', body: payload);
    dev.log('[SBGroups] POST create → ${res.statusCode}');
    if (res.statusCode != 201) throw Exception('Create failed (${res.statusCode})');
  }
}

// ─────────────────────────────────────────────────────────────
//  1. BROWSE STUDY GROUPS
//
//  State pattern mirrors profile_screen.dart:
//    _loading / _error / _groups  (atomic setState)
// ─────────────────────────────────────────────────────────────
class SBGroupsScreen extends StatefulWidget {
  const SBGroupsScreen({super.key});

  @override
  State<SBGroupsScreen> createState() => _SBGroupsScreenState();
}

class _SBGroupsScreenState extends State<SBGroupsScreen> {
  int    _filter      = 0;
  String _searchQuery = '';

  List<GroupModel>? _groups;
  bool    _loading = true;
  String? _error;

  // Optimistic join/leave state: groupId → isJoined
  final Map<String, bool> _joinedOverride = {};
  final Set<String>        _loadingJoin   = {};

  final _filters = ['All', 'My Groups', 'Nearby', 'Online', 'Open'];

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    if (mounted) setState(() { _loading = true; _error = null; });

    try {
      final subject = _filter == 0 ? null : _filters[_filter];
      final data    = await _GroupsApi.fetchGroups(
        subject: _searchQuery.isEmpty ? subject : null,
        search:  _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (mounted) setState(() { _groups = data; _loading = false; });
    } catch (e, st) {
      dev.log('[SBGroups] _fetchGroups error: $e', stackTrace: st);
      if (mounted) {
        setState(() {
          _error   = 'Could not load groups. Check your connection.';
          _loading = false;
        });
      }
    }
  }

  bool _isJoined(GroupModel g) => _joinedOverride[g.id] ?? g.isJoined;

  Future<void> _toggleJoin(GroupModel g) async {
    final joining = !_isJoined(g);
    // Optimistic update — same discipline as profile_screen setState
    setState(() {
      _joinedOverride[g.id] = joining;
      _loadingJoin.add(g.id);
    });
    try {
      if (joining) {
        await _GroupsApi.joinGroup(g.id);
      } else {
        await _GroupsApi.leaveGroup(g.id);
      }
    } catch (e, st) {
      dev.log('[SBGroups] _toggleJoin error: $e', stackTrace: st);
      // Revert on failure
      if (mounted) setState(() => _joinedOverride[g.id] = !joining);
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: SBColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Study Groups', style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700, color: SBColors.text)),
        actions: [
          GestureDetector(
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SBCreateGroupScreen()));
              _fetchGroups();   // reload after returning from create
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: SBColors.brand, borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text('+',
                  style: TextStyle(fontSize: 22, color: Colors.white,
                      fontWeight: FontWeight.w700))),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _fetchGroups(),
        color: SBColors.brand,
        child: CustomScrollView(
          slivers: [
            // ── Search ────────────────────────────────────
            SliverToBoxAdapter(
              child: SBSearchBar(
                hint: 'Search groups by course or topic...',
                onChanged: (q) {
                  setState(() => _searchQuery = q);
                  _fetchGroups();
                },
              ),
            ),

            // ── Filter chips ──────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => SBChip(
                    label: _filters[i],
                    active: _filter == i,
                    onTap: () {
                      setState(() => _filter = i);
                      _fetchGroups();
                    },
                  ),
                ),
              ),
            ),

            // ── Content ───────────────────────────────────
            SliverToBoxAdapter(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Loading state
    if (_loading) {
      return Column(children: [
        _heroBanner(null),
        SBSectionLabel(title: 'Loading groups...', action: 'See all'),
        ..._shimmerCards(),
      ]);
    }

    // Error state (same pattern as _NameBlock)
    if (_error != null) {
      return Column(children: [
        _heroBanner(0),
        _ErrorState(message: _error!, onRetry: _fetchGroups),
      ]);
    }

    final groups = _groups ?? [];

    return Column(children: [
      _heroBanner(groups.length),
      if (groups.isEmpty)
        const _EmptyState()
      else ...[
        SBSectionLabel(
            title: 'Recommended for You (${groups.length})',
            action: 'See all'),
        ...groups.map((g) => _GroupCard(
          group:        g,
          isJoined:     _isJoined(g),
          isLoading:    _loadingJoin.contains(g.id),
          onTap:        () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => SBGroupDetailScreen(group: g))),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        count != null && count > 0 ? 'Join $count Active Groups' : 'Study Groups',
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      const SizedBox(height: 4),
      Text('Connect with peers studying the same courses right now',
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85))),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: const Text('Explore All →', style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    ]),
  );

  List<Widget> _shimmerCards() => List.generate(3, (_) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    padding: const EdgeInsets.all(14),
    decoration: SBTheme.card,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(width: 160, height: 14,
            decoration: BoxDecoration(color: SBColors.border,
                borderRadius: BorderRadius.circular(7))),
        Container(width: 60, height: 22,
            decoration: BoxDecoration(color: SBColors.border,
                borderRadius: BorderRadius.circular(8))),
      ]),
      const SizedBox(height: 8),
      Container(width: double.infinity, height: 10,
          decoration: BoxDecoration(color: SBColors.border,
              borderRadius: BorderRadius.circular(5))),
      const SizedBox(height: 6),
      Container(width: 220, height: 10,
          decoration: BoxDecoration(color: SBColors.border,
              borderRadius: BorderRadius.circular(5))),
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
    required this.group,
    required this.isJoined,
    required this.isLoading,
    required this.onTap,
    required this.onJoinToggle,
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
          if (group.course.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                  color: SBColors.brandPale, borderRadius: BorderRadius.circular(8)),
              child: Text(group.course, style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: SBColors.brand)),
            ),
        ]),
        const SizedBox(height: 6),
        Text(group.description, style: const TextStyle(
            fontSize: 12, color: SBColors.text2, height: 1.5)),
        const SizedBox(height: 10),
        Wrap(spacing: 12, children: [
          _Meta('📅', group.schedule),
          _Meta('📍', group.location),
          _Meta('👥', '${group.members}/${group.maxMembers}'),
        ]),
        const SizedBox(height: 10),
        const Divider(color: SBColors.border, height: 1),
        const SizedBox(height: 10),
        Row(children: [
          // Member avatars
          Row(children: List.generate(
            group.memberList.isNotEmpty
                ? group.memberList.length.clamp(0, 3)
                : group.members.clamp(0, 3),
            (i) => Container(
              width: 24, height: 24,
              margin: EdgeInsets.only(left: i == 0 ? 0 : -6),
              decoration: BoxDecoration(
                color: SBColors.brandPale,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(child: Text(
                group.memberList.isNotEmpty && i < group.memberList.length
                    ? (group.memberList[i].emoji.isNotEmpty
                        ? group.memberList[i].emoji[0]
                        : String.fromCharCode(65 + i))
                    : String.fromCharCode(65 + i),
                style: const TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700, color: SBColors.brand),
              )),
            ),
          )),
          const SizedBox(width: 8),
          if (group.members > 3)
            Text('+${group.members - 3} more',
                style: const TextStyle(fontSize: 10, color: SBColors.text3)),
          const Spacer(),
          GestureDetector(
            onTap: isLoading ? null : onJoinToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isJoined
                    ? SBColors.green.withOpacity(0.1)
                    : SBColors.brandPale,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isJoined ? SBColors.green : SBColors.brand, width: 1.5),
              ),
              child: isLoading
                  ? SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5,
                          color: isJoined ? SBColors.green : SBColors.brand))
                  : Text(isJoined ? '✓ Joined' : 'Join',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: isJoined ? SBColors.green : SBColors.brand)),
            ),
          ),
        ]),
      ]),
    ),
  );
}

class _Meta extends StatelessWidget {
  final String icon, label;
  const _Meta(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text(icon, style: const TextStyle(fontSize: 11)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 10, color: SBColors.text3)),
  ]);
}

// ─────────────────────────────────────────────────────────────
//  2. GROUP DETAIL
// ─────────────────────────────────────────────────────────────
class SBGroupDetailScreen extends StatefulWidget {
  final GroupModel group;
  const SBGroupDetailScreen({super.key, required this.group});

  @override
  State<SBGroupDetailScreen> createState() => _SBGroupDetailScreenState();
}

class _SBGroupDetailScreenState extends State<SBGroupDetailScreen> {
  late bool _isJoined;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _isJoined = widget.group.isJoined;
  }

  Future<void> _toggleMembership() async {
    setState(() => _loading = true);
    try {
      if (_isJoined) {
        await _GroupsApi.leaveGroup(widget.group.id);
      } else {
        await _GroupsApi.joinGroup(widget.group.id);
      }
      if (mounted) setState(() => _isJoined = !_isJoined);
    } catch (e, st) {
      dev.log('[SBGroups] _toggleMembership error: $e', stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Action failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    return Scaffold(
      backgroundColor: SBColors.surface2,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: SBColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(g.name, style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: SBColors.text)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Text('⋯', style: TextStyle(fontSize: 22, color: SBColors.text2)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: SBTheme.brandGradient(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (g.course.isNotEmpty)
                Text(g.course.toUpperCase(), style: TextStyle(
                    fontSize: 10, color: Colors.white.withOpacity(0.75),
                    fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 6),
              Text('${g.emoji}  ${g.name}', style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 8),
              Text(g.description, style: TextStyle(
                  fontSize: 12, color: Colors.white.withOpacity(0.85), height: 1.5)),
              const SizedBox(height: 12),
              Wrap(spacing: 16, children: [
                Text('📅 ${g.schedule}', style: TextStyle(
                    fontSize: 11, color: Colors.white.withOpacity(0.8))),
                Text('📍 ${g.location}', style: TextStyle(
                    fontSize: 11, color: Colors.white.withOpacity(0.8))),
              ]),
            ]),
          ),

          // Stats bar
          _StatsBar([
            ('${g.members}', 'Members'),
            ('${g.maxMembers}', 'Max'),
            ('${g.sessions.length}', 'Sessions'),
            ('${g.fileCount}', 'Files'),
          ]),

          // Members
          SBSectionLabel(title: 'Members (${g.members})', action: 'Invite +'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(children: [
              if (g.memberList.isEmpty)
                const Text('No member details available',
                    style: TextStyle(fontSize: 12, color: SBColors.text3))
              else ...[
                ...g.memberList.take(3).map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MemberRow(
                    m.emoji, m.name, m.degree, m.isOnline, isAdmin: m.isAdmin),
                )),
                if (g.members > 3)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('+ ${g.members - 3} more members',
                        style: const TextStyle(fontSize: 12,
                            color: SBColors.brand, fontWeight: FontWeight.w600)),
                  ),
              ],
            ]),
          ),

          // Upcoming sessions
          const SBSectionLabel(title: 'Upcoming Sessions'),
          if (g.sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SBColors.border)),
                child: const Center(child: Text('No upcoming sessions',
                    style: TextStyle(fontSize: 12, color: SBColors.text3))),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SBColors.border)),
              child: Column(
                children: g.sessions.take(3).toList().asMap().entries.map((e) =>
                  Column(children: [
                    if (e.key > 0) const Divider(color: SBColors.border, height: 1),
                    _SessionRow(e.value.dayLabel, e.value.dateNum,
                        e.value.title, e.value.subtitle,
                        SBColors.brand, SBColors.brandPale),
                  ])
                ).toList(),
              ),
            ),

          // CTA button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            child: GestureDetector(
              onTap: _loading ? null : _toggleMembership,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: _isJoined ? SBColors.green : SBColors.brand,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: (_isJoined ? SBColors.green : SBColors.brand).withOpacity(0.3),
                      blurRadius: 20, offset: const Offset(0, 6))],
                ),
                child: Center(
                  child: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          _isJoined
                              ? "✅  You're a Member · View Chat"
                              : '👥  Join This Group',
                          style: const TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  final List<(String, String)> items;
  const _StatsBar(this.items);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    decoration: BoxDecoration(color: Colors.white,
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
  final String emoji, name, degree;
  final bool isOnline, isAdmin;
  const _MemberRow(this.emoji, this.name, this.degree, this.isOnline,
      {this.isAdmin = false});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 36, height: 36,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [SBColors.brand, SBColors.brandDark]),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
    ),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(name, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
        if (isAdmin) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: SBColors.brandPale, borderRadius: BorderRadius.circular(6)),
            child: const Text('Admin', style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w700, color: SBColors.brand)),
          ),
        ],
      ]),
      Text(degree, style: const TextStyle(fontSize: 11, color: SBColors.text3)),
    ])),
    Text(
      isOnline ? '● Online' : '2h ago',
      style: TextStyle(fontSize: 11,
          color: isOnline ? SBColors.green : SBColors.text3),
    ),
  ]);
}

class _SessionRow extends StatelessWidget {
  final String dayLabel, dateNum, title, subtitle;
  final Color color, bgColor;
  const _SessionRow(this.dayLabel, this.dateNum, this.title, this.subtitle,
      this.color, this.bgColor);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(dayLabel, style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700, color: color)),
          Text(dateNum, style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: SBColors.text3)),
      ])),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────
//  3. CREATE GROUP
// ─────────────────────────────────────────────────────────────
class SBCreateGroupScreen extends StatefulWidget {
  const SBCreateGroupScreen({super.key});

  @override
  State<SBCreateGroupScreen> createState() => _SBCreateGroupScreenState();
}

class _SBCreateGroupScreenState extends State<SBCreateGroupScreen> {
  String _privacy = 'Open';
  bool   _loading = false;

  final _nameCtrl       = TextEditingController();
  final _courseCtrl     = TextEditingController();
  final _descCtrl       = TextEditingController();
  final _maxMembersCtrl = TextEditingController(text: '12');
  final _scheduleCtrl   = TextEditingController();
  final _locationCtrl   = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _courseCtrl.dispose();
    _descCtrl.dispose();
    _maxMembersCtrl.dispose();
    _scheduleCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a group name')));
      return;
    }
    setState(() => _loading = true);
    try {
      await _GroupsApi.createGroup({
        'name':        _nameCtrl.text.trim(),
        'course':      _courseCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'max_members': int.tryParse(_maxMembersCtrl.text.trim()) ?? 12,
        'schedule':    _scheduleCtrl.text.trim(),
        'location':    _locationCtrl.text.trim(),
        'privacy':     _privacy.toLowerCase(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('🚀 Group created successfully!'),
        backgroundColor: SBColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e, st) {
      dev.log('[SBGroups] _submit error: $e', stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to create group: ${e.toString()}'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SBColors.surface2,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 18, color: SBColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Study Group', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: SBColors.text)),
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
          SBFormField(label: 'Group Name',  controller: _nameCtrl),
          const SizedBox(height: 12),
          SBFormField(label: 'Course Code', controller: _courseCtrl),
          const SizedBox(height: 12),
          SBFormField(label: 'Description', controller: _descCtrl, multiline: true),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: SBFormField(label: 'Max Members', controller: _maxMembersCtrl)),
            const SizedBox(width: 12),
            Expanded(child: SBFormField(label: 'Schedule', controller: _scheduleCtrl)),
          ]),
          const SizedBox(height: 12),
          SBFormField(label: 'Location', controller: _locationCtrl),
          const SizedBox(height: 12),

          // Privacy
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SBColors.border, width: 1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('GROUP PRIVACY', style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: SBColors.text3, letterSpacing: 1)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                SBChip(label: '🔓 Open', active: _privacy == 'Open',
                    onTap: () => setState(() => _privacy = 'Open')),
                SBChip(label: '🔒 Request to Join', active: _privacy == 'Request',
                    onTap: () => setState(() => _privacy = 'Request')),
                SBChip(label: '🔑 Invite Only', active: _privacy == 'Invite',
                    onTap: () => setState(() => _privacy = 'Invite')),
              ]),
            ]),
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
                boxShadow: [BoxShadow(color: SBColors.brand.withOpacity(0.3),
                    blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: Center(
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('🚀  Create Group', style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EMPTY / ERROR STATES
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(children: const [
      Text('👥', style: TextStyle(fontSize: 40)),
      SizedBox(height: 12),
      Text('No groups found', style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600, color: SBColors.text)),
      SizedBox(height: 4),
      Text('Try a different filter or create a new group',
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
          child: const Text('Retry', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    ]),
  );
}