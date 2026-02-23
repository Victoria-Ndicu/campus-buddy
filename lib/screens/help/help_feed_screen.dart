import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'post_question_screen.dart';
import 'answer_thread_screen.dart';

class HelpFeedScreen extends StatelessWidget {
  const HelpFeedScreen({super.key});

  static final List<Map<String, dynamic>> _questions = [
    {
      'user': 'Priya N.',
      'emoji': '👩‍🎓',
      'avatarBg': AppColors.brandPale,
      'time': '15 minutes ago',
      'course': 'MATH 201',
      'courseColor': AppColors.brand,
      'courseBg': AppColors.brandPale,
      'question': 'Can someone explain how to apply L\'Hôpital\'s Rule when dealing with indeterminate forms like ∞/∞? I keep getting confused about when it\'s valid to apply it.',
      'tags': ['Calculus', 'Limits', 'L\'Hôpital'],
      'tagColor': AppColors.accent,
      'tagBg': Color(0xFFFFF4E6),
      'upvotes': 12,
      'answers': 3,
      'answersColor': AppColors.brand,
    },
    {
      'user': 'Kwame A.',
      'emoji': '👨‍💻',
      'avatarBg': Color(0xFFEDFAF5),
      'time': '1 hour ago',
      'course': 'CS 301',
      'courseColor': AppColors.green,
      'courseBg': Color(0xFFEDFAF5),
      'question': 'What\'s the time complexity of a binary search on a balanced BST vs an AVL tree? Are there practical differences in interview scenarios?',
      'tags': ['Algorithms', 'Data Structures', 'BST'],
      'tagColor': AppColors.green,
      'tagBg': Color(0xFFEDFAF5),
      'upvotes': 8,
      'answers': 5,
      'answersColor': AppColors.brand,
    },
    {
      'user': 'Aisha B.',
      'emoji': '👩‍🔬',
      'avatarBg': Color(0xFFFFF4E6),
      'time': '3 hours ago',
      'course': 'CHEM 102',
      'courseColor': AppColors.accent,
      'courseBg': Color(0xFFFFF4E6),
      'question': 'Does anyone have good resources or tips for balancing redox reactions using the half-reaction method? The lecture slides aren\'t clicking for me 😭',
      'tags': ['Chemistry', 'Redox'],
      'tagColor': AppColors.accent,
      'tagBg': Color(0xFFFFF4E6),
      'upvotes': 5,
      'answers': 0,
      'answersColor': AppColors.text3,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: AppBar(
        title: const Text('Help Centre'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.brand),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostQuestionScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          SBSearchBar(hint: 'Search questions by topic or keyword...'),
          SBFilterRow(options: const ['All', 'Unanswered', 'Mathematics', 'CS', 'Physics', 'Economics']),
          SectionLabel(title: 'Recent Questions', actionLabel: 'Filter ↕'),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _questions.length,
              itemBuilder: (context, i) => _QuestionCard(
                question: _questions[i],
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnswerThreadScreen(question: _questions[i]))),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostQuestionScreen())),
        backgroundColor: AppColors.brand,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('Ask', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final VoidCallback? onTap;
  const _QuestionCard({required this.question, this.onTap});

  @override
  Widget build(BuildContext context) {
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
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: question['avatarBg'] as Color, shape: BoxShape.circle),
                  child: Center(child: Text(question['emoji'], style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(question['user'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text)),
                    Text(question['time'], style: const TextStyle(fontSize: 10, color: AppColors.text3)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: question['courseBg'] as Color, borderRadius: BorderRadius.circular(8)),
                  child: Text(question['course'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: question['courseColor'] as Color)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(question['question'], style: const TextStyle(fontSize: 13, color: AppColors.text, fontWeight: FontWeight.w500, height: 1.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 5, runSpacing: 5,
              children: (question['tags'] as List<String>).map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: question['tagBg'] as Color, borderRadius: BorderRadius.circular(8)),
                child: Text(t, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: question['tagColor'] as Color)),
              )).toList(),
            ),
            const SizedBox(height: 10),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('👍', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text('${question['upvotes']}', style: const TextStyle(fontSize: 12, color: AppColors.brand, fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
                const Icon(Icons.bookmark_border, size: 16, color: AppColors.text3),
                const SizedBox(width: 4),
                const Text('Save', style: TextStyle(fontSize: 12, color: AppColors.text3)),
                const SizedBox(width: 16),
                const Icon(Icons.share_outlined, size: 16, color: AppColors.text3),
                const SizedBox(width: 4),
                const Text('Share', style: TextStyle(fontSize: 12, color: AppColors.text3)),
                const Spacer(),
                Text(
                  '💬 ${question['answers']} ${(question['answers'] as int) == 1 ? 'answer' : 'answers'}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: question['answersColor'] as Color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
