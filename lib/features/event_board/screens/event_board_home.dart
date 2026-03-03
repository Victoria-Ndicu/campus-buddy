import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/eb_constants.dart';
import '../widgets/eb_widgets.dart';
import 'eb_discovery_screen.dart';
import 'eb_calendar_screen.dart';
import 'eb_rsvp_screen.dart';
import 'eb_reminders_screen.dart';

// ─────────────────────────────────────────────────────────────
//  EventBoardHome
// ─────────────────────────────────────────────────────────────
class EventBoardHome extends StatefulWidget {
  const EventBoardHome({super.key});
  @override
  State<EventBoardHome> createState() => _EventBoardHomeState();
}

class _EventBoardHomeState extends State<EventBoardHome> {
  bool _featuredGoing = false;
  int _navSelected    = 0;

  static const _stats = [
    _Stat('🗓', '18', 'Upcoming'),
    _Stat('✅', '3',  'My RSVPs'),
    _Stat('🔔', '2',  'Reminders'),
    _Stat('🏷', '5',  'Categories'),
  ];

  @override
  Widget build(BuildContext context) {
    final modules = [
      _Mod('🗓', 'Browse Events',  '18 upcoming events',
          EBColors.brand, EBColors.brandDark, const EBDiscoveryScreen()),
      _Mod('📅', 'Event Calendar', 'Feb 2026',
          EBColors.blue, const Color(0xFF4A5FCC), const EBCalendarScreen()),
      _Mod('🎟', 'My RSVPs',       '3 confirmed',
          EBColors.green, const Color(0xFF059669), const EBRsvpScreen()),
      _Mod('🔔', 'Reminders',      '2 upcoming',
          EBColors.amber, const Color(0xFFD97706), const EBRemindersScreen()),
    ];

    return Scaffold(
      backgroundColor: EBColors.surface2,
      body: CustomScrollView(slivers: [
        // ── App Bar ──────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          stretch: true,
          backgroundColor: EBColors.brandDark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [EBColors.brand, EBColors.brandDark],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Stack(children: [
                Positioned(top: -40, right: -30, child: Container(width: 160, height: 160,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)))),
                Positioned(bottom: 20, left: 16, right: 16, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    const Text('EventBoard', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text('University of Nairobi · 18 upcoming events',
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75))),
                    const SizedBox(height: 14),
                    Row(children: _stats.map<Widget>((s) => Expanded(child: Column(children: [
                      Text(s.value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text(s.label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.65))),
                    ]))).toList()),
                  ],
                )),
              ]),
            ),
          ),
          actions: [
            IconButton(icon: Icon(Icons.notifications_none, color: Colors.white.withOpacity(0.9)), onPressed: () {}),
            const SizedBox(width: 4),
          ],
        ),

        // ── Module grid ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: GridView.count(
              crossAxisCount: 2, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.1,
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

        // ── Featured event ───────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [EBColors.brand, EBColors.brandDark],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(children: [
              Positioned(right: 10, top: 0, bottom: 0,
                  child: Text('🎓', style: TextStyle(fontSize: 72, color: Colors.white.withOpacity(0.12)))),
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
                gradient: RadialGradient(center: const Alignment(0.7, -0.8), radius: 1.0,
                    colors: [Colors.white.withOpacity(0.12), Colors.transparent])))),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('🔥 FEATURED EVENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.72), letterSpacing: 1.5)),
                const SizedBox(height: 6),
                const Text('UoN Tech Hackathon 2026', style: TextStyle(fontSize: 18,
                    fontStyle: FontStyle.italic, color: Colors.white, height: 1.3)),
                const SizedBox(height: 6),
                Text('📅 Sat, Feb 22 · 8:00 AM  ·  📍 Innovation Hub',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.75))),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('+247 attending', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.75))),
                  GestureDetector(
                    onTap: () {
                      setState(() => _featuredGoing = !_featuredGoing);
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(_featuredGoing ? "✅ You're going to UoN Tech Hackathon!" : 'RSVP cancelled'),
                        backgroundColor: EBColors.brand));
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _featuredGoing ? Colors.white.withOpacity(0.35) : Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.35)),
                      ),
                      child: Text(_featuredGoing ? '✅ Going' : 'RSVP →',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white))),
                  ),
                ]),
              ]),
            ]),
          ),
        ),

        // ── Upcoming events ──────────────────────────────────
        SliverToBoxAdapter(
          child: EBSectionLabel(title: '🎉 Upcoming Events', action: 'See all →',
              onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EBDiscoveryScreen()))),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            _UpcomingEventCard(
              emoji: '🎓', category: '📚 Academic', categoryColor: EBColors.blue,
              title: 'Final Year Project Symposium', date: 'Feb 18 · 2:00 PM',
              location: '📍 Main Hall', attending: '82 attending',
              gradA: const Color(0xFFEDE9FE), gradB: const Color(0xFFC4B5FD), rsvpColor: EBColors.brand,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EBRsvpScreen())),
            ),
            _UpcomingEventCard(
              emoji: '⚽', category: '⚽ Sports', categoryColor: EBColors.green,
              title: 'Inter-Faculty Football Finals 2026', date: 'Feb 19 · 3:00 PM',
              location: '📍 Main Field', attending: '184 attending',
              gradA: const Color(0xFFECFDF5), gradB: const Color(0xFF6EE7B7), rsvpColor: EBColors.green,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EBRsvpScreen())),
            ),
            _UpcomingEventCard(
              emoji: '🎭', category: '🎭 Cultural', categoryColor: EBColors.pink,
              title: 'Afrobeats Night — Cultural Evening', date: 'Feb 18 · 6:00 PM',
              location: '📍 Student Union Hall', attending: '156 attending',
              gradA: const Color(0xFFFDF2F8), gradB: const Color(0xFFFBCFE8), rsvpColor: EBColors.pink,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EBRsvpScreen())),
            ),
            const SizedBox(height: 100),
          ]),
        ),
      ]),

      // ── FAB ──────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: EBColors.brand,
        foregroundColor: Colors.white,
        icon: const Text('🎉', style: TextStyle(fontSize: 18)),
        label: const Text('Create Event', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EBCreateEventScreen())),
      ),

      // ── Bottom Nav ───────────────────────────────────────
      bottomNavigationBar: _EBBottomNav(selected: _navSelected, onTap: (i) {
        setState(() => _navSelected = i);
        switch (i) {
          case 1: Navigator.push(context, MaterialPageRoute(builder: (_) => const EBCalendarScreen())); break;
          case 2: Navigator.push(context, MaterialPageRoute(builder: (_) => const EBRsvpScreen())); break;
          case 3: Navigator.push(context, MaterialPageRoute(builder: (_) => const EBRemindersScreen())); break;
        }
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DATA
// ─────────────────────────────────────────────────────────────
class _Stat  { final String emoji, value, label; const _Stat(this.emoji, this.value, this.label); }
class _Mod   { final String emoji, title, subtitle; final Color colorA, colorB; final Widget screen;
               const _Mod(this.emoji, this.title, this.subtitle, this.colorA, this.colorB, this.screen); }

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
      child: Material(color: Colors.transparent, child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withOpacity(0.15),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(gradient: LinearGradient(
              colors: [colorA, colorB], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: Stack(children: [
            Positioned(top: -16, right: -16, child: Container(width: 72, height: 72,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)))),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.75))),
            ]),
            Positioned(top: 0, right: 0, child: Container(width: 24, height: 24,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: const Center(child: Text('›', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w900))))),
          ]),
        ),
      )),
    );
  }
}

