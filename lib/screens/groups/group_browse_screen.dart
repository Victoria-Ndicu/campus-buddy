import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';

class GroupBrowseScreen extends StatelessWidget {
  const GroupBrowseScreen({super.key});

  static final List<Map<String, dynamic>> _groups = [
    {
      'name': '📐 MATH201 Study Squad',
      'course': 'MATH 201',
      'description': 'Focused on Calculus II exam prep. Working through past papers together every week. All levels welcome!',
      'schedule': 'Tue & Thu, 4pm',
      'location': 'Library Room 3',
      'members': 8,
      'max': 12,
      'isFull': false,
      'online': true,
    },
    {
      'name': '💻 CS301 Algorithm Busters',
      'course': 'CS 301',
      'description': 'Tackling Data Structures & Algorithms together. Weekly coding challenges and peer code reviews.',
      'schedule': 'Wed, 6pm',
      'location': 'Online (Google Meet)',
      'members': 3,
      'max': 10,
      'isFull': false,
      'online': true,
    },
    {
      'name': '⚗️ CHEM102 Lab Prep Group',
      'course': 'CHEM 102',
      'description': 'Pre-lab discussions, theory review and post-lab report writing support. Bring your lab manuals!',
      'schedule': 'Mon, 2pm',
      'location': 'Science Block B4',
      'members': 10,
      'max': 10,
      'isFull': true,
      'online': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: AppBar(
        title: const Text('Study Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.brand),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            SBSearchBar(hint: 'Search groups by course or topic...'),
            SBFilterRow(options: const ['All', 'My Groups', 'Nearby', 'Online', 'Open']),

            // Hero banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3ECF8E), Color(0xFF0D9488)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Join 42 Active Groups', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 4),
                      const Text('Connect with peers studying the same courses right now', style: TextStyle(fontSize: 12, color: Colors.white70)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white40),
                        ),
                        child: const Text('Explore All →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 0, top: 0,
                    child: const Text('📚', style: TextStyle(fontSize: 40)),
                  ),
                ],
              ),
            ),

            SectionLabel(title: 'Recommended for You', actionLabel: 'See all'),
            const SizedBox(height: 4),

            ..._groups.map((g) => _GroupCard(
              group: g,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailScreen(group: g))),
            )),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback? onTap;
  const _GroupCard({required this.group, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isFull = group['isFull'] as bool;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: AppColors.brand.withOpacity(0.07), blurRadius: 12, offset: const Offset(0,4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(group['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.brandPale, borderRadius: BorderRadius.circular(8)),
                  child: Text(group['course'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.brand)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(group['description'], style: const TextStyle(fontSize: 12, color: AppColors.text2, height: 1.5)),
            const SizedBox(height: 10),
            // Meta
            Wrap(
              spacing: 12, runSpacing: 4,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.calendar_today, size: 12, color: AppColors.text3),
                  const SizedBox(width: 4),
                  Text(group['schedule'], style: const TextStyle(fontSize: 11, color: AppColors.text3)),
                ]),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(group['online'] ? Icons.language : Icons.location_on_outlined, size: 12, color: AppColors.text3),
                  const SizedBox(width: 4),
                  Text(group['location'], style: const TextStyle(fontSize: 11, color: AppColors.text3)),
                ]),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Member avatars
                    SizedBox(
                      width: 72,
                      child: Stack(
                        children: List.generate(3, (i) => Positioned(
                          left: i * 18.0,
                          child: Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.brandPale,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Center(child: Text('👤', style: TextStyle(fontSize: 10))),
                          ),
                        )),
                      ),
                    ),
                    Text('${group['members']}/${group['max']} members', style: const TextStyle(fontSize: 11, color: AppColors.text3)),
                  ],
                ),
                isFull
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(color: AppColors.surface3, borderRadius: BorderRadius.circular(10)),
                        child: const Text('Full', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text3)),
                      )
                    : GestureDetector(
                        onTap: onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.brandPale,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.brand, width: 1.5),
                          ),
                          child: const Text('Join', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brand)),
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
