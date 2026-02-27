// ============================================================
//  CampusBuddy — home_screen.dart  (FULLY INTERACTIVE)
//
//  Changes from original:
//   ✅  Bottom nav tab 1 (📚 Study)  → pushes StudyBuddyHome
//   ✅  Module tile "StudyBuddy"     → pushes StudyBuddyHome
//   ✅  Quick-action "Find Tutor"    → pushes StudyBuddyHome
//   ✅  Stat chip "Study Groups"     → pushes StudyBuddyHome
//   ✅  Search "Find a Tutor"        → pushes StudyBuddyHome
//   All other tabs still show "coming soon" snackbar as before.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── StudyBuddy module ─────────────────────────────────────────
import '../../study_buddy/study_buddy.dart';

// ─────────────────────────────────────────────────────────────
//  BRAND COLOURS
// ─────────────────────────────────────────────────────────────
class _C {
  static const brand      = Color(0xFF667EEA);
  static const brandD     = Color(0xFF4A5FCC);
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
//  DATA MODELS
// ─────────────────────────────────────────────────────────────
class _StatData {
  final String emoji, value, label;
  final Color color;
  final int navTab;
  const _StatData(this.emoji, this.value, this.label, this.color, this.navTab);
}

class _ActionData {
  final String emoji, label;
  final Color bgColor;
  final int navTab;
  const _ActionData(this.emoji, this.label, this.bgColor, this.navTab);
}

class _ModuleData {
  final String emoji, name, sub, badge;
  final Color colorA, colorB;
  final int navTab;
  const _ModuleData(this.emoji, this.name, this.sub, this.badge,
      this.colorA, this.colorB, this.navTab);
}

class _HousingData {
  final String emoji, type, title, price, distance;
  final Color gradA, gradB, typeColor;
  const _HousingData(this.emoji, this.type, this.gradA, this.gradB,
      this.typeColor, this.title, this.price, this.distance);
}

class _EventData {
  final String emoji, category, date, title, attending;
  final Color catColor, gradA, gradB, rsvpColor;
  const _EventData(this.emoji, this.category, this.catColor, this.date,
      this.gradA, this.gradB, this.title, this.attending, this.rsvpColor);
}

class ActivityItem {
  final String emoji, title, time;
  final Color iconBg, dotColor;
  bool unread;
  ActivityItem(this.emoji, this.iconBg, this.dotColor,
      this.title, this.time, this.unread);
}

// ─────────────────────────────────────────────────────────────
//  STATIC DATA
// ─────────────────────────────────────────────────────────────
const _kStats = [
  _StatData('📚', '4',  'Study Groups',   _C.brand,  1),
  _StatData('🛒', '12', 'New Listings',   _C.terra,  2),
  _StatData('🏠', '7',  'Housing Alerts', _C.green,  3),
  _StatData('🎉', '3',  'Events Today',   _C.violet, 4),
];

const _kActions = [
  _ActionData('📚', 'Find Tutor', _C.brandPale,  1),
  _ActionData('➕', 'Post Item',  _C.terraPale,  2),
  _ActionData('🏠', 'Find Room',  _C.greenPale,  3),
  _ActionData('🎉', 'RSVP Event', _C.violetPale, 4),
];

const _kModules = [
  _ModuleData('📚', 'StudyBuddy',   'Tutors · Groups · Q&A',   '4 groups active',
      _C.brand,  _C.brandD,         1),
  _ModuleData('🛒', 'CampusMarket', 'Buy · Sell · Donate',     '12 new listings',
      _C.terra,  _C.terraD,         2),
  _ModuleData('🏠', 'HousingHub',   'Rooms · Roommates · Map', '7 new alerts',
      _C.green,  Color(0xFF0D9488), 3),
  _ModuleData('🎉', 'EventBoard',   'Events · RSVP · Calendar','3 events today',
      _C.violet, Color(0xFF5B21B6), 4),
];

const _kHousings = [
  _HousingData('🏠', 'Apartment',   Color(0xFFFDF0EC), Color(0xFFF4C5B5),
      _C.terraD, '2BR · Westlands',    'KES 28,000', '📍 1.2km from UoN'),
  _HousingData('🛏', 'Single Room', Color(0xFFECFDF5), Color(0xFFA7F3D0),
      _C.green,  'Single · Parklands', 'KES 9,500',  '📍 0.8km from UoN'),
  _HousingData('🏘', 'Shared',      Color(0xFFEEF1FD), Color(0xFFC7D2FA),
      _C.brand,  'Shared · CBD',       'KES 6,000',  '📍 2.1km from UoN'),
];

const _kEvents = [
  _EventData('🎓', '📚 Academic', _C.brand,         'Feb 18 · 2PM',
      Color(0xFFEDE9FE), Color(0xFFC4B5FD),
      'Final Year Project Symposium',   '82 attending',  _C.violet),
  _EventData('⚽', '⚽ Sports',   _C.green,         'Feb 19 · 3PM',
      Color(0xFFECFDF5), Color(0xFF6EE7B7),
      'Inter-Faculty Football Finals',  '184 attending', _C.green),
  _EventData('🎭', '🎭 Cultural', Color(0xFFEC4899), 'Feb 18 · 6PM',
      Color(0xFFFDF2F8), Color(0xFFFBCFE8),
      'Afrobeats Night — Cultural Eve', '156 attending', Color(0xFFEC4899)),
];

List<ActivityItem> _buildActivities() => [
  ActivityItem('📚', _C.brandPale,  _C.brand,
      'New tutor available — Mathematics (Dr. Njoroge)',
      '5 min ago · StudyBuddy', true),
  ActivityItem('🛒', _C.terraPale,  _C.terra,
      'Your HP Laptop Charger got an offer — KES 1,200',
      '23 min ago · CampusMarket', true),
  ActivityItem('🏠', _C.greenPale,  _C.green,
      'New 2BR apartment match in Westlands — KES 26k',
      '1h ago · HousingHub', true),
  ActivityItem('🎉', _C.violetPale, _C.violet,
      '⏰ Reminder: Hackathon starts tomorrow at 8AM!',
      '2h ago · EventBoard', false),
  ActivityItem('💬', Color(0xFFFFFBEB), _C.amber,
      'Kevin O. matched as a potential roommate — 84%',
      '3h ago · HousingHub', false),
];

// ─────────────────────────────────────────────────────────────
//  HOME SCREEN ROOT
// ─────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int  _navIndex      = 0;
  bool _featuredGoing = false;
  late final List<ActivityItem> _activities;

