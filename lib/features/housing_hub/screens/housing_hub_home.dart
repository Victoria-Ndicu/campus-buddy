import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/hh_constants.dart';
import '../widgets/hh_widgets.dart';
import 'hh_listings_screen.dart';
import 'hh_roommate_screen.dart';
import 'hh_alerts_screen.dart';
import '../../../core/api_client.dart';

// ─────────────────────────────────────────────────────────────
//  API ENDPOINTS
//
//  GET /api/v1/housing/stats/          → { listings, matches, near_campus, alerts }
//  GET /api/v1/housing/listings/       → latest listings preview
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────────────────────
class _Stats {
  final int listings, matches, nearCampus, alerts;
  const _Stats({
    this.listings   = 0,
    this.matches    = 0,
    this.nearCampus = 0,
    this.alerts     = 0,
  });

  factory _Stats.fromJson(Map<String, dynamic> j) => _Stats(
    listings:   (j['listings']    as num?)?.toInt() ?? 0,
    matches:    (j['matches']     as num?)?.toInt() ?? 0,
    nearCampus: (j['near_campus'] as num?)?.toInt() ?? 0,
    alerts:     (j['alerts']      as num?)?.toInt() ?? 0,
  );
}

// ─────────────────────────────────────────────────────────────
//  HousingHubHome
// ─────────────────────────────────────────────────────────────
class HousingHubHome extends StatefulWidget {
  const HousingHubHome({super.key});
  @override
  State<HousingHubHome> createState() => _HousingHubHomeState();
}

class _HousingHubHomeState extends State<HousingHubHome> {
  _Stats  _stats           = const _Stats();
  List<HousingListing> _previews = [];
  bool    _loadingStats    = true;
  bool    _loadingPreviews = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchPreviews();
  }

  // ─────────────────────────────────────────────────────────
  //  GET /api/v1/housing/stats/
  // ─────────────────────────────────────────────────────────
  Future<void> _fetchStats() async {
    try {
      final res = await ApiClient.get('/api/v1/housing/stats/');
      dev.log('[HousingHome] GET /housing/stats/ → ${res.statusCode}');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>?;
        if (j != null) setState(() => _stats = _Stats.fromJson(j));
      }
    } catch (e) {
      dev.log('[HousingHome] stats error: $e');
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  GET /api/v1/housing/listings/?page_size=3
  //  Uses HousingListing.fromJson — same model as the full
  //  listings screen, so navigation just works.
  // ─────────────────────────────────────────────────────────
  Future<void> _fetchPreviews() async {
    try {
      final res = await ApiClient.get(
          '/api/v1/housing/listings/?page_size=3');
      dev.log('[HousingHome] GET /housing/listings/ → ${res.statusCode}');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final raw = decoded is List
            ? decoded
            : (decoded['results'] as List?) ?? [];
        setState(() {
          _previews = raw
              .whereType<Map<String, dynamic>>()
              .map(HousingListing.fromJson)
              .toList();
        });
      }
    } catch (e) {
      dev.log('[HousingHome] previews error: $e');
    } finally {
      if (mounted) setState(() => _loadingPreviews = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loadingStats    = true;
      _loadingPreviews = true;
    });
    await Future.wait([_fetchStats(), _fetchPreviews()]);
  }

  @override
  Widget build(BuildContext context) {
    final modules = [
      _ModuleCard(
        emoji: '🏠', title: 'Browse Listings',
        subtitle: _loadingStats
            ? 'Loading…'
            : '${_stats.listings} available now',
        colorA: HHColors.brand,
        colorB: HHColors.brandDark,
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(context, MaterialPageRoute(
              builder: (_) => const HHListingsScreen()));
        },
      ),
      _ModuleCard(
        emoji: '👫', title: 'Roommate Match',
        subtitle: _loadingStats
            ? 'Loading…'
            : '${_stats.matches} new profiles',
        colorA: HHColors.teal,
        colorB: const Color(0xFF0A7A70),
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(context, MaterialPageRoute(
              builder: (_) => const HHRoommateScreen()));
        },
      ),
      _ModuleCard(
        emoji: '🔔', title: 'My Alerts',
        subtitle: _loadingStats
            ? 'Loading…'
            : '${_stats.alerts} active alerts',
        colorA: HHColors.amber,
        colorB: const Color(0xFFD97706),
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(context, MaterialPageRoute(
              builder: (_) => const HHAlertsScreen()));
        },
      ),
    ];

    return Scaffold(
      backgroundColor: HHColors.surface2,
      body: RefreshIndicator(
        color: HHColors.brand,
        onRefresh: _refresh,
        child: CustomScrollView(slivers: [

          // ── App Bar ────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: HHColors.brandDark,
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
                    colors: [HHColors.brand, HHColors.brandDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(children: [
                  Positioned(top: -40, right: -30,
                    child: Container(width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08)))),
                  Positioned(
                    bottom: 20, left: 16, right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Housing Hub', style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w900,
                          color: Colors.white, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text(
                          _loadingStats
                              ? 'Loading listings…'
                              : 'Nairobi · ${_stats.listings} listings available',
                          style: TextStyle(fontSize: 13,
                              color: Colors.white.withOpacity(0.75))),
                        const SizedBox(height: 14),
                        _loadingStats
                          ? SizedBox(height: 40,
                              child: Center(child: SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white.withOpacity(0.6)))))
                          : Row(children: [
                              _StatPill('🏠', '${_stats.listings}',   'Listings'),
                              _StatPill('👫', '${_stats.matches}',    'Matches'),
                              _StatPill('📍', '${_stats.nearCampus}', 'Near Campus'),
                              _StatPill('🔔', '${_stats.alerts}',     'Alerts'),
                            ]),
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
                        builder: (_) => const HHAlertsScreen())),
              ),
              const SizedBox(width: 4),
            ],
          ),

          // ── Search bar ─────────────────────────────────────
          SliverToBoxAdapter(child: HHSearchBar(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const HHListingsScreen())),
          )),

          // ── Module grid ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12, crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: modules,
              ),
            ),
          ),

          // ── Hero banner ────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [HHColors.brand, HHColors.brandDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(children: [
                Positioned(right: 10, top: 0, bottom: 0,
                  child: Text('🏠', style: TextStyle(
                    fontSize: 72,
                    color: Colors.white.withOpacity(0.15)))),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Find Your Home\nAway From Home',
                      style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900,
                        color: Colors.white, height: 1.25)),
                    const SizedBox(height: 6),
                    Text(
                      'Browse student-friendly accommodation near campus. Verified listings, real prices.',
                      style: TextStyle(fontSize: 12,
                          color: Colors.white.withOpacity(0.8))),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const HHListingsScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10)),
                        child: Text('Browse All →',
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800,
                            color: HHColors.brand)),
                      ),
                    ),
                  ]),
              ]),
            ),
          ),

          // ── Latest listings header ─────────────────────────
          SliverToBoxAdapter(
            child: HHSectionLabel(
              title: '🏠 Latest Listings',
              action: 'See all →',
              onAction: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const HHListingsScreen())),
            ),
          ),

          // ── Latest listings body ───────────────────────────
          if (_loadingPreviews)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator())))
          else if (_previews.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 20),
                child: Text('No listings available right now.',
                  style: TextStyle(
                    fontSize: 13, color: HHColors.text3))))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  if (i == _previews.length) {
                    return const SizedBox(height: 100);
                  }
                  final l = _previews[i];
                  return _PreviewCard(
                    listing: l,
                    // ✅ FIX: pass the full HousingListing object
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                        builder: (_) => HHListingDetailScreen(
                          listing: l,
                        ))),
                  );
                },
                childCount: _previews.length + 1,
              )),
        ]),
      ),

      // ── Bottom Nav ─────────────────────────────────────────
      bottomNavigationBar: _HHBottomNav(
        selected: 0,
        onTap: (i) {
          switch (i) {
            case 1:
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const HHRoommateScreen()));
            case 2:
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const HHAlertsScreen()));
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Private widgets
// ─────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String emoji, value, label;
  const _StatPill(this.emoji, this.value, this.label);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: const TextStyle(
        fontSize: 20, fontWeight: FontWeight.w900,
        color: Colors.white)),
      Text(label, style: TextStyle(
        fontSize: 10, color: Colors.white.withOpacity(0.65))),
    ]),
  );
}

