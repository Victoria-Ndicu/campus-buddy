// ============================================================
//  StudyBuddy — sb_help_screen.dart  (Bot Buddy Edition)
//
//  Primary interface: Bot Buddy chat — an AI-powered study
//  assistant that answers academic questions inline.
//
//  Secondary: Community Q&A feed (tab switch)
//
//  Bot API will be wired in Phase 2 (see _BotApi stub).
//
//  Screen stack:
//    SBHelpScreen  (tab: Bot | Community)
//      ├─ _BotChatView          ← new primary experience
//      ├─ _CommunityFeedView    ← existing Q&A feed
//      ├─ SBAnswerThreadScreen  (tap Q&A card)
//      └─ SBAskQuestionScreen   (tap FAB in community tab)
// ============================================================

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/api_client.dart';
import '../models/sb_constants.dart';
import '../widgets/sb_widgets.dart';

// ─────────────────────────────────────────────────────────────
//  CHAT MESSAGE MODEL
// ─────────────────────────────────────────────────────────────
enum _Sender { bot, user }

class _ChatMessage {
  final String   text;
  final _Sender  sender;
  final DateTime time;
  final bool     isTyping; // true = animated "…" bubble

  const _ChatMessage({
    required this.text,
    required this.sender,
    required this.time,
    this.isTyping = false,
  });

  _ChatMessage copyWith({String? text, bool? isTyping}) => _ChatMessage(
    text:      text     ?? this.text,
    sender:    sender,
    time:      time,
    isTyping:  isTyping ?? this.isTyping,
  );
}

// ─────────────────────────────────────────────────────────────
//  BOT API STUB  (Phase 2: replace body with real LLM call)
// ─────────────────────────────────────────────────────────────
class _BotApi {
  /// Send [question] to Bot Buddy and return the answer string.
  /// Phase 1 → returns a placeholder.
  /// Phase 2 → uncomment the ApiClient call below.
  static Future<String> ask(String question) async {
    await Future.delayed(const Duration(milliseconds: 1400)); // simulate latency

    // ── Phase 2 (uncomment when endpoint is ready) ──────────
    // final res = await ApiClient.post('/api/v1/study-buddy/bot/', body: {
    //   'question': question,
    // });
    // if (res.statusCode == 200) {
    //   final body = jsonDecode(res.body) as Map<String, dynamic>;
    //   return body['answer'] as String? ?? 'Hmm, I could not get an answer.';
    // }
    // throw Exception('Bot error (${res.statusCode})');
    // ────────────────────────────────────────────────────────

    // Phase 1 placeholder
    return "Great question! 🤓 I'm Bot Buddy — your AI study assistant. "
        "Once I'm fully wired up, I'll give you detailed answers, worked "
        "examples, and resources for any academic topic. Stay tuned!";
  }
}

// ─────────────────────────────────────────────────────────────
//  QUESTION MODEL  (unchanged from original)
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
    } catch (_) { return ''; }
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
//  COMMUNITY API SERVICE  (unchanged)
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
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final path  = query.isEmpty ? '$_base/questions/' : '$_base/questions/?$query';
    final res   = await ApiClient.get(path);
    dev.log('[SBHelp] GET $path → ${res.statusCode}');
    if (res.statusCode != 200) throw Exception('Failed to load questions (${res.statusCode})');
    final body    = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (body['results'] ?? body) as List<dynamic>;
    return results.map((e) => QuestionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> postQuestion(Map<String, dynamic> payload) async {
    final res = await ApiClient.post('$_base/questions/', body: payload);
    dev.log('[SBHelp] POST question → ${res.statusCode}');
    if (res.statusCode != 201) throw Exception('Failed to post question (${res.statusCode})');
  }

  static Future<void> upvoteQuestion(String id) async {
    final res = await ApiClient.post('$_base/questions/$id/vote/');
    dev.log('[SBHelp] POST vote $id → ${res.statusCode}');
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception('Vote failed (${res.statusCode})');
  }
}

// ─────────────────────────────────────────────────────────────
//  ROOT SCREEN  — tabs: Bot Buddy | Community
// ─────────────────────────────────────────────────────────────
class SBHelpScreen extends StatefulWidget {
  const SBHelpScreen({super.key});

  @override
  State<SBHelpScreen> createState() => _SBHelpScreenState();
}

