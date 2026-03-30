// campus_market/screens/campus_market_home.dart
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cm_constants.dart';
import '../widgets/cm_widgets.dart';
import '../../../core/api_client.dart';
import 'cm_listings_screen.dart';
import 'cm_post_screen.dart';
import 'cm_donations_screen.dart';

// ─────────────────────────────────────────────────────────────
//  API ENDPOINTS  (all under /api/v1/market/)
//
//  GET    /api/v1/market/listings/                          → list all listings
//  POST   /api/v1/market/listings/                          → create listing
//  GET    /api/v1/market/listings/<uuid>/                   → listing detail
//  PATCH  /api/v1/market/listings/<uuid>/                   → update listing
//  DELETE /api/v1/market/listings/<uuid>/                   → delete listing
//  POST   /api/v1/market/uploads/                           → upload image
//  POST   /api/v1/market/donations/<uuid>/claim/            → claim donation
//  GET    /api/v1/market/donations/<uuid>/claims/<uuid>/    → claim detail
//  GET    /api/v1/market/messages/                          → all messages
//  POST   /api/v1/market/messages/                          → send message
//  GET    /api/v1/market/messages/<uuid>/                   → messages for listing
//  GET    /api/v1/market/saved/                             → saved listings
//  POST   /api/v1/market/saved/                             → save listing
//  DELETE /api/v1/market/saved/                             → unsave listing
//  GET    /api/v1/market/reviews/                           → reviews
//  POST   /api/v1/market/reviews/                           → post review
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
//  HUB SCREEN
// ─────────────────────────────────────────────────────────────
class CampusMarketHome extends StatefulWidget {
  const CampusMarketHome({super.key});
  @override
  State<CampusMarketHome> createState() => _CampusMarketHomeState();
}

class _CampusMarketHomeState extends State<CampusMarketHome> {
  List<CMListing> _featured    = [];
  CMStats         _stats       = const CMStats();
  bool            _loadingFeed = true;
  String?         _feedError;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  // ─────────────────────────────────────────────────────────
  //  READ: GET /api/v1/market/listings/
  // ─────────────────────────────────────────────────────────
  Future<void> _loadFeed() async {
    if (mounted) setState(() { _loadingFeed = true; _feedError = null; });
    try {
      final res = await ApiClient.get('/api/v1/market/listings/');
      dev.log('[CMHome] GET /listings → ${res.statusCode}');
      dev.log('[CMHome] body: ${res.body}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final raw = decoded is List
            ? decoded
            : (decoded['results'] as List?) ?? [];

        final listings = raw
            .whereType<Map<String, dynamic>>()
            .map(CMListing.fromJson)
            .toList();

        setState(() {
          _featured    = listings.take(3).toList();
          _stats       = CMStats.fromListings(listings);
          _loadingFeed = false;
        });
      } else {
        setState(() {
          _feedError   = 'Could not load listings (${res.statusCode}).';
          _loadingFeed = false;
        });
      }
    } catch (e, s) {
      dev.log('[CMHome] _loadFeed error: $e', stackTrace: s);
      if (mounted) setState(() {
        _feedError   = 'Network error. Pull to refresh.';
        _loadingFeed = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────
  //  UPDATE: Save / unsave listing
  //  POST   /api/v1/market/saved/   { listingId }
  //  DELETE /api/v1/market/saved/   { listingId }
  // ─────────────────────────────────────────────────────────
  Future<void> _toggleSave(CMListing listing) async {
    final wasSaved = listing.isSaved;
    setState(() {
      _featured = _featured.map((l) =>
          l.id == listing.id ? l.copyWith(isSaved: !wasSaved) : l).toList();
    });

    try {
      final res = wasSaved
          ? await ApiClient.delete('/api/v1/market/saved/',
              body: {'listingId': listing.id})
          : await ApiClient.post('/api/v1/market/saved/',
              body: {'listingId': listing.id});

      dev.log('[CMHome] Save ${listing.id} → ${res.statusCode}');

      final ok = res.statusCode == 200 ||
                 res.statusCode == 201 ||
                 res.statusCode == 204;
      if (!ok) {
        setState(() {
          _featured = _featured.map((l) =>
              l.id == listing.id ? l.copyWith(isSaved: wasSaved) : l).toList();
        });
        _snack('Could not save listing. Please try again.');
      } else {
        _snack(wasSaved ? 'Listing unsaved.' : '❤️ Listing saved!');
      }
    } catch (_) {
      setState(() {
        _featured = _featured.map((l) =>
            l.id == listing.id ? l.copyWith(isSaved: wasSaved) : l).toList();
      });
      _snack('Network error. Please try again.');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: CMColors.brandDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      ));
  }

  // ─────────────────────────────────────────────────────────
  //  Module definitions
  // ─────────────────────────────────────────────────────────
  List<_ModuleItem> get _modules => [
    _ModuleItem('🛍', 'Browse Listings', 'Buy · Browse · Search',
        '${_stats.newListings} new today',
        const Color(0xFFE07A5F), const Color(0xFFC4674E)),
    _ModuleItem('➕', 'Post an Item', 'Sell · Donate · Price',
        'Quick & easy',
        const Color(0xFFEA9A84), const Color(0xFFE07A5F)),
    _ModuleItem('🎁', 'Free Donations', 'Free items near you',
        '${_stats.freeItems} free items',
        const Color(0xFF10B981), const Color(0xFF0D9488)),
    _ModuleItem('⭐', 'Top Sellers', 'Rated · Verified',
        '${_stats.activeSellers} sellers',
        const Color(0xFFF59E0B), const Color(0xFFD97706)),
  ];

  List<_StatItem> get _statItems => [
    _StatItem('🛒', '${_stats.newListings}',   'New Listings'),
    _StatItem('🎁', '${_stats.freeItems}',     'Free Items'),
    _StatItem('⭐', '${_stats.activeSellers}', 'Active Sellers'),
    _StatItem('🔥', '${_stats.dealsToday}',    'Deals Today'),
  ];

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CMColors.surface2,
      body: RefreshIndicator(
        color: CMColors.brand,
        onRefresh: _loadFeed,
        child: CustomScrollView(slivers: [

          // ── App Bar ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 195,
            pinned: true,
            backgroundColor: CMColors.brand,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.white),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context,
                    MaterialPageRoute(
                      builder: (_) => const CMListingsScreen()));
                }),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _CMHeader(
                stats: _stats, loading: _loadingFeed)),
          ),

