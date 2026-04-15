// ============================================================
//  StudyBuddy — sb_help_screen.dart  (Bot Buddy)
//
//  Flow:
//    1. User ID is read from SharedPreferences (set at login)
//    2. POST https://buddy-bot-production.up.railway.app/api/chat
//       body: { "message": "...", "user_id": "..." }
//       response: { "reply": "...", "user_id": "..." }
//    3. Uses raw http.post — NOT ApiClient — because the bot
//       is on a completely separate backend URL.
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  final bool     isTyping;

  const _ChatMessage({
    required this.text,
    required this.sender,
    required this.time,
    this.isTyping = false,
  });

  _ChatMessage copyWith({String? text, bool? isTyping}) => _ChatMessage(
        text:     text     ?? this.text,
        sender:   sender,
        time:     time,
        isTyping: isTyping ?? this.isTyping,
      );
}

// ─────────────────────────────────────────────────────────────
//  BOT API
//
//  • Uses http directly — never goes through ApiClient.
//  • ApiClient hard-codes campusbuddybackend URL; passing a
//    full URL as its "path" would produce a double-URL and fail.
//  • Reads the logged-in user's UUID from SharedPreferences
//    so the Flask backend keeps per-user conversation history.
// ─────────────────────────────────────────────────────────────
class _BotApi {
  static const String _botUrl = 'https://buddy-bot-production.up.railway.app/';

  /// Cached so SharedPreferences is only hit once per session.
  static String? _cachedUserId;

  // ── Resolve user ID ──────────────────────────────────────
  /// Tries every key your login screen might store the UUID under.
  /// Falls back to a generated UUID so the bot still works even
  /// if the key name doesn't match.
  static Future<String> _resolveUserId() async {
    if (_cachedUserId != null && _cachedUserId!.isNotEmpty) {
      return _cachedUserId!;
    }

    final prefs = await SharedPreferences.getInstance();

    // Try all common key names your Django/JWT login might use
    final id =
        prefs.getString('userId')    ??   // camelCase (common in Dart)
        prefs.getString('user_id')   ??   // snake_case (common from Django)
        prefs.getString('id')        ??   // bare id
        prefs.getString('uid')       ??   // Firebase style
        prefs.getString('botUserId');     // our own fallback key

    if (id != null && id.isNotEmpty) {
      _cachedUserId = id;
      dev.log('[BotBuddy] ✓ user_id resolved from prefs: $_cachedUserId');
    } else {
      // No login key found — generate a stable UUID for this install
      _cachedUserId = _generateUUID();
      await prefs.setString('botUserId', _cachedUserId!);
      dev.log('[BotBuddy] ⚠ No user_id in prefs — generated fallback: $_cachedUserId');
    }

    return _cachedUserId!;
  }

  /// Call on logout so the next user gets a fresh conversation.
  static void clearCache() => _cachedUserId = null;

