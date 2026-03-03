import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/hh_constants.dart';
import '../widgets/hh_widgets.dart';
import 'hh_listings_screen.dart';
import 'hh_roommate_screen.dart';
import 'hh_map_screen.dart';
import 'hh_alerts_screen.dart';

// ─────────────────────────────────────────────────────────────
//  DATA
// ─────────────────────────────────────────────────────────────
class _Stat {
  final String emoji, value, label;
  const _Stat(this.emoji, this.value, this.label);
}

class _Mod {
  final String emoji, title, subtitle;
  final Color colorA, colorB;
  final Widget screen;
  const _Mod(this.emoji, this.title, this.subtitle, this.colorA, this.colorB, this.screen);
}

// ─────────────────────────────────────────────────────────────
//  HousingHubHome
// ─────────────────────────────────────────────────────────────
class HousingHubHome extends StatelessWidget {
  const HousingHubHome({super.key});

  static const _stats = [
    _Stat('🏠', '64',  'Listings'),
    _Stat('👫', '18',  'Matches'),
    _Stat('📍', '12',  'Near Campus'),
    _Stat('🔔', '3',   'Alerts'),
  ];

  @override
  Widget build(BuildContext context) {
    final modules = [
      _Mod('🏠', 'Browse Listings',  '64 available now',
          HHColors.brand, HHColors.brandDark, const HHListingsScreen()),
      _Mod('👫', 'Roommate Match',   '18 new profiles',
          HHColors.teal, const Color(0xFF0A7A70), const HHRoommateScreen()),
      _Mod('🗺️', 'Map View',         '12 listings nearby',
          HHColors.blue, const Color(0xFF4A5FCC), const HHMapScreen()),
      _Mod('🔔', 'My Alerts',        '3 active alerts',
          HHColors.amber, const Color(0xFFD97706), const HHAlertsScreen()),
    ];

    return Scaffold(
      backgroundColor: HHColors.surface2,
      body: CustomScrollView(slivers: [
        // ── App Bar ──────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          stretch: true,
          backgroundColor: HHColors.brandDark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
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
                // decorative circle
                Positioned(top: -40, right: -30,
                  child: Container(width: 160, height: 160,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08)))),
                Positioned(bottom: 20, left: 16, right: 16, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Housing Hub', style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w900,
                      color: Colors.white, letterSpacing: -0.5,
                    )),
                    const SizedBox(height: 4),
                    Text('Nairobi · 64 listings available',
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75))),
                    const SizedBox(height: 14),
                    // Stats strip
                    Row(children: _stats.map<Widget>((s) => Expanded(
                      child: Column(children: [
                        Text(s.value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                        Text(s.label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.65))),
                      ]),
                    )).toList()),
                  ],
                )),
              ]),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.notifications_none, color: Colors.white.withOpacity(0.9)),
              onPressed: () {},
            ),
            const SizedBox(width: 4),
          ],
        ),

        // ── Search bar ───────────────────────────────────────
        SliverToBoxAdapter(child: HHSearchBar()),

        // ── Module grid ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12, crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: modules.map<Widget>((m) => _ModuleCard(
                emoji: m.emoji, title: m.title, subtitle: m.subtitle,
                colorA: m.colorA, colorB: m.colorB,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => m.screen));
                },
              )).toList(),
            ),
          ),
        ),

        // ── Hero banner ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [HHColors.brand, HHColors.brandDark],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(children: [
              Positioned(right: 10, top: 0, bottom: 0,
                child: Text('🏠', style: TextStyle(fontSize: 72, color: Colors.white.withOpacity(0.15)))),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Find Your Home\nAway From Home',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, height: 1.25)),
                const SizedBox(height: 6),
                Text('Browse student-friendly accommodation near campus. Verified listings, real prices.',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HHListingsScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: Text('Browse All →',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: HHColors.brand)),
                  ),
                ),
              ]),
            ]),
          ),
        ),

        // ── Latest listings ──────────────────────────────────
        SliverToBoxAdapter(
          child: HHSectionLabel(title: '🏠 Latest Listings', action: 'See all →',
              onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HHListingsScreen()))),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            _UpcomingListingCard(
              emoji: '🏠', type: 'Apartment',
              title: 'Spacious 2-Bedroom — Westlands',
              price: 'KES 28,000', location: '📍 Westlands · 1.2km from UoN',
              gradA: const Color(0xFFFDF0EC), gradB: const Color(0xFFF4C5B5),
              typeColor: HHColors.brand,
              tags: ['WiFi ✓', 'Parking ✓', '2 Beds', 'Furnished'],
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const HHListingDetailScreen(
                    title: 'Spacious 2-Bedroom — Westlands',
                    price: 'KES 28,000',
                    location: 'Westlands, Nairobi · 1.2 km from UoN Main Campus',
                    type: 'Apartment',
                    emoji: '🏠',
                  ))),
            ),
            _UpcomingListingCard(
              emoji: '🛏', type: 'Single Room',
              title: 'Self-Contained Room — Parklands',
              price: 'KES 9,500', location: '📍 Parklands · 0.8km from UoN',
              gradA: const Color(0xFFF0F4FF), gradB: const Color(0xFFDDE6FF),
              typeColor: HHColors.blue,
              tags: ['WiFi ✓', 'En-suite', 'Furnished'],
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const HHListingDetailScreen(
                    title: 'Self-Contained Room — Parklands',
                    price: 'KES 9,500',
                    location: 'Parklands, Nairobi · 0.8 km from UoN Main Campus',
                    type: 'Single Room',
                    emoji: '🛏',
                  ))),
            ),
            const SizedBox(height: 100),
          ]),
        ),
      ]),

      // ── FAB ──────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: HHColors.brand,
        foregroundColor: Colors.white,
        icon: const Text('🏠', style: TextStyle(fontSize: 18)),
        label: const Text('Post Listing', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HHPostListingScreen())),
      ),

      // ── Bottom Nav ───────────────────────────────────────
      bottomNavigationBar: _HHBottomNav(selected: 0, onTap: (i) {
        switch (i) {
          case 1: Navigator.push(context, MaterialPageRoute(builder: (_) => const HHMapScreen())); break;
          case 2: Navigator.push(context, MaterialPageRoute(builder: (_) => const HHRoommateScreen())); break;
          case 3: Navigator.push(context, MaterialPageRoute(builder: (_) => const HHAlertsScreen())); break;
        }
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Private widgets
// ─────────────────────────────────────────────────────────────

class _ModuleCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color colorA, colorB;
  final VoidCallback onTap;
  const _ModuleCard({required this.emoji, required this.title, required this.subtitle,
      required this.colorA, required this.colorB, required this.onTap});

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
              gradient: LinearGradient(colors: [colorA, colorB],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Stack(children: [
              Positioned(top: -16, right: -16,
                child: Container(width: 72, height: 72,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1)))),
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(height: 6),
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.75))),
              ]),
              Positioned(top: 0, right: 0,
                child: Container(width: 24, height: 24,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Center(child: Text('›', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w900))))),
            ]),
          ),
        ),
      ),
    );
  }
}

