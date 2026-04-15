import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import '../models/eb_constants.dart';
import '../../../core/api_client.dart';

// ─────────────────────────────────────────────────────────────
//  SCREEN — My RSVPs (Updated to use my-rsvps endpoint)
//
//  Route:  /events/my-rsvps
//  No params needed - gets all events user has RSVP'd to
//
//  API endpoints used:
//  GET  /api/v1/events/my-rsvps/    → load user's RSVP'd events
//  POST /api/v1/events/<id>/rsvp/   → update RSVP status
//  DELETE /api/v1/events/<id>/rsvp/ → cancel RSVP
// ─────────────────────────────────────────────────────────────
class EBRsvpScreen extends StatefulWidget {
  final String? eventId; // Optional - if provided, show single event
  
  const EBRsvpScreen({super.key, this.eventId});

  @override
  State<EBRsvpScreen> createState() => _EBRsvpScreenState();
}

class _EBRsvpScreenState extends State<EBRsvpScreen> {
  // ── Load state ────────────────────────────────────────────
  bool _loading = true;
  String? _error;
  
  // For list view (when no eventId provided)
  List<Map<String, dynamic>> _myRsvps = [];
  
  // For single event view (when eventId provided)
  Map<String, dynamic>? _event;
  
  // ── RSVP state ────────────────────────────────────────────
  String? _choice;
  bool _submitting = false;
  String? _confirmedStatus;
  
  // Track which event is being modified (for list view)
  String? _selectedEventId;

  // ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ─────────────────────────────────────────────────────────
  //  Load either my-rsvps list or single event
  // ─────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    if (widget.eventId != null) {
      await _loadEvent();
    } else {
      await _loadMyRsvps();
    }
  }

  // ── GET /api/v1/events/my-rsvps/ ─────────────────────────
  Future<void> _loadMyRsvps({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _error = null; });

    try {
      final res = await ApiClient.get('/api/v1/events/my-rsvps/');
      dev.log('[My RSVPs] GET /events/my-rsvps/ → ${res.statusCode}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final data = json['data'] as List? ?? [];
        
        setState(() {
          _myRsvps = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
        
        dev.log('[My RSVPs] Loaded ${_myRsvps.length} RSVPs');
      } else {
        setState(() {
          _error = 'Could not load your RSVPs (${res.statusCode}).';
          _loading = false;
        });
      }
    } catch (e) {
      dev.log('[My RSVPs] load error: $e');
      if (mounted) {
        setState(() {
          _error = 'Network error. Please try again.';
          _loading = false;
        });
      }
    }
  }

  // ── GET /api/v1/events/<id>/ (existing method) ────────────
  Future<void> _loadEvent({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _error = null; });

    try {
      final res = await ApiClient.get('/api/v1/events/${widget.eventId}/');
      dev.log('[RSVP] GET /events/${widget.eventId}/ → ${res.statusCode}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>? ?? json;
        final existing = data['userRsvp'] as String?;

        setState(() {
          _event = data;
          _loading = false;
          _confirmedStatus = existing;
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
          _error = 'Could not load event (${res.statusCode}).';
          _loading = false;
        });
      }
    } catch (e) {
      dev.log('[RSVP] load error: $e');
      if (mounted) {
        setState(() {
          _error = 'Network error. Please try again.';
          _loading = false;
        });
      }
    }
  }

  // ── POST /api/v1/events/<id>/rsvp/ (existing method) ──────
  Future<void> _submitRsvp({String? specificEventId}) async {
    final eventId = specificEventId ?? widget.eventId;
    if (_choice == null || eventId == null) return;
    
    setState(() => _submitting = true);

    try {
      final res = await ApiClient.post(
        '/api/v1/events/$eventId/rsvp/',
        body: {'status': _choice},
      );

      dev.log('[RSVP] POST /events/$eventId/rsvp/ → ${res.statusCode}');

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (widget.eventId != null) {
          // Single event view - refresh the event
          await _loadEvent(silent: true);
        } else {
          // List view - refresh the entire list
          await _loadMyRsvps(silent: true);
          _snack(_choice == 'going' ? "You're going!" : "Response saved");
          // Reset selection
          setState(() {
            _choice = null;
            _selectedEventId = null;
          });
        }
      } else {
        final body = jsonDecode(res.body) as Map<String, dynamic>?;
        final msg = body?['error']?['message']?.toString()
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

  // ── DELETE /api/v1/events/<id>/rsvp/ (cancel RSVP) ────────
  Future<void> _cancelRsvp(String eventId) async {
    setState(() => _submitting = true);

    try {
      final res = await ApiClient.delete('/api/v1/events/$eventId/rsvp/');
      
      dev.log('[RSVP] DELETE /events/$eventId/rsvp/ → ${res.statusCode}');

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 204) {
        await _loadMyRsvps(silent: true);
        _snack('Removed from event');
      } else {
        _snack('Could not cancel RSVP');
      }
    } catch (e) {
      _snack('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Helper methods ────────────────────────────────────────
  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final m = dt.minute.toString().padLeft(2, '0');
      final ap = dt.hour >= 12 ? 'PM' : 'AM';
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  ·  $h:$m $ap';
    } catch (_) { return iso; }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: EBColors.brand,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showRsvpDialog(Map<String, dynamic> event) {
    final currentStatus = event['userRsvp'] as String?;
    String? tempChoice = currentStatus == 'going' || currentStatus == 'waitlist' 
        ? 'going' 
        : currentStatus == 'not_going' 
            ? 'not_going' 
            : null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'] ?? 'Event',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Update your response?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _RsvpOption(
                    emoji: '✅',
                    label: 'Going',
                    sub: "I'll be there!",
                    selected: tempChoice == 'going',
                    color: const Color(0xFF22C87A),
                    onTap: () => setModalState(() => tempChoice = 'going'),
                  ),
                  const SizedBox(height: 8),
                  _RsvpOption(
                    emoji: '❌',
                    label: "Can't make it",
                    sub: 'Maybe next time',
                    selected: tempChoice == 'not_going',
                    color: const Color(0xFFFF4B6E),
                    onTap: () => setModalState(() => tempChoice = 'not_going'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: tempChoice != null
                              ? () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _choice = tempChoice;
                                    _selectedEventId = event['id'];
                                  });
                                  _submitRsvp(specificEventId: event['id']);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EBColors.brand,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Confirm'),
                        ),
                      ),
                    ],
                  ),
                  if (currentStatus != null) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _cancelRsvp(event['id']);
                        },
                        child: const Text(
                          'Remove RSVP',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EBColors.surface2,
      appBar: AppBar(
        title: Text(widget.eventId != null ? 'Event RSVP' : 'My RSVPs'),
        backgroundColor: EBColors.surface,
        foregroundColor: EBColors.text,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: EBColors.brand))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadData)
              : widget.eventId != null && _event != null
                  ? _buildSingleEventView()
                  : _buildMyRsvpsList(),
    );
  }

  // ── List view of all user's RSVPs ────────────────────────
  Widget _buildMyRsvpsList() {
    if (_myRsvps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 64, color: EBColors.text3),
            const SizedBox(height: 16),
            const Text(
              'No RSVPs yet',
              style: TextStyle(fontSize: 16, color: EBColors.text2),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse events and RSVP to see them here',
              style: TextStyle(fontSize: 13, color: EBColors.text3),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to events list
                Navigator.pushNamed(context, '/events');
              },
              icon: const Icon(Icons.explore),
              label: const Text('Browse Events'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EBColors.brand,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final event = _myRsvps[index];
                final userRsvp = event['userRsvp'] as String?;
                final isGoing = userRsvp == 'going';
                final isWaitlist = userRsvp == 'waitlist';
                final bannerUrl = event['bannerUrl'] as String?;
                
                return GestureDetector(
                  onTap: () => _showRsvpDialog(event),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: EBColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Banner or placeholder
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: bannerUrl != null
                              ? Image.network(
                                  bannerUrl,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 140,
                                    color: EBColors.brandPale,
                                    child: const Center(
                                      child: Text('🎪', style: TextStyle(fontSize: 48)),
                                    ),
                                  ),
                                )
                              : Container(
                                  height: 140,
                                  color: EBColors.brandPale,
                                  child: const Center(
                                    child: Text('🎪', style: TextStyle(fontSize: 48)),
                                  ),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      event['title'] ?? 'Untitled',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: EBColors.text,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isGoing
                                          ? const Color(0xFF22C87A).withOpacity(0.1)
                                          : isWaitlist
                                              ? Colors.orange.withOpacity(0.1)
                                              : const Color(0xFFFF4B6E).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isGoing
                                              ? Icons.check_circle
                                              : isWaitlist
                                                  ? Icons.hourglass_empty
                                                  : Icons.cancel,
                                          size: 14,
                                          color: isGoing
                                              ? const Color(0xFF22C87A)
                                              : isWaitlist
                                                  ? Colors.orange
                                                  : const Color(0xFFFF4B6E),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isGoing
                                              ? 'Going'
                                              : isWaitlist
                                                  ? 'Waitlist'
                                                  : 'Not Going',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isGoing
                                                ? const Color(0xFF22C87A)
                                                : isWaitlist
                                                    ? Colors.orange
                                                    : const Color(0xFFFF4B6E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (event['startAt'] != null) ...[
                                _MetaRow(
                                  icon: Icons.calendar_today_outlined,
                                  text: _fmtDate(event['startAt']),
                                ),
                                const SizedBox(height: 4),
                              ],
                              if (event['location'] != null && event['location'].isNotEmpty) ...[
                                _MetaRow(
                                  icon: Icons.place_outlined,
                                  text: event['location'],
                                ),
                                const SizedBox(height: 4),
                              ],
                              _MetaRow(
                                icon: Icons.people_outline,
                                text: '${event['rsvpCount'] ?? 0}/${event['capacity'] ?? '∞'} going',
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: EBColors.surface2,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.touch_app,
                                      size: 16,
                                      color: EBColors.brand,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Tap to update your response',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: EBColors.text2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: _myRsvps.length,
            ),
          ),
        ),
      ],
    );
  }

  // ── Single event view (original UI) ──────────────────────
  Widget _buildSingleEventView() {
    final ev = _event!;
    final bannerUrl = ev['bannerUrl'] as String? ?? ev['banner_url'] as String?;
    final title = ev['title'] as String? ?? 'Event';
    final startAt = ev['startAt'] as String? ?? ev['start_at'] as String?;
    final location = ev['location'] as String?;
    final description = ev['description'] as String?;
    final rsvpCount = ev['rsvpCount'] as int? ?? ev['rsvp_count'] as int? ?? 0;
    final capacity = ev['capacity'] as int?;
    final isConfirmed = _confirmedStatus != null;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: EBColors.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: EBColors.text),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: EBColors.text,
                  ),
                ),
                const SizedBox(height: 10),
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
                      fontSize: 13,
                      color: EBColors.text,
                      height: 1.7,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                const Divider(color: EBColors.border),
                const SizedBox(height: 20),
                if (!isConfirmed) ...[
                  const Text(
                    'Will you attend?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: EBColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _RsvpOption(
                    emoji: '✅',
                    label: 'Going',
                    sub: "I'll be there!",
                    selected: _choice == 'going',
                    color: const Color(0xFF22C87A),
                    onTap: () => setState(() => _choice = 'going'),
                  ),
                  const SizedBox(height: 8),
                  _RsvpOption(
                    emoji: '❌',
                    label: "Can't make it",
                    sub: 'Maybe next time',
                    selected: _choice == 'not_going',
                    color: const Color(0xFFFF4B6E),
                    onTap: () => setState(() => _choice = 'not_going'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_choice == null || _submitting) ? null : _submitRsvp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EBColors.brand,
                        disabledBackgroundColor: EBColors.brandLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirm RSVP',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ] else ...[
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
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: EBColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_confirmedStatus == 'waitlist') ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3CD),
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
                        TextButton(
                          onPressed: () => setState(() {
                            _confirmedStatus = null;
                          }),
                          child: Text(
                            _confirmedStatus == 'waitlist'
                                ? 'Leave waitlist'
                                : 'Change my response',
                            style: TextStyle(
                              color: EBColors.brand,
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

// ── RSVP OPTION CARD (same as before) ──────────────────────
class _RsvpOption extends StatelessWidget {
  final String emoji;
  final String label;
  final String sub;
  final bool selected;
  final Color color;
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
          color: selected ? color.withOpacity(0.08) : EBColors.surface,
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
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? color : EBColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(fontSize: 11, color: EBColors.text3),
                ),
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

// ── META ROW (same as before) ──────────────────────────────
class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: EBColors.text3),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: TextStyle(fontSize: 13, color: EBColors.text2),
        ),
      ),
    ],
  );
}

// ── ERROR VIEW (same as before) ────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
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
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: EBColors.text2),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: EBColors.brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}