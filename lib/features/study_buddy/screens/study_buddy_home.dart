// ============================================================
//  StudyBuddy — study_buddy_home.dart
//
//  Landing screen for the StudyBuddy module.
//  Registered in main.dart as:
//    '/study-buddy': (_) => const StudyBuddyHome(),
//
//  Tapping any module card pushes directly to that sub-screen.
//  Bottom nav is owned by the parent CampusBuddy shell; this
//  screen has no bottom nav of its own.
// ============================================================

import 'package:flutter/material.dart';
import '../models/sb_constants.dart';
import '../widgets/sb_widgets.dart';
import 'sb_tutors_screen.dart';
import 'sb_groups_screen.dart';
import 'sb_resources_screen.dart';
import 'sb_help_screen.dart';

class StudyBuddyHome extends StatelessWidget {
  const StudyBuddyHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SBColors.surface2,
      body: CustomScrollView(
        slivers: [
          // ── Gradient app-bar ──────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: SBColors.brand,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [SBColors.brand, SBColors.brandDark],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'ACADEMIC SUPPORT',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                                      color: Colors.white, letterSpacing: 1.5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'StudyBuddy',
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tutors · Groups · Resources · Help',
                                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                              ),
                            ],
                          ),
                        ),
                        const Text('📚', style: TextStyle(fontSize: 52)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Quick stats strip ─────────────────────────────
          SliverToBoxAdapter(child: _StatsStrip()),

          // ── Module cards grid ─────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
            sliver: SliverToBoxAdapter(
              child: const Text(
                'Academic Modules',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: SBColors.text),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate([
                _ModuleCard(
                  emoji: '👩‍🏫',
                  title: 'Find Tutors',
                  subtitle: '24 tutors available',
                  gradient: const [Color(0xFF667EEA), Color(0xFF4A5FCC)],
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SBTutorsScreen())),
                ),
                _ModuleCard(
                  emoji: '👥',
                  title: 'Study Groups',
                  subtitle: '42 active groups',
                  gradient: const [Color(0xFF3ECF8E), Color(0xFF0D9488)],
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SBGroupsScreen())),
                ),
                _ModuleCard(
                  emoji: '📁',
                  title: 'Resources',
                  subtitle: '150+ study materials',
                  gradient: const [Color(0xFFF5A623), Color(0xFFE67E22)],
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SBResourcesScreen())),
                ),
                _ModuleCard(
                  emoji: '❓',
                  title: 'Ask for Help',
                  subtitle: 'Get answers fast',
                  gradient: const [Color(0xFFFF6B6B), Color(0xFFC0392B)],
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SBHelpScreen())),
                ),
              ]),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
            ),
          ),

          // ── Upcoming sessions ─────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: SBSectionLabel(title: 'Upcoming Sessions', action: 'See all'),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _UpcomingCard(
                emoji: '📅',
                title: 'Calculus II – Integration',
                subtitle: 'With Sarah K. · Tue, 4:00 PM',
                color: SBColors.brand,
                tag: 'Today',
              ),
              _UpcomingCard(
                emoji: '👥',
                title: 'MATH201 Study Squad',
                subtitle: 'Library Room 3 · Thu, 4:00 PM',
                color: SBColors.green,
                tag: 'Group',
              ),
              const SizedBox(height: 28),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Stats strip
// ─────────────────────────────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SBColors.border),
      ),
      child: Row(
        children: [
          _Stat('3', 'Sessions\nBooked', '📅'),
          _Vline(),
          _Stat('2', 'My\nGroups', '👥'),
          _Vline(),
          _Stat('5', 'Saved\nFiles', '📌'),
          _Vline(),
          _Stat('1', 'Open\nQuestions', '💬'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label, emoji;
  const _Stat(this.value, this.label, this.emoji);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: SBColors.brand)),
      Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 9, color: SBColors.text3, height: 1.35)),
    ]),
  );
}

class _Vline extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: SBColors.border);
}

// ─────────────────────────────────────────────────────────────
//  Module card
// ─────────────────────────────────────────────────────────────
class _ModuleCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.32),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
            ],
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  Upcoming session row
// ─────────────────────────────────────────────────────────────
class _UpcomingCard extends StatelessWidget {
  final String emoji, title, subtitle, tag;
  final Color color;
  const _UpcomingCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: SBColors.border),
    ),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
          const SizedBox(height: 3),
          Text(subtitle,
              style: const TextStyle(fontSize: 11, color: SBColors.text3)),
        ]),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(tag,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      ),
    ]),
  );
}