  @override
  void initState() {
    super.initState();
    _activities = _buildActivities();
  }

  // ── helpers ──────────────────────────────────────────────

  /// Opens StudyBuddyHome by pushing it onto the stack.
  void _openStudyBuddy() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StudyBuddyHome()),
    );
  }

  void _goTab(int tab) => setState(() => _navIndex = tab);

  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color ?? _C.brandD,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
  }

  void _markRead(int i) {
    if (!_activities[i].unread) { _snack('Already read', color: _C.text3); return; }
    setState(() => _activities[i].unread = false);
    _snack('Marked as read ✓');
  }

  void _showNotifications() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationSheet(
        activities: _activities,
        onMarkAll: () => setState(() {
          for (final a in _activities) a.unread = false;
        }),
      ),
    );
  }

  void _showProfile() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ProfileSheet(),
    );
  }

  void _openSearch() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (_) => _SearchDialog(onNavigate: (tab, label) {
        // Tab 1 = StudyBuddy → push screen; others → snackbar
        if (tab == 1) {
          _openStudyBuddy();
        } else {
          _goTab(tab);
          _snack('Opening $label…');
        }
      }),
    );
  }

  void _showHousingDetail(_HousingData card) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _HousingDetailSheet(card: card, onContact: () {
        _snack('Opening HousingHub…', color: _C.green);
        _goTab(3);
      }),
    );
  }

  // ── build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.offWhite,
      extendBody: true,
      body: CustomScrollView(
        slivers: [
          // 1. Header
          SliverToBoxAdapter(
            child: _Header(
              onSearch:        _openSearch,
              onNotifications: _showNotifications,
              onProfile:       _showProfile,
            ),
          ),
          // 2. Quick stats — tab 1 → StudyBuddy
          SliverToBoxAdapter(
            child: _QuickStatsRow(onTap: (tab) {
              if (tab == 1) { _openStudyBuddy(); } else { _goTab(tab); }
            }),
          ),
          // 3. Quick actions — tab 1 → StudyBuddy
          _sec('⚡ Quick Actions'),
          SliverToBoxAdapter(
            child: _QuickActionsGrid(onTap: (tab, label) {
              if (tab == 1) { _openStudyBuddy(); } else { _goTab(tab); _snack('Opening $label…'); }
            }),
          ),
          // 4. Module grid — tab 1 → StudyBuddy
          _sec('🧭 Explore Modules', showMore: false),
          SliverToBoxAdapter(
            child: _ModuleGrid(onTap: (tab, name) {
              if (tab == 1) { _openStudyBuddy(); } else { _goTab(tab); _snack('Opening $name…', color: _C.brandD); }
            }),
          ),
          // 5. Featured event
          SliverToBoxAdapter(
            child: _FeaturedEvent(
              going: _featuredGoing,
              onRsvp: () {
                setState(() => _featuredGoing = !_featuredGoing);
                HapticFeedback.mediumImpact();
                _snack(_featuredGoing
                    ? '✅ You\'re going to UoN Tech Hackathon!'
                    : 'RSVP cancelled', color: _C.violet);
              },
              onDetail: () => _snack('Opening event details…', color: _C.violet),
            ),
          ),
          // 6. Housing strip
          _sec('🏠 Near Campus', moreLabel: 'See all →',
              onMore: () { _goTab(3); _snack('Opening HousingHub…', color: _C.green); }),
          SliverToBoxAdapter(
            child: _HousingStrip(onTap: _showHousingDetail),
          ),
          // 7. Events strip
          _sec('🎉 Upcoming Events', moreLabel: 'Calendar →',
              onMore: () { _goTab(4); _snack('Opening Events calendar…', color: _C.violet); }),
          SliverToBoxAdapter(child: _EventsStrip()),
          // 8. Activity feed
          _sec('⚡ Recent Activity', moreLabel: 'See all →',
              onMore: () => _snack('Showing all activity…')),
          SliverToBoxAdapter(
            child: _ActivityFeed(activities: _activities, onTap: _markRead),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selected: _navIndex,
        onTap: (i) {
          HapticFeedback.selectionClick();
          // Tab 1 = 📚 Study → push StudyBuddyHome
          if (i == 1) {
            _openStudyBuddy();
            return;
          }
          _goTab(i);
          if (i != 0) {
            const labels = ['Home', 'Study', 'Market', 'Housing', 'Events'];
            _snack('${labels[i]} — coming soon…');
          }
        },
      ),
    );
  }

  SliverToBoxAdapter _sec(String label,
      {String moreLabel = 'See all →',
      bool showMore = true,
      VoidCallback? onMore}) =>
      SliverToBoxAdapter(
        child: _SectionLabel(label,
            moreLabel: moreLabel, showMore: showMore, onMore: onMore),
      );
}

