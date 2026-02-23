import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class GroupDetailScreen extends StatelessWidget {
  final Map<String, dynamic> group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: AppBar(
        title: Text(group['name'], overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: [
            // Group hero
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brand, AppColors.brandDark],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group['course'], style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  Text(group['name'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(group['description'], style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.5)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MetaPill(icon: Icons.calendar_today, text: group['schedule']),
                      const SizedBox(width: 12),
                      _MetaPill(icon: Icons.location_on_outlined, text: group['location']),
                    ],
                  ),
                ],
              ),
            ),

            StatsRow(stats: const [
              {'value': '8', 'label': 'Members'},
              {'value': '12', 'label': 'Max'},
              {'value': '24', 'label': 'Sessions'},
              {'value': '18', 'label': 'Files'},
            ]),

            SectionLabel(title: 'Members (8)', actionLabel: 'Invite +'),
            const SizedBox(height: 4),

            _MemberTile(emoji: '👩‍🎓', name: 'Sarah K.', sub: 'BSc Mathematics', isAdmin: true, online: true,
                gradient: const [Color(0xFF667EEA), Color(0xFF4A5FCC)]),
            _MemberTile(emoji: '👨‍💻', name: 'James M.', sub: 'BSc CS', isAdmin: false, online: false,
                lastSeen: '2h ago', gradient: const [Color(0xFF3ECF8E), Color(0xFF0D9488)]),
            _MemberTile(emoji: '👩‍🔬', name: 'Amara O.', sub: 'BSc Physics', isAdmin: false, online: true,
                gradient: const [Color(0xFFF5A623), Color(0xFFE67E22)]),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: GestureDetector(
                onTap: () {},
                child: const Text('+ 5 more members', style: TextStyle(fontSize: 12, color: AppColors.brand, fontWeight: FontWeight.w600)),
              ),
            ),

            const SizedBox(height: 12),
            SectionLabel(title: 'Upcoming Sessions'),
            _UpcomingSessionCard(),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppColors.green.withOpacity(0.3), blurRadius: 20, offset: const Offset(0,6))],
                  ),
                  child: const Text('✅ You\'re a Member · View Chat',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.white70),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final String emoji, name, sub;
  final bool isAdmin, online;
  final String? lastSeen;
  final List<Color> gradient;

  const _MemberTile({
    required this.emoji, required this.name, required this.sub,
    required this.isAdmin, required this.online, this.lastSeen,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                    if (isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.brandPale, borderRadius: BorderRadius.circular(6)),
                        child: const Text('Admin', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.brand)),
                      ),
                    ],
                  ],
                ),
                Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.text3)),
              ],
            ),
          ),
          online
              ? const Text('● Online', style: TextStyle(fontSize: 11, color: AppColors.green))
              : Text(lastSeen ?? '', style: const TextStyle(fontSize: 11, color: AppColors.text3)),
        ],
      ),
    );
  }
}

class _UpcomingSessionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _SessionRow(dayAbbr: 'TUE', dayNum: '18', title: 'Calculus II – Integration', time: '4:00 PM · Library Room 3', color: AppColors.brand, bgColor: AppColors.brandPale),
          const Divider(height: 1, color: AppColors.border),
          _SessionRow(dayAbbr: 'THU', dayNum: '20', title: 'Mock Exam Practice', time: '4:00 PM · Google Meet', color: AppColors.green, bgColor: Color(0xFFEDFAF5)),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final String dayAbbr, dayNum, title, time;
  final Color color, bgColor;
  const _SessionRow({required this.dayAbbr, required this.dayNum, required this.title, required this.time, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(dayAbbr, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
              Text(dayNum, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            ]),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
            const SizedBox(height: 2),
            Text(time, style: const TextStyle(fontSize: 11, color: AppColors.text3)),
          ]),
        ],
      ),
    );
  }
}
