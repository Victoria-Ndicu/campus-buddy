// ============================================================
//  StudyBuddy — sb_tutors_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import '../models/sb_constants.dart';
import '../widgets/sb_widgets.dart';

// ─────────────────────────────────────────────────────────────
//  1. Browse Tutors
// ─────────────────────────────────────────────────────────────
class SBTutorsScreen extends StatefulWidget {
  const SBTutorsScreen({super.key});

  @override
  State<SBTutorsScreen> createState() => _SBTutorsScreenState();
}

class _SBTutorsScreenState extends State<SBTutorsScreen> {
  int _filter = 0;
  final _filters = ['All Subjects', 'Maths', 'Physics', 'CS', 'Economics', 'Chemistry'];

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
        title: const Text('Find a Tutor',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: SBColors.text)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 36, height: 36,
            decoration: BoxDecoration(color: SBColors.brand, borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Text('⚙️', style: TextStyle(fontSize: 16))),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SBSearchBar(hint: 'Search by subject, name...')),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(children: [
                _FilterPill('💰', 'Price Range', '\$10 – \$50/hr'),
                const SizedBox(width: 8),
                _FilterPill('⭐', 'Min Rating', '4.0 & above'),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SBColors.border, width: 1.5),
                  ),
                  child: const Text('📅', style: TextStyle(fontSize: 14)),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SBSectionLabel(title: '24 tutors found', action: 'Sort ↕'),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _TutorCard(
                emoji: '👩‍🎓',
                gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                name: 'Sarah K.',
                subject: 'BSc Mathematics · Univ of Nairobi',
                tags: const ['Calculus', 'Statistics', 'Linear Algebra'],
                rate: '\$25/hr',
                rating: '⭐ 4.9  (128 reviews)',
                isOnline: true,
                onViewProfile: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SBTutorProfileScreen())),
                onBook: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SBBookingScreen())),
              ),
              _TutorCard(
                emoji: '👨‍💻',
                gradient: const [Color(0xFF3ECF8E), Color(0xFF0D9488)],
                name: 'James M.',
                subject: 'MSc Computer Science · KU',
                tags: const ['Algorithms', 'Python', 'ML'],
                rate: '\$35/hr',
                rating: '⭐ 4.8  (87 reviews)',
                isOnline: true,
                onViewProfile: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SBTutorProfileScreen(
                      name: 'James Mwangi',
                      subject: 'CS Tutor · 2 yrs experience',
                      emoji: '👨‍💻',
                    ))),
                onBook: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SBBookingScreen())),
              ),
              _TutorCard(
                emoji: '👩‍🔬',
                gradient: const [Color(0xFFF5A623), Color(0xFFE67E22)],
                name: 'Amara O.',
                subject: 'PhD Chemistry · Strathmore',
                tags: const ['Organic Chem', 'Lab Skills'],
                rate: '\$40/hr',
                rating: '⭐ 4.7  (54 reviews)',
                isOnline: false,
                onViewProfile: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SBTutorProfileScreen(
                      name: 'Amara Osei',
                      subject: 'Chemistry Tutor · 4 yrs experience',
                      emoji: '👩‍🔬',
                    ))),
                onBook: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SBBookingScreen())),
              ),
              _TutorCard(
                emoji: '👨‍🏫',
                gradient: const [Color(0xFFFF6B6B), Color(0xFFC0392B)],
                name: 'David L.',
                subject: 'BA Economics · USIU',
                tags: const ['Micro', 'Macro', 'Finance'],
                rate: '\$20/hr',
                rating: '⭐ 4.6  (42 reviews)',
                isOnline: true,
                onViewProfile: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SBTutorProfileScreen(
                      name: 'David Lukwago',
                      subject: 'Economics Tutor · 1 yr experience',
                      emoji: '👨‍🏫',
                    ))),
                onBook: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SBBookingScreen())),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String icon, label, value;
  const _FilterPill(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SBColors.border, width: 1.5),
      ),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 9, color: SBColors.text3)),
            Text(value,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SBColors.text)),
          ]),
        ),
      ]),
    ),
  );
}

class _TutorCard extends StatelessWidget {
  final String emoji, name, subject, rate, rating;
  final List<Color> gradient;
  final List<String> tags;
  final bool isOnline;
  final VoidCallback onViewProfile, onBook;