// ─────────────────────────────────────────────────────────────
//  1. HEADER
// ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final VoidCallback onSearch, onNotifications, onProfile;
  const _Header({required this.onSearch, required this.onNotifications,
      required this.onProfile});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        height: 250,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF8096F0), _C.brand, _C.brandD],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: CustomPaint(painter: _TopoPainter(), child: const SizedBox.expand()),
      ),
      Positioned(bottom: 0, left: 0, right: 0,
        child: CustomPaint(
          size: const Size(double.infinity, 52), painter: _WavePainter())),
      Positioned.fill(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _LogoPill(),
                _HeaderIcons(onNotifications: onNotifications, onProfile: onProfile),
              ]),
              const SizedBox(height: 16),
              Text('Hello,',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.65))),
              const SizedBox(height: 2),
              const Text('Sarah K. 👋',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                      color: Colors.white, letterSpacing: -0.3)),
              const SizedBox(height: 14),
              _SearchBarWidget(onTap: onSearch),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _LogoPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(shape: BoxShape.circle,
            gradient: LinearGradient(begin: Alignment.topLeft,
                end: Alignment.bottomRight, colors: [_C.red, Color(0xFFA80F0F)])),
          child: const Center(child: Text('C',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900,
                  color: Colors.white, height: 1))),
        ),
        const SizedBox(width: 6),
        RichText(text: const TextSpan(
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          children: [
            TextSpan(text: 'Campus', style: TextStyle(color: _C.red)),
            TextSpan(text: 'Buddy',  style: TextStyle(color: _C.brand)),
          ],
        )),
      ]),
    );
  }
}

