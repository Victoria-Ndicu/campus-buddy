import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/hh_constants.dart';
import '../widgets/hh_widgets.dart';
import '../../../core/api_client.dart';

// ─────────────────────────────────────────────────────────────
//  API ENDPOINTS
//
//  GET    /api/v1/housing/roommates/             → browse profiles
//  GET    /api/v1/housing/roommates/<uuid>/      → profile detail
//  GET    /api/v1/housing/roommates/my-profile/  → current user's profile
//  POST   /api/v1/housing/roommates/my-profile/  → create/update preferences
//
//  Response wrapper: { "success": true, "data": [...] | {...} }
//
//  Name  : user.full_name  (falls back to user.name)
//  Phone : user.phone      (appended to wa.me/ for WhatsApp)
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────────────────────
class _Roommate {
  final String id, name, phone, course, year, location;
  final int    matchPct;
  final List<String> prefs;

  const _Roommate({
    required this.id,
    required this.name,
    required this.phone,
    required this.course,
    required this.year,
    required this.location,
    required this.matchPct,
    required this.prefs,
  });

  factory _Roommate.fromJson(Map<String, dynamic> j) {
    // Prefer full_name from the users table, fall back to name
    final name = (j['full_name']?.toString().trim().isNotEmpty == true)
        ? j['full_name'].toString().trim()
        : j['name']?.toString().trim() ?? 'Unknown';

    // Phone number stored in users.phone — used for wa.me deep link
    final phone = j['phone']?.toString().trim() ?? '';

    // Location
    String location = j['preferred_location']?.toString() ?? '';
    if (location.isEmpty) {
      final areas = j['preferredAreas'];
      if (areas is List && areas.isNotEmpty) {
        location = areas.first.toString();
      }
    }

    return _Roommate(
      id:       j['id']?.toString() ?? '',
      name:     name,
      phone:    phone,
      course:   j['course']?.toString() ?? '',
      year:     j['year']?.toString() ?? '',
      location: location,
      matchPct: (j['match_percent'] as num?)?.toInt() ?? 0,
      prefs:    (j['lifestyle_prefs'] as List?)
          ?.map((e) => e.toString()).toList() ?? [],
    );
  }

  String get emoji {
    final n = name.isNotEmpty ? name[0].toLowerCase() : 'u';
    const map = {
      'a': '👩‍🎓', 'b': '👨‍🔬', 'c': '👨‍💻', 'd': '👩‍💼',
      'e': '👨‍🎨', 'f': '👩‍🔬', 'g': '👨‍🎓', 'h': '👩‍💻',
    };
    return map[n] ?? '🧑‍🎓';
  }

  Color get gradA {
    const opts = [Color(0xFFEEF1FD), Color(0xFFECFDF5), Color(0xFFFDF0EC), Color(0xFFFFF3E0)];
    return opts[name.hashCode.abs() % opts.length];
  }

  Color get gradB {
    const opts = [Color(0xFFC7D2FA), Color(0xFFA7F3D0), Color(0xFFF4C5B5), Color(0xFFFFCC80)];
    return opts[name.hashCode.abs() % opts.length];
  }

  /// Appends user.phone to https://wa.me/ after sanitising.
  /// Local Kenyan 07xx → 2547xx.
  String get whatsappUrl {
    final stripped = phone.replaceAll(RegExp(r'[\s\-()+]'), '');
    final digits = stripped.startsWith('0')
        ? '254${stripped.substring(1)}'
        : stripped;
    return 'https://wa.me/$digits';
  }
}

// ─────────────────────────────────────────────────────────────
//  Response unwrappers
// ─────────────────────────────────────────────────────────────
List<dynamic> _unwrapList(dynamic d) {
  if (d is List) return d;
  if (d is Map) {
    if (d['data'] is List)    return d['data'] as List;
    if (d['results'] is List) return d['results'] as List;
  }
  return [];
}

Map<String, dynamic>? _unwrapObject(dynamic d) {
  if (d is Map && d['data'] is Map) return d['data'] as Map<String, dynamic>;
  if (d is Map<String, dynamic>)    return d;
  return null;
}

