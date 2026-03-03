import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/eb_constants.dart';
import '../widgets/eb_widgets.dart';

// ═════════════════════════════════════════════════════════════
// CALENDAR SCREEN
// ═════════════════════════════════════════════════════════════
class EBCalendarScreen extends StatefulWidget {
  const EBCalendarScreen({super.key});
  @override
  State<EBCalendarScreen> createState() => _EBCalendarScreenState();
}

class _EBCalendarScreenState extends State<EBCalendarScreen> {
  int _selectedDay = 18;

  // days in Feb 2026 with events
  static const _eventDays = {2, 4, 6, 9, 12, 17, 18, 19, 22, 23, 25, 28};
  static const _today = 17;

  static const _dayEvents = {
    18: [
      (time: '2:00 PM', stripe: EBColors.blue,  name: 'Final Year Project Symposium',  meta: '📍 Main Hall · School of Engineering', cat: '📚 Academic', catColor: EBColors.blue,  attending: 'You\'re going ✓'),
      (time: '6:00 PM', stripe: EBColors.pink,  name: 'Afrobeats Night — Cultural Evening', meta: '📍 Student Union Hall',              cat: '🎭 Cultural', catColor: EBColors.pink,  attending: '156 attending'),
    ],
    19: [
      (time: '3:00 PM', stripe: EBColors.green, name: 'Inter-Faculty Football Finals',  meta: '📍 Main Field',                       cat: '⚽ Sports',   catColor: EBColors.green, attending: '184 attending'),
    ],
    22: [
      (time: '8:00 AM', stripe: EBColors.brand, name: 'UoN Tech Hackathon 2026',        meta: '📍 Innovation Hub',                   cat: '🛠 Career',   catColor: EBColors.amber, attending: 'You\'re going ✓'),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final eventsForDay = _dayEvents[_selectedDay] ?? [];

    return Scaffold(
      backgroundColor: EBColors.surface2,
      appBar: AppBar(
        backgroundColor: EBColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: EBColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Event Calendar',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: EBColors.text)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: EBColors.brandPale, borderRadius: BorderRadius.circular(11)),
            child: const Text('🗂', style: TextStyle(fontSize: 18)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: EBColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // month header + nav
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('February 2026',
                  style: TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                      color: EBColors.text)),
              Row(children: [
                _CalBtn('←'),
                const SizedBox(width: 6),
                _CalBtn('→'),
              ]),
            ]),
          ),

          // day-of-week headers
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(d,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: EBColors.text3)),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // calendar grid
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
              childAspectRatio: 1.0,
              children: List.generate(28, (i) {
                final day = i + 1;
                final isToday = day == _today;
                final isSel = day == _selectedDay && !isToday;
                final hasEvent = _eventDays.contains(day);
                final isPast = day < _today;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = day),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isToday
                          ? EBColors.brand
                          : isSel
                              ? EBColors.brandPale
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('$day',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isToday
                                ? Colors.white
                                : isPast
                                    ? EBColors.text3
                                    : isSel
                                        ? EBColors.brand
                                        : EBColors.text2,
                          )),
                      if (hasEvent)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isToday
                                ? Colors.white.withOpacity(0.7)
                                : EBColors.brandLight,
                          ),
                        ),
                    ]),
                  ),
                );
              }),
            ),
          ),

          // selected day strip
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
                color: EBColors.brandPale, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(_dayLabel(_selectedDay),
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: EBColors.brand)),
              Text(
                '${eventsForDay.length} event${eventsForDay.length != 1 ? 's' : ''}',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: EBColors.brand),
              ),
            ]),
          ),

          // events for selected day
          if (eventsForDay.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              decoration: EBTheme.cardSm,
              child: Column(
                children: eventsForDay
                    .map((ev) => _CalEventRow(
                          time: ev.time,
                          stripColor: ev.stripe,
                          name: ev.name,
                          meta: ev.meta,
                          cat: ev.cat,
                          catColor: ev.catColor,
                          attending: ev.attending,
                        ))
                    .toList(),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('No events this day',
                    style: TextStyle(fontSize: 13, color: EBColors.text3)),
              ),
            ),

          // week strip
          EBSectionLabel(title: '📅 This Week'),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final days   = [18, 19, 20, 21, 22];
                final labels = ['TUE', 'WED', 'THU', 'FRI', 'SAT'];
                final hasEv  = {18, 19, 22}.contains(days[i]);
                final isSel  = days[i] == _selectedDay;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = days[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 52,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSel ? EBColors.brandPale : EBColors.surface3,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: isSel ? EBColors.brandLight : Colors.transparent,
                          width: 1.5),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(labels[i],
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isSel ? EBColors.brand : EBColors.text3)),
                      Text('${days[i]}',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isSel ? EBColors.brand : EBColors.text2)),
                      if (hasEv)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 3),
                          decoration: BoxDecoration(
                            color: isSel ? EBColors.brand : EBColors.brandLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  String _dayLabel(int d) {
    final labels = {
      17: 'Monday, Feb 17',
      18: 'Tuesday, Feb 18',
      19: 'Wednesday, Feb 19',
      20: 'Thursday, Feb 20',
      21: 'Friday, Feb 21',
      22: 'Saturday, Feb 22',
    };
    return labels[d] ?? 'February $d, 2026';
  }
}

