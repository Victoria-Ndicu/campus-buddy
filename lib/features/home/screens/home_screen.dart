// ============================================================
//  CampusBuddy — home_screen.dart
//
//  Faithfully converted from home-screen-ui.html design.
//  Sections (top → bottom):
//    1. Wavy blue gradient header (logo pill, greeting, search)
//    2. Quick stats chips (horizontal scroll)
//    3. Quick actions grid (4 buttons)
//    4. Module grid (2×2 gradient tiles)
//    5. Featured event banner (violet)
//    6. Housing listings strip (horizontal scroll)
//    7. Upcoming events strip (horizontal scroll)
//    8. Recent activity feed
//    9. Bottom navigation bar (5 tabs)
//
//  Zero external dependencies beyond Flutter SDK.
//  Drop into your lib/ folder and route to HomeScreen().
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  BRAND COLOURS  (mirrors CSS :root variables)
// ─────────────────────────────────────────────────────────────
class _C {
  static const brand      = Color(0xFF667EEA);
  static const brandD     = Color(0xFF4A5FCC);
  static const brandL     = Color(0xFF8B9EF0);
  static const brandPale  = Color(0xFFEEF1FD);
  static const terra      = Color(0xFFE07A5F);
  static const terraD     = Color(0xFFC4674E);
  static const terraPale  = Color(0xFFFDF0EC);
  static const violet     = Color(0xFF7C3AED);
  static const violetPale = Color(0xFFF5F3FF);
  static const green      = Color(0xFF10B981);
  static const greenPale  = Color(0xFFECFDF5);
  static const amber      = Color(0xFFF59E0B);
  static const red        = Color(0xFFCC1616);
  static const coral      = Color(0xFFEF4444);
  static const offWhite   = Color(0xFFF5F4F0);
  static const surf       = Color(0xFFFFFFFF);
  static const text       = Color(0xFF1A1A2E);
  static const text2      = Color(0xFF555577);
  static const text3      = Color(0xFF9999BB);
  static const border     = Color(0xFFE1E5F7);
}

// ─────────────────────────────────────────────────────────────
//  DATA MODELS  (plain structs — swap for real models later)
// ─────────────────────────────────────────────────────────────
class _StatChip {
  final String emoji;
  final String value;
  final String label;
  final Color  color;
  const _StatChip(this.emoji, this.value, this.label, this.color);
}

class _QuickAction {
  final String emoji;
  final String label;
  final Color  bgColor;
  const _QuickAction(this.emoji, this.label, this.bgColor);
}

class _Module {
  final String emoji;
  final String name;
  final String sub;
  final String badge;
  final Color  colorA;
  final Color  colorB;
  const _Module(this.emoji, this.name, this.sub, this.badge, this.colorA, this.colorB);
}

class _HousingCard {
  final String emoji;
  final String type;
  final Color  gradA;
  final Color  gradB;
  final Color  typeColor;
  final String title;
  final String price;
  final String distance;
  const _HousingCard(this.emoji, this.type, this.gradA, this.gradB,
      this.typeColor, this.title, this.price, this.distance);
}

class _EventCard {
  final String emoji;
  final String category;
  final Color  catColor;
  final String date;
  final Color  gradA;
  final Color  gradB;
  final String title;
  final String attending;
  final String rsvpLabel;
  final Color  rsvpColor;
  const _EventCard(this.emoji, this.category, this.catColor, this.date,
      this.gradA, this.gradB, this.title, this.attending,
      this.rsvpLabel, this.rsvpColor);
}

class _ActivityItem {
  final String emoji;
  final Color  iconBg;
  final Color  dotColor;
  final String title;
  final String time;
  final bool   unread;
  const _ActivityItem(this.emoji, this.iconBg, this.dotColor,
      this.title, this.time, this.unread);
}

// ─────────────────────────────────────────────────────────────
//  STATIC SAMPLE DATA
// ─────────────────────────────────────────────────────────────
const _stats = [
  _StatChip('📚', '4',  'Study Groups',   _C.brand),
  _StatChip('🛒', '12', 'New Listings',   _C.terra),
  _StatChip('🏠', '7',  'Housing Alerts', _C.green),
  _StatChip('🎉', '3',  'Events Today',   _C.violet),
];

