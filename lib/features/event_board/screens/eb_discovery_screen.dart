import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/eb_constants.dart';
import '../widgets/eb_widgets.dart';

// ─────────────────────────────────────────────────────────────
//  DATA
// ─────────────────────────────────────────────────────────────
class _Event {
  final String emoji, title, date, location, organiser, category;
  final int attending;
  final Color catColor, gradA, gradB, rsvpColor;
  const _Event({
    required this.emoji, required this.title, required this.date,
    required this.location, required this.organiser, required this.category,
    required this.attending, required this.catColor,
    required this.gradA, required this.gradB, required this.rsvpColor,
  });
}

const _kEvents = [
  _Event(
    emoji: '🎓', title: 'Final Year Project Symposium — School of Engineering',
    date: 'Feb 18 · 2:00 PM', location: '📍 Main Hall', organiser: 'School of Engineering',
    category: '📚 Academic', attending: 82, catColor: EBColors.blue,
    gradA: Color(0xFFEDE9FE), gradB: Color(0xFFC4B5FD), rsvpColor: EBColors.brand,
  ),
  _Event(
    emoji: '⚽', title: 'Inter-Faculty Football Finals 2026',
    date: 'Feb 19 · 3:00 PM', location: '📍 Main Field', organiser: 'Athletics Union',
    category: '⚽ Sports', attending: 184, catColor: EBColors.green,
    gradA: Color(0xFFECFDF5), gradB: Color(0xFF6EE7B7), rsvpColor: EBColors.green,
  ),
  _Event(
    emoji: '🎭', title: 'Afrobeats Night — Cultural Evening',
    date: 'Feb 18 · 6:00 PM', location: '📍 Student Union Hall', organiser: 'Cultural Society',
    category: '🎭 Cultural', attending: 156, catColor: EBColors.pink,
    gradA: Color(0xFFFDF2F8), gradB: Color(0xFFFBCFE8), rsvpColor: EBColors.pink,
  ),
  _Event(
    emoji: '💼', title: 'Graduate Career Fair 2026',
    date: 'Feb 25 · 9:00 AM', location: '📍 Amphitheatre', organiser: 'Career Services',
    category: '🛠 Career', attending: 320, catColor: EBColors.amber,
    gradA: Color(0xFFFFFBEB), gradB: Color(0xFFFDE68A), rsvpColor: EBColors.amber,
  ),
];

// ─────────────────────────────────────────────────────────────
//  SCREEN 1 — Event Discovery (Browse)
// ─────────────────────────────────────────────────────────────
class EBDiscoveryScreen extends StatefulWidget {
  const EBDiscoveryScreen({super.key});
  @override
  State<EBDiscoveryScreen> createState() => _EBDiscoveryScreenState();
}

class _EBDiscoveryScreenState extends State<EBDiscoveryScreen> {
  int _catFilter  = 0;
  int _sortFilter = 0;

  final _categories = ['All', '📚 Academic', '🎵 Social', '⚽ Sports', '🎭 Cultural', '🛠 Career'];
  final _sorts      = ['🗓 Upcoming', '🔥 Popular', '📍 Nearby', '📅 Today'];

