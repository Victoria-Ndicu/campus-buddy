// ============================================================
//  StudyBuddy — sb_help_screen.dart
//
//  Screen stack:
//    SBHelpScreen
//      ├─ SBAnswerThreadScreen   (tap Q&A card)
//      └─ SBAskQuestionScreen    (tap FAB)
// ============================================================

import 'package:flutter/material.dart';
import '../models/sb_constants.dart';
import '../widgets/sb_widgets.dart';

// ─────────────────────────────────────────────────────────────
//  1. Q&A Feed
// ─────────────────────────────────────────────────────────────
class SBHelpScreen extends StatefulWidget {
  const SBHelpScreen({super.key});

  @override
  State<SBHelpScreen> createState() => _SBHelpScreenState();
}

class _SBHelpScreenState extends State<SBHelpScreen> {
  int _filter = 0;
  final _filters = ['All', 'Unanswered', 'MATH', 'CS', 'CHEM'];

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
        title: const Text('Academic Help',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: SBColors.text)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SBAskQuestionScreen())),
        backgroundColor: SBColors.brand,
        icon: const Text('🙋', style: TextStyle(fontSize: 18)),
        label: const Text('Ask Question',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SBSearchBar(hint: 'Search questions...')),
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
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverList(
            delegate: SliverChildListDelegate([
              _QACard(
                emoji: '👩‍🎓', user: 'Priya N.', time: '15 min ago', course: 'MATH 201',
                question: "Can someone explain how to apply L'Hôpital's Rule when dealing with indeterminate forms like ∞/∞?",
                tags: const ['Calculus', 'Limits'],
                urgency: '⏰ Urgent', urgencyColor: SBColors.accent,
                urgencyBg: Color(0xFFFFF4E6),
                votes: 12, answerCount: 3, answered: true,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SBAnswerThreadScreen())),
              ),
              _QACard(
                emoji: '👨‍💻', user: 'Kevin O.', time: '1h ago', course: 'CS 301',
                question: "What is the time complexity of Dijkstra's algorithm with a min-heap implementation?",
                tags: const ['Algorithms', 'Graphs'],
                urgency: '😊 Not Urgent', urgencyColor: SBColors.green,
                urgencyBg: Color(0xFFEDFAF5),
                votes: 8, answerCount: 1, answered: true,
                onTap: () {},
              ),
              _QACard(
                emoji: '👩‍🔬', user: 'Fatima A.', time: '2h ago', course: 'CHEM 202',
                question: 'How do I predict the product of an E2 elimination reaction?',
                tags: const ['Organic Chem', 'Reactions'],
                urgency: '🔥 Urgent', urgencyColor: SBColors.accent2,
                urgencyBg: Color(0xFFFFF0F0),
                votes: 5, answerCount: 0, answered: false,
                onTap: () {},
              ),
              const SizedBox(height: 80),
            ]),
          ),
        ],
      ),
    );
  }
}

class _QACard extends StatelessWidget {
  final String emoji, user, time, course, question, urgency;
  final List<String> tags;
  final Color urgencyColor, urgencyBg;
  final int votes, answerCount;
  final bool answered;
  final VoidCallback onTap;

  const _QACard({
    required this.emoji, required this.user, required this.time,
    required this.course, required this.question, required this.tags,
    required this.urgency, required this.urgencyColor, required this.urgencyBg,
    required this.votes, required this.answerCount, required this.answered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: SBTheme.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(
                color: SBColors.brandPale, shape: BoxShape.circle),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: SBColors.text)),
              Text('$time · $course',
                  style: const TextStyle(fontSize: 10, color: SBColors.text3)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: urgencyBg, borderRadius: BorderRadius.circular(8)),
            child: Text(urgency,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: urgencyColor)),
          ),
        ]),
        const SizedBox(height: 10),
        Text(question,
            style: const TextStyle(
                fontSize: 13, color: SBColors.text, height: 1.5, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(spacing: 5, runSpacing: 5, children: tags.map((t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: const Color(0xFFFFF4E6), borderRadius: BorderRadius.circular(8)),
          child: Text(t,
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: SBColors.accent)),
        )).toList()),
        const SizedBox(height: 10),
        const Divider(color: SBColors.border, height: 1),
        const SizedBox(height: 10),
        Row(children: [
          const Text('👍', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text('$votes',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: SBColors.text2)),
          const SizedBox(width: 14),
          const Text('💬', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text('$answerCount',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: SBColors.text2)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: answered
                  ? SBColors.green.withOpacity(0.1)
                  : SBColors.accent2.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              answered ? '✓ Answered' : 'Unanswered',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: answered ? SBColors.green : SBColors.accent2),
            ),
          ),
        ]),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  2. Ask Question