  const _TutorCard({
    required this.emoji,
    required this.gradient,
    required this.name,
    required this.subject,
    required this.tags,
    required this.rate,
    required this.rating,
    required this.isOnline,
    required this.onViewProfile,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onViewProfile,
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: SBTheme.card,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          if (isOnline)
            Positioned(
              bottom: 2, right: 2,
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: SBColors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SBColors.text)),
            const SizedBox(height: 2),
            Text(subject,
                style: const TextStyle(fontSize: 11, color: SBColors.text2)),
            const SizedBox(height: 6),
            // FIX: use explicit lambda instead of SBTag.new
            Wrap(spacing: 5, runSpacing: 5,
                children: tags.map<Widget>((t) => SBTag(t)).toList()),
            const SizedBox(height: 8),
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(rate,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SBColors.brand)),
                Text(rating,
                    style: const TextStyle(fontSize: 11, color: SBColors.accent)),
              ]),
              const Spacer(),
              GestureDetector(
                onTap: onBook,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: SBColors.brand,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Book',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  2. Tutor Profile
// ─────────────────────────────────────────────────────────────
class SBTutorProfileScreen extends StatelessWidget {
  final String name;
  final String subject;
  final String emoji;

  const SBTutorProfileScreen({
    super.key,
    this.name    = 'Sarah Kamau',
    this.subject = 'Mathematics Tutor · 3 yrs experience',
    this.emoji   = '👩‍🎓',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SBColors.surface2,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [SBColors.brand, SBColors.brandDark],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(children: [
                    Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                        ),
                        child: Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 30)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(subject,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.white.withOpacity(0.75))),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Text('★★★★★',
                                style: TextStyle(color: SBColors.accent, fontSize: 13)),
                            const SizedBox(width: 6),
                            const Text('4.9 · 128 reviews',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      _ActionBtn('💬', 'Message'),
                      const SizedBox(width: 8),
                      _ActionBtn('🤝', 'Follow'),
                      const SizedBox(width: 8),
                      _ActionBtn('↗', 'Share'),
                    ]),
                  ]),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _StatsRow(const [
              ('128', 'Reviews'), ('240', 'Sessions'), ('98%', 'Response'),
            ]),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                _ProfileSection(
                  label: 'Subjects',
                  child: Wrap(
                    spacing: 6, runSpacing: 6,
                    // FIX: explicit lambda instead of SBTag.new
                    children: ['Calculus', 'Statistics', 'Linear Algebra',
                      'Discrete Math', 'Probability']
                        .map<Widget>((t) => SBTag(t)).toList(),
                  ),
                ),
                _ProfileSection(
                  label: 'Rate & Qualifications',
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.8,
                    children: const [
                      _InfoBox('Hourly Rate', '\$25/hr'),
                      _InfoBox('Degree',      'BSc Math, UoN'),
                      _InfoBox('Level',       'Undergrad & A-Level'),
                      _InfoBox('Mode',        'Online & In-person'),
                    ],
                  ),
                ),
                _ProfileSection(
                  label: 'Availability This Week',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      _AvailChip('Mon', false),
                      _AvailChip('Tue', true),
                      _AvailChip('Wed', true),
                      _AvailChip('Thu', false),
                      _AvailChip('Fri', true),
                      _AvailChip('Sat', true),
                      _AvailChip('Sun', false),
                    ],
                  ),
                ),
                _ProfileSection(
                  label: 'About',
                  child: const Text(
                    'Final year BSc Mathematics student with a passion for making '
                    'complex concepts simple. Specialise in Calculus, Statistics '
                    'and Linear Algebra for university and A-Level students.',
                    style: TextStyle(fontSize: 13, color: SBColors.text2, height: 1.6),
                  ),
                ),
                const SizedBox(height: 8),
              ]),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SBPrimaryButton(
                label: '📅  Book a Session',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SBBookingScreen())),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String icon, label;
  const _ActionBtn(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Center(
        child: Text('$icon  $label',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    ),
  );
}