class _UpcomingEventCard extends StatefulWidget {
  final String emoji, category, title, date, location, attending;
  final Color categoryColor, gradA, gradB, rsvpColor;
  final VoidCallback onTap;
  const _UpcomingEventCard({required this.emoji, required this.category, required this.categoryColor,
      required this.title, required this.date, required this.location, required this.attending,
      required this.gradA, required this.gradB, required this.rsvpColor, required this.onTap});
  @override
  State<_UpcomingEventCard> createState() => _UpcomingEventCardState();
}

class _UpcomingEventCardState extends State<_UpcomingEventCard> {
  bool _going = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: EBTheme.card,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 110, decoration: BoxDecoration(
            gradient: LinearGradient(colors: [widget.gradA, widget.gradB], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ), child: Stack(children: [
            Center(child: Text(widget.emoji, style: const TextStyle(fontSize: 54))),
            Positioned(top: 10, left: 10, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: widget.categoryColor, borderRadius: BorderRadius.circular(8)),
              child: Text(widget.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)))),
            Positioned(top: 10, right: 10, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(7)),
              child: Text(widget.date, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)))),
            Positioned(top: 10, right: 10, child: Container(width: 28, height: 28,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
              child: const Center(child: Text('🤍', style: TextStyle(fontSize: 13))))),
          ])),
          Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: EBColors.text)),
            const SizedBox(height: 3),
            Text(widget.location, style: TextStyle(fontSize: 11, color: EBColors.text3)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(widget.attending, style: TextStyle(fontSize: 11, color: EBColors.text3)),
              EBRsvpButton(going: _going, color: widget.rsvpColor, onTap: () {
                setState(() => _going = !_going);
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(_going ? "✅ You're going to ${widget.title}!" : 'RSVP cancelled'),
                  backgroundColor: widget.rsvpColor));
              }),
            ]),
          ])),
        ]),
      ),
    );
  }
}

class _EBBottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _EBBottomNav({required this.selected, required this.onTap});

  static const _items = [
    ('🗓', 'Events'),
    ('📅', 'Calendar'),
    ('🎟', 'My RSVPs'),
    ('🔔', 'Alerts'),
    ('👤', 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: EBColors.border))),
      padding: EdgeInsets.only(top: 10, bottom: MediaQuery.of(context).padding.bottom + 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final active = i == selected;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onTap(i); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: active ? EBColors.brand.withOpacity(0.10) : Colors.transparent,
                borderRadius: BorderRadius.circular(12)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_items[i].$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 3),
                Text(_items[i].$2, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: active ? EBColors.brand : EBColors.text3)),
              ]),
            ),
          );
        }),
      ),
    );
  }
}