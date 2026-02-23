import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class TutorProfileScreen extends StatelessWidget {
  final Map<String, dynamic> tutor;
  const TutorProfileScreen({super.key, required this.tutor});

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const available = [false, true, true, false, true, true, false];

    return Scaffold(
      backgroundColor: AppColors.surface2,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero ──────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [AppColors.brand, AppColors.brandDark],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white30, width: 2),
                            ),
                            child: Center(child: Text(tutor['emoji'], style: const TextStyle(fontSize: 32))),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tutor['name'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                                const SizedBox(height: 3),
                                Text(tutor['degree'], style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Text('★★★★★', style: TextStyle(color: Color(0xFFF5A623), fontSize: 13)),
                                    const SizedBox(width: 6),
                                    Text('${tutor['rating']} · ${tutor['reviews']} reviews',
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: ['💬 Message', '🤝 Follow', '↗ Share'].map((a) => Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white15,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: Text(a, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // ── Stats ─────────────────────────────────────────
            StatsRow(stats: const [
              {'value': '128', 'label': 'Reviews'},
              {'value': '240', 'label': 'Sessions'},
              {'value': '98%', 'label': 'Response'},
            ]),

            // ── Subjects ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SUBJECTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.text3, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: (tutor['tags'] as List<String>)
                        .map((t) => TagChip(label: t))
                        .toList(),
                  ),
                ],
              ),
            ),

            // ── Rate & Qualifications ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RATE & QUALIFICATIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.text3, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  GridView.count(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2, childAspectRatio: 2.8, crossAxisSpacing: 8, mainAxisSpacing: 8,
                    children: [
                      InfoBox(label: 'Hourly Rate', value: tutor['rate']),
                      const InfoBox(label: 'Degree', value: 'BSc Math, UoN'),
                      const InfoBox(label: 'Level', value: 'Undergrad & A-Level'),
                      const InfoBox(label: 'Mode', value: 'Online & In-person'),
                    ],
                  ),
                ],
              ),
            ),

            // ── Availability ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AVAILABILITY THIS WEEK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.text3, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) => Column(
                      children: [
                        Text(days[i].substring(0, 1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: available[i] ? AppColors.brand : AppColors.text3)),
                        const SizedBox(height: 4),
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: available[i] ? AppColors.brand : AppColors.surface3,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              available[i] ? '✓' : '–',
                              style: TextStyle(fontSize: 12, color: available[i] ? Colors.white : AppColors.text3, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    )),
                  ),
                ],
              ),
            ),

            // ── About ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ABOUT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.text3, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  const Text(
                    'Final year BSc Mathematics student with passion for making complex concepts simple. Specialise in Calculus, Statistics and Linear Algebra for university and A-Level students.',
                    style: TextStyle(fontSize: 13, color: AppColors.text2, height: 1.6),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            SBPrimaryButton(label: '📅 Book a Session', icon: null, onTap: () {}),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
