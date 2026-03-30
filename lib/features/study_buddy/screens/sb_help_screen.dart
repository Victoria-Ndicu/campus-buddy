// ============================================================
//  StudyBuddy — sb_help_screen.dart  (API-connected)
//
//  Now uses ApiClient (lib/core/api_client.dart) for all
//  requests — automatic token refresh, same pattern as
//  profile_screen.dart.
//
//  GET  /api/study/questions/           → Q&A feed
//  POST /api/study/questions/           → post question
//  POST /api/study/questions/<id>/vote/ → upvote
//
//  Screen stack:
//    SBHelpScreen
//      ├─ SBAnswerThreadScreen   (tap Q&A card)
//      └─ SBAskQuestionScreen    (tap FAB)
// ============================================================

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';

import '../../../core/api_client.dart';   // ← same shared client as profile_screen
import '../models/sb_constants.dart';
import '../widgets/sb_widgets.dart';

// ─────────────────────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────────────────────
class QuestionModel {
  final String id;
  final String user;
  final String emoji;
  final String timeAgo;
  final String course;
  final String question;
  final List<String> tags;
  final String urgency;
  final Color  urgencyColor;
  final Color  urgencyBg;
  final int    votes;
  final int    answerCount;
  final bool   answered;

  const QuestionModel({
    required this.id,
    required this.user,
    required this.emoji,
    required this.timeAgo,
    required this.course,
    required this.question,
    required this.tags,
    required this.urgency,
    required this.urgencyColor,
    required this.urgencyBg,
    required this.votes,
    required this.answerCount,
    required this.answered,
  });