  List<_Event> get _filtered {
    if (_catFilter == 0) return _kEvents;
    final cats = ['', 'Academic', 'Social', 'Sports', 'Cultural', 'Career'];
    return _kEvents.where((e) => e.category.contains(cats[_catFilter])).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EBColors.surface2,
      appBar: AppBar(
        backgroundColor: EBColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: EBColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('EventBoard', style: TextStyle(
            fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w900,
            color: EBColors.brandDark, fontStyle: FontStyle.italic)),
          Text('University of Nairobi · 18 upcoming events',
              style: TextStyle(fontSize: 11, color: EBColors.text3)),
        ]),
        titleSpacing: 0,
        actions: [
          Container(margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: EBColors.brandPale, borderRadius: BorderRadius.circular(11)),
              child: const Text('🔍', style: TextStyle(fontSize: 18))),
          Container(margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: EBColors.brand, borderRadius: BorderRadius.circular(11)),
              child: const Text('🔔', style: TextStyle(fontSize: 18))),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(color: EBColors.border, height: 1)),
      ),
      body: CustomScrollView(slivers: [
        // category chips
        SliverToBoxAdapter(
          child: SizedBox(height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (_, i) => EBChip(label: _categories[i], active: _catFilter == i,
                  onTap: () => setState(() => _catFilter = i)),
            )),
        ),
        // featured event banner
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [EBColors.brand, EBColors.brandDark],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(children: [
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
                gradient: RadialGradient(center: const Alignment(0.8, -0.8), radius: 1.0,
                    colors: [Colors.white.withOpacity(0.12), Colors.transparent])))),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('🔥 FEATURED EVENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.72), letterSpacing: 1.5)),
                const SizedBox(height: 6),
                const Text('UoN Tech Hackathon 2026', style: TextStyle(fontSize: 17,
                    fontStyle: FontStyle.italic, color: Colors.white, height: 1.3)),
                const SizedBox(height: 5),
                Text('📅 Feb 22 · 8:00 AM  —  📍 Innovation Hub',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('+247 attending', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.75))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                        border: Border.all(color: Colors.white.withOpacity(0.4)), borderRadius: BorderRadius.circular(10)),
                    child: const Text('RSVP →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white))),
                ]),
              ]),
            ]),
          ),
        ),
        // sort chips
        SliverToBoxAdapter(
          child: SizedBox(height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              itemCount: _sorts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (_, i) => EBChip(label: _sorts[i], active: _sortFilter == i,
                  onTap: () => setState(() => _sortFilter = i)),
            )),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              if (i >= _filtered.length) return const SizedBox(height: 100);
              final e = _filtered[i];
              return _EventCard(
                event: e,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => EBEventDetailScreen(event: e))),
              );
            },
            childCount: _filtered.length + 1,
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: EBColors.brand,
        foregroundColor: Colors.white,
        icon: const Text('🎉', style: TextStyle(fontSize: 18)),
        label: const Text('Create Event', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EBCreateEventScreen())),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 2 — Event Detail
// ─────────────────────────────────────────────────────────────
class EBEventDetailScreen extends StatefulWidget {
  final _Event? event;
  const EBEventDetailScreen({super.key, this.event});
  @override
  State<EBEventDetailScreen> createState() => _EBEventDetailScreenState();
}

class _EBEventDetailScreenState extends State<EBEventDetailScreen> {
  bool _going = false;