class _UpcomingListingCard extends StatelessWidget {
  final String emoji, type, title, price, location;
  final Color gradA, gradB, typeColor;
  final List<String> tags;
  final VoidCallback onTap;
  const _UpcomingListingCard({
    required this.emoji, required this.type, required this.title,
    required this.price, required this.location,
    required this.gradA, required this.gradB, required this.typeColor,
    required this.tags, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: HHTheme.card,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // image area
          Container(
            height: 130,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [gradA, gradB], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Stack(children: [
              Center(child: Text(emoji, style: const TextStyle(fontSize: 56))),
              Positioned(top: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
                  child: Text(type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: typeColor)),
                )),
              Positioned(top: 10, right: 10,
                child: Container(width: 30, height: 30,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                  child: const Center(child: Text('🤍', style: TextStyle(fontSize: 14))))),
            ]),
          ),
          // body
          Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: HHColors.text)),
            const SizedBox(height: 4),
            Row(children: [
              Text(price, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: HHColors.brand)),
              Text(' /month', style: TextStyle(fontSize: 11, color: HHColors.text3)),
            ]),
            const SizedBox(height: 3),
            Text(location, style: TextStyle(fontSize: 11, color: HHColors.text3)),
            const SizedBox(height: 8),
            Wrap(spacing: 5, runSpacing: 5,
              children: tags.map<Widget>((t) => HHTag(t, bg: HHColors.greenPale, fg: HHColors.teal)).toList()),
            const SizedBox(height: 10),
            Divider(color: HHColors.border, height: 1),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('📅 Available Now', style: TextStyle(fontSize: 11, color: HHColors.text3)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(color: HHColors.brand, borderRadius: BorderRadius.circular(10)),
                child: const Text('View →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ]),
          ])),
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
    ('🗺️', 'Map'),
    ('👫', 'Match'),
    ('🔔', 'Alerts'),
    ('👤', 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: HHColors.border)),
      ),
      padding: EdgeInsets.only(top: 10, bottom: MediaQuery.of(context).padding.bottom + 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final active = i == selected;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onTap(i); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: active ? HHColors.brand.withOpacity(0.10) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_items[i].$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 3),
                Text(_items[i].$2, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: active ? HHColors.brand : HHColors.text3)),
              ]),
            ),
          );
        }),
      ),
    );
  }
}