import 'package:flutter/material.dart';
import '../models/hh_constants.dart';
import '../widgets/hh_widgets.dart';

// ─────────────────────────────────────────────────────────────
//  DATA
// ─────────────────────────────────────────────────────────────
class _Roommate {
  final String emoji, name, course, year, location;
  final int matchPct;
  final List<String> prefs;
  final Color gradA, gradB;
  const _Roommate({
    required this.emoji, required this.name, required this.course, required this.year,
    required this.location, required this.matchPct, required this.prefs,
    required this.gradA, required this.gradB,
  });
}

const _kRoommates = [
  _Roommate(
    emoji: '👨‍💻', name: 'Kevin O.', course: 'BSc Computer Science', year: '3rd Year',
    location: 'Westlands / Parklands', matchPct: 84,
    prefs: ['Night owl', 'Very tidy', 'Quiet', 'Non-smoker'],
    gradA: Color(0xFFEEF1FD), gradB: Color(0xFFC7D2FA),
  ),
  _Roommate(
    emoji: '👩‍🎓', name: 'Amina H.', course: 'BA Economics', year: '2nd Year',
    location: 'CBD / Ngara', matchPct: 76,
    prefs: ['Early bird', 'Relaxed', 'Moderate', 'Pets okay'],
    gradA: Color(0xFFECFDF5), gradB: Color(0xFFA7F3D0),
  ),
  _Roommate(
    emoji: '👨‍🔬', name: 'Brian M.', course: 'BSc Chemistry', year: '4th Year',
    location: 'Parklands', matchPct: 91,
    prefs: ['Night owl', 'Very tidy', 'Quiet', 'Non-smoker'],
    gradA: Color(0xFFFDF0EC), gradB: Color(0xFFF4C5B5),
  ),
];

// ─────────────────────────────────────────────────────────────
//  SCREEN 1 — Roommate Browse
// ─────────────────────────────────────────────────────────────
class HHRoommateScreen extends StatefulWidget {
  const HHRoommateScreen({super.key});
  @override
  State<HHRoommateScreen> createState() => _HHRoommateScreenState();
}

class _HHRoommateScreenState extends State<HHRoommateScreen> {
  int _filter = 0;
  final _filters = ['All', 'High Match', 'Near Campus', 'Female Only', 'Male Only'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HHColors.surface2,
      appBar: AppBar(
        backgroundColor: HHColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: HHColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Roommate Matching', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: HHColors.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HHRoommatePrefsScreen())),
            child: Text('My Prefs', style: TextStyle(color: HHColors.brand, fontWeight: FontWeight.w700)),
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(color: HHColors.border, height: 1)),
      ),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: HHSearchBar(hint: 'Search by name, course, area...')),
        SliverToBoxAdapter(
          child: SizedBox(height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (_, i) => HHChip(label: _filters[i], active: _filter == i, onTap: () => setState(() => _filter = i)),
            )),
        ),
        SliverToBoxAdapter(child: HHSectionLabel(title: '👫 Top Matches for You', action: 'Update prefs →')),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              if (i >= _kRoommates.length) return const SizedBox(height: 100);
              final r = _kRoommates[i];
              return _RoommateCard(
                roommate: r,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => HHRoommateDetailScreen(roommate: r))),
              );
            },
            childCount: _kRoommates.length + 1,
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 2 — Roommate Detail
// ─────────────────────────────────────────────────────────────
class HHRoommateDetailScreen extends StatelessWidget {
  final _Roommate roommate;
  const HHRoommateDetailScreen({super.key, required this.roommate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HHColors.surface2,
      appBar: AppBar(
        backgroundColor: HHColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: HHColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(roommate.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: HHColors.text)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(color: HHColors.border, height: 1)),
      ),
      body: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Profile header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: HHTheme.card,
          child: Row(children: [
            Container(width: 64, height: 64, decoration: BoxDecoration(
              gradient: LinearGradient(colors: [roommate.gradA, roommate.gradB]),
              borderRadius: BorderRadius.circular(18)),
              child: Center(child: Text(roommate.emoji, style: const TextStyle(fontSize: 30)))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(roommate.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: HHColors.text)),
              Text(roommate.course, style: TextStyle(fontSize: 13, color: HHColors.text2)),
              Text(roommate.year, style: TextStyle(fontSize: 12, color: HHColors.text3)),
            ])),
            Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: HHColors.tealPale, borderRadius: BorderRadius.circular(10)),
                child: Text('${roommate.matchPct}% Match',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: HHColors.teal))),
            ]),
          ]),
        ),
        HHFormField(label: 'Preferred Location', value: roommate.location),
        HHFormField(label: 'Budget Range', value: 'KES 8,000 – 15,000 /month'),
        HHSectionLabel(title: 'Lifestyle Preferences'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(spacing: 8, runSpacing: 8,
            children: roommate.prefs.map<Widget>((p) => HHTag(p, bg: HHColors.brandPale, fg: HHColors.brand)).toList()),
        ),
        const SizedBox(height: 14),
        HHFormField(label: 'About', value: 'Friendly, organized student looking for a compatible roommate. I keep the common areas clean and respect quiet hours after 10pm.', multiline: true),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(child: OutlinedButton(
              style: OutlinedButton.styleFrom(side: BorderSide(color: HHColors.brand), foregroundColor: HHColors.brand,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () {},
              child: const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.w800)))),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: HHColors.teal, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Match request sent!')));
              },
              child: const Text('Connect 👋', style: TextStyle(fontWeight: FontWeight.w800)))),
          ]),
        ),
        const SizedBox(height: 40),
      ])),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 3 — Roommate Preferences (Create/Action)