// ═════════════════════════════════════════════════════════════
// RSVP SCREEN
// ═════════════════════════════════════════════════════════════
class EBRsvpScreen extends StatefulWidget {
  const EBRsvpScreen({super.key});
  @override
  State<EBRsvpScreen> createState() => _EBRsvpScreenState();
}

class _EBRsvpScreenState extends State<EBRsvpScreen> {
  final _going = [true, true, true];

  static const _myRsvps = [
    _RsvpItem(dayLabel: 'TUE', day: '18', dayColor: EBColors.amber,  stripe: EBColors.amber,
        name: 'Final Year Project Symposium',  meta: '2:00 PM · Main Hall · ⏰ Reminder set',
        goingColor: EBColors.brandPale,  goingTxt: EBColors.brand),
    _RsvpItem(dayLabel: 'WED', day: '19', dayColor: EBColors.green,  stripe: EBColors.green,
        name: 'Inter-Faculty Football Finals', meta: '3:00 PM · Main Field · ⏰ Reminder set',
        goingColor: EBColors.greenPale,  goingTxt: EBColors.green),
    _RsvpItem(dayLabel: 'SAT', day: '22', dayColor: EBColors.brand,  stripe: EBColors.brand,
        name: 'UoN Tech Hackathon 2026',       meta: '8:00 AM · Innovation Hub · ⏰ Reminder set',
        goingColor: EBColors.brandPale,  goingTxt: EBColors.brand),
  ];

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
        title: const Text('My RSVPs',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: EBColors.text)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: EBColors.border, height: 1),
        ),
      ),
      body: CustomScrollView(slivers: [
        // Featured event hero
        SliverToBoxAdapter(
          child: Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [EBColors.brand, EBColors.brandDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            child: Stack(children: [
              Center(child: Text('🎓', style: const TextStyle(fontSize: 80))),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: EBColors.brand, borderRadius: BorderRadius.circular(8)),
                          child: const Text('📚 Academic',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                        const SizedBox(height: 6),
                        const Text('Final Year Project Symposium',
                            style: TextStyle(
                                fontSize: 17,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                                height: 1.3)),
                      ]),
                ),
              ),
            ]),
          ),
        ),

        // event detail row
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: EBTheme.cardSm,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('📅 Feb 18 · 2:00 PM',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: EBColors.text)),
                  Text('📍 Main Hall · School of Engineering',
                      style: TextStyle(fontSize: 11, color: EBColors.text3)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                      color: EBColors.greenPale, borderRadius: BorderRadius.circular(10)),
                  child: Text('✅ Going',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800, color: EBColors.green)),
                ),
              ]),
              const SizedBox(height: 10),
              Text('82 people confirmed · +3 waiting',
                  style: TextStyle(fontSize: 12, color: EBColors.text3)),
            ]),
          ),
        ),

        // my rsvps
        SliverToBoxAdapter(child: EBSectionLabel(title: 'My RSVPs (3 Upcoming)')),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            decoration: EBTheme.cardSm,
            child: Column(
              children: List.generate(_myRsvps.length, (i) {
                final r = _myRsvps[i];
                return _RsvpRow(
                  item: r,
                  going: _going[i],
                  onCancel: () {
                    setState(() => _going[i] = !_going[i]);
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          _going[i] ? 'RSVP restored!' : 'RSVP cancelled for ${r.name}'),
                      backgroundColor: EBColors.brand,
                    ));
                  },
                );
              }),
            ),
          ),
        ),

        // attendee list
        SliverToBoxAdapter(child: EBSectionLabel(title: 'Attendees')),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            decoration: EBTheme.cardSm,
            child: Column(children: [
              _AttendeeRow(emoji: '👩‍💻', name: 'Sarah K.',  sub: 'BSc CS',       color: EBColors.brandLight),
              Divider(color: EBColors.border, height: 1),
              _AttendeeRow(emoji: '👨‍🔬', name: 'James M.',  sub: 'BSc Mech Eng', color: EBColors.blue),
              Divider(color: EBColors.border, height: 1),
              _AttendeeRow(emoji: '👩‍🎓', name: 'Aisha O.',  sub: 'BSc Civil',    color: EBColors.pink),
              Divider(color: EBColors.border, height: 1),
              _AttendeeRow(emoji: '👨‍🏫', name: 'David L.',  sub: 'BA Econ',      color: EBColors.coral),
              Padding(
                padding: const EdgeInsets.all(9),
                child: Center(
                  child: Text('+ 77 more attendees',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: EBColors.brand)),
                ),
              ),
            ]),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// REMINDERS SCREEN
// ═════════════════════════════════════════════════════════════
class EBRemindersScreen extends StatefulWidget {
  const EBRemindersScreen({super.key});
  @override
  State<EBRemindersScreen> createState() => _EBRemindersScreenState();
}

class _EBRemindersScreenState extends State<EBRemindersScreen> {
  bool _remind24h  = true;
  bool _remind1h   = true;
  bool _organiserUp = true;
  bool _nearby     = false;

  // Static RSVP data reused in this screen
  static const _rsvpItems = [
    _RsvpItem(dayLabel: 'TUE', day: '18', dayColor: EBColors.amber, stripe: EBColors.amber,
        name: 'Final Year Project Symposium',  meta: '2:00 PM · Main Hall · ⏰ Reminder set',
        goingColor: EBColors.brandPale, goingTxt: EBColors.brand),
    _RsvpItem(dayLabel: 'WED', day: '19', dayColor: EBColors.green, stripe: EBColors.green,
        name: 'Inter-Faculty Football Finals', meta: '3:00 PM · Main Field · ⏰ Reminder set',
        goingColor: EBColors.greenPale, goingTxt: EBColors.green),
    _RsvpItem(dayLabel: 'SAT', day: '22', dayColor: EBColors.brand, stripe: EBColors.brand,
        name: 'UoN Tech Hackathon 2026',       meta: '8:00 AM · Innovation Hub · ⏰ Reminder set',
        goingColor: EBColors.brandPale, goingTxt: EBColors.brand),
  ];

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
        title: const Text('My RSVPs & Reminders',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: EBColors.text)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: EBColors.brandPale, borderRadius: BorderRadius.circular(11)),
            child: const Text('⚙️', style: TextStyle(fontSize: 18)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: EBColors.border, height: 1),
        ),
      ),
      body: CustomScrollView(slivers: [
        // 24h reminder banner
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              border: Border.all(color: EBColors.amber, width: 1.5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('⏰', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Event in 24 hours!',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF92400E))),
                  const SizedBox(height: 3),
                  const Text('Final Year Project Symposium',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: EBColors.text)),
                  const SizedBox(height: 2),
                  Text('📅 Tomorrow · Feb 18 · 2:00 PM · Main Hall',
                      style: TextStyle(fontSize: 11, color: EBColors.text2)),
                  const SizedBox(height: 9),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: EBColors.amber, borderRadius: BorderRadius.circular(9)),
                      child: const Text('View Event',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: const Color(0xFF92400E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(9)),
                      child: const Text('Get Directions',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF92400E))),
                    ),
                  ]),
                ]),
              ),
            ]),
          ),
        ),

        // my rsvps — use _RsvpRow widgets, NOT raw _RsvpItem objects
        SliverToBoxAdapter(child: EBSectionLabel(title: 'My RSVPs (3 Upcoming)')),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            decoration: EBTheme.cardSm,
            child: Column(
              children: _rsvpItems
                  .map((item) => _RsvpRow(item: item, going: true, onCancel: () {}))
                  .toList(),
            ),
          ),
        ),

        // notification settings
        SliverToBoxAdapter(child: EBSectionLabel(title: 'Notification Settings')),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            decoration: EBTheme.cardSm,
            child: Column(children: [
              EBToggleRow(
                  label: '⏰ 24-hour reminders',
                  subtitle: 'Day before event starts',
                  value: _remind24h,
                  onChanged: (v) => setState(() => _remind24h = v)),
              Divider(color: EBColors.border, height: 1),
              EBToggleRow(
                  label: '⏰ 1-hour reminders',
                  subtitle: '1 hour before event starts',
                  value: _remind1h,
                  onChanged: (v) => setState(() => _remind1h = v)),
              Divider(color: EBColors.border, height: 1),
              EBToggleRow(
                  label: '📣 Organiser updates',
                  subtitle: 'When organiser sends an update',
                  value: _organiserUp,
                  onChanged: (v) => setState(() => _organiserUp = v)),
              Divider(color: EBColors.border, height: 1),
              EBToggleRow(
                  label: '🆕 New nearby events',
                  subtitle: 'Events within 1km of campus',
                  value: _nearby,
                  onChanged: (v) => setState(() => _nearby = v)),
            ]),
          ),
        ),

        // notification feed
        SliverToBoxAdapter(child: EBSectionLabel(title: 'Recent Notifications')),
        const SliverToBoxAdapter(
          child: Column(children: [
            _NotifCard(
                emoji: '⏰',
                bg: EBColors.brandPale,
                title: 'Reminder: Project Symposium is tomorrow at 2pm!',
                sub: '24-hour reminder · Auto-sent · 2h ago',
                unread: true),
            _NotifCard(
                emoji: '📣',
                bg: EBColors.greenPale,
                title: 'Hackathon update: Venue changed to Innovation Hub!',
                sub: 'From: School of Engineering · Yesterday',
                unread: false),
            _NotifCard(
                emoji: '🎟',
                bg: EBColors.amberPale,
                title: 'Afrobeats Night is now at full capacity — 200 attendees!',
                sub: 'Event you saved · 2 days ago',
                unread: false),
          ]),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Private data + widgets
// ─────────────────────────────────────────────────────────────

class _RsvpItem {
  final String dayLabel, day, name, meta;
  final Color dayColor, stripe, goingColor, goingTxt;
  const _RsvpItem({
    required this.dayLabel,
    required this.day,
    required this.dayColor,
    required this.stripe,
    required this.name,
    required this.meta,
    required this.goingColor,
    required this.goingTxt,
  });
}

class _RsvpRow extends StatelessWidget {
  final _RsvpItem item;
  final bool going;
  final VoidCallback onCancel;
  const _RsvpRow({required this.item, required this.going, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(children: [
        Container(
          width: 4,
          margin: const EdgeInsets.only(right: 11),
          decoration:
              BoxDecoration(color: item.stripe, borderRadius: BorderRadius.circular(2)),
          height: 50,
        ),
        Container(
          width: 38,
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration:
              BoxDecoration(color: item.goingColor, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Text(item.dayLabel,
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w800, color: item.dayColor)),
            Text(item.day,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w900, color: item.dayColor)),
          ]),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.name,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: EBColors.text)),
            const SizedBox(height: 2),
            Text(item.meta,
                style: TextStyle(fontSize: 11, color: EBColors.text3)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: item.goingColor, borderRadius: BorderRadius.circular(7)),
              child: Text(going ? '✅ Going' : 'Not Going',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800, color: item.goingTxt)),
            ),
          ]),
        ),
        GestureDetector(
            onTap: onCancel,
            child: const Icon(Icons.more_vert, color: EBColors.text3, size: 20)),
      ]),
    );
  }
}

class _AttendeeRow extends StatelessWidget {
  final String emoji, name, sub;
  final Color color;
  const _AttendeeRow(
      {required this.emoji, required this.name, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient:
                LinearGradient(colors: [color, color.withOpacity(0.6)]),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text(name,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: EBColors.text))),
        Text(sub, style: TextStyle(fontSize: 11, color: EBColors.text3)),
        const SizedBox(width: 8),
        Text('✓', style: TextStyle(fontSize: 16, color: EBColors.green)),
      ]),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final String emoji, title, sub;
  final Color bg;
  final bool unread;
  const _NotifCard(
      {required this.emoji,
      required this.bg,
      required this.title,
      required this.sub,
      required this.unread});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: unread ? EBColors.brandXp : EBColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color:
                unread ? EBColors.brandLight.withOpacity(0.5) : EBColors.border),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                    color: EBColors.text,
                    height: 1.3)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 10, color: EBColors.text3)),
          ]),
        ),
        if (unread)
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: EBColors.brand, shape: BoxShape.circle)),
      ]),
    );
  }
}

class _CalBtn extends StatelessWidget {
  final String label;
  const _CalBtn(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration:
          BoxDecoration(color: EBColors.brandPale, borderRadius: BorderRadius.circular(8)),
      child: Center(
        child: Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: EBColors.brand)),
      ),
    );
  }
}

class _CalEventRow extends StatelessWidget {
  final String time, name, meta, cat, attending;
  final Color stripColor, catColor;
  const _CalEventRow({
    required this.time,
    required this.stripColor,
    required this.name,
    required this.meta,
    required this.cat,
    required this.catColor,
    required this.attending,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 4,
          height: 60,
          margin: const EdgeInsets.only(right: 11),
          decoration:
              BoxDecoration(color: stripColor, borderRadius: BorderRadius.circular(2)),
        ),
        SizedBox(
          width: 44,
          child: Text(time,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: EBColors.text3)),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: EBColors.text)),
            const SizedBox(height: 2),
            Text(meta, style: TextStyle(fontSize: 11, color: EBColors.text3)),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: catColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(7)),
                child: Text(cat,
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w800, color: catColor)),
              ),
              const SizedBox(width: 8),
              Text(attending, style: TextStyle(fontSize: 10, color: EBColors.text3)),
            ]),
          ]),
        ),
      ]),
    );
  }
}