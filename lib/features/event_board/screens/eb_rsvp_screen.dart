import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import '../models/eb_constants.dart';
import '../../../core/api_client.dart';

// ─────────────────────────────────────────────────────────────
//  SCREEN — Event RSVP
//
//  Route:  /events/:eventId/rsvp
//  Params: eventId (String UUID)
//
//  API endpoints used:
//  GET  /api/v1/events/<id>/          → load event details
//  POST /api/v1/events/<id>/rsvp/     → submit RSVP
//                                       (re-fetches after to get
//                                        actual status incl. waitlist)
// ─────────────────────────────────────────────────────────────
class EBRsvpScreen extends StatefulWidget {
  final String eventId;

  const EBRsvpScreen({super.key, required this.eventId});

  @override
  State<EBRsvpScreen> createState() => _EBRsvpScreenState();
}

class _EBRsvpScreenState extends State<EBRsvpScreen> {
  // ── Load state ────────────────────────────────────────────
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _event;

  // ── RSVP state ────────────────────────────────────────────
  // The user's current CHOICE before confirming: 'going' | 'not_going' | null
  String? _choice;
  bool _submitting = false;

  // The CONFIRMED status returned by the server after re-fetch:
  // 'going' | 'not_going' | 'waitlist' | null (not yet submitted)
  String? _confirmedStatus;

  // ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  // ─────────────────────────────────────────────────────────
  //  GET /api/v1/events/<id>/
  //
  //  Called on init AND after a successful POST so the count
  //  and real rsvp status (incl. waitlist) are always fresh.
  // ─────────────────────────────────────────────────────────
  Future<void> _loadEvent({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _error = null; });