class _HeaderIcons extends StatelessWidget {
  final VoidCallback onNotifications, onProfile;
  const _HeaderIcons({required this.onNotifications, required this.onProfile});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _HIconBtn(onTap: onNotifications,
        child: Stack(clipBehavior: Clip.none, children: [
          const Text('🔔', style: TextStyle(fontSize: 18)),
          Positioned(top: -4, right: -4,
            child: Container(width: 16, height: 16,
              decoration: BoxDecoration(color: _C.coral, shape: BoxShape.circle,
                  border: Border.all(color: _C.brandD, width: 1.5)),
              child: const Center(child: Text('3',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800,
                      color: Colors.white))))),
        ])),
      const SizedBox(width: 8),
      _HIconBtn(onTap: onProfile,
        child: const Text('👤', style: TextStyle(fontSize: 18))),
    ]);
  }
}

class _HIconBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HIconBtn({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Center(child: child)),
    );
  }
}

class _SearchBarWidget extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBarWidget({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12),
              blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          const Text('🔍', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          const Expanded(child: Text('Search tutors, rooms, events…',
              style: TextStyle(fontSize: 13, color: _C.text3))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: _C.brand, borderRadius: BorderRadius.circular(9)),
            child: const Row(children: [
              Text('⚙', style: TextStyle(fontSize: 11)),
              SizedBox(width: 4),
              Text('Filter', style: TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w800, color: Colors.white)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  2. QUICK STATS
// ─────────────────────────────────────────────────────────────
class _QuickStatsRow extends StatelessWidget {
  final ValueChanged<int> onTap;
  const _QuickStatsRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        itemCount: _kStats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (_, i) {
          final s = _kStats[i];
          return GestureDetector(
            onTap: () => onTap(s.navTab),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: _C.surf, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.border),
                boxShadow: [BoxShadow(color: _C.brand.withOpacity(0.07),
                    blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(s.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 9),
                Column(mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.value, style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.w900, color: s.color, height: 1)),
                    const SizedBox(height: 2),
                    Text(s.label, style: const TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w700, color: _C.text3)),
                  ]),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label, moreLabel;
  final bool showMore;
  final VoidCallback? onMore;
  const _SectionLabel(this.label,
      {this.moreLabel = 'See all →', this.showMore = true, this.onMore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 14,
            fontWeight: FontWeight.w800, color: _C.text)),
        if (showMore)
          GestureDetector(
            onTap: onMore,
            child: Text(moreLabel, style: const TextStyle(fontSize: 12,
                fontWeight: FontWeight.w700, color: _C.brand)),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  3. QUICK ACTIONS
// ─────────────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  final void Function(int tab, String label) onTap;
  const _QuickActionsGrid({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _kActions.map((a) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Material(
            color: _C.surf, borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onTap(a.navTab, a.label),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _C.border),
                    boxShadow: [BoxShadow(color: _C.brand.withOpacity(0.06),
                        blurRadius: 8, offset: const Offset(0, 2))]),
                child: Column(children: [
                  Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: a.bgColor,
                        borderRadius: BorderRadius.circular(13)),
                    child: Center(child: Text(a.emoji,
                        style: const TextStyle(fontSize: 18)))),
                  const SizedBox(height: 6),
                  Text(a.label, textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w700, color: _C.text2)),
                ]),
              ),
            ),
          ),
        ))).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  4. MODULE GRID
// ─────────────────────────────────────────────────────────────
class _ModuleGrid extends StatelessWidget {
  final void Function(int tab, String name) onTap;
  const _ModuleGrid({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.95,
        children: _kModules.map((m) => ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Material(color: Colors.transparent, child: InkWell(
            onTap: () => onTap(m.navTab, m.name),
            splashColor: Colors.white.withOpacity(0.15),
            highlightColor: Colors.white.withOpacity(0.08),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [m.colorA, m.colorB])),
              child: Stack(children: [
                Positioned(top: -22, right: -22,
                  child: Container(width: 90, height: 90,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.09)))),
                Positioned(bottom: -14, left: -14,
                  child: Container(width: 64, height: 64,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06)))),
                Positioned(top: 0, right: 0,
                  child: Container(width: 26, height: 26,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Center(child: Text('›',
                        style: TextStyle(fontSize: 16, color: Colors.white,
                            fontWeight: FontWeight.w900))))),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(m.badge, style: const TextStyle(fontSize: 9,
                        fontWeight: FontWeight.w800, color: Colors.white))),
                  const Spacer(),
                  Text(m.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 6),
                  Text(m.name, style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w900, color: Colors.white,
                      letterSpacing: -0.1)),
                  const SizedBox(height: 2),
                  Text(m.sub, style: TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.72))),
                ]),
              ]),
            ),
          )),
        )).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  5. FEATURED EVENT