class _SBHelpScreenState extends State<SBHelpScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: SBColors.surface3,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tab,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: SBColors.text,
              unselectedLabelColor: SBColors.text3,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: '🤖  Bot Buddy'),
                Tab(text: '👥  Community'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          _BotChatView(),
          _CommunityFeedView(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BOT BUDDY CHAT VIEW
// ─────────────────────────────────────────────────────────────
class _BotChatView extends StatefulWidget {
  const _BotChatView();

  @override
  State<_BotChatView> createState() => _BotChatViewState();
}

class _BotChatViewState extends State<_BotChatView> {
  final _ctrl       = TextEditingController();
  final _scroll     = ScrollController();
  final _focusNode  = FocusNode();
  bool  _sending    = false;

  // Prompt suggestions shown below the intro card
  static const _suggestions = [
    '📐 Explain the chain rule',
    '⚛️  How does osmosis work?',
    '💡 What is Big O notation?',
    '📜 Summarise the Cold War',
  ];

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text:   '__intro__', // sentinel — rendered as the fancy intro card
      sender: _Sender.bot,
      time:   DateTime.now(),
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── scroll helpers ────────────────────────────────────────
  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      if (animated) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  // ── send a message ────────────────────────────────────────
  Future<void> _send([String? prefilled]) async {
    final text = (prefilled ?? _ctrl.text).trim();
    if (text.isEmpty || _sending) return;

    HapticFeedback.lightImpact();
    _ctrl.clear();
    _focusNode.unfocus();

    // 1. Add user bubble
    final userMsg = _ChatMessage(
      text: text, sender: _Sender.user, time: DateTime.now());
    // 2. Add typing indicator
    final typingMsg = _ChatMessage(
      text: '', sender: _Sender.bot, time: DateTime.now(), isTyping: true);

    setState(() {
      _sending = true;
      _messages.add(userMsg);
      _messages.add(typingMsg);
    });
    _scrollToBottom();

    try {
      final answer = await _BotApi.ask(text);
      if (!mounted) return;
      setState(() {
        _messages[_messages.length - 1] =
            typingMsg.copyWith(text: answer, isTyping: false);
        _sending = false;
      });
    } catch (e, st) {
      dev.log('[BotBuddy] error: $e', stackTrace: st);
      if (!mounted) return;
      setState(() {
        _messages[_messages.length - 1] = typingMsg.copyWith(
          text: '⚠️ Sorry, I hit a snag. Please try again.',
          isTyping: false,
        );
        _sending = false;
      });
    }
    _scrollToBottom();
  }

  // ── build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final showSuggestions =
        _messages.length == 1; // only intro card shown

    return Column(
      children: [
        // ── message list ─────────────────────────────────────
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: _messages.length + (showSuggestions ? 1 : 0),
            itemBuilder: (_, i) {
              // Suggestions row (after intro card)
              if (showSuggestions && i == 1) {
                return _SuggestionsRow(
                  suggestions: _suggestions,
                  onTap: _send,
                );
              }
              final msg = _messages[i];
              if (msg.text == '__intro__') return const _BotIntroCard();
              if (msg.sender == _Sender.bot) {
                return msg.isTyping
                    ? const _TypingBubble()
                    : _BotBubble(text: msg.text, time: msg.time);
              }
              return _UserBubble(text: msg.text, time: msg.time);
            },
          ),
        ),

        // ── input bar ────────────────────────────────────────
        _ChatInputBar(
          controller: _ctrl,
          focusNode:  _focusNode,
          sending:    _sending,
          onSend:     _send,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BOT INTRO CARD
// ─────────────────────────────────────────────────────────────
class _BotIntroCard extends StatelessWidget {
  const _BotIntroCard();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [SBColors.brand, SBColors.brandDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: SBColors.brand.withOpacity(0.3),
            blurRadius: 20, offset: const Offset(0, 6)),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        // Bot avatar
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 26))),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Bot Buddy', style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
          Row(children: [
            Container(
              width: 7, height: 7,
              decoration: const BoxDecoration(
                  color: Color(0xFF4ADE80), shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text('Online  ·  AI Study Assistant',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
          ]),
        ]),
      ]),
      const SizedBox(height: 14),
      const Text(
        'Hey there! 👋  I\'m Bot Buddy, your personal AI tutor. '
        'Ask me anything — maths, science, history, coding — '
        'and I\'ll explain it clearly, step by step.',
        style: TextStyle(fontSize: 13, color: Colors.white, height: 1.6),
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 6, children: [
        _IntroTag('📖 Explanations'),
        _IntroTag('🔢 Worked Examples'),
        _IntroTag('📚 Study Resources'),
        _IntroTag('✍️  Essay Help'),
      ]),
    ]),
  );
}