          // ── Stats strip ───────────────────────────────
          SliverToBoxAdapter(
            child: _StatsStrip(
              items: _statItems,
              loading: _loadingFeed)),

          // ── Module grid ───────────────────────────────
          SliverToBoxAdapter(
            child: CMSectionLabel(title: '🧭 What are you looking for?')),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              delegate: SliverChildListDelegate(
                _modules.map<Widget>((m) => _ModuleCard(
                  module: m,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    if (m.title == 'Browse Listings') {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const CMListingsScreen()));
                    } else if (m.title == 'Post an Item') {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const CMPostScreen()));
                    } else if (m.title == 'Free Donations') {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const CMDonationsScreen()));
                    } else {
                      _snack('Top Sellers — coming soon!');
                    }
                  },
                )).toList(),
              ),
            ),
          ),

          // ── Featured listings ─────────────────────────
          SliverToBoxAdapter(
            child: CMSectionLabel(
              title: '🔥 Featured Listings',
              action: 'See all →',
              onAction: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CMListingsScreen())),
            )),

          // Loading / error / list
          if (_loadingFeed)
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator())))
          else if (_feedError != null)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_feedError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13, color: CMColors.text3)),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _loadFeed,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry')),
                    ]))))
          else
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: _featured.isEmpty
                  ? Center(child: Text('No listings yet.',
                      style: TextStyle(
                        fontSize: 13, color: CMColors.text3)))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _featured.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final item = _featured[i];
                        return _FeaturedCard(
                          listing: item,
                          onSaveTap: () => _toggleSave(item),
                          // ✅ Fixed: uses listingId + snapshot only
                          onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                              builder: (_) => CMListingDetailScreen(
                                listingId: item.id,
                                snapshot:  item,
                              ))).then((_) => _loadFeed()),
                        );
                      },
                    ))),

          // ── Quick post CTA ────────────────────────────
          SliverToBoxAdapter(child: _QuickPostBanner(
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CMPostScreen()))
                .then((_) => _loadFeed()),
          )),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────