// ─────────────────────────────────────────────────────────────
class _FeaturedEvent extends StatelessWidget {
  final bool going;
  final VoidCallback onRsvp, onDetail;
  const _FeaturedEvent(
      {required this.going, required this.onRsvp, required this.onDetail});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(begin: Alignment.topLeft,
            end: Alignment.bottomRight, colors: [_C.violet, Color(0xFF5B21B6)]),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(color: Colors.transparent, child: InkWell(
          onTap: onDetail,
          splashColor: Colors.white.withOpacity(0.1),
          child: Stack(children: [
            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
              gradient: RadialGradient(center: const Alignment(0.7, -0.8),
                radius: 1.0, colors: [Colors.white.withOpacity(0.12), Colors.transparent])))),
            Positioned(right: 16, bottom: 10,
              child: Text('🎓', style: TextStyle(fontSize: 56,
                  color: Colors.white.withOpacity(0.12)))),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('🔥 FEATURED EVENT', style: TextStyle(fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.72), letterSpacing: 1.5)),
                const SizedBox(height: 6),
                const Text('UoN Tech Hackathon 2026', style: TextStyle(fontSize: 18,
                    fontStyle: FontStyle.italic, color: Colors.white, height: 1.3)),
                const SizedBox(height: 6),
                Text('📅 Sat, Feb 22 · 8:00 AM  ·  📍 Innovation Hub',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.75))),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    _AvatarStack(),
                    const SizedBox(width: 8),
                    Text('+247 going', style: TextStyle(fontSize: 11,
                        color: Colors.white.withOpacity(0.75))),
                  ]),
                  GestureDetector(
                    onTap: onRsvp,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: going ? Colors.white.withOpacity(0.35) : Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.35)),
                      ),
                      child: Text(going ? '✅ Going' : 'RSVP →',
                          style: const TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                ]),
              ]),
            ),
          ]),
        )),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final _av = const [
    ('SK', Color(0xFF8B9EF0)), ('JM', Color(0xFF5B21B6)), ('AO', Color(0xFFA78BFA))
  ];
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 52, height: 24,
      child: Stack(children: List.generate(_av.length, (i) => Positioned(
        left: i * 18.0,
        child: Container(width: 24, height: 24,
          decoration: BoxDecoration(shape: BoxShape.circle, color: _av[i].$2,
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 2)),
          child: Center(child: Text(_av[i].$1, style: const TextStyle(
              fontSize: 7, fontWeight: FontWeight.w800, color: Colors.white)))),
      ))));
  }
}

// ─────────────────────────────────────────────────────────────
//  6. HOUSING STRIP
// ─────────────────────────────────────────────────────────────
class _HousingStrip extends StatelessWidget {
  final void Function(_HousingData) onTap;
  const _HousingStrip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _kHousings.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(color: _C.surf, child: InkWell(
            onTap: () => onTap(_kHousings[i]),
            child: Container(width: 170,
              decoration: BoxDecoration(border: Border.all(color: _C.border),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                    blurRadius: 12, offset: const Offset(0, 3))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 88, decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_kHousings[i].gradA, _kHousings[i].gradB])),
                  child: Stack(children: [
                    Center(child: Text(_kHousings[i].emoji,
                        style: const TextStyle(fontSize: 44))),
                    Positioned(top: 7, left: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(7)),
                        child: Text(_kHousings[i].type, style: TextStyle(fontSize: 9,
                            fontWeight: FontWeight.w800, color: _kHousings[i].typeColor)))),
                  ])),
                Padding(padding: const EdgeInsets.all(10), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_kHousings[i].title, style: const TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w800, color: _C.text)),
                    const SizedBox(height: 3),
                    Text(_kHousings[i].price, style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w900, color: _C.terra)),
                    const SizedBox(height: 2),
                    Text(_kHousings[i].distance, style: const TextStyle(
                        fontSize: 10, color: _C.text3)),
                  ])),
              ]),
            ),
          )),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  7. EVENTS STRIP