// ─────────────────────────────────────────────────────────────
//  WhatsApp launcher
// ─────────────────────────────────────────────────────────────
Future<void> _openWhatsApp(BuildContext ctx, _Roommate r) async {
  if (r.phone.isEmpty) {
    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
      content: Text('No phone number available for this user.')));
    return;
  }
  final uri = Uri.parse(r.whatsappUrl);
  dev.log('[WhatsApp] ${r.whatsappUrl}');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else if (ctx.mounted) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text('Could not open WhatsApp for ${r.name}. '
          'Make sure WhatsApp is installed.')));
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 1 — Browse Roommates
// ─────────────────────────────────────────────────────────────
class HHRoommateScreen extends StatefulWidget {
  const HHRoommateScreen({super.key});
  @override
  State<HHRoommateScreen> createState() => _HHRoommateScreenState();
}

class _HHRoommateScreenState extends State<HHRoommateScreen> {
  int    _filter = 0;
  String _query  = '';
  List<_Roommate> _roommates = [];
  bool   _loading = true;
  String? _error;
  DateTime _lastSearch = DateTime(0);

  static const _filters    = ['All','High Match','Near Campus','Female Only','Male Only'];
  static const _filterKeys = ['','high_match','near_campus','female','male'];

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    final params = <String>[];
    final key = _filterKeys[_filter];
    if (key.isNotEmpty) params.add('filter=$key');
    if (_query.isNotEmpty) params.add('search=${Uri.encodeComponent(_query)}');
    final qs = params.isEmpty ? '' : '?${params.join('&')}';
    try {
      final res = await ApiClient.get('/api/v1/housing/roommates/$qs');
      dev.log('[Roommates] GET $qs → ${res.statusCode}');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final raw = _unwrapList(jsonDecode(res.body));
        setState(() {
          _roommates = raw.whereType<Map<String, dynamic>>()
              .map(_Roommate.fromJson).toList();
          _loading = false;
        });
        dev.log('[Roommates] ${_roommates.length} profiles');
      } else {
        setState(() { _error = 'Could not load profiles (${res.statusCode}).'; _loading = false; });
      }
    } catch (e, s) {
      dev.log('[Roommates] $e', stackTrace: s);
      if (mounted) setState(() { _error = 'Network error. Pull to refresh.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HHColors.surface2,
      appBar: AppBar(
        backgroundColor: HHColors.surface, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: HHColors.text),
          onPressed: () => Navigator.pop(context)),
        title: const Text('Roommate Matching',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: HHColors.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HHRoommatePrefsScreen()))
              .then((_) => _load()),
            child: Text('My Prefs',
              style: TextStyle(color: HHColors.brand, fontWeight: FontWeight.w700))),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: HHColors.border, height: 1))),
      body: RefreshIndicator(
        color: HHColors.teal, onRefresh: _load,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: _HHInlineSearchBar(
              hint: 'Search by name, course, area…',
              onChanged: (v) {
                setState(() => _query = v);
                final now = DateTime.now(); _lastSearch = now;
                Future.delayed(const Duration(milliseconds: 500),
                  () { if (_lastSearch == now) _load(); });
              })),

          SliverToBoxAdapter(
            child: SizedBox(height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 7),
                itemBuilder: (_, i) => HHChip(
                  label: _filters[i], active: _filter == i,
                  onTap: () { setState(() => _filter = i); _load(); })))),

          SliverToBoxAdapter(child: HHSectionLabel(
            title: '👫 Top Matches for You',
            action: 'Update prefs →',
            onAction: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HHRoommatePrefsScreen()))
              .then((_) => _load()))),

          if (_loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            SliverFillRemaining(child: Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: HHColors.text3)),
                const SizedBox(height: 12),
                TextButton.icon(onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry')),
              ])))
          else if (_roommates.isEmpty)
            const SliverFillRemaining(child: Center(child: Text('No matches found.',
              style: TextStyle(fontSize: 13, color: HHColors.text3))))
          else
            SliverList(delegate: SliverChildBuilderDelegate(
              (_, i) {
                if (i == _roommates.length) return const SizedBox(height: 100);
                final r = _roommates[i];
                return _RoommateCard(
                  roommate: r,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => HHRoommateDetailScreen(roommateId: r.id, snapshot: r))));
              },
              childCount: _roommates.length + 1)),
        ])),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 2 — Roommate Detail