  static (String, Color, Color) _urgencyMeta(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'urgent':
        return ('🔥 Urgent', SBColors.accent2, const Color(0xFFFFF0F0));
      case 'need_soon':
      case 'need soon':
        return ('⏰ Need Soon', SBColors.accent, const Color(0xFFFFF4E6));
      default:
        return ('😊 Not Urgent', SBColors.green, const Color(0xFFEDFAF5));
    }
  }

  static String _timeAgo(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt   = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours   < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final urgencyStr = json['urgency'] as String? ?? 'not_urgent';
    final (urgencyLabel, urgencyColor, urgencyBg) = _urgencyMeta(urgencyStr);

    final tags = (json['tags'] as List? ?? []).map((t) => t.toString()).toList();

    return QuestionModel(
      id:           json['id']?.toString() ?? '',
      user:         json['user_name'] as String? ??
                    json['user']?['full_name'] as String? ?? 'Student',
      emoji:        json['user_emoji'] as String? ?? '👩‍🎓',
      timeAgo:      _timeAgo(json['created_at'] as String?),
      course:       json['course'] as String? ?? json['course_code'] as String? ?? '',
      question:     json['question'] as String? ?? json['body'] as String? ?? '',
      tags:         tags,
      urgency:      urgencyLabel,
      urgencyColor: urgencyColor,
      urgencyBg:    urgencyBg,
      votes:        (json['votes'] ?? json['upvote_count'] ?? 0) as int,
      answerCount:  (json['answer_count'] ?? json['answers_count'] ?? 0) as int,
      answered:     json['is_answered'] as bool? ?? (((json['answer_count'] ?? 0) as int) > 0),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  API SERVICE
// ─────────────────────────────────────────────────────────────
class _HelpApi {
  static const _base = '/api/v1/study-buddy';

  static Future<List<QuestionModel>> fetchQuestions({
    String? filter,
    String? search,
  }) async {
    final params = <String, String>{};
    if (filter != null && filter.isNotEmpty) params['filter'] = filter;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final path  = query.isEmpty ? '$_base/questions/' : '$_base/questions/?$query';

    final res = await ApiClient.get(path);
    dev.log('[SBHelp] GET $path → ${res.statusCode}');

    if (res.statusCode != 200) {
      throw Exception('Failed to load questions (${res.statusCode})');
    }

    final body    = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (body['results'] ?? body) as List<dynamic>;
    return results
        .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> postQuestion(Map<String, dynamic> payload) async {
    final res = await ApiClient.post('$_base/questions/', body: payload);
    dev.log('[SBHelp] POST question → ${res.statusCode}');
    if (res.statusCode != 201) {
      throw Exception('Failed to post question (${res.statusCode})');
    }
  }

  static Future<void> upvoteQuestion(String id) async {
    final res = await ApiClient.post('$_base/questions/$id/vote/');
    dev.log('[SBHelp] POST vote $id → ${res.statusCode}');
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Vote failed (${res.statusCode})');
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  1. Q&A FEED
//
//  State pattern mirrors profile_screen.dart:
//    _loading / _error / _questions  (atomic setState)
// ─────────────────────────────────────────────────────────────
class SBHelpScreen extends StatefulWidget {
  const SBHelpScreen({super.key});

  @override
  State<SBHelpScreen> createState() => _SBHelpScreenState();
}

class _SBHelpScreenState extends State<SBHelpScreen> {
  int    _filter      = 0;
  String _searchQuery = '';

  List<QuestionModel>? _questions;
  bool    _loading = true;
  String? _error;

  // Optimistic vote tracking
  final Set<String> _voted = {};

  static const _filters    = ['All', 'Unanswered', 'MATH', 'CS', 'CHEM'];
  static const _filterKeys = ['',    'unanswered',  'math', 'cs', 'chem'];

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    if (mounted) setState(() { _loading = true; _error = null; });

    try {
      final filterKey = _filterKeys[_filter];
      final data      = await _HelpApi.fetchQuestions(
        filter: filterKey.isEmpty ? null : filterKey,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (mounted) setState(() { _questions = data; _loading = false; });
    } catch (e, st) {
      dev.log('[SBHelp] _fetchQuestions error: $e', stackTrace: st);
      if (mounted) {
        setState(() {
          _error   = 'Could not load questions. Check your connection.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _upvote(QuestionModel q) async {
    if (_voted.contains(q.id)) return;   // already voted this session
    setState(() => _voted.add(q.id));    // optimistic
    try {
      await _HelpApi.upvoteQuestion(q.id);
    } catch (e, st) {
      dev.log('[SBHelp] _upvote error: $e', stackTrace: st);
      if (mounted) setState(() => _voted.remove(q.id));   // revert
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: SBColors.brandDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

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
        title: const Text('Academic Help', style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700, color: SBColors.text)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SBAskQuestionScreen()));
          // Reload after returning from ask screen
          _fetchQuestions();
        },
        backgroundColor: SBColors.brand,
        icon: const Text('🙋', style: TextStyle(fontSize: 18)),
        label: const Text('Ask Question',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _fetchQuestions(),
        color: SBColors.brand,
        child: CustomScrollView(
          slivers: [
            // ── Search ─────────────────────────────────────
            SliverToBoxAdapter(
              child: SBSearchBar(
                hint: 'Search questions...',
                onChanged: (q) {
                  setState(() => _searchQuery = q);
                  _fetchQuestions();
                },
              ),
            ),

            // ── Filter chips ───────────────────────────────
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
                    onTap: () {
                      setState(() => _filter = i);
                      _fetchQuestions();
                    },
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Content ────────────────────────────────────
            SliverToBoxAdapter(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Loading — shimmer cards
    if (_loading) {
      return Column(children: _shimmerCards());
    }

    // Error (same pattern as _NameBlock)
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(children: [
          const Text('⚠️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: SBColors.text2)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _fetchQuestions,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                  color: SBColors.brand, borderRadius: BorderRadius.circular(12)),
              child: const Text('Retry', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ]),
      );
    }

    final questions = _questions ?? [];

    if (questions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(children: const [
          Text('🤔', style: TextStyle(fontSize: 40)),
          SizedBox(height: 12),
          Text('No questions yet', style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: SBColors.text)),
          SizedBox(height: 4),
          Text('Be the first to ask something!',
              style: TextStyle(fontSize: 12, color: SBColors.text3)),
        ]),
      );
    }

    return Column(children: [
      ...questions.map((q) => _QACard(
        q:       q,
        voted:   _voted.contains(q.id),
        onVote:  () => _upvote(q),
        onTap:   () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => SBAnswerThreadScreen(question: q))),
      )),
      const SizedBox(height: 80),
    ]);
  }

  List<Widget> _shimmerCards() => List.generate(3, (_) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    padding: const EdgeInsets.all(14),
    decoration: SBTheme.card,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 36, height: 36,
            decoration: const BoxDecoration(color: SBColors.border, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 100, height: 11,
              decoration: BoxDecoration(color: SBColors.border,
                  borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 5),
          Container(width: 140, height: 9,
              decoration: BoxDecoration(color: SBColors.border,
                  borderRadius: BorderRadius.circular(5))),
        ])),
      ]),
      const SizedBox(height: 12),
      Container(width: double.infinity, height: 12,
          decoration: BoxDecoration(color: SBColors.border,
              borderRadius: BorderRadius.circular(6))),
      const SizedBox(height: 6),
      Container(width: 240, height: 12,
          decoration: BoxDecoration(color: SBColors.border,
              borderRadius: BorderRadius.circular(6))),
    ]),
  ));
}

// ─────────────────────────────────────────────────────────────
//  Q&A CARD  (data-driven, same visual)
// ─────────────────────────────────────────────────────────────
class _QACard extends StatelessWidget {
  final QuestionModel q;
  final bool          voted;
  final VoidCallback  onVote;
  final VoidCallback  onTap;