// ─────────────────────────────────────────────────────────────
class _EventsStrip extends StatefulWidget {
  const _EventsStrip();
  @override
  State<_EventsStrip> createState() => _EventsStripState();
}

class _EventsStripState extends State<_EventsStrip> {
  final _going = [false, true, false];

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 184,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _kEvents.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final e = _kEvents[i];
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(color: _C.surf, child: InkWell(
              onTap: () => ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(SnackBar(
                  content: Text('Opening: ${e.title}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  backgroundColor: e.rsvpColor, behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2))),
              child: Container(width: 200,
                decoration: BoxDecoration(border: Border.all(color: _C.border)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(height: 90, decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft,
                        end: Alignment.bottomRight, colors: [e.gradA, e.gradB])),
                    child: Stack(children: [
                      Center(child: Text(e.emoji, style: const TextStyle(fontSize: 48))),
                      Positioned(top: 8, left: 8, child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: e.catColor,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(e.category, style: const TextStyle(fontSize: 9,
                            fontWeight: FontWeight.w800, color: Colors.white)))),
                      Positioned(bottom: 8, right: 8, child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(7)),
                        child: Text(e.date, style: const TextStyle(fontSize: 9,
                            fontWeight: FontWeight.w800, color: Colors.white)))),
                    ])),
                  Padding(padding: const EdgeInsets.all(10), child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.title, maxLines: 2, style: const TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w800, color: _C.text, height: 1.3)),
                      const SizedBox(height: 5),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(e.attending, style: const TextStyle(
                            fontSize: 10, color: _C.text3)),
                        GestureDetector(
                          onTap: () {
                            setState(() => _going[i] = !_going[i]);
                            HapticFeedback.mediumImpact();
                            ScaffoldMessenger.of(context)
                              ..clearSnackBars()
                              ..showSnackBar(SnackBar(
                                content: Text(_going[i]
                                    ? '✅ You\'re going to ${e.title}!'
                                    : 'RSVP cancelled',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                backgroundColor: e.rsvpColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 2)));
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _going[i] ? _C.green : e.rsvpColor,
                              borderRadius: BorderRadius.circular(8)),
                            child: Text(_going[i] ? 'Going ✓' : 'RSVP',
                                style: const TextStyle(fontSize: 10,
                                    fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ),
                      ]),
                    ])),
                ]),
              ),
            )),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  8. ACTIVITY FEED
// ─────────────────────────────────────────────────────────────
class _ActivityFeed extends StatelessWidget {
  final List<ActivityItem> activities;
  final void Function(int) onTap;
  const _ActivityFeed({required this.activities, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _C.surf, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: [BoxShadow(color: _C.brand.withOpacity(0.07),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: List.generate(activities.length, (i) {
          final a = activities[i];
          final isLast = i == activities.length - 1;
          return Material(
            color: a.unread ? _C.offWhite : _C.surf,
            child: InkWell(
              onTap: () => onTap(i),
              child: Container(
                decoration: isLast ? null
                    : const BoxDecoration(border: Border(bottom: BorderSide(color: _C.border))),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 38, height: 38,
                    decoration: BoxDecoration(color: a.iconBg,
                        borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(a.emoji,
                        style: const TextStyle(fontSize: 16)))),
                  const SizedBox(width: 11),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.title, style: TextStyle(fontSize: 12,
                        fontWeight: a.unread ? FontWeight.w800 : FontWeight.w700,
                        color: _C.text, height: 1.3)),
                    const SizedBox(height: 3),
                    Text(a.time, style: const TextStyle(fontSize: 10, color: _C.text3)),
                  ])),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 8, height: 8,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          color: a.unread ? a.dotColor : _C.border),
                    ),
                  ),
                ]),
              ),
            ),
          );
        })),
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
    ('🏠', 'Home',    _C.brand),
    ('📚', 'Study',   _C.brand),
    ('🛒', 'Market',  _C.terra),
    ('🏘', 'Housing', _C.green),
    ('🎉', 'Events',  _C.violet),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white,
          border: Border(top: BorderSide(color: _C.border))),
      padding: EdgeInsets.only(top: 10,
          bottom: MediaQuery.of(context).padding.bottom + 10, left: 4, right: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final active = i == selected;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active ? _items[i].$3.withOpacity(0.10) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_items[i].$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 3),
                Text(_items[i].$2, style: TextStyle(fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: active ? _items[i].$3 : _C.text3)),
              ]),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SEARCH DIALOG