const _actions = [
  _QuickAction('📚', 'Find Tutor', _C.brandPale),
  _QuickAction('➕', 'Post Item',  _C.terraPale),
  _QuickAction('🏠', 'Find Room',  _C.greenPale),
  _QuickAction('🎉', 'RSVP Event', _C.violetPale),
];

const _modules = [
  _Module('📚', 'StudyBuddy',    'Tutors · Groups · Q&A',     '4 groups active',  _C.brand,  _C.brandD),
  _Module('🛒', 'CampusMarket',  'Buy · Sell · Donate',        '12 new listings',  _C.terra,  _C.terraD),
  _Module('🏠', 'HousingHub',    'Rooms · Roommates · Map',    '7 new alerts',     _C.green,  Color(0xFF0D9488)),
  _Module('🎉', 'EventBoard',    'Events · RSVP · Calendar',   '3 events today',   _C.violet, Color(0xFF5B21B6)),
];

const _housings = [
  _HousingCard('🏠', 'Apartment',   Color(0xFFFDF0EC), Color(0xFFF4C5B5), _C.terraD,
      '2BR · Westlands', 'KES 28,000', '📍 1.2km from UoN'),
  _HousingCard('🛏', 'Single Room', Color(0xFFECFDF5), Color(0xFFA7F3D0), _C.green,
      'Single · Parklands', 'KES 9,500', '📍 0.8km from UoN'),
  _HousingCard('🏘', 'Shared',      Color(0xFFEEF1FD), Color(0xFFC7D2FA), _C.brand,
      'Shared · CBD', 'KES 6,000', '📍 2.1km from UoN'),
];

const _events = [
  _EventCard('🎓', '📚 Academic', _C.brand,     'Feb 18 · 2PM',
      Color(0xFFEDE9FE), Color(0xFFC4B5FD),
      'Final Year Project Symposium', '82 attending', 'RSVP', _C.violet),
  _EventCard('⚽', '⚽ Sports',   _C.green,     'Feb 19 · 3PM',
      Color(0xFFECFDF5), Color(0xFF6EE7B7),
      'Inter-Faculty Football Finals', '184 attending', 'Going ✓', _C.green),
  _EventCard('🎭', '🎭 Cultural', Color(0xFFEC4899), 'Feb 18 · 6PM',
      Color(0xFFFDF2F8), Color(0xFFFBCFE8),
      'Afrobeats Night — Cultural Eve', '156 attending', 'RSVP', Color(0xFFEC4899)),
];

const _activities = [
  _ActivityItem('📚', _C.brandPale, _C.brand,
      'New tutor available — Mathematics (Dr. Njoroge)',
      '5 min ago · StudyBuddy', true),
  _ActivityItem('🛒', _C.terraPale, _C.terra,
      'Your HP Laptop Charger got an offer — KES 1,200',
      '23 min ago · CampusMarket', true),
  _ActivityItem('🏠', _C.greenPale, _C.green,
      'New 2BR apartment match in Westlands — KES 26k',
      '1h ago · HousingHub', true),
  _ActivityItem('🎉', _C.violetPale, _C.violet,
      '⏰ Reminder: Hackathon starts tomorrow at 8AM!',
      '2h ago · EventBoard', false),
  _ActivityItem('💬', Color(0xFFFFFBEB), _C.amber,
      'Kevin O. matched as a potential roommate — 84%',
      '3h ago · HousingHub', false),
];