  const _QACard({
    required this.q,
    required this.voted,
    required this.onVote,
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
            child: Center(child: Text(q.emoji, style: const TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(q.user, style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: SBColors.text)),
            Text(
              [q.timeAgo, if (q.course.isNotEmpty) q.course]
                  .where((s) => s.isNotEmpty).join(' · '),
              style: const TextStyle(fontSize: 10, color: SBColors.text3)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: q.urgencyBg,
                borderRadius: BorderRadius.circular(8)),
            child: Text(q.urgency, style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: q.urgencyColor)),
          ),
        ]),
        const SizedBox(height: 10),
        Text(q.question, style: const TextStyle(
            fontSize: 13, color: SBColors.text, height: 1.5,
            fontWeight: FontWeight.w500)),
        if (q.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 5, runSpacing: 5, children: q.tags.map((t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF4E6), borderRadius: BorderRadius.circular(8)),
            child: Text(t, style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: SBColors.accent)),
          )).toList()),
        ],
        const SizedBox(height: 10),
        const Divider(color: SBColors.border, height: 1),
        const SizedBox(height: 10),
        Row(children: [
          GestureDetector(
            onTap: onVote,
            child: Row(children: [
              Text(voted ? '👍' : '👍', style: TextStyle(
                  fontSize: 14,
                  color: voted ? SBColors.brand : null)),
              const SizedBox(width: 4),
              Text('${q.votes + (voted ? 1 : 0)}', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: voted ? SBColors.brand : SBColors.text2)),
            ]),
          ),
          const SizedBox(width: 14),
          const Text('💬', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text('${q.answerCount}', style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: SBColors.text2)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: q.answered
                  ? SBColors.green.withOpacity(0.1)
                  : SBColors.accent2.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              q.answered ? '✓ Answered' : 'Unanswered',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: q.answered ? SBColors.green : SBColors.accent2),
            ),
          ),
        ]),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  2. ASK QUESTION  (posts to /api/study/questions/)
// ─────────────────────────────────────────────────────────────
class SBAskQuestionScreen extends StatefulWidget {
  const SBAskQuestionScreen({super.key});

  @override
  State<SBAskQuestionScreen> createState() => _SBAskQuestionScreenState();
}

class _SBAskQuestionScreenState extends State<SBAskQuestionScreen> {
  String _urgency = 'need_soon';
  String _helpVia = 'Written Answer';
  bool   _loading = false;

  final _questionCtrl = TextEditingController();
  final _courseCtrl   = TextEditingController();
  final _tagsCtrl     = TextEditingController();