// ─────────────────────────────────────────────────────────────
class SBAskQuestionScreen extends StatefulWidget {
  const SBAskQuestionScreen({super.key});

  @override
  State<SBAskQuestionScreen> createState() => _SBAskQuestionScreenState();
}

class _SBAskQuestionScreenState extends State<SBAskQuestionScreen> {
  String _urgency = 'Need Soon';
  String _helpVia = 'Written Answer';

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
        title: const Text('Ask for Help',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: SBColors.text)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text('Post',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.brand)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            'Be specific and clear – better questions get better answers! 💡',
            style: TextStyle(fontSize: 12, color: SBColors.text2),
          ),
          const SizedBox(height: 14),
          SBFormField(
            label: 'Your Question',
            value: "Can someone explain how to apply L'Hôpital's Rule when dealing "
                "with indeterminate forms like ∞/∞? I keep getting confused about "
                "when it's valid to apply it.",
            multiline: true,
            active: true,
          ),
          const SizedBox(height: 12),
          SBFormField(label: 'Course Code', value: 'MATH 201 – Calculus II'),
          const SizedBox(height: 12),

          // Tags
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SBColors.border, width: 1.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('TOPIC / TAGS',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: SBColors.text3, letterSpacing: 1)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                SBChip(label: 'Calculus ✕', active: true),
                SBChip(label: 'Limits ✕', active: true),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: SBColors.border, width: 1.5),
                  ),
                  child: const Text('+ Add tag',
                      style: TextStyle(
                          fontSize: 12, color: SBColors.text3, fontWeight: FontWeight.w600)),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 12),

          // Attach
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SBColors.border, width: 1.5),
            ),
            child: Row(children: [
              const Text('📎', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('Attach a file (optional)',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
                  Text('Add a photo, PDF or document to clarify your question',
                      style: TextStyle(fontSize: 11, color: SBColors.text3)),
                ]),
              ),
              const Text('Upload',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: SBColors.brand)),
            ]),
          ),
          const SizedBox(height: 12),

          // Urgency
          _PickerField(
            label: 'URGENCY',
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              _UrgencyChip('😊 Not Urgent', 'Not Urgent', SBColors.green,
                  const Color(0xFFEDFAF5), _urgency, (v) => setState(() => _urgency = v)),
              _UrgencyChip('⏰ Need Soon', 'Need Soon', SBColors.accent,
                  const Color(0xFFFFF4E6), _urgency, (v) => setState(() => _urgency = v)),
              _UrgencyChip('🔥 Urgent', 'Urgent', SBColors.accent2,
                  const Color(0xFFFFF0F0), _urgency, (v) => setState(() => _urgency = v)),
            ]),
          ),
          const SizedBox(height: 12),

          // Help via — FIX: typed as List<Widget> to avoid List<dynamic> error
          _PickerField(
            label: 'PREFER HELP VIA',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <String>[
                '💬 Written Answer',
                '🎥 Video Call',
                '📚 Resource Link',
              ].map<Widget>((opt) {
                final key = opt.split(' ').sublist(1).join(' ');
                return SBChip(
                  label: opt,
                  active: _helpVia == key,
                  onTap: () => setState(() => _helpVia = key),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('🙋  Your question has been posted!'),
                backgroundColor: SBColors.brand,
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
                child: Text('🙋  Post Question',
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

class _PickerField extends StatelessWidget {
  final String label;
  final Widget child;
  const _PickerField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: SBColors.border, width: 1.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: SBColors.text3, letterSpacing: 1)),
      const SizedBox(height: 8),
      child,
    ]),
  );
}

class _UrgencyChip extends StatelessWidget {
  final String label, value;
  final Color color, bgColor;
  final String current;
  final Function(String) onTap;