// ─────────────────────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.offWhite,
      extendBody: true,
      body: CustomScrollView(
        slivers: [
          // ── 1. Header ──────────────────────────────────────
          SliverToBoxAdapter(child: _Header()),

          // ── 2. Quick stats ─────────────────────────────────
          SliverToBoxAdapter(child: _QuickStatsRow()),

          // ── 3. Quick actions ───────────────────────────────
          const SliverToBoxAdapter(child: _SectionLabel('⚡ Quick Actions')),
          const SliverToBoxAdapter(child: _QuickActionsGrid()),

          // ── 4. Module grid ─────────────────────────────────
          const SliverToBoxAdapter(
            child: _SectionLabel('🧭 Explore Modules', showMore: false)),
          const SliverToBoxAdapter(child: _ModuleGrid()),

          // ── 5. Featured event ──────────────────────────────
          const SliverToBoxAdapter(child: _FeaturedEvent()),

          // ── 6. Housing strip ───────────────────────────────
          const SliverToBoxAdapter(
            child: _SectionLabel('🏠 Near Campus', moreLabel: 'See all →')),
          const SliverToBoxAdapter(child: _HousingStrip()),

          // ── 7. Events strip ────────────────────────────────
          const SliverToBoxAdapter(
            child: _SectionLabel('🎉 Upcoming Events', moreLabel: 'Calendar →')),
          const SliverToBoxAdapter(child: _EventsStrip()),

          // ── 8. Activity feed ───────────────────────────────
          const SliverToBoxAdapter(
            child: _SectionLabel('⚡ Recent Activity', moreLabel: 'See all →')),
          const SliverToBoxAdapter(child: _ActivityFeed()),

          // Bottom padding for nav bar
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // ── 9. Bottom nav ──────────────────────────────────────
      bottomNavigationBar: _BottomNav(
        selected: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  1. HEADER
// ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blue gradient bg
        Container(
          height: 250,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8096F0), _C.brand, _C.brandD],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: CustomPaint(
            painter: _TopoPainter(),
            child: const SizedBox.expand(),
          ),
        ),

        // Wave bottom clip
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: CustomPaint(
            size: const Size(double.infinity, 52),
            painter: _WavePainter(),
          ),
        ),

        // Header content
        Positioned.fill(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row — logo + icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _LogoPill(),
                      _HeaderIcons(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Greeting
                  Text('Good morning,',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.65))),
                  const SizedBox(height: 2),
                  const Text('Sarah K. 👋',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3)),
                  const SizedBox(height: 14),

                  // Search bar
                  _SearchBar(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.18),
              blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Red circle with C + cap
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_C.red, Color(0xFFA80F0F)],
              ),
            ),
            child: const Center(
              child: Text('C',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1)),
            ),
          ),
          const SizedBox(width: 6),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              children: [
                TextSpan(text: 'Campus', style: TextStyle(color: _C.red)),
                TextSpan(text: 'Buddy',  style: TextStyle(color: _C.brand)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HIcon(child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Text('🔔', style: TextStyle(fontSize: 18)),
            Positioned(
              top: -4, right: -4,
              child: Container(
                width: 16, height: 16,
                decoration: BoxDecoration(
                  color: _C.coral,
                  shape: BoxShape.circle,
                  border: Border.all(color: _C.brandD, width: 1.5),
                ),
                child: const Center(
                  child: Text('3',
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
            ),
          ],
        )),
        const SizedBox(width: 8),
        const _HIcon(child: Text('👤', style: TextStyle(fontSize: 18))),
      ],
    );
  }
}

class _HIcon extends StatelessWidget {
  final Widget child;
  const _HIcon({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Center(child: child),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12),
              blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          const Text('🔍', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Search tutors, rooms, events...',
                style: TextStyle(fontSize: 13, color: _C.text3)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _C.brand,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Row(
              children: [
                Text('⚙', style: TextStyle(fontSize: 11)),
                SizedBox(width: 4),
                Text('Filter',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  2. QUICK STATS
// ─────────────────────────────────────────────────────────────
class _QuickStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        itemCount: _stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (_, i) => _StatChipWidget(_stats[i]),
      ),
    );
  }
}

class _StatChipWidget extends StatelessWidget {
  final _StatChip data;
  const _StatChipWidget(this.data);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: _C.surf,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(color: _C.brand.withOpacity(0.07),
              blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(data.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 9),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.value,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: data.color,
                      height: 1)),
              const SizedBox(height: 2),
              Text(data.label,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _C.text3)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final String moreLabel;
  final bool showMore;
  const _SectionLabel(this.label,
      {this.moreLabel = 'See all →', this.showMore = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _C.text)),
          if (showMore)
            Text(moreLabel,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _C.brand)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  3. QUICK ACTIONS GRID
// ─────────────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _actions
            .map((a) => Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _QAButton(a),
                )))
            .toList(),
      ),
    );
  }
}