class _IntroTag extends StatelessWidget {
  final String label;
  const _IntroTag(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: Colors.white)),
  );
}

// ─────────────────────────────────────────────────────────────
//  SUGGESTION CHIPS
// ─────────────────────────────────────────────────────────────
class _SuggestionsRow extends StatelessWidget {
  final List<String>     suggestions;
  final void Function(String) onTap;

  const _SuggestionsRow({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Try asking:', style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600, color: SBColors.text3)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: suggestions.map((s) => GestureDetector(
          onTap: () => onTap(s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SBColors.border, width: 1.5),
            ),
            child: Text(s, style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: SBColors.text)),
          ),
        )).toList(),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────
//  CHAT BUBBLES
// ─────────────────────────────────────────────────────────────
class _BotBubble extends StatelessWidget {
  final String   text;
  final DateTime time;
  const _BotBubble({required this.text, required this.time});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      // Mini bot avatar
      Container(
        width: 30, height: 30,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [SBColors.brand, SBColors.brandDark]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
      ),
      Flexible(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft:     Radius.circular(18),
                topRight:    Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft:  Radius.circular(4),
              ),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Text(text, style: const TextStyle(
                fontSize: 13, color: SBColors.text, height: 1.6)),
          ),
          const SizedBox(height: 4),
          Text(_fmt(time), style: const TextStyle(
              fontSize: 10, color: SBColors.text3)),
        ]),
      ),
      const SizedBox(width: 48), // keep bot bubbles from spanning full width
    ]),
  );
}

class _UserBubble extends StatelessWidget {
  final String   text;
  final DateTime time;
  const _UserBubble({required this.text, required this.time});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: 48),
        Flexible(
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [SBColors.brand, SBColors.brandDark]),
                borderRadius: BorderRadius.only(
                  topLeft:     Radius.circular(18),
                  topRight:    Radius.circular(18),
                  bottomLeft:  Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(text, style: const TextStyle(
                  fontSize: 13, color: Colors.white, height: 1.6)),
            ),
            const SizedBox(height: 4),
            Text(_fmt(time), style: const TextStyle(
                fontSize: 10, color: SBColors.text3)),
          ]),
        ),
      ],
    ),
  );
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Container(
        width: 30, height: 30,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [SBColors.brand, SBColors.brandDark]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18), topRight: Radius.circular(18),
            bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4),
          ),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final delay = i / 3;
              final val   = (_anim.value - delay).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Transform.translate(
                  offset: Offset(0, -4 * val),
                  child: Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                        color: SBColors.brand.withOpacity(0.5 + 0.5 * val),
                        shape: BoxShape.circle),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    ]),
  );
}

String _fmt(DateTime t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

// ─────────────────────────────────────────────────────────────
//  CHAT INPUT BAR
// ─────────────────────────────────────────────────────────────
class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode             focusNode;
  final bool                  sending;
  final VoidCallback          onSend;

  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 16, offset: const Offset(0, -4))],
    ),
    padding: EdgeInsets.fromLTRB(
        16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
    child: Row(children: [
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: SBColors.surface2,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SBColors.border, width: 1.5),
          ),
          child: TextField(
            controller: controller,
            focusNode:  focusNode,
            maxLines: 4,
            minLines: 1,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
            style: const TextStyle(fontSize: 14, color: SBColors.text),
            decoration: const InputDecoration(
              hintText:        'Ask Bot Buddy anything...',
              hintStyle:       TextStyle(fontSize: 13, color: SBColors.text3),
              border:          InputBorder.none,
              contentPadding:  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: sending ? null : onSend,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: sending
                ? SBColors.brand.withOpacity(0.5)
                : SBColors.brand,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: SBColors.brand.withOpacity(0.3),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: sending
              ? const Center(child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)))
              : const Center(child: Icon(
                  Icons.send_rounded, color: Colors.white, size: 20)),
        ),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────
//  COMMUNITY FEED VIEW  (moved from root — unchanged logic)
// ─────────────────────────────────────────────────────────────
class _CommunityFeedView extends StatefulWidget {
  const _CommunityFeedView();

  @override
  State<_CommunityFeedView> createState() => _CommunityFeedViewState();
}

class _CommunityFeedViewState extends State<_CommunityFeedView> {
  int    _filter      = 0;
  String _searchQuery = '';