  // ── POST /api/chat ───────────────────────────────────────
  static Future<String> ask(String question) async {
    try {
      final uid = await _resolveUserId();
      final url = Uri.parse('$_botUrl/api/chat');

      dev.log('[BotBuddy] → POST $url');
      dev.log('[BotBuddy]   user_id : $uid');
      dev.log('[BotBuddy]   message : $question');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': question,
          'user_id': uid,          // ← always sent, always from prefs
        }),
      ).timeout(const Duration(seconds: 30));

      dev.log('[BotBuddy] ← status: ${response.statusCode}');
      dev.log('[BotBuddy] ← body  : ${response.body}');

      switch (response.statusCode) {
        case 200:
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          if (body.containsKey('error')) return '⚠️ ${body['error']}';
          final reply = body['reply'] as String?;
          return (reply != null && reply.isNotEmpty)
              ? reply
              : 'Hmm, I got an empty response. Please try again. 🤔';

        case 400: return '⚠️ Bad request — message or user ID missing.';
        case 401: return '⚠️ Unauthorized. Check API key configuration.';
        case 500: return '⚠️ Server error. Please try again shortly.';
        case 504: return '⏰ The assistant took too long. Please try again.';
        default:  return '⚠️ Unexpected error (${response.statusCode}).';
      }
    } on SocketException {
      return '📡 No internet connection. Please check your network.';
    } on TimeoutException {
      return '⏰ Request timed out. Please try again.';
    } on Exception catch (e, st) {
      dev.log('[BotBuddy] ✗ exception: $e', stackTrace: st);
      return '⚠️ Connection error: ${e.toString()}';
    }
  }

  // ── POST /api/reset ──────────────────────────────────────
  /// Clears the server-side conversation history for this user.
  static Future<void> resetSession() async {
    try {
      final uid = await _resolveUserId();
      final res = await http.post(
        Uri.parse('$_botUrl/api/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': uid}),
      ).timeout(const Duration(seconds: 10));
      dev.log('[BotBuddy] reset → ${res.statusCode} for user_id=$uid');
    } catch (e) {
      dev.log('[BotBuddy] reset failed: $e');
    }
  }

  // ── GET / (health) ───────────────────────────────────────
  static Future<bool> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('$_botUrl/'))
          .timeout(const Duration(seconds: 10));
      dev.log('[BotBuddy] health → ${res.statusCode}');
      return res.statusCode == 200;
    } catch (e) {
      dev.log('[BotBuddy] health check failed: $e');
      return false;
    }
  }

  // ── UUID fallback generator ──────────────────────────────
  static String _generateUUID() {
    final r = DateTime.now().microsecondsSinceEpoch;
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replaceAllMapped(
      RegExp(r'[xy]'),
      (m) {
        final v = (r + m.start * 16) % 16;
        return (m.group(0) == 'x' ? v : (v & 0x3 | 0x8)).toRadixString(16);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN ENTRY POINT
// ─────────────────────────────────────────────────────────────
class SBHelpScreen extends StatelessWidget {
  const SBHelpScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: SBColors.surface2,
        body: _BotChatView(),
      );
}

// ─────────────────────────────────────────────────────────────
//  CHAT VIEW
// ─────────────────────────────────────────────────────────────
class _BotChatView extends StatefulWidget {
  const _BotChatView();

  @override
  State<_BotChatView> createState() => _BotChatViewState();
}

class _BotChatViewState extends State<_BotChatView> {
  final _ctrl      = TextEditingController();
  final _scroll    = ScrollController();
  final _focusNode = FocusNode();
  bool  _sending   = false;

  late List<_ChatMessage> _messages;

  static const _suggestions = [
    '📐 Explain the chain rule',
    '⚛️ How does osmosis work?',
    '💡 What is Big O notation?',
    '📜 Summarise the Cold War',
    '🐍 How do I use lists in Python?',
    '🧮 Solve for x: 2x + 5 = 15',
  ];

  @override
  void initState() {
    super.initState();
    _messages = [
      _ChatMessage(
        text:   '__intro__',
        sender: _Sender.bot,
        time:   DateTime.now(),
      ),
    ];

    // Pre-fetch user ID and warm up health check in background
    _BotApi._resolveUserId().then((uid) {
      dev.log('[BotBuddy] Screen ready. user_id=$uid');
    });
    _BotApi.checkHealth().then((ok) {
      if (!ok) dev.log('[BotBuddy] ⚠ Backend health check failed');
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Scroll ───────────────────────────────────────────────
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // ── Send ─────────────────────────────────────────────────
  Future<void> _send([String? prefilled]) async {
    final text = (prefilled ?? _ctrl.text).trim();
    if (text.isEmpty || _sending) return;

    HapticFeedback.lightImpact();
    _ctrl.clear();
    _focusNode.unfocus();

    final userMsg   = _ChatMessage(text: text, sender: _Sender.user, time: DateTime.now());
    final typingMsg = _ChatMessage(text: '',   sender: _Sender.bot,  time: DateTime.now(), isTyping: true);

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
      dev.log('[BotBuddy] _send error: $e', stackTrace: st);
      if (!mounted) return;
      setState(() {
        _messages[_messages.length - 1] = typingMsg.copyWith(
          text:     '⚠️ Sorry, something went wrong. Please try again.',
          isTyping: false,
        );
        _sending = false;
      });
    }
    _scrollToBottom();
  }

  // ── Clear (resets both UI and server history) ────────────
  Future<void> _clear() async {
    await _BotApi.resetSession(); // tell backend to clear history for this user
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..add(_ChatMessage(
          text:   '__intro__',
          sender: _Sender.bot,
          time:   DateTime.now(),
        ));
    });
    _scrollToBottom();
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final showSuggestions = _messages.length == 1;

    return Column(children: [
      _buildAppBar(),
      Expanded(
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          itemCount: _messages.length + (showSuggestions ? 1 : 0),
          itemBuilder: (_, i) {
            if (showSuggestions && i == 1) {
              return _SuggestionsRow(suggestions: _suggestions, onTap: _send);
            }
            final idx = showSuggestions && i > 0 ? i - 1 : i;
            final msg = _messages[idx];
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
      _ChatInputBar(
        controller: _ctrl,
        focusNode:  _focusNode,
        sending:    _sending,
        onSend:     _send,
      ),
    ]);
  }

  Widget _buildAppBar() => Container(
    padding: EdgeInsets.only(
      top:    MediaQuery.of(context).padding.top,
      left:   16, right: 16, bottom: 12,
    ),
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
    ),
    child: Row(children: [
      IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: SBColors.text),
        onPressed: () => Navigator.pop(context),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
      const SizedBox(width: 12),
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [SBColors.brand, SBColors.brandDark]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('🤖', style: TextStyle(fontSize: 22))),
      ),
      const SizedBox(width: 12),
      const Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Buddy',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: SBColors.text)),
          Text('AI Study Assistant • Online',
              style: TextStyle(fontSize: 11, color: SBColors.text3)),
        ]),
      ),
      IconButton(
        icon: const Icon(Icons.delete_outline, color: SBColors.text2, size: 22),
        onPressed: _clear,
        tooltip: 'Clear conversation',
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────
//  INTRO CARD
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
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(
        color: SBColors.brand.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6),
      )],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
          child: const Center(child: Text('🤖', style: TextStyle(fontSize: 26))),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Buddy', style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
          Row(children: [
            Container(width: 7, height: 7,
                decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text('Online  ·  AI Study Assistant',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
          ]),
        ]),
      ]),
      const SizedBox(height: 14),
      const Text(
        'Hey there! 👋 I\'m Your Buddy, your personal AI tutor. '
        'Ask me anything — maths, science, history, coding — '
        'and I\'ll explain it clearly, step by step.',
        style: TextStyle(fontSize: 13, color: Colors.white, height: 1.6),
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 6, children: [
        _IntroTag('📖 Explanations'),
        _IntroTag('🔢 Worked Examples'),
        _IntroTag('📚 Study Resources'),
        _IntroTag('✍️ Essay Help'),
        _IntroTag('💻 Code Help'),
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
      color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
  );
}