// ─────────────────────────────────────────────────────────────
class _SearchDialog extends StatefulWidget {
  final void Function(int tab, String label) onNavigate;
  const _SearchDialog({required this.onNavigate});
  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final _ctrl = TextEditingController();
  final _suggestions = [
    (emoji: '📚', label: 'Find a Tutor',    tab: 1),
    (emoji: '🛒', label: 'Browse Market',   tab: 2),
    (emoji: '🏠', label: 'Search Rooms',    tab: 3),
    (emoji: '🎉', label: 'Upcoming Events', tab: 4),
  ];

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search tutors, rooms, events…',
              prefixIcon: const Icon(Icons.search, color: _C.brand),
              filled: true, fillColor: _C.brandPale,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          const Align(alignment: Alignment.centerLeft,
            child: Text('Quick Jump', style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w800, color: _C.text2))),
          const SizedBox(height: 8),
          ..._suggestions.map((s) => ListTile(
            leading: Text(s.emoji, style: const TextStyle(fontSize: 20)),
            title: Text(s.label, style: const TextStyle(
                fontWeight: FontWeight.w700, color: _C.text)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: _C.text3),
            onTap: () { Navigator.pop(context); widget.onNavigate(s.tab, s.label); },
          )),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  NOTIFICATION SHEET
// ─────────────────────────────────────────────────────────────
class _NotificationSheet extends StatefulWidget {
  final List<ActivityItem> activities;
  final VoidCallback onMarkAll;
  const _NotificationSheet({required this.activities, required this.onMarkAll});
  @override
  State<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<_NotificationSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: _C.surf,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
          decoration: BoxDecoration(color: _C.border,
              borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Notifications', style: TextStyle(fontSize: 18,
              fontWeight: FontWeight.w900, color: _C.text)),
          TextButton(
            onPressed: () { widget.onMarkAll(); setState(() {}); },
            child: const Text('Mark all read',
                style: TextStyle(color: _C.brand, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 8),
        ...widget.activities.map((a) => ListTile(
          leading: Container(width: 38, height: 38,
            decoration: BoxDecoration(color: a.iconBg,
                borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(a.emoji,
                style: const TextStyle(fontSize: 16)))),
          title: Text(a.title, style: TextStyle(fontSize: 12,
              fontWeight: a.unread ? FontWeight.w800 : FontWeight.w600,
              color: _C.text)),
          subtitle: Text(a.time,
              style: const TextStyle(fontSize: 10, color: _C.text3)),
          trailing: Container(width: 8, height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: a.unread ? a.dotColor : _C.border)),
          onTap: () => setState(() => a.unread = false),
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PROFILE SHEET
// ─────────────────────────────────────────────────────────────
class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: _C.surf,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
          decoration: BoxDecoration(color: _C.border,
              borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Container(width: 72, height: 72,
          decoration: const BoxDecoration(shape: BoxShape.circle,
            gradient: LinearGradient(colors: [_C.brand, _C.brandD],
                begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: const Center(child: Text('SK', style: TextStyle(fontSize: 26,
              fontWeight: FontWeight.w900, color: Colors.white)))),
        const SizedBox(height: 12),
        const Text('Sarah K.', style: TextStyle(fontSize: 20,
            fontWeight: FontWeight.w900, color: _C.text)),
        const SizedBox(height: 4),
        const Text('sarah.k@uon.ac.ke',
            style: TextStyle(fontSize: 13, color: _C.text3)),
        const SizedBox(height: 24),
        _PTile(icon: '👤', label: 'Edit Profile',
            onTap: () => Navigator.pop(context)),
        _PTile(icon: '⚙', label: 'Settings',
            onTap: () => Navigator.pop(context)),
        _PTile(icon: '🔔', label: 'Notification Preferences',
            onTap: () => Navigator.pop(context)),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(side: const BorderSide(color: _C.coral),
              foregroundColor: _C.coral,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () => Navigator.pop(context),
            child: const Text('Log Out',
                style: TextStyle(fontWeight: FontWeight.w800)))),
      ]),
    );
  }
}