  _Event get _e => widget.event ?? const _Event(
    emoji: '🎓', title: 'Final Year Project Symposium', date: 'Feb 18 · 2:00 PM',
    location: '📍 Main Hall', organiser: 'School of Engineering',
    category: '📚 Academic', attending: 82, catColor: EBColors.blue,
    gradA: Color(0xFFEDE9FE), gradB: Color(0xFFC4B5FD), rsvpColor: EBColors.brand,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EBColors.surface2,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: false,
          backgroundColor: Colors.transparent,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.88), borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: EBColors.text))),
          actions: [
            GestureDetector(onTap: () {},
              child: Container(margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.88), borderRadius: BorderRadius.circular(11)),
                child: const Padding(padding: EdgeInsets.all(8), child: Text('🤍', style: TextStyle(fontSize: 18))))),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(gradient: LinearGradient(colors: [_e.gradA, _e.gradB],
                  begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: Stack(children: [
                Center(child: Text(_e.emoji, style: const TextStyle(fontSize: 80))),
                Positioned(bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 30, 16, 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
                          begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: _e.catColor, borderRadius: BorderRadius.circular(8)),
                        child: Text(_e.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white))),
                      const SizedBox(height: 6),
                      Text(_e.title, style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.white, height: 1.3)),
                    ]),
                  )),
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0), child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_e.date, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EBColors.text)),
                  Text(_e.location, style: TextStyle(fontSize: 12, color: EBColors.text3)),
                ]),
                GestureDetector(
                  onTap: () {
                    setState(() => _going = !_going);
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(_going ? "✅ You're going!" : 'RSVP cancelled'),
                      backgroundColor: _e.rsvpColor));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                    decoration: BoxDecoration(
                      color: _going ? EBColors.green : _e.rsvpColor,
                      borderRadius: BorderRadius.circular(12)),
                    child: Text(_going ? '✅ Going' : 'RSVP →',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
              ])),
            const SizedBox(height: 14),
            EBFormField(label: 'Organised by', value: _e.organiser),
            EBFormField(label: 'Attending', value: '${_e.attending} people confirmed'),
            EBFormField(label: 'Entry', value: 'Free Entry · Open to all students'),
            EBFormField(label: 'About', value: 'Join us for an outstanding showcase of final year student projects across all engineering disciplines. Industry judges, awards, and networking.', multiline: true),
            EBSectionLabel(title: 'Who\'s Going'),
            _AttendeeList(),
            const SizedBox(height: 40),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 3 — Create Event
// ─────────────────────────────────────────────────────────────
class EBCreateEventScreen extends StatefulWidget {
  const EBCreateEventScreen({super.key});
  @override
  State<EBCreateEventScreen> createState() => _EBCreateEventScreenState();
}

class _EBCreateEventScreenState extends State<EBCreateEventScreen> {
  String _category = 'Academic';
  String _mode     = 'In-Person';

  static const _cats = [
    ('📚', 'Academic'), ('🎵', 'Social'), ('⚽', 'Sports'), ('🎭', 'Cultural'), ('🛠', 'Career'),
  ];
  static const _modes = ['In-Person', 'Online', 'Hybrid'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EBColors.surface2,
      appBar: AppBar(
        backgroundColor: EBColors.surface, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: EBColors.text), onPressed: () => Navigator.pop(context)),
        title: const Text('Create Event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: EBColors.text)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('✅ Event published!'), backgroundColor: EBColors.brand));
            },
            child: Text('Publish', style: TextStyle(fontWeight: FontWeight.w800, color: EBColors.brand))),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(color: EBColors.border, height: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text('Create an event and invite your campus community 🎉',
                style: TextStyle(fontSize: 13, color: EBColors.text2))),
          EBFormField(label: 'Event Title', value: 'e.g. Annual Science Fair 2026', active: true),
          EBSectionLabel(title: 'Category'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.5,
              children: _cats.map<Widget>((c) => GestureDetector(
                onTap: () => setState(() => _category = c.$2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _category == c.$2 ? EBColors.brandPale : EBColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _category == c.$2 ? EBColors.brand : EBColors.border, width: 1.5)),
                  child: Row(children: [
                    Text(c.$1, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(c.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: _category == c.$2 ? EBColors.brand : EBColors.text2)),
                  ]),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 10),
          EBFormField(label: 'Date & Time', value: 'Feb 22, 2026 · 8:00 AM', active: true),
          EBFormField(label: 'Venue / Location', value: 'e.g. Innovation Hub, UoN', active: true),
          EBSectionLabel(title: 'Event Mode'),
          SizedBox(height: 46, child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _modes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (_, i) => EBChip(label: _modes[i], active: _mode == _modes[i],
                onTap: () => setState(() => _mode = _modes[i])),
          )),
          const SizedBox(height: 10),
          EBFormField(label: 'Expected Attendees', value: '50 – 200'),
          EBFormField(label: 'Description', value: 'Describe the event, what attendees can expect, how to prepare...', multiline: true),
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: EBColors.brandPale, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: EBColors.brandLight, width: 1.5)),
            child: Row(children: [
              const Text('🔔', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Auto-reminders enabled', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EBColors.brand)),
                const SizedBox(height: 2),
                Text('Attendees get 24h and 1h reminders automatically.', style: TextStyle(fontSize: 11, color: EBColors.text2)),
              ])),
            ]),
          ),
          EBPrimaryButton(
            label: '🎉 Publish Event',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('✅ Event published!'), backgroundColor: EBColors.brand));
            },
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Private helpers
// ─────────────────────────────────────────────────────────────

class _EventCard extends StatefulWidget {
  final _Event event;
  final VoidCallback onTap;
  const _EventCard({required this.event, required this.onTap});
  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _going = false;
  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: EBTheme.card,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 110, decoration: BoxDecoration(
            gradient: LinearGradient(colors: [e.gradA, e.gradB], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ), child: Stack(children: [
            Center(child: Text(e.emoji, style: const TextStyle(fontSize: 52))),
            Positioned(top: 8, left: 8, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: e.catColor, borderRadius: BorderRadius.circular(8)),
              child: Text(e.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)))),
            Positioned(bottom: 8, right: 8, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(7)),
              child: Text(e.date, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)))),
            Positioned(top: 8, right: 8, child: Container(width: 28, height: 28,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
              child: const Center(child: Text('🤍', style: TextStyle(fontSize: 12))))),
          ])),
          Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.title, maxLines: 2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: EBColors.text, height: 1.3)),
            const SizedBox(height: 3),
            Text('${e.location} · Free Entry · ${e.organiser}', style: TextStyle(fontSize: 11, color: EBColors.text3)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                _MiniAvatarStack(),
                const SizedBox(width: 6),
                Text('+${e.attending} attending', style: TextStyle(fontSize: 11, color: EBColors.text3)),
              ]),
              EBRsvpButton(going: _going, color: e.rsvpColor, onTap: () {
                setState(() => _going = !_going);
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(_going ? "✅ You're going to ${e.title}!" : 'RSVP cancelled'),
                  backgroundColor: e.rsvpColor));
              }),
            ]),
          ])),
        ]),
      ),
    );
  }
}

class _MiniAvatarStack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const avs = [('SK', EBColors.brandLight), ('JM', EBColors.brandDark), ('AO', EBColors.blue)];
    return SizedBox(width: 42, height: 20,
      child: Stack(children: List.generate(avs.length, (i) => Positioned(
        left: i * 14.0,
        child: Container(width: 20, height: 20,
          decoration: BoxDecoration(shape: BoxShape.circle, color: avs[i].$2,
              border: Border.all(color: Colors.white, width: 1.5)),
          child: Center(child: Text(avs[i].$1, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w800, color: Colors.white)))),
      ))));
  }
}

class _AttendeeList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const attendees = [
      ('👩‍💻', 'Sarah K.', 'BSc CS', EBColors.brandLight),
      ('👨‍🔬', 'James M.', 'BSc Mech Eng', EBColors.blue),
      ('👩‍🎓', 'Aisha O.', 'BSc Civil', EBColors.pink),
      ('👨‍🏫', 'David L.', 'BA Econ', EBColors.coral),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: EBTheme.cardSm,
      child: Column(children: [
        ...attendees.map<Widget>((a) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(
              gradient: LinearGradient(colors: [a.$4, a.$4.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(11)),
              child: Center(child: Text(a.$1, style: const TextStyle(fontSize: 16)))),
            const SizedBox(width: 10),
            Expanded(child: Text('${a.$2}  ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EBColors.text))),
            Text(a.$3, style: TextStyle(fontSize: 11, color: EBColors.text3)),
            const SizedBox(width: 8),
            Text('✓', style: TextStyle(fontSize: 16, color: EBColors.green)),
          ]),
        )),
        Padding(padding: const EdgeInsets.all(9),
          child: Center(child: Text('+ 77 more attendees',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EBColors.brand)))),
      ]),
    );
  }
}