  List<QuestionModel>? _questions;
  bool    _loading = true;
  String? _error;

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
      if (mounted) setState(() {
        _error   = 'Could not load questions. Check your connection.';
        _loading = false;
      });
    }
  }

  Future<void> _upvote(QuestionModel q) async {
    if (_voted.contains(q.id)) return;
    setState(() => _voted.add(q.id));
    try {
      await _HelpApi.upvoteQuestion(q.id);
    } catch (e, st) {
      dev.log('[SBHelp] _upvote error: $e', stackTrace: st);
      if (mounted) setState(() => _voted.remove(q.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async => _fetchQuestions(),
          color: SBColors.brand,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SBSearchBar(
                hint: 'Search community questions...',
                onChanged: (q) {
                  setState(() => _searchQuery = q);
                  _fetchQuestions();
                },
              )),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 46,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => SBChip(
                      label:  _filters[i],
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
              SliverToBoxAdapter(child: _buildContent()),
            ],
          ),
        ),

        // FAB — Ask question
        Positioned(
          bottom: 16, right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'community_fab',
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SBAskQuestionScreen()));
              _fetchQuestions();
            },
            backgroundColor: SBColors.brand,
            icon: const Text('🙋', style: TextStyle(fontSize: 18)),
            label: const Text('Ask Question',
                style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) return Column(children: _shimmerCards());

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
        q:      q,
        voted:  _voted.contains(q.id),
        onVote: () => _upvote(q),
        onTap:  () => Navigator.push(context,
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
//  Q&A CARD  (unchanged)
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
          Container(width: 36, height: 36,
              decoration: const BoxDecoration(
                  color: SBColors.brandPale, shape: BoxShape.circle),
              child: Center(child: Text(q.emoji,
                  style: const TextStyle(fontSize: 16)))),
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
                color: const Color(0xFFFFF4E6),
                borderRadius: BorderRadius.circular(8)),
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
                  fontSize: 14, color: voted ? SBColors.brand : null)),
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
//  ASK QUESTION SCREEN  (unchanged)
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
        'question': _questionCtrl.text.trim(),
        'course':   _courseCtrl.text.trim(),
        'tags':     tags,
        'urgency':  _urgency,
        'help_via': _helpVia.toLowerCase().replaceAll(' ', '_'),
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
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: SBColors.brand))
                    : const Text('Post', style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: SBColors.brand)),
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
          _PickerField(
            label: 'PREFER HELP VIA',
            child: Wrap(spacing: 8, runSpacing: 8,
              children: ['💬 Written Answer', '🎥 Video Call', '📚 Resource Link']
                .map<Widget>((opt) {
                  final key = opt.split(' ').sublist(1).join(' ');
                  return SBChip(
                    label:  opt,
                    active: _helpVia == key,
                    onTap:  () => setState(() => _helpVia = key),
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
                color: _loading
                    ? SBColors.brand.withOpacity(0.6)
                    : SBColors.brand,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: SBColors.brand.withOpacity(0.3),
                    blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: Center(
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('🙋  Post Question', style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: Colors.white)),
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
//  ANSWER THREAD SCREEN  (unchanged)
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
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: SBTheme.brandGradient(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle),
                  child: Center(child: Text(q.emoji,
                      style: const TextStyle(fontSize: 14))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(q.user, style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: Colors.white)),
                  Text(
                    [q.timeAgo, if (q.course.isNotEmpty) q.course]
                        .where((s) => s.isNotEmpty).join(' · '),
                    style: TextStyle(fontSize: 10,
                        color: Colors.white.withOpacity(0.75))),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(q.urgency, style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: Colors.white)),
                ),
              ]),
              const SizedBox(height: 10),
              Text(q.question, style: const TextStyle(
                  fontSize: 13, color: Colors.white, height: 1.5)),
              if (q.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 6, children: q.tags.map((t) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(t, style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: Colors.white)),
                )).toList()),
              ],
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              '💬  ${q.answerCount} ${q.answerCount == 1 ? 'Answer' : 'Answers'}',
              style: const TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w600, color: SBColors.text2)),
          ),
          if (q.answered) _BestAnswerCard(),
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
                Wrap(spacing: 6, children: ['📎 File', '🔗 Link', '📚 Resource']
                    .map((opt) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                      color: SBColors.surface3,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(opt, style: const TextStyle(
                      fontSize: 11, color: SBColors.text2)),
                )).toList()),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                      color: SBColors.brand,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Text('Post', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: Colors.white)),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

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
            gradient: LinearGradient(
                colors: [SBColors.brand, SBColors.brandDark]),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: const Center(child: Text('👨‍🏫',
              style: TextStyle(fontSize: 16))),
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
                  fontSize: 9, fontWeight: FontWeight.w700,
                  color: SBColors.green)),
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