  @override
  void dispose() {
    _questionCtrl.dispose();
    _courseCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_questionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your question')));
      return;
    }
    setState(() => _loading = true);
    try {
      final tags = _tagsCtrl.text.trim().isEmpty
          ? <String>[]
          : _tagsCtrl.text.split(',').map((t) => t.trim()).toList();

      await _HelpApi.postQuestion({
        'question':  _questionCtrl.text.trim(),
        'course':    _courseCtrl.text.trim(),
        'tags':      tags,
        'urgency':   _urgency,
        'help_via':  _helpVia.toLowerCase().replaceAll(' ', '_'),
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('🙋  Your question has been posted!'),
        backgroundColor: SBColors.brand,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e, st) {
      dev.log('[SBHelp] _submit error: $e', stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to post question: ${e.toString()}'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
        title: const Text('Ask for Help', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: SBColors.text)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _loading ? null : _submit,
              child: Center(
                child: _loading
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: SBColors.brand))
                    : const Text('Post', style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.brand)),
              ),
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
          SBFormField(label: 'Your Question', controller: _questionCtrl,
              multiline: true, active: true),
          const SizedBox(height: 12),
          SBFormField(label: 'Course Code', controller: _courseCtrl),
          const SizedBox(height: 12),
          SBFormField(label: 'Tags (comma-separated)', controller: _tagsCtrl),
          const SizedBox(height: 12),

          // Attach row (UI only — file attachment handled natively in production)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SBColors.border, width: 1.5)),
            child: Row(children: const [
              Text('📎', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Attach a file (optional)', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
                Text('Add a photo, PDF or document to clarify your question',
                    style: TextStyle(fontSize: 11, color: SBColors.text3)),
              ])),
              Text('Upload', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: SBColors.brand)),
            ]),
          ),
          const SizedBox(height: 12),

          // Urgency
          _PickerField(
            label: 'URGENCY',
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              _UrgencyChip('😊 Not Urgent', 'not_urgent', SBColors.green,
                  const Color(0xFFEDFAF5), _urgency,
                  (v) => setState(() => _urgency = v)),
              _UrgencyChip('⏰ Need Soon', 'need_soon', SBColors.accent,
                  const Color(0xFFFFF4E6), _urgency,
                  (v) => setState(() => _urgency = v)),
              _UrgencyChip('🔥 Urgent', 'urgent', SBColors.accent2,
                  const Color(0xFFFFF0F0), _urgency,
                  (v) => setState(() => _urgency = v)),
            ]),
          ),
          const SizedBox(height: 12),

          // Help via
          _PickerField(
            label: 'PREFER HELP VIA',
            child: Wrap(spacing: 8, runSpacing: 8,
              children: ['💬 Written Answer', '🎥 Video Call', '📚 Resource Link']
                .map<Widget>((opt) {
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
            onTap: _loading ? null : _submit,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: _loading ? SBColors.brand.withOpacity(0.6) : SBColors.brand,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: SBColors.brand.withOpacity(0.3),
                    blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: Center(
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('🙋  Post Question', style: TextStyle(
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
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SBColors.border, width: 1.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: SBColors.text3, letterSpacing: 1)),
      const SizedBox(height: 8),
      child,
    ]),
  );
}

class _UrgencyChip extends StatelessWidget {
  final String label, value;
  final Color  color, bgColor;
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
        child: Text(label, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: on ? color : SBColors.text2)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  3. ANSWER THREAD  (receives the full QuestionModel)
// ─────────────────────────────────────────────────────────────
class SBAnswerThreadScreen extends StatelessWidget {
  final QuestionModel question;
  const SBAnswerThreadScreen({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final q = question;
    return Scaffold(
      backgroundColor: SBColors.surface2,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: SBColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Question Thread', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: SBColors.text)),
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
                  child: Center(child: Text(q.emoji, style: const TextStyle(fontSize: 14))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(q.user, style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  Text(
                    [q.timeAgo, if (q.course.isNotEmpty) q.course]
                        .where((s) => s.isNotEmpty).join(' · '),
                    style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.75))),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(q.urgency, style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ]),
              const SizedBox(height: 10),
              Text(q.question, style: const TextStyle(
                  fontSize: 13, color: Colors.white, height: 1.5)),
              if (q.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 6, children: q.tags.map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(t, style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                )).toList()),
              ],
            ]),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text('💬  ${q.answerCount} ${q.answerCount == 1 ? 'Answer' : 'Answers'}',
                style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w600, color: SBColors.text2)),
          ),

          // Placeholder best-answer card (real answers would be fetched from
          // GET /api/study/questions/<id>/answers/ in a production impl)
          if (q.answered) _BestAnswerCard(),

          // Reply box
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SBColors.brand, width: 1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('YOUR ANSWER', style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: SBColors.brand, letterSpacing: 1)),
              const SizedBox(height: 6),
              Text('Share what you know to help ${q.user.split(' ').first}...',
                  style: const TextStyle(fontSize: 13, color: SBColors.text3)),
              const SizedBox(height: 10),
              Row(children: [
                Wrap(spacing: 6, children: ['📎 File', '🔗 Link', '📚 Resource'].map((opt) =>
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                        color: SBColors.surface3, borderRadius: BorderRadius.circular(8)),
                    child: Text(opt, style: const TextStyle(fontSize: 11, color: SBColors.text2)),
                  )
                ).toList()),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                      color: SBColors.brand, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Post', style: TextStyle(
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

// ── Static best-answer placeholder ───────────────────────────
// (In production, fetch real answers via GET /api/study/questions/<id>/answers/)
class _BestAnswerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: SBColors.green, width: 2),
      boxShadow: [BoxShadow(color: SBColors.green.withOpacity(0.15),
          blurRadius: 12, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 36, height: 36,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [SBColors.brand, SBColors.brandDark]),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: const Center(child: Text('👨‍🏫', style: TextStyle(fontSize: 16))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Top Answer', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: SBColors.text)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: SBColors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6)),
              child: const Text('✓ Best Answer', style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w700, color: SBColors.green)),
            ),
          ]),
          const Text('Verified by community', style: TextStyle(
              fontSize: 10, color: SBColors.text3)),
        ])),
      ]),
      const SizedBox(height: 10),
      const Text('View the full answer by tapping on this question.',
          style: TextStyle(fontSize: 13, color: SBColors.text, height: 1.6)),
      const SizedBox(height: 10),
      const Divider(color: SBColors.border, height: 1),
      const SizedBox(height: 10),
      const Row(children: [
        Text('👍', style: TextStyle(fontSize: 14)),
        SizedBox(width: 4),
        Text('—', style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: SBColors.brand)),
        SizedBox(width: 14),
        Text('💬 Reply', style: TextStyle(fontSize: 12, color: SBColors.text3)),
        Spacer(),
        Text('↗ Share', style: TextStyle(fontSize: 12, color: SBColors.text3)),
      ]),
    ]),
  );
}