class _QAButton extends StatelessWidget {
  final _QuickAction data;
  const _QAButton(this.data);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: _C.surf,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(color: _C.brand.withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: data.bgColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(data.emoji,
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(height: 6),
          Text(data.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _C.text2)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  4. MODULE GRID
// ─────────────────────────────────────────────────────────────
class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
        children: _modules.map((m) => _ModuleTile(m)).toList(),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final _Module data;
  const _ModuleTile(this.data);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [data.colorA, data.colorB],
        ),
      ),
      child: Stack(
        children: [
          // Deco circles
          Positioned(top: -22, right: -22,
            child: Container(width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.09),
              ))),
          Positioned(bottom: -14, left: -14,
            child: Container(width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ))),

          // Arrow top-right
          Positioned(top: 0, right: 0,
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('›',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w900)),
              ),
            )),

          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(data.badge,
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
              const Spacer(),
              Text(data.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 6),
              Text(data.name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.1)),
              const SizedBox(height: 2),
              Text(data.sub,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.72))),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  5. FEATURED EVENT BANNER
// ─────────────────────────────────────────────────────────────
class _FeaturedEvent extends StatelessWidget {
  const _FeaturedEvent();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.violet, Color(0xFF5B21B6)],
        ),
      ),
      child: Stack(
        children: [
          // Radial glow
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: RadialGradient(
                  center: const Alignment(0.7, -0.8),
                  radius: 1.0,
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Decorative emoji
          Positioned(right: 16, bottom: 10,
            child: Text('🎓',
                style: TextStyle(
                    fontSize: 56,
                    color: Colors.white.withOpacity(0.12)))),

          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🔥 FEATURED EVENT',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(0.72),
                      letterSpacing: 1.5)),
              const SizedBox(height: 6),
              const Text('UoN Tech Hackathon 2026',
                  style: TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                      height: 1.3)),
              const SizedBox(height: 6),
              Text('📅 Sat, Feb 22 · 8:00 AM  ·  📍 Innovation Hub',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.75))),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Avatar stack + count
                  Row(
                    children: [
                      _AvatarStack(),
                      const SizedBox(width: 8),
                      Text('+247 going',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.75))),
                    ],
                  ),
                  // RSVP button
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.35)),
                    ),
                    child: const Text('RSVP →',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final _avatars = const [
    (initials: 'SK', color: Color(0xFF8B9EF0)),
    (initials: 'JM', color: Color(0xFF5B21B6)),
    (initials: 'AO', color: Color(0xFFA78BFA)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 24,
      child: Stack(
        children: List.generate(_avatars.length, (i) => Positioned(
          left: i * 18.0,
          child: Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _avatars[i].color,
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
            ),
            child: Center(
              child: Text(_avatars[i].initials,
                  style: const TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
          ),
        )),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  6. HOUSING STRIP
// ─────────────────────────────────────────────────────────────
class _HousingStrip extends StatelessWidget {
  const _HousingStrip();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _housings.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _HousingCardWidget(_housings[i]),
      ),
    );
  }
}

class _HousingCardWidget extends StatelessWidget {
  final _HousingCard data;
  const _HousingCardWidget(this.data);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: _C.surf,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          Container(
            height: 88,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [data.gradA, data.gradB],
              ),
            ),
            child: Stack(
              children: [
                Center(child: Text(data.emoji,
                    style: const TextStyle(fontSize: 44))),
                Positioned(top: 7, left: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(data.type,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: data.typeColor)),
                  )),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _C.text)),
                const SizedBox(height: 3),
                Text(data.price,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: _C.terra)),
                const SizedBox(height: 2),
                Text(data.distance,
                    style: const TextStyle(fontSize: 10, color: _C.text3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  7. EVENTS STRIP
// ─────────────────────────────────────────────────────────────
class _EventsStrip extends StatelessWidget {
  const _EventsStrip();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 184,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _EventCardWidget(_events[i]),
      ),
    );
  }
}