// ─────────────────────────────────────────────────────────────
//  SUGGESTIONS
// ─────────────────────────────────────────────────────────────
class _SuggestionsRow extends StatelessWidget {
  final List<String> suggestions;
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
      Container(
        width: 30, height: 30,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [SBColors.brand, SBColors.brandDark]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
      ),
      Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: SelectableText(text,
              style: const TextStyle(fontSize: 13, color: SBColors.text, height: 1.6)),
        ),
        const SizedBox(height: 4),
        Text(_fmt(time), style: const TextStyle(fontSize: 10, color: SBColors.text3)),
      ])),
      const SizedBox(width: 48),
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
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [SBColors.brand, SBColors.brandDark]),
              borderRadius: BorderRadius.only(
                topLeft:     Radius.circular(18),
                topRight:    Radius.circular(18),
                bottomLeft:  Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: SelectableText(text,
                style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.6)),
          ),
          const SizedBox(height: 4),
          Text(_fmt(time), style: const TextStyle(fontSize: 10, color: SBColors.text3)),
        ])),
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
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
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
          gradient: const LinearGradient(colors: [SBColors.brand, SBColors.brandDark]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft:     Radius.circular(18),
            topRight:    Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft:  Radius.circular(4),
          ),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final val = ((_anim.value - i / 3)).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Transform.translate(
                  offset: Offset(0, -4 * val),
                  child: Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      color: SBColors.brand.withOpacity(0.5 + 0.5 * val),
                      shape: BoxShape.circle,
                    ),
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

String _fmt(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

// ─────────────────────────────────────────────────────────────
//  INPUT BAR
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
        color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))],
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
            controller:      controller,
            focusNode:       focusNode,
            maxLines:        4,
            minLines:        1,
            textInputAction: TextInputAction.send,
            onSubmitted:     (_) => onSend(),
            style: const TextStyle(fontSize: 14, color: SBColors.text),
            decoration: const InputDecoration(
              hintText:       'Ask Buddy anything...',
              hintStyle:      TextStyle(fontSize: 13, color: SBColors.text3),
              border:         InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              ? const Center(
                  child: SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  ))
              : const Center(
                  child: Icon(Icons.send_rounded, color: Colors.white, size: 20)),
        ),
      ),
    ]),
  );
}