class _ModuleCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color colorA, colorB;
  final VoidCallback onTap;
  const _ModuleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.colorA,
    required this.colorB,
    required this.onTap,
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [colorA, colorB],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            child: Stack(children: [
              Positioned(top: -16, right: -16,
                child: Container(width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
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
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.75))),
                ]),
              Positioned(top: 0, right: 0,
                child: Container(
                  width: 24, height: 24,
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

class _PreviewCard extends StatelessWidget {
  final HousingListing listing;
  final VoidCallback onTap;
  const _PreviewCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: HHTheme.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // image area
            Container(
              height: 130,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [listing.gradA, listing.gradB],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18)),
              ),
              child: Stack(children: [
                Center(child: Text(listing.emoji,
                    style: const TextStyle(fontSize: 56))),
                Positioned(top: 10, left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8)),
                    child: Text(listing.tagLabel, style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: listing.typeColor)))),
                Positioned(top: 10, right: 10,
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle),
                    child: const Center(child: Text('🤍',
                        style: TextStyle(fontSize: 14))))),
              ]),
            ),
            // body
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.title, style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800,
                    color: HHColors.text)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('KES ${listing.rentPerMonth}',
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900,
                        color: HHColors.brand)),
                    Text(' /month', style: TextStyle(
                      fontSize: 11, color: HHColors.text3)),
                  ]),
                  const SizedBox(height: 3),
                  Text(listing.locationName, style: TextStyle(
                    fontSize: 11, color: HHColors.text3)),
                  if (listing.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 5, runSpacing: 5,
                      children: listing.tags.map<Widget>((t) =>
                        HHTag(HousingListing.labelFor(t),
                          bg: HHColors.greenPale,
                          fg: HHColors.teal)
                      ).toList()),
                  ],
                  const SizedBox(height: 10),
                  Divider(color: HHColors.border, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        listing.availableFrom != null
                          ? '📅 ${listing.availableFrom}'
                          : '📅 Available Now',
                        style: TextStyle(
                          fontSize: 11,
                          color: listing.availableFrom != null
                            ? HHColors.text3 : HHColors.green,
                          fontWeight: listing.availableFrom == null
                            ? FontWeight.w700 : FontWeight.normal)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: HHColors.brand,
                          borderRadius: BorderRadius.circular(10)),
                        child: const Text('View →', style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800,
                          color: Colors.white))),
                    ]),
                ]),
            ),
          ]),
      ),
    );
  }
}

class _HHBottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _HHBottomNav({required this.selected, required this.onTap});

  static const _items = [
    ('🏠', 'Home'),
    ('👫', 'Match'),
    ('🔔', 'Alerts'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: HHColors.border)),
      ),
      padding: EdgeInsets.only(
          top: 10,
          bottom: MediaQuery.of(context).padding.bottom + 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final active = i == selected;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap(i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? HHColors.brand.withOpacity(0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_items[i].$1,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 3),
                  Text(_items[i].$2, style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: active
                        ? HHColors.brand : HHColors.text3)),
                ]),
            ),
          );
        }),
      ),
    );
  }
}