    try {
      final res = await ApiClient.get('/api/v1/events/${widget.eventId}/');
      dev.log('[RSVP] GET /events/${widget.eventId}/ → ${res.statusCode}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        // Server: { success: true, data: { ...event, userRsvp: "going"|"waitlist"|"not_going"|null } }
        final data = json['data'] as Map<String, dynamic>? ?? json;
        final existing = data['userRsvp'] as String?;

        setState(() {
          _event           = data;
          _loading         = false;
          _confirmedStatus = existing; // null | 'going' | 'not_going' | 'waitlist'
          // Pre-populate choice so "Change my response" restores the last selection.
          // Waitlist counts as wanting to go, so mirror that.
          if (existing == 'going' || existing == 'waitlist') {
            _choice = 'going';
          } else if (existing == 'not_going') {
            _choice = 'not_going';
          } else {
            _choice = null;
          }
        });
      } else {
        setState(() {
          _error   = 'Could not load event (${res.statusCode}).';
          _loading = false;
        });
      }
    } catch (e) {
      dev.log('[RSVP] load error: $e');
      if (mounted) {
        setState(() {
          _error   = 'Network error. Please try again.';
          _loading = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  //  POST /api/v1/events/<id>/rsvp/
  //
  //  Body: { "status": "going" | "not_going" }
  //
  //  After a 200/201 we re-fetch the event so that:
  //    • rsvpCount is accurate
  //    • userRsvp reflects the REAL status the backend assigned
  //      (e.g. "waitlist" when capacity was full)
  // ─────────────────────────────────────────────────────────
  Future<void> _submitRsvp() async {
    if (_choice == null) return;
    setState(() => _submitting = true);

    try {
      final res = await ApiClient.post(
        '/api/v1/events/${widget.eventId}/rsvp/',
        body: {'status': _choice},
      );

      dev.log('[RSVP] POST /events/${widget.eventId}/rsvp/ → ${res.statusCode}');

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        // Re-fetch to get the real confirmed status + updated rsvpCount.
        await _loadEvent(silent: true);
      } else {
        final body = jsonDecode(res.body) as Map<String, dynamic>?;
        final msg  = body?['error']?['message']?.toString()
            ?? body?['detail']?.toString()
            ?? 'Could not save RSVP (${res.statusCode}).';
        _snack(msg);
      }
    } catch (e) {
      if (mounted) _snack('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ─────────────────────────────────────────────────────────
  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt     = DateTime.parse(iso).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
      final h  = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final m  = dt.minute.toString().padLeft(2, '0');
      final ap = dt.hour >= 12 ? 'PM' : 'AM';
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  ·  $h:$m $ap';
    } catch (_) { return iso; }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg),
      backgroundColor: EBColors.brand,
      behavior:        SnackBarBehavior.floating,
    ));
  }

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EBColors.surface2,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: EBColors.brand))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadEvent)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final ev = _event!;
    final bannerUrl   = ev['bannerUrl']   as String? ?? ev['banner_url']   as String?;
    final title       = ev['title']       as String? ?? 'Event';
    final startAt     = ev['startAt']     as String? ?? ev['start_at']     as String?;
    final location    = ev['location']    as String?;
    final description = ev['description'] as String?;
    final rsvpCount   = ev['rsvpCount']   as int?    ?? ev['rsvp_count']   as int? ?? 0;
    final capacity    = ev['capacity']    as int?;

    // True once the user has a confirmed server-side status.
    final bool isConfirmed = _confirmedStatus != null;

    return CustomScrollView(
      slivers: [
        // ── Hero banner ──────────────────────────────────
        SliverAppBar(
          expandedHeight:  220,
          pinned:          true,
          backgroundColor: EBColors.surface,
          leading: IconButton(
            icon:  const Icon(Icons.arrow_back, color: EBColors.text),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: bannerUrl != null
                ? (bannerUrl.startsWith('data:')
                    ? Image.memory(
                        base64Decode(bannerUrl.split(',')[1]),
                        fit: BoxFit.cover,
                      )
                    : Image.network(bannerUrl, fit: BoxFit.cover))
                : Container(
                    color: EBColors.brandPale,
                    child: const Center(
                      child: Text('🎪', style: TextStyle(fontSize: 64)),
                    ),
                  ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Title ────────────────────────────────
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: EBColors.text,
                  ),
                ),
                const SizedBox(height: 10),

                // ── Meta rows ────────────────────────────
                if (startAt != null) ...[
                  _MetaRow(icon: Icons.calendar_today_outlined, text: _fmtDate(startAt)),
                  const SizedBox(height: 6),
                ],
                if (location != null && location.isNotEmpty) ...[
                  _MetaRow(icon: Icons.place_outlined, text: location),
                  const SizedBox(height: 6),
                ],
                _MetaRow(
                  icon: Icons.people_outline,
                  text: capacity != null
                      ? '$rsvpCount / $capacity going'
                      : '$rsvpCount going',
                ),

                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13, color: EBColors.text, height: 1.7,
                    ),
                  ),
                ],

                const SizedBox(height: 28),
                const Divider(color: EBColors.border),
                const SizedBox(height: 20),

                // ── RSVP section ─────────────────────────
                if (!isConfirmed) ...[
                  // ── Selection UI ─────────────────────
                  const Text(
                    'Will you attend?',
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: EBColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _RsvpOption(
                    emoji:    '✅',
                    label:    'Going',
                    sub:      "I'll be there!",
                    selected: _choice == 'going',
                    color:    const Color(0xFF22C87A),
                    onTap:    () => setState(() => _choice = 'going'),
                  ),
                  const SizedBox(height: 8),
                  _RsvpOption(
                    emoji:    '❌',
                    label:    "Can't make it",
                    sub:      'Maybe next time',
                    selected: _choice == 'not_going',
                    color:    const Color(0xFFFF4B6E),
                    onTap:    () => setState(() => _choice = 'not_going'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_choice == null || _submitting) ? null : _submitRsvp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:         EBColors.brand,
                        disabledBackgroundColor: EBColors.brandLight,
                        foregroundColor:         Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirm RSVP',
                              style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),

                ] else ...[
                  // ── Confirmed state ───────────────────
                  //  Handles: 'going' | 'waitlist' | 'not_going'
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _confirmedStatus == 'going'
                              ? '🎉'
                              : _confirmedStatus == 'waitlist'
                                  ? '⏳'
                                  : '👋',
                          style: const TextStyle(fontSize: 52),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _confirmedStatus == 'going'
                              ? "You're going!"
                              : _confirmedStatus == 'waitlist'
                                  ? "You're on the waitlist"
                                  : "Maybe next time",
                          style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800, color: EBColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // ── Waitlist gets an extra explanation chip ──
                        if (_confirmedStatus == 'waitlist') ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:        const Color(0xFFFFF3CD),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFFD966)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.info_outline,
                                    size: 15, color: Color(0xFF856404)),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    "This event is full. We'll notify you if a spot opens up.",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF856404),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Text(
                            _confirmedStatus == 'going'
                                ? "You're confirmed. See you at the event!"
                                : "Your response has been saved.",
                            style: TextStyle(fontSize: 13, color: EBColors.text2),
                            textAlign: TextAlign.center,
                          ),
                        ],

                        const SizedBox(height: 20),
                        // Allow changing mind (not shown for waitlist — user
                        // already expressed intent to go; they can cancel via
                        // posting 'not_going' which removes them from the list)
                        TextButton(
                          onPressed: () => setState(() {
                            _confirmedStatus = null;
                            // _choice already mirrors the last intent, keep it
                          }),
                          child: Text(
                            _confirmedStatus == 'waitlist'
                                ? 'Leave waitlist'
                                : 'Change my response',
                            style: TextStyle(
                              color:      EBColors.brand,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  RSVP OPTION CARD
// ─────────────────────────────────────────────────────────────
class _RsvpOption extends StatelessWidget {
  final String       emoji;
  final String       label;
  final String       sub;
  final bool         selected;
  final Color        color;
  final VoidCallback onTap;

  const _RsvpOption({
    required this.emoji,
    required this.label,
    required this.sub,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:        selected ? color.withOpacity(0.08) : EBColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : EBColors.border,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: selected ? color : EBColors.text,
                )),
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(fontSize: 11, color: EBColors.text3)),
              ],
            ),
            const Spacer(),
            if (selected)
              Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  META ROW
// ─────────────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: EBColors.text3),
      const SizedBox(width: 6),
      Expanded(
        child: Text(text, style: TextStyle(fontSize: 13, color: EBColors.text2)),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────
//  ERROR VIEW
// ─────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: EBColors.text2)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: EBColors.brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}