class _PTile extends StatelessWidget {
  final String icon, label;
  final VoidCallback onTap;
  const _PTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(width: 36, height: 36,
        decoration: BoxDecoration(color: _C.brandPale,
            borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text(icon, style: const TextStyle(fontSize: 16)))),
      title: Text(label, style: const TextStyle(
          fontWeight: FontWeight.w700, color: _C.text)),
      trailing: const Icon(Icons.chevron_right, color: _C.text3),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  HOUSING DETAIL SHEET
// ─────────────────────────────────────────────────────────────
class _HousingDetailSheet extends StatelessWidget {
  final _HousingData card;
  final VoidCallback onContact;
  const _HousingDetailSheet({required this.card, required this.onContact});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: _C.surf,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
          decoration: BoxDecoration(color: _C.border,
              borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Container(width: double.infinity, height: 140,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(begin: Alignment.topLeft,
                end: Alignment.bottomRight, colors: [card.gradA, card.gradB])),
          child: Center(child: Text(card.emoji,
              style: const TextStyle(fontSize: 64)))),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(card.title, style: const TextStyle(fontSize: 20,
              fontWeight: FontWeight.w900, color: _C.text)),
          Text(card.price, style: const TextStyle(fontSize: 18,
              fontWeight: FontWeight.w900, color: _C.terra)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Text(card.distance, style: const TextStyle(fontSize: 13, color: _C.text3)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: _C.greenPale,
                borderRadius: BorderRadius.circular(8)),
            child: Text(card.type, style: TextStyle(fontSize: 11,
                fontWeight: FontWeight.w700, color: card.typeColor))),
        ]),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(
            style: OutlinedButton.styleFrom(side: const BorderSide(color: _C.brand),
              foregroundColor: _C.brand,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Listing saved ❤️'),
                backgroundColor: _C.brand, behavior: SnackBarBehavior.floating));
            },
            child: const Text('Save Listing',
                style: TextStyle(fontWeight: FontWeight.w800)))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _C.brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () { Navigator.pop(context); onContact(); },
            child: const Text('Contact Agent',
                style: TextStyle(fontWeight: FontWeight.w800)))),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CUSTOM PAINTERS
// ─────────────────────────────────────────────────────────────
class _TopoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (final r in [(80.0, 44.0), (55.0, 30.0), (32.0, 18.0)])
      canvas.drawOval(Rect.fromCenter(
          center: Offset(s.width * 0.187, s.height * 0.24),
          width: r.$1 * 2, height: r.$2 * 2), p);
    for (final r in [(95.0, 52.0), (66.0, 36.0), (38.0, 20.0)])
      canvas.drawOval(Rect.fromCenter(
          center: Offset(s.width * 0.827, s.height * 0.60),
          width: r.$1 * 2, height: r.$2 * 2), p);
    final t = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..style = PaintingStyle.stroke..strokeWidth = 1.0;
    void c(List<double> v) => canvas.drawPath(Path()
      ..moveTo(v[0], v[1])..cubicTo(v[2], v[3], v[4], v[5], v[6], v[7]), t);
    c([0, s.height*.16, s.width*.213, s.height*.04, s.width*.48, s.height*.22, s.width, s.height*.18]);
    c([0, s.height*.40, s.width*.187, s.height*.28, s.width*.453, s.height*.42, s.width, s.height*.40]);
    c([0, s.height*.66, s.width*.24, s.height*.56, s.width*.493, s.height*.68, s.width, s.height*.64]);
  }
  @override bool shouldRepaint(_) => false;
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawPath(
      Path()
        ..moveTo(0, s.height * .19)
        ..quadraticBezierTo(s.width*.213, s.height*1.06, s.width*.507, s.height*.577)
        ..quadraticBezierTo(s.width*.795, s.height*.154, s.width, s.height*.962)
        ..lineTo(s.width, s.height)..lineTo(0, s.height)..close(),
      Paint()..color = _C.offWhite,
    );
  }
  @override bool shouldRepaint(_) => false;
}