class _CMHeader extends StatelessWidget {
  final CMStats stats;
  final bool    loading;
  const _CMHeader({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CMTheme.headerGradient,
      child: Stack(children: [
        Positioned(top: -30, right: -20,
          child: Container(width: 140, height: 140,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.07)))),
        Positioned(bottom: 20, left: -30,
          child: Container(width: 100, height: 100,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05)))),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('🛒 CampusMarket', style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: Colors.white70, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                const Text('Buy. Sell. Donate.', style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900,
                  color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text(
                  loading
                    ? 'Loading listings…'
                    : '${stats.newListings} new listings this week · '
                      '${stats.freeItems} free items available',
                  style: TextStyle(
                    fontSize: 12, color: Colors.white.withOpacity(0.75))),
              ],
            )),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STATS STRIP
// ─────────────────────────────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  final List<_StatItem> items;
  final bool loading;
  const _StatsStrip({required this.items, required this.loading});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final s = items[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CMColors.border),
              boxShadow: [BoxShadow(
                color: CMColors.brand.withOpacity(0.07),
                blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(s.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  loading
                    ? const SizedBox(width: 24, height: 18,
                        child: Center(child: CircularProgressIndicator(
                          strokeWidth: 2)))
                    : Text(s.value, style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900,
                        color: CMColors.brand, height: 1)),
                  const SizedBox(height: 2),
                  Text(s.label, style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: CMColors.text3)),
                ]),
            ]),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MODULE CARD
// ─────────────────────────────────────────────────────────────
class _ModuleCard extends StatelessWidget {
  final _ModuleItem  module;
  final VoidCallback onTap;
  const _ModuleCard({required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withOpacity(0.15),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [module.colorA, module.colorB]),
            ),
            child: Stack(children: [
              Positioned(top: -18, right: -18,
                child: Container(width: 70, height: 70,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.09)))),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(20)),
                  child: Text(module.badge, style: const TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w800,
                    color: Colors.white))),
                const Spacer(),
                Text(module.emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(height: 5),
                Text(module.title, style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w900,
                  color: Colors.white)),
                const SizedBox(height: 2),
                Text(module.subtitle, style: TextStyle(
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
//  FEATURED CARD
// ─────────────────────────────────────────────────────────────
class _FeaturedCard extends StatelessWidget {
  final CMListing    listing;
  final VoidCallback onTap;
  final VoidCallback onSaveTap;
  const _FeaturedCard({
    required this.listing,
    required this.onTap,
    required this.onSaveTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CMColors.border),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image / gradient banner
          Container(
            height: 96,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16)),
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [listing.gradA, listing.gradB]),
            ),
            child: Stack(children: [
              Center(child: Text(listing.emoji,
                style: const TextStyle(fontSize: 44))),
              Positioned(top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(7)),
                  child: Text(listing.category, style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w800,
                    color: CMColors.brandDark)))),
              Positioned(top: 8, right: 8,
                child: GestureDetector(
                  onTap: onSaveTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: listing.isSaved
                        ? Colors.red.withOpacity(0.85)
                        : Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle),
                    child: Center(child: Text(
                      listing.isSaved ? '❤️' : '🤍',
                      style: const TextStyle(fontSize: 13)))))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing.title, maxLines: 2,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                    color: CMColors.text, height: 1.3)),
                const SizedBox(height: 4),
                Text(listing.price, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w900,
                  color: listing.isFree ? CMColors.green : CMColors.brand)),
                const SizedBox(height: 2),
                Text(listing.condition, style: TextStyle(
                  fontSize: 10, color: CMColors.text3)),
              ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  QUICK POST BANNER
// ─────────────────────────────────────────────────────────────
class _QuickPostBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _QuickPostBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [CMColors.brand, CMColors.brandDark]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
            color: CMColors.brand.withOpacity(0.3),
            blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Got something to sell?', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900,
                color: Colors.white)),
              const SizedBox(height: 4),
              Text('Post a listing in under 2 minutes →',
                style: TextStyle(
                  fontSize: 12, color: Colors.white.withOpacity(0.8))),
            ])),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12)),
            child: const Text('➕', style: TextStyle(fontSize: 24))),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PRIVATE DATA CLASSES  (UI only — not exported)
// ─────────────────────────────────────────────────────────────
class _StatItem {
  final String emoji, value, label;
  const _StatItem(this.emoji, this.value, this.label);
}

class _ModuleItem {
  final String emoji, title, subtitle, badge;
  final Color  colorA, colorB;
  const _ModuleItem(this.emoji, this.title, this.subtitle, this.badge,
      this.colorA, this.colorB);
}