class _StatsRow extends StatelessWidget {
  final List<(String, String)> items;
  const _StatsRow(this.items);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: SBColors.border),
    ),
    child: Row(
      children: items.indexed.map(((int, (String, String)) e) {
        final (i, (val, lbl)) = e;
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
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
                      fontSize: 18, fontWeight: FontWeight.w700, color: SBColors.brand)),
              const SizedBox(height: 2),
              Text(lbl,
                  style: const TextStyle(fontSize: 10, color: SBColors.text3)),
            ]),
          ),
        );
      }).toList(),
    ),
  );
}

class _ProfileSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _ProfileSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(),
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: SBColors.text3, letterSpacing: 1)),
      const SizedBox(height: 8),
      child,
    ]),
  );
}

class _InfoBox extends StatelessWidget {
  final String label, value;
  const _InfoBox(this.label, this.value);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: SBColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: SBColors.text3)),
        Text(value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: SBColors.text)),
      ],
    ),
  );
}

class _AvailChip extends StatelessWidget {
  final String day;
  final bool available;
  const _AvailChip(this.day, this.available);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: available ? SBColors.green.withOpacity(0.1) : SBColors.surface3,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(day,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: available ? SBColors.green : SBColors.text3)),
  );
}

// ─────────────────────────────────────────────────────────────
//  3. Booking Screen
// ─────────────────────────────────────────────────────────────
class SBBookingScreen extends StatefulWidget {
  const SBBookingScreen({super.key});

  @override
  State<SBBookingScreen> createState() => _SBBookingScreenState();
}

class _SBBookingScreenState extends State<SBBookingScreen> {
  int    _selDay  = 1;
  int    _selTime = 2;
  String _mode    = 'Online';

  static const _days  = ['Mon\n14', 'Tue\n15', 'Wed\n16', 'Thu\n17', 'Fri\n18', 'Sat\n19'];
  static const _times = ['9:00 AM', '10:00 AM', '11:00 AM', '2:00 PM', '3:00 PM', '4:00 PM'];

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
        title: const Text('Book a Session',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: SBColors.text)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: SBTheme.card,
            child: Row(children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [SBColors.brand, SBColors.brandDark]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: Text('👩‍🎓', style: TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Sarah Kamau',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SBColors.text)),
                Text('Mathematics Tutor',
                    style: TextStyle(fontSize: 11, color: SBColors.text2)),
                SizedBox(height: 4),
                Text('\$25/hr  ·  ⭐ 4.9',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SBColors.brand)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          const _BookLabel('SELECT DATE'),
          const SizedBox(height: 10),
          SizedBox(
            height: 68,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => setState(() => _selDay = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 56,
                  decoration: BoxDecoration(
                    color: _selDay == i ? SBColors.brand : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _selDay == i ? SBColors.brand : SBColors.border, width: 1.5),
                  ),
                  child: Center(
                    child: Text(_days[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: _selDay == i ? Colors.white : SBColors.text2,
                            height: 1.5)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const _BookLabel('SELECT TIME'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: List.generate(_times.length, (i) => GestureDetector(
              onTap: () => setState(() => _selTime = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _selTime == i ? SBColors.brand : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _selTime == i ? SBColors.brand : SBColors.border, width: 1.5),
                ),
                child: Text(_times[i],
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: _selTime == i ? Colors.white : SBColors.text2)),
              ),
            )),
          ),
          const SizedBox(height: 20),

          const _BookLabel('SESSION MODE'),
          const SizedBox(height: 10),
          Row(
            children: ['Online', 'In-person'].map((m) => Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _mode = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _mode == m ? SBColors.brand : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _mode == m ? SBColors.brand : SBColors.border, width: 1.5),
                  ),
                  child: Center(
                    child: Text(m,
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: _mode == m ? Colors.white : SBColors.text2)),
                  ),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: SBColors.brandPale, borderRadius: BorderRadius.circular(14)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Session Total',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
                Text('\$25.00',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: SBColors.brand)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                content: const Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('🎉', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('Session Booked!',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700, color: SBColors.text)),
                  SizedBox(height: 8),
                  Text('Your session with Sarah Kamau has been confirmed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: SBColors.text2)),
                ]),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('Done',
                        style: TextStyle(color: SBColors.brand, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
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
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Text('✅  Confirm Booking',
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

class _BookLabel extends StatelessWidget {
  final String text;
  const _BookLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
        fontSize: 10, fontWeight: FontWeight.w700,
        color: SBColors.text3, letterSpacing: 1),
  );
}