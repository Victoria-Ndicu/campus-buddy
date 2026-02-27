// campus_market/screens/campus_market_home.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cm_constants.dart';
import '../widgets/cm_widgets.dart';
import 'cm_listings_screen.dart';
import 'cm_post_screen.dart';
import 'cm_donations_screen.dart';

// ─────────────────────────────────────────────────────────────
//  DATA
// ─────────────────────────────────────────────────────────────
class _StatItem {
  final String emoji, value, label;
  const _StatItem(this.emoji, this.value, this.label);
}

class _ModuleItem {
  final String emoji, title, subtitle, badge;
  final Color colorA, colorB;
  const _ModuleItem(this.emoji, this.title, this.subtitle, this.badge,
      this.colorA, this.colorB);
}

class _FeaturedItem {
  final String emoji, title, price, category, condition, seller;
  final Color gradA, gradB;
  const _FeaturedItem(this.emoji, this.title, this.price, this.category,
      this.condition, this.seller, this.gradA, this.gradB);
}

const _kStats = [
  _StatItem('🛒', '12', 'New Listings'),
  _StatItem('🎁', '5',  'Free Items'),
  _StatItem('⭐', '38', 'Active Sellers'),
  _StatItem('🔥', '3',  'Deals Today'),
];

const _kModules = [
  _ModuleItem('🛍', 'Browse Listings', 'Buy · Browse · Search', '12 new today',
      Color(0xFFE07A5F), Color(0xFFC4674E)),
  _ModuleItem('➕', 'Post an Item',    'Sell · Donate · Price', 'Quick & easy',
      Color(0xFFEA9A84), Color(0xFFE07A5F)),
  _ModuleItem('🎁', 'Free Donations',  'Free items near you',   '5 free items',
      Color(0xFF10B981), Color(0xFF0D9488)),
  _ModuleItem('⭐', 'Top Sellers',     'Rated · Verified',      '38 sellers',
      Color(0xFFF59E0B), Color(0xFFD97706)),
];

const _kFeatured = [
  _FeaturedItem('💻', 'HP Laptop 15"', 'KES 32,000', 'Electronics',
      'Used — Good', 'James M.', Color(0xFFFDF0EC), Color(0xFFEED5CC)),
  _FeaturedItem('📚', 'Engineering Textbooks (3)', 'KES 800',
      'Books', 'Like New', 'Amina K.',
      Color(0xFFEEF1FD), Color(0xFFC7D2FA)),
  _FeaturedItem('🎧', 'Sony Earphones WH-1000X', 'KES 4,500',
      'Electronics', 'Used — Excellent', 'Kevin O.',
      Color(0xFFECFDF5), Color(0xFFA7F3D0)),
];

// ─────────────────────────────────────────────────────────────
//  HUB SCREEN
// ─────────────────────────────────────────────────────────────
class CampusMarketHome extends StatelessWidget {
  const CampusMarketHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CMColors.surface2,
      body: CustomScrollView(slivers: [
        // 1. App Bar
        SliverAppBar(
          expandedHeight: 195,
          pinned: true,
          backgroundColor: CMColors.brand,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Colors.white),
              onPressed: () {
                HapticFeedback.selectionClick();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Search coming soon'),
                  behavior: SnackBarBehavior.floating,
                ));
              },
            ),
            const SizedBox(width: 4),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _CMHeader(),
          ),
        ),

        // 2. Stats strip
        SliverToBoxAdapter(child: _StatsStrip()),

        // 3. Module grid
        SliverToBoxAdapter(
          child: CMSectionLabel(title: '🧭 What are you looking for?'),
        ),
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
              _kModules.map<Widget>((m) => _ModuleCard(
                module: m,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  if (m.title == 'Browse Listings') {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => CMListingsScreen()));
                  } else if (m.title == 'Post an Item') {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => CMPostScreen()));
                  } else if (m.title == 'Free Donations') {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => CMDonationsScreen()));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${m.title} — coming soon'),
                      backgroundColor: CMColors.brandDark,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ));
                  }
                },
              )).toList(),
            ),
          ),
        ),

        // 4. Featured listings
        SliverToBoxAdapter(
          child: CMSectionLabel(
            title: '🔥 Featured Listings',
            action: 'See all →',
            onAction: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => CMListingsScreen())),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _kFeatured.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _FeaturedCard(
                item: _kFeatured[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CMListingDetailScreen(
                      title: _kFeatured[i].title,
                      price: _kFeatured[i].price,
                      category: _kFeatured[i].category,
                      condition: _kFeatured[i].condition,
                      seller: _kFeatured[i].seller,
                      emoji: _kFeatured[i].emoji,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // 5. Quick post CTA
        SliverToBoxAdapter(child: _QuickPostBanner(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => CMPostScreen())),
        )),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────
class _CMHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CMTheme.headerGradient,
      child: Stack(children: [
        // Background decoration circles
        Positioned(top: -30, right: -20,
          child: Container(width: 140, height: 140,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07)))),
        Positioned(bottom: 20, left: -30,
          child: Container(width: 100, height: 100,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05)))),
        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('🛒 CampusMarket',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        letterSpacing: 1.2)),
                const SizedBox(height: 4),
                const Text('Buy. Sell. Donate.',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text('12 new listings this week · 5 free items available',
                    style: TextStyle(
                        fontSize: 12, color: Colors.white.withOpacity(0.75))),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STATS STRIP
// ─────────────────────────────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        itemCount: _kStats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final s = _kStats[i];
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
                  Text(s.value, style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w900, color: CMColors.brand, height: 1)),
                  const SizedBox(height: 2),
                  Text(s.label, style: TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w700, color: CMColors.text3)),
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
  final _ModuleItem module;
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
                colors: [module.colorA, module.colorB],
              ),
            ),
            child: Stack(children: [
              Positioned(top: -18, right: -18,
                child: Container(width: 70, height: 70,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.09)))),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(module.badge, style: const TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                const Spacer(),
                Text(module.emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(height: 5),
                Text(module.title, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
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
  final _FeaturedItem item;
  final VoidCallback onTap;
  const _FeaturedCard({required this.item, required this.onTap});

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
          Container(
            height: 96,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [item.gradA, item.gradB],
              ),
            ),
            child: Stack(children: [
              Center(child: Text(item.emoji, style: const TextStyle(fontSize: 44))),
              Positioned(top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(item.category, style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w800, color: CMColors.brandDark)),
                )),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, maxLines: 2,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                      color: CMColors.text, height: 1.3)),
              const SizedBox(height: 4),
              Text(item.price, style: TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w900, color: CMColors.brand)),
              const SizedBox(height: 2),
              Text(item.condition, style: TextStyle(fontSize: 10, color: CMColors.text3)),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [CMColors.brand, CMColors.brandDark],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
              color: CMColors.brand.withOpacity(0.3),
              blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Got something to sell?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text('Post a listing in under 2 minutes →',
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
          ])),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('➕', style: TextStyle(fontSize: 24)),
          ),
        ]),
      ),
    );
  }
}