// ============================================================
//  StudyBuddy — sb_groups_screen.dart
//
//  Screen stack:
//    SBGroupsScreen
//      ├─ SBGroupDetailScreen   (tap group card)
//      └─ SBCreateGroupScreen   (tap + in app bar)
// ============================================================

import 'package:flutter/material.dart';
import '../models/sb_constants.dart';
import '../widgets/sb_widgets.dart';

// ─────────────────────────────────────────────────────────────
//  1. Browse Study Groups
// ─────────────────────────────────────────────────────────────
class SBGroupsScreen extends StatefulWidget {
  const SBGroupsScreen({super.key});

  @override
  State<SBGroupsScreen> createState() => _SBGroupsScreenState();
}

class _SBGroupsScreenState extends State<SBGroupsScreen> {
  int _filter = 0;
  final _filters = ['All', 'My Groups', 'Nearby', 'Online', 'Open'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SBColors.surface2,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: SBColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Study Groups',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: SBColors.text)),
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SBCreateGroupScreen())),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36, height: 36,
              decoration: BoxDecoration(color: SBColors.brand, borderRadius: BorderRadius.circular(10)),
              child: const Center(
                child: Text('+',
                    style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SBSearchBar(hint: 'Search groups by course or topic...')),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => SBChip(
                  label: _filters[i],
                  active: _filter == i,
                  onTap: () => setState(() => _filter = i),
                ),
              ),
            ),
          ),
          // Hero banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF3ECF8E), Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Join 42 Active Groups',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Connect with peers studying the same courses right now',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: const Text('Explore All →',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: SBSectionLabel(title: 'Recommended for You', action: 'See all'),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _GroupCard(
                emoji: '📐',
                name: 'MATH201 Study Squad',
                course: 'MATH 201',
                description: 'Focused on Calculus II exam prep. Working through past papers together every week.',
                schedule: 'Tue & Thu · 4pm',
                location: 'Library Room 3',
                members: 8, maxMembers: 12, isJoined: true,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SBGroupDetailScreen())),
              ),
              _GroupCard(
                emoji: '💻',
                name: 'CS301 Algorithms Hub',
                course: 'CS 301',
                description: 'Algorithm analysis and design. LeetCode sessions & graph theory deep dives.',
                schedule: 'Mon & Wed · 5pm',
                location: 'Online – Discord',
                members: 11, maxMembers: 15, isJoined: false,
                onTap: () {},
              ),
              _GroupCard(
                emoji: '⚗️',
                name: 'Organic Chemistry Crew',
                course: 'CHEM 202',
                description: 'Mastering organic synthesis mechanisms together. Weekly lab discussion sessions.',
                schedule: 'Fri · 2pm',
                location: 'Science Block B',
                members: 6, maxMembers: 10, isJoined: false,
                onTap: () {},
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String emoji, name, course, description, schedule, location;
  final int members, maxMembers;
  final bool isJoined;
  final VoidCallback onTap;

  const _GroupCard({
    required this.emoji, required this.name, required this.course,
    required this.description, required this.schedule, required this.location,
    required this.members, required this.maxMembers,
    required this.isJoined, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: SBTheme.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Text('$emoji  $name',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: SBColors.text)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
                color: SBColors.brandPale, borderRadius: BorderRadius.circular(8)),
            child: Text(course,
                style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: SBColors.brand)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(description,
            style: const TextStyle(fontSize: 12, color: SBColors.text2, height: 1.5)),
        const SizedBox(height: 10),
        Wrap(spacing: 12, children: [
          _Meta('📅', schedule),
          _Meta('📍', location),
          _Meta('👥', '$members/$maxMembers'),
        ]),
        const SizedBox(height: 10),
        const Divider(color: SBColors.border, height: 1),
        const SizedBox(height: 10),
        Row(children: [
          // member avatars
          Row(children: List.generate(3, (i) => Container(
            width: 24, height: 24,
            margin: EdgeInsets.only(left: i == 0 ? 0 : -6),
            decoration: BoxDecoration(
              color: SBColors.brandPale,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(String.fromCharCode(65 + i),
                  style: const TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700, color: SBColors.brand)),
            ),
          ))),
          const SizedBox(width: 8),
          Text('+${members - 3} more',
              style: const TextStyle(fontSize: 10, color: SBColors.text3)),
          const Spacer(),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isJoined ? SBColors.green.withOpacity(0.1) : SBColors.brandPale,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isJoined ? SBColors.green : SBColors.brand, width: 1.5),
              ),
              child: Text(
                isJoined ? '✓ Joined' : 'Join',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: isJoined ? SBColors.green : SBColors.brand),
              ),
            ),
          ),
        ]),
      ]),
    ),
  );
}

class _Meta extends StatelessWidget {
  final String icon, label;
  const _Meta(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text(icon, style: const TextStyle(fontSize: 11)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 10, color: SBColors.text3)),
  ]);
}

// ─────────────────────────────────────────────────────────────
//  2. Group Detail
// ─────────────────────────────────────────────────────────────
class SBGroupDetailScreen extends StatelessWidget {
  const SBGroupDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SBColors.surface2,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: SBColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('MATH201 Study Squad',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: SBColors.text)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Text('⋯', style: TextStyle(fontSize: 22, color: SBColors.text2)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: SBTheme.brandGradient(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MATH 201 · CALCULUS II',
                  style: TextStyle(
                      fontSize: 10, color: Colors.white.withOpacity(0.75),
                      fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 6),
              const Text('📐  MATH201 Study Squad',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Focused on Calculus II exam prep. Working through past papers together every week.',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85), height: 1.5)),
              const SizedBox(height: 12),
              Wrap(spacing: 16, children: [
                Text('📅 Tue & Thu · 4pm',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
                Text('📍 Library Room 3',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
              ]),
            ]),
          ),
          // Stats
          _StatsBar(const [('8','Members'),('12','Max'),('24','Sessions'),('18','Files')]),

          // Members
          SBSectionLabel(title: 'Members (8)', action: 'Invite +'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(children: [
              _MemberRow('👩‍🎓', 'Sarah K.', 'BSc Mathematics', true, isAdmin: true),
              const SizedBox(height: 10),
              _MemberRow('👨‍💻', 'James M.', 'BSc CS', false),
              const SizedBox(height: 10),
              _MemberRow('👩‍🔬', 'Amara O.', 'BSc Physics', true),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('+ 5 more members',
                    style: TextStyle(fontSize: 12, color: SBColors.brand, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),

          // Sessions
          const SBSectionLabel(title: 'Upcoming Sessions'),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SBColors.border),
            ),
            child: Column(children: [
              _SessionRow('TUE','18','Calculus II – Integration',
                  '4:00 PM · Library Room 3', SBColors.brand, SBColors.brandPale),
              const Divider(color: SBColors.border, height: 1),
              _SessionRow('THU','20','Mock Exam Practice',
                  '4:00 PM · Google Meet', SBColors.green, Color(0xFFEDFAF5)),
            ]),
          ),

          // CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: SBColors.green,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: SBColors.green.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6)),
                  ],
                ),
                child: const Center(
                  child: Text("✅  You're a Member · View Chat",
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  final List<(String, String)> items;
  const _StatsBar(this.items);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SBColors.border)),
    child: Row(
      children: items.indexed.map(((int, (String, String)) e) {
        final (i, (val, lbl)) = e;
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                right: i < items.length - 1
                    ? const BorderSide(color: SBColors.border)
                    : BorderSide.none,
              ),
            ),
            child: Column(children: [
              Text(val,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: SBColors.brand)),
              Text(lbl, style: const TextStyle(fontSize: 9, color: SBColors.text3)),
            ]),
          ),
        );
      }).toList(),
    ),
  );
}

class _MemberRow extends StatelessWidget {
  final String emoji, name, degree;
  final bool isOnline;
  final bool isAdmin;
  const _MemberRow(this.emoji, this.name, this.degree, this.isOnline, {this.isAdmin = false});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [SBColors.brand, SBColors.brandDark]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(name,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
          if (isAdmin) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: SBColors.brandPale, borderRadius: BorderRadius.circular(6)),
              child: const Text('Admin',
                  style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700, color: SBColors.brand)),
            ),
          ],
        ]),
        Text(degree, style: const TextStyle(fontSize: 11, color: SBColors.text3)),
      ]),
    ),
    Text(
      isOnline ? '● Online' : '2h ago',
      style: TextStyle(
          fontSize: 11, color: isOnline ? SBColors.green : SBColors.text3),
    ),
  ]);
}

class _SessionRow extends StatelessWidget {
  final String dayLabel, dateNum, title, subtitle;
  final Color color, bgColor;
  const _SessionRow(
      this.dayLabel, this.dateNum, this.title, this.subtitle, this.color, this.bgColor);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(dayLabel,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
          Text(dateNum,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
          Text(subtitle,
              style: const TextStyle(fontSize: 11, color: SBColors.text3)),
        ]),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────
//  3. Create Group
// ─────────────────────────────────────────────────────────────
class SBCreateGroupScreen extends StatefulWidget {
  const SBCreateGroupScreen({super.key});

  @override
  State<SBCreateGroupScreen> createState() => _SBCreateGroupScreenState();
}

class _SBCreateGroupScreenState extends State<SBCreateGroupScreen> {
  String _privacy = 'Open';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SBColors.surface2,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 18, color: SBColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Study Group',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: SBColors.text)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text('Save',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.brand)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          SBFormField(label: 'Group Name', value: 'MATH201 Study Squad'),
          const SizedBox(height: 12),
          SBFormField(label: 'Course Code', value: 'MATH 201 – Calculus II'),
          const SizedBox(height: 12),
          SBFormField(
            label: 'Description',
            value: 'Focused on Calculus II exam prep. Working through past papers together every week.',
            multiline: true,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: SBFormField(label: 'Max Members', value: '12')),
            const SizedBox(width: 12),
            Expanded(child: SBFormField(label: 'Schedule', value: 'Tue & Thu · 4pm')),
          ]),
          const SizedBox(height: 12),
          SBFormField(label: 'Location', value: '📍 University Library – Room 3'),
          const SizedBox(height: 12),
          // Privacy
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SBColors.border, width: 1.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('GROUP PRIVACY',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: SBColors.text3, letterSpacing: 1)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                SBChip(label: '🔓 Open',
                    active: _privacy == 'Open',
                    onTap: () => setState(() => _privacy = 'Open')),
                SBChip(label: '🔒 Request to Join',
                    active: _privacy == 'Request',
                    onTap: () => setState(() => _privacy = 'Request')),
                SBChip(label: '🔑 Invite Only',
                    active: _privacy == 'Invite',
                    onTap: () => setState(() => _privacy = 'Invite')),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('🚀 Group created successfully!'),
                backgroundColor: SBColors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: SBColors.brand,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: SBColors.brand.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: const Center(
                child: Text('🚀  Create Group',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}