// ─────────────────────────────────────────────────────────────
class HHRoommatePrefsScreen extends StatefulWidget {
  const HHRoommatePrefsScreen({super.key});
  @override
  State<HHRoommatePrefsScreen> createState() => _HHRoommatePrefsScreenState();
}

class _HHRoommatePrefsScreenState extends State<HHRoommatePrefsScreen> {
  String _sleep    = 'Night owl';
  String _clean    = 'Very tidy';
  String _noise    = 'Quiet';
  bool   _noSmoke  = true;
  bool   _petsOk   = false;
  int    _budget   = 12000;
  final _locs      = ['Parklands', 'Westlands', 'CBD', 'Ngara', 'Highridge'];
  final _selLocs   = {'Parklands', 'Westlands'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HHColors.surface2,
      appBar: AppBar(
        backgroundColor: HHColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: HHColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Roommate Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: HHColors.text)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(color: HHColors.border, height: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          HHSectionLabel(title: 'Budget Range'),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
            Expanded(child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: HHColors.surface, border: Border.all(color: HHColors.border), borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                Text('Min', style: TextStyle(fontSize: 10, color: HHColors.text3)),
                Text('KES 5,000', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: HHColors.brand)),
              ]))),
            const SizedBox(width: 10),
            Expanded(child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: HHColors.surface, border: Border.all(color: HHColors.border), borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                Text('Max', style: TextStyle(fontSize: 10, color: HHColors.text3)),
                Text('KES ${_budget.toStringAsFixed(0)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: HHColors.brand)),
              ]))),
          ])),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(value: _budget.toDouble(), min: 5000, max: 30000,
              activeColor: HHColors.brand, onChanged: (v) => setState(() => _budget = v.round()))),
          HHSectionLabel(title: 'Preferred Location'),
          SizedBox(height: 50,
            child: ListView.separated(
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
                }),
              ),
            )),
          HHSectionLabel(title: 'Lifestyle Preferences'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: HHTheme.card,
            child: Column(children: [
              _PrefRow(label: '🌙 Sleep Schedule', options: ['Early bird', 'Night owl'],
                  value: _sleep, onChanged: (v) => setState(() => _sleep = v)),
              Divider(color: HHColors.border, height: 1),
              _PrefRow(label: '🧹 Cleanliness', options: ['Relaxed', 'Very tidy'],
                  value: _clean, onChanged: (v) => setState(() => _clean = v)),
              Divider(color: HHColors.border, height: 1),
              _PrefRow(label: '🎵 Noise Level', options: ['Quiet', 'Moderate', 'Social'],
                  value: _noise, onChanged: (v) => setState(() => _noise = v)),
              Divider(color: HHColors.border, height: 1),
              HHToggleRow(label: '🚬 Non-smoker preferred', subtitle: 'Only match with non-smokers',
                  value: _noSmoke, onChanged: (v) => setState(() => _noSmoke = v)),
              Divider(color: HHColors.border, height: 1),
              HHToggleRow(label: '🐾 Pets okay', subtitle: 'Open to roommates with pets',
                  value: _petsOk, onChanged: (v) => setState(() => _petsOk = v)),
            ]),
          ),
          HHPrimaryButton(
            label: '💾 Save & Find Matches',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('✅ Preferences saved! Finding your matches...'),
                backgroundColor: HHColors.teal,
              ));
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
        child: Row(children: [
          Container(width: 54, height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [roommate.gradA, roommate.gradB]),
              borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text(roommate.emoji, style: const TextStyle(fontSize: 24)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(roommate.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: HHColors.text)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: HHColors.tealPale, borderRadius: BorderRadius.circular(8)),
                child: Text('${roommate.matchPct}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: HHColors.teal))),
            ]),
            const SizedBox(height: 2),
            Text(roommate.course, style: TextStyle(fontSize: 12, color: HHColors.text2)),
            Text('📍 ${roommate.location}', style: TextStyle(fontSize: 11, color: HHColors.text3)),
            const SizedBox(height: 6),
            Wrap(spacing: 5, runSpacing: 5,
              children: roommate.prefs.take(3).map<Widget>((p) => HHTag(p, bg: HHColors.brandPale, fg: HHColors.brand)).toList()),
          ])),
        ]),
      ),
    );
  }
}

class _PrefRow extends StatelessWidget {
  final String label, value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  const _PrefRow({required this.label, required this.options, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: HHColors.text)),
        Wrap(spacing: 5, children: options.map<Widget>((o) => GestureDetector(
          onTap: () => onChanged(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: value == o ? HHColors.brand : HHColors.surface3,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: value == o ? HHColors.brand : HHColors.border),
            ),
            child: Text(o, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: value == o ? Colors.white : HHColors.text2)),
          ),
        )).toList()),
      ]),
    );
  }
}