  const _UrgencyChip(
      this.label, this.value, this.color, this.bgColor, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final on = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: on ? bgColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? color : SBColors.border, width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: on ? color : SBColors.text2)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  3. Answer Thread
// ─────────────────────────────────────────────────────────────
class SBAnswerThreadScreen extends StatelessWidget {
  const SBAnswerThreadScreen({super.key});

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
        title: const Text('Question Thread',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: SBColors.text)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Text('⋯', style: TextStyle(fontSize: 22, color: SBColors.text2)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Question card (gradient)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: SBTheme.brandGradient(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Center(child: Text('👩‍🎓', style: TextStyle(fontSize: 14))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Priya N.',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                    Text('15 minutes ago · MATH 201',
                        style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.75))),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('⏰ Urgent',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ]),
              const SizedBox(height: 10),
              const Text(
                "Can someone explain how to apply L'Hôpital's Rule when dealing with indeterminate forms like ∞/∞?",
                style: TextStyle(fontSize: 13, color: Colors.white, height: 1.5),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 6, children: ['Calculus', 'Limits'].map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(t,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
              )).toList()),
            ]),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text('💬  3 Answers',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SBColors.text2)),
          ),

          // Best answer
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: SBColors.green, width: 2),
              boxShadow: [
                BoxShadow(
                    color: SBColors.green.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [SBColors.brand, SBColors.brandDark]),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Center(child: Text('👨‍🏫', style: TextStyle(fontSize: 16))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Text('James M. ',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: SBColors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('✓ Best Answer',
                            style: TextStyle(
                                fontSize: 9, fontWeight: FontWeight.w700, color: SBColors.green)),
                      ),
                    ]),
                    const Text('30 mins ago · Tutor · Math Specialist',
                        style: TextStyle(fontSize: 10, color: SBColors.text3)),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              const Text(
                "L'Hôpital's Rule is valid when you have an indeterminate form (0/0 or ±∞/∞). "
                "First verify you have one of these forms, then differentiate numerator and "
                "denominator separately (not as a quotient!), then take the limit again. "
                "Repeat if still indeterminate.",
                style: TextStyle(fontSize: 13, color: SBColors.text, height: 1.6),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SBColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(left: BorderSide(color: SBColors.brand, width: 3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('📌  Key condition:',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700, color: SBColors.brand)),
                  SizedBox(height: 4),
                  Text("Both f and g must be differentiable near the point, and g'(x) ≠ 0 near that point.",
                      style: TextStyle(fontSize: 12, color: SBColors.text2)),
                ]),
              ),
              const SizedBox(height: 10),
              const Divider(color: SBColors.border, height: 1),
              const SizedBox(height: 10),
              const Row(children: [
                Text('👍', style: TextStyle(fontSize: 14)),
                SizedBox(width: 4),
                Text('24',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: SBColors.brand)),
                SizedBox(width: 14),
                Text('💬 Reply', style: TextStyle(fontSize: 12, color: SBColors.text3)),
                Spacer(),
                Text('↗ Share', style: TextStyle(fontSize: 12, color: SBColors.text3)),
              ]),
            ]),
          ),

          // Answer 2
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(14),
            decoration: SBTheme.card,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF3ECF8E), Color(0xFF0D9488)]),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Center(child: Text('👩‍🔬', style: TextStyle(fontSize: 16))),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('Amara O.',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
                  Text('45 mins ago', style: TextStyle(fontSize: 10, color: SBColors.text3)),
                ]),
              ]),
              const SizedBox(height: 10),
              const Text(
                'I uploaded a worked example PDF from our class last semester – it covers exactly this. '
                'Check Resources for "MATH201 Limits Examples 2023" it really helped me!',
                style: TextStyle(fontSize: 13, color: SBColors.text, height: 1.6),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: SBColors.brandPale, borderRadius: BorderRadius.circular(10)),
                child: Row(children: const [
                  Text('📄', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('MATH201 Limits Examples 2023.pdf',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600, color: SBColors.brand)),
                      Text('Shared resource · Tap to view',
                          style: TextStyle(fontSize: 10, color: SBColors.text3)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              const Divider(color: SBColors.border, height: 1),
              const SizedBox(height: 10),
              const Row(children: [
                Text('👍', style: TextStyle(fontSize: 14)),
                SizedBox(width: 4),
                Text('11',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: SBColors.text2)),
                SizedBox(width: 14),
                Text('💬 Reply', style: TextStyle(fontSize: 12, color: SBColors.text3)),
                Spacer(),
                Text('↗ Share', style: TextStyle(fontSize: 12, color: SBColors.text3)),
              ]),
            ]),
          ),

          // Reply box
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SBColors.brand, width: 1.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('YOUR ANSWER',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: SBColors.brand, letterSpacing: 1)),
              const SizedBox(height: 6),
              const Text('Share what you know to help Priya...',
                  style: TextStyle(fontSize: 13, color: SBColors.text3)),
              const SizedBox(height: 10),
              Row(children: [
                Wrap(spacing: 6, children: ['📎 File', '🔗 Link', '📚 Resource'].map((opt) =>
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                        color: SBColors.surface3, borderRadius: BorderRadius.circular(8)),
                    child: Text(opt,
                        style: const TextStyle(fontSize: 11, color: SBColors.text2)),
                  )
                ).toList()),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                      color: SBColors.brand, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Post',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}