// ─────────────────────────────────────────────────────────────
class HHRoommateDetailScreen extends StatefulWidget {
  final String roommateId;
  final _Roommate? snapshot;
  const HHRoommateDetailScreen({super.key, required this.roommateId, this.snapshot});
  @override
  State<HHRoommateDetailScreen> createState() => _HHRoommateDetailScreenState();
}

class _HHRoommateDetailScreenState extends State<HHRoommateDetailScreen> {
  _Roommate? _roommate;
  Map<String, dynamic>? _detail;
  bool _loading = true;
  bool _opening = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.snapshot != null) { _roommate = widget.snapshot; _loading = false; }
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final res = await ApiClient.get('/api/v1/housing/roommates/${widget.roommateId}/');
      dev.log('[RoommateDetail] GET → ${res.statusCode}');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final profile = _unwrapObject(jsonDecode(res.body));
        if (profile != null) {
          setState(() { _roommate = _Roommate.fromJson(profile); _detail = profile; _loading = false; });
        } else { setState(() => _loading = false); }
      } else if (_roommate == null) {
        setState(() { _error = 'Could not load profile (${res.statusCode}).'; _loading = false; });
      } else { setState(() => _loading = false); }
    } catch (e) {
      dev.log('[RoommateDetail] $e');
      if (mounted && _roommate == null) setState(() { _error = 'Network error.'; _loading = false; });
      else if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _connectWhatsApp() async {
    final r = _roommate; if (r == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _opening = true);
    await _openWhatsApp(context, r);
    if (mounted) setState(() => _opening = false);
  }

  String _field(String key, String fb) => _detail?[key]?.toString() ?? fb;

  @override
  Widget build(BuildContext context) {
    if (_error != null && _roommate == null) {
      return Scaffold(
        backgroundColor: HHColors.surface2,
        appBar: AppBar(
          backgroundColor: HHColors.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: HHColors.text),
            onPressed: () => Navigator.pop(context))),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_error!, textAlign: TextAlign.center,
            style: const TextStyle(color: HHColors.text3)),
          const SizedBox(height: 12),
          TextButton.icon(onPressed: _fetchDetail,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry')),
        ])));
    }

    final r = _roommate;
    if (r == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final budget = _field('budget_range', '');
    final about  = _field('about', '');

    return Scaffold(
      backgroundColor: HHColors.surface2,
      appBar: AppBar(
        backgroundColor: HHColors.surface, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: HHColors.text),
          onPressed: () => Navigator.pop(context)),
        title: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: HHColors.text)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: HHColors.border, height: 1))),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Hero card ──────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: HHTheme.card,
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(width: 64, height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [r.gradA, r.gradB]),
                  borderRadius: BorderRadius.circular(18)),
                child: Center(child: Text(r.emoji, style: const TextStyle(fontSize: 30)))),
              const SizedBox(width: 14),
              // Flexible prevents overflow on long full_name values
              Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: HHColors.text)),
                Text(r.course, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: HHColors.text2)),
                Text(r.year,
                  style: const TextStyle(fontSize: 12, color: HHColors.text3)),
              ])),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: HHColors.tealPale, borderRadius: BorderRadius.circular(10)),
                child: Text('${r.matchPct}%',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: HHColors.teal))),
            ])),

          if (_loading)
            const Padding(padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator())),

          HHFormField(label: 'Preferred Location', value: r.location.isNotEmpty ? r.location : '—'),
          if (budget.isNotEmpty) HHFormField(label: 'Budget Range', value: budget),

          if (r.prefs.isNotEmpty) ...[
            HHSectionLabel(title: 'Lifestyle Preferences'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(spacing: 8, runSpacing: 8,
                children: r.prefs.map<Widget>((p) =>
                  HHTag(p, bg: HHColors.brandPale, fg: HHColors.brand)).toList())),
            const SizedBox(height: 14),
          ],

          if (about.isNotEmpty)
            HHFormField(label: 'About', value: about, multiline: true),

          const SizedBox(height: 16),

          // ── WhatsApp connect button ────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _opening ? null : _connectWhatsApp,
                icon: _opening
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('💬', style: TextStyle(fontSize: 18)),
                label: Text(_opening ? 'Opening WhatsApp…' : 'Connect on WhatsApp',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))))),

          const SizedBox(height: 40),
        ])),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 3 — My Roommate Preferences
// ─────────────────────────────────────────────────────────────
class HHRoommatePrefsScreen extends StatefulWidget {
  const HHRoommatePrefsScreen({super.key});
  @override
  State<HHRoommatePrefsScreen> createState() => _HHRoommatePrefsScreenState();
}

class _HHRoommatePrefsScreenState extends State<HHRoommatePrefsScreen> {
  String _sleep = 'Night owl'; String _clean = 'Very tidy'; String _noise = 'Quiet';
  bool   _noSmoke = true;      bool   _petsOk = false;
  int    _budget  = 12000;
  bool   _loading = true;      bool   _saving  = false;

  final _locs    = ['Parklands','Westlands','CBD','Ngara','Highridge'];
  final _selLocs = <String>{'Parklands','Westlands'};

  @override void initState() { super.initState(); _fetchMyProfile(); }

  Future<void> _fetchMyProfile() async {
    if (mounted) setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/api/v1/housing/roommates/my-profile/');
      dev.log('[RoommatePrefs] GET → ${res.statusCode}');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final j = _unwrapObject(jsonDecode(res.body));
        if (j != null) setState(() {
          _sleep   = j['sleep_schedule']?.toString() ?? j['sleepSchedule']?.toString() ?? _sleep;
          _clean   = j['cleanliness']?.toString() ?? _clean;
          _noise   = j['noise_level']?.toString() ?? j['noiseLevel']?.toString() ?? _noise;
          _noSmoke = j['no_smoking'] as bool? ?? j['smoking'] as bool? ?? _noSmoke;
          _petsOk  = j['pets_ok'] as bool?    ?? j['pets'] as bool?    ?? _petsOk;
          _budget  = (j['budget_max'] as num?)?.toInt() ?? (j['budgetMax'] as num?)?.toInt() ?? _budget;
          final locs = (j['preferred_locations'] as List?)?.map((e) => e.toString()).toSet()
              ?? (j['preferredAreas'] as List?)?.map((e) => e.toString()).toSet();
          if (locs != null) { _selLocs..clear()..addAll(locs); }
        });
      }
    } catch (e) { dev.log('[RoommatePrefs] $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final res = await ApiClient.post('/api/v1/housing/roommates/my-profile/', body: {
        'sleep_schedule': _sleep, 'cleanliness': _clean, 'noise_level': _noise,
        'no_smoking': _noSmoke, 'pets_ok': _petsOk,
        'budget_max': _budget, 'preferred_locations': _selLocs.toList(),
      });
      dev.log('[RoommatePrefs] POST → ${res.statusCode}');
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Preferences saved! Finding your matches…'),
          backgroundColor: HHColors.teal));
      } else {
        final err = jsonDecode(res.body) as Map<String, dynamic>?;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err?['detail']?.toString() ?? 'Could not save (${res.statusCode}).'),
          backgroundColor: HHColors.brandDark));
      }
    } catch (e) {
      dev.log('[RoommatePrefs] save error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HHColors.surface2,
      appBar: AppBar(
        backgroundColor: HHColors.surface, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: HHColors.text),
          onPressed: () => Navigator.pop(context)),
        title: const Text('My Roommate Preferences',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: HHColors.text)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: HHColors.border, height: 1))),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              HHSectionLabel(title: 'Budget Range'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: HHColors.surface,
                      border: Border.all(color: HHColors.border),
                      borderRadius: BorderRadius.circular(10)),
                    child: const Column(children: [
                      Text('Min', style: TextStyle(fontSize: 10, color: HHColors.text3)),
                      Text('KES 5,000', style: TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w800, color: HHColors.brand)),
                    ]))),
                  const SizedBox(width: 10),
                  Expanded(child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: HHColors.surface,
                      border: Border.all(color: HHColors.border),
                      borderRadius: BorderRadius.circular(10)),
                    child: Column(children: [
                      const Text('Max', style: TextStyle(fontSize: 10, color: HHColors.text3)),
                      Text('KES $_budget', style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w800, color: HHColors.brand)),
                    ]))),
                ])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Slider(
                  value: _budget.toDouble(), min: 5000, max: 30000,
                  activeColor: HHColors.brand,
                  onChanged: (v) => setState(() => _budget = v.round()))),

              HHSectionLabel(title: 'Preferred Location'),
              SizedBox(height: 50, child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _locs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 7),
                itemBuilder: (_, i) => HHChip(
                  label: _selLocs.contains(_locs[i]) ? '${_locs[i]} ✓' : _locs[i],
                  active: _selLocs.contains(_locs[i]),
                  onTap: () => setState(() {
                    if (_selLocs.contains(_locs[i])) _selLocs.remove(_locs[i]);
                    else _selLocs.add(_locs[i]);
                  })))),

              HHSectionLabel(title: 'Lifestyle Preferences'),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: HHTheme.card,
                child: Column(children: [
                  _PrefRow(label: '🌙 Sleep Schedule', options: ['Early bird','Night owl'],
                    value: _sleep, onChanged: (v) => setState(() => _sleep = v)),
                  Divider(color: HHColors.border, height: 1),
                  _PrefRow(label: '🧹 Cleanliness', options: ['Relaxed','Very tidy'],
                    value: _clean, onChanged: (v) => setState(() => _clean = v)),
                  Divider(color: HHColors.border, height: 1),
                  _PrefRow(label: '🎵 Noise Level', options: ['Quiet','Moderate','Social'],
                    value: _noise, onChanged: (v) => setState(() => _noise = v)),
                  Divider(color: HHColors.border, height: 1),
                  HHToggleRow(label: '🚬 Non-smoker preferred',
                    subtitle: 'Only match with non-smokers',
                    value: _noSmoke, onChanged: (v) => setState(() => _noSmoke = v)),
                  Divider(color: HHColors.border, height: 1),
                  HHToggleRow(label: '🐾 Pets okay',
                    subtitle: 'Open to roommates with pets',
                    value: _petsOk, onChanged: (v) => setState(() => _petsOk = v)),
                ])),

              HHPrimaryButton(
                label: _saving ? '⏳ Saving…' : '💾 Save & Find Matches',
                onTap: _saving ? null : _save),
            ])));
  }
}

// ─────────────────────────────────────────────────────────────
//  Private widgets
// ─────────────────────────────────────────────────────────────

class _HHInlineSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _HHInlineSearchBar({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 13, 16, 0),
      decoration: BoxDecoration(
        color: HHColors.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HHColors.border, width: 1.5),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Row(children: [
        const Padding(padding: EdgeInsets.only(left: 14),
          child: Text('🔍', style: TextStyle(fontSize: 16))),
        Expanded(child: TextField(
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: HHColors.text3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            border: InputBorder.none))),
        Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(color: HHColors.brandPale, borderRadius: BorderRadius.circular(8)),
          child: const Text('Filter',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: HHColors.brand))),
      ]));
  }
}

/// Browse-list card.
/// [Flexible] wraps the text column so long full_name values
/// never push the match badge off screen (was 75 px overflow).
class _RoommateCard extends StatelessWidget {
  final _Roommate roommate;
  final VoidCallback onTap;
  const _RoommateCard({required this.roommate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(14),
        decoration: HHTheme.card,
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Avatar
          Container(width: 54, height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [roommate.gradA, roommate.gradB]),
              borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text(roommate.emoji, style: const TextStyle(fontSize: 24)))),
          const SizedBox(width: 12),
          // Text + badge — Flexible absorbs excess width
          Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(roommate.name,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: HHColors.text))),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: HHColors.tealPale, borderRadius: BorderRadius.circular(8)),
                child: Text('${roommate.matchPct}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: HHColors.teal))),
            ]),
            const SizedBox(height: 2),
            Text(roommate.course, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: HHColors.text2)),
            Text('📍 ${roommate.location}', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: HHColors.text3)),
            if (roommate.prefs.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(spacing: 5, runSpacing: 5,
                children: roommate.prefs.take(3).map<Widget>((p) =>
                  HHTag(p, bg: HHColors.brandPale, fg: HHColors.brand)).toList()),
            ],
          ])),
        ])));
  }
}

class _PrefRow extends StatelessWidget {
  final String label, value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  const _PrefRow({required this.label, required this.options,
    required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: HHColors.text))),
        const SizedBox(width: 8),
        Wrap(spacing: 5, children: options.map<Widget>((o) =>
          GestureDetector(
            onTap: () => onChanged(o),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: value == o ? HHColors.brand : HHColors.surface3,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: value == o ? HHColors.brand : HHColors.border)),
              child: Text(o, style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: value == o ? Colors.white : HHColors.text2))))).toList()),
      ]));
  }
}