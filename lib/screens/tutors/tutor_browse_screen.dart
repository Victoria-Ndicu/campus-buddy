import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'tutor_profile_screen.dart';
import 'create_tutor_profile_screen.dart';

class TutorBrowseScreen extends StatelessWidget {
  const TutorBrowseScreen({super.key});

  static final List<Map<String, dynamic>> _tutors = [
    {
      'name': 'Sarah K.',
      'degree': 'BSc Mathematics · Univ of Nairobi',
      'tags': ['Calculus', 'Statistics', 'Linear Algebra'],
      'rate': '\$25/hr',
      'rating': '4.9',
      'reviews': '128',
      'online': true,
      'emoji': '👩‍🎓',
      'gradient': [Color(0xFF667EEA), Color(0xFF764BA2)],
    },
    {
      'name': 'James M.',
      'degree': 'MSc Computer Science · KU',
      'tags': ['Algorithms', 'Python', 'ML'],
      'rate': '\$35/hr',
      'rating': '4.8',
      'reviews': '87',
      'online': true,
      'emoji': '👨‍💻',
      'gradient': [Color(0xFF3ECF8E), Color(0xFF0D9488)],
    },
    {
      'name': 'Amara O.',
      'degree': 'PhD Chemistry · Strathmore',
      'tags': ['Organic Chem', 'Lab Skills'],
      'rate': '\$40/hr',
      'rating': '4.7',
      'reviews': '54',
      'online': false,
      'emoji': '👩‍🔬',
      'gradient': [Color(0xFFF5A623), Color(0xFFE67E22)],
    },
    {
      'name': 'David L.',
      'degree': 'BA Economics · USIU',
      'tags': ['Micro', 'Macro', 'Finance'],
      'rate': '\$20/hr',
      'rating': '4.6',
      'reviews': '42',
      'online': true,
      'emoji': '👨‍🏫',
      'gradient': [Color(0xFFFF6B6B), Color(0xFFC0392B)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: AppBar(
        title: const Text('Find a Tutor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          SBSearchBar(hint: 'Search by subject, name...'),
          SBFilterRow(options: const [
            'All Subjects', 'Maths', 'Physics', 'CS', 'Economics', 'Chemistry'
          ]),
          _FilterBar(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('24 tutors found',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                TextButton(onPressed: () {}, child: const Text('Sort ↕', style: TextStyle(fontSize: 12, color: AppColors.brand))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: _tutors.length,
              itemBuilder: (context, i) => _TutorCard(tutor: _tutors[i]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTutorProfileScreen())),
        backgroundColor: AppColors.brand,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Become a Tutor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _FilterBox(icon: Icons.attach_money, title: 'Price Range', value: '\$10 – \$50/hr')),
          const SizedBox(width: 8),
          Expanded(child: _FilterBox(icon: Icons.star_outline, title: 'Min Rating', value: '4.0 & above')),
          const SizedBox(width: 8),
          _FilterBox(icon: Icons.calendar_today_outlined, title: '', value: ''),
        ],
      ),
    );
  }
}

class _FilterBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _FilterBox({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [BoxShadow(color: AppColors.brand.withOpacity(0.06), blurRadius: 8, offset: const Offset(0,2))],
      ),
      child: title.isEmpty
          ? Icon(icon, color: AppColors.text2, size: 18)
          : Row(
              children: [
                Icon(icon, size: 16, color: AppColors.text2),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 9, color: AppColors.text3)),
                    Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text)),
                  ],
                ),
              ],
            ),
    );
  }
}

class _TutorCard extends StatelessWidget {
  final Map<String, dynamic> tutor;
  const _TutorCard({required this.tutor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TutorProfileScreen(tutor: tutor))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: AppColors.brand.withOpacity(0.07), blurRadius: 12, offset: const Offset(0,4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: tutor['gradient'] as List<Color>,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(child: Text(tutor['emoji'], style: const TextStyle(fontSize: 26))),
                ),
                if (tutor['online'] == true)
                  Positioned(
                    bottom: 2, right: 2,
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tutor['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                  const SizedBox(height: 2),
                  Text(tutor['degree'], style: const TextStyle(fontSize: 11, color: AppColors.text2)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 5, runSpacing: 5,
                    children: (tutor['tags'] as List<String>).map((t) => TagChip(label: t)).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tutor['rate'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.brand)),
                          Text('⭐ ${tutor['rating']} (${tutor['reviews']} reviews)', style: const TextStyle(fontSize: 11, color: AppColors.accent)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TutorProfileScreen(tutor: tutor))),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.brand,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Book', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