class _EventCardWidget extends StatelessWidget {
  final _EventCard data;
  const _EventCardWidget(this.data);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: _C.surf,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          Container(
            height: 90,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [data.gradA, data.gradB],
              ),
            ),
            child: Stack(
              children: [
                Center(child: Text(data.emoji,
                    style: const TextStyle(fontSize: 48))),
                Positioned(top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: data.catColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(data.category,
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  )),
                Positioned(bottom: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(data.date,
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  )),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title,
                    maxLines: 2,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _C.text,
                        height: 1.3)),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(data.attending,
                        style: const TextStyle(
                            fontSize: 10, color: _C.text3)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: data.rsvpColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(data.rsvpLabel,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  8. ACTIVITY FEED
// ─────────────────────────────────────────────────────────────
class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _C.surf,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(color: _C.brand.withOpacity(0.07),
              blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: List.generate(_activities.length, (i) {
          final a = _activities[i];
          final isLast = i == _activities.length - 1;
          return Container(
            decoration: BoxDecoration(
              color: a.unread ? _C.offWhite : _C.surf,
              border: isLast
                  ? null
                  : const Border(
                      bottom: BorderSide(color: _C.border)),
              borderRadius: isLast
                  ? const BorderRadius.vertical(bottom: Radius.circular(20))
                  : (i == 0
                      ? const BorderRadius.vertical(top: Radius.circular(20))
                      : null),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: a.iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(a.emoji,
                        style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 11),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.title,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: a.unread
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              color: _C.text,
                              height: 1.3)),
                      const SizedBox(height: 3),
                      Text(a.time,
                          style: const TextStyle(
                              fontSize: 10, color: _C.text3)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Dot
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: a.dotColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  9. BOTTOM NAV
// ─────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.selected, required this.onTap});

  static const _items = [
    (emoji: '🏠', label: 'Home',    activeColor: _C.brand),
    (emoji: '📚', label: 'Study',   activeColor: _C.brand),
    (emoji: '🛒', label: 'Market',  activeColor: _C.terra),
    (emoji: '🏘', label: 'Housing', activeColor: _C.green),
    (emoji: '🎉', label: 'Events',  activeColor: _C.violet),
  ];

  Color _bgFor(int i, Color c) => i == selected
      ? c.withOpacity(0.10)
      : Colors.transparent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _C.border)),
      ),
      padding: EdgeInsets.only(
          top: 10,
          bottom: MediaQuery.of(context).padding.bottom + 10,
          left: 4,
          right: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final active = i == selected;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _bgFor(i, item.activeColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.emoji,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 3),
                  Text(item.label,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? item.activeColor
                              : _C.text3)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CUSTOM PAINTERS
// ─────────────────────────────────────────────────────────────

/// Topographic SVG-style contour lines in the header
class _TopoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    // Top-left cluster
    for (final r in [(80.0, 44.0), (55.0, 30.0), (32.0, 18.0)]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s.width * 0.187, s.height * 0.24),
          width: r.$1 * 2, height: r.$2 * 2,
        ),
        p,
      );
    }

    // Right cluster
    for (final r in [(95.0, 52.0), (66.0, 36.0), (38.0, 20.0)]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s.width * 0.827, s.height * 0.60),
          width: r.$1 * 2, height: r.$2 * 2,
        ),
        p,
      );
    }

    // Flowing organic lines
    final thin = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    void curve(List<double> pts) {
      canvas.drawPath(
        Path()
          ..moveTo(pts[0], pts[1])
          ..cubicTo(pts[2], pts[3], pts[4], pts[5], pts[6], pts[7]),
        thin,
      );
    }

    curve([0, s.height * 0.16, s.width * 0.213, s.height * 0.04,
           s.width * 0.48, s.height * 0.22, s.width, s.height * 0.18]);
    curve([0, s.height * 0.40, s.width * 0.187, s.height * 0.28,
           s.width * 0.453, s.height * 0.42, s.width, s.height * 0.40]);
    curve([0, s.height * 0.66, s.width * 0.24, s.height * 0.56,
           s.width * 0.493, s.height * 0.68, s.width, s.height * 0.64]);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Wave cutout at the bottom of the header
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final path = Path()
      ..moveTo(0, s.height * 0.19)
      ..quadraticBezierTo(
          s.width * 0.213, s.height * 1.06,
          s.width * 0.507, s.height * 0.577)
      ..quadraticBezierTo(
          s.width * 0.795, s.height * 0.154,
          s.width, s.height * 0.962)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();

    canvas.drawPath(path, Paint()..color = _C.offWhite);
  }

  @override
  bool shouldRepaint(_) => false;
}