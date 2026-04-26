import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/eb_constants.dart';
import '../widgets/eb_widgets.dart';
import '../../../core/api_client.dart';

// ─────────────────────────────────────────────────────────────
//  SCREEN — Create Event
//
//  API endpoint used:
//  POST /api/v1/events/   → create & publish event
//                           (banner sent as base64 in body,
//                            same pattern as campus market)
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
//  HELPER — encode a file to a data-URI base64 string
//  (mirrors _fileToBase64 in cm_post_screen.dart)
// ─────────────────────────────────────────────────────────────
Future<String> _fileToBase64(File file) async {
  final bytes = await file.readAsBytes();
  final ext   = file.path.split('.').last.toLowerCase();
  final mime  = switch (ext) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png'           => 'image/png',
    'gif'           => 'image/gif',
    'webp'          => 'image/webp',
    _               => 'image/jpeg',
  };
  return 'data:$mime;base64,${base64Encode(bytes)}';
}

class EBCreateEventScreen extends StatefulWidget {
  const EBCreateEventScreen({super.key});

  @override
  State<EBCreateEventScreen> createState() => _EBCreateEventScreenState();
}

class _EBCreateEventScreenState extends State<EBCreateEventScreen> {
  // ── Form state ────────────────────────────────────────────
  String _category   = 'academic';
  String _mode       = 'In-Person';
  bool   _publishing = false;

  // Banner — single File reference + encoded base64 data-URI.
  // _bannerFile    : kept for local display via Image.file()
  // _bannerBase64  : data-URI sent directly in the POST body,
  //                  same way market listings send image_data.
  //                  null → no banner selected yet.
  File?   _bannerFile;
  String? _bannerBase64;
  bool    _pickingBanner = false;

  // Date/time
  DateTime? _startAt;
  DateTime? _endAt;

  final _titleCtrl    = TextEditingController();
  final _venueCtrl    = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _descCtrl     = TextEditingController();

  // ── Category options ──────────────────────────────────────
  static const _cats = [
    ('📚', 'academic', 'Academic'),
    ('🎵', 'social',   'Social'),
    ('⚽', 'sports',   'Sports'),
    ('🛠',  'career',   'Career'),
    ('🎭', 'other',    'Other'),
  ];

  // ── Event mode options ────────────────────────────────────
  static const _modes = ['In-Person', 'Online', 'Hybrid'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _venueCtrl.dispose();
    _capacityCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  //  BANNER — pick from gallery and encode to base64.
  //
  //  No separate upload API call is made here.
  //  The data-URI is stored and sent as `banner_image` when
  //  the user taps Publish — identical to how the market
  //  screen sends `image_data` for listing images.
  // ─────────────────────────────────────────────────────────
  Future<void> _pickBanner() async {
    HapticFeedback.selectionClick();
    setState(() => _pickingBanner = true);

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source:       ImageSource.gallery,
        maxWidth:     1920,
        maxHeight:    1080,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      final file     = File(picked.path);
      final dataUri  = await _fileToBase64(file);

      setState(() {
        _bannerFile   = file;
        _bannerBase64 = dataUri;
      });
    } catch (e) {
      dev.log('[Banner] pick error: $e');
      if (mounted) _snack('Could not pick image. Please try again.');
    } finally {
      if (mounted) setState(() => _pickingBanner = false);
    }
  }

  void _removeBanner() => setState(() {
    _bannerFile   = null;
    _bannerBase64 = null;
  });

  // ─────────────────────────────────────────────────────────
  //  DATE / TIME PICKERS
  // ─────────────────────────────────────────────────────────
  Future<void> _pickDateTime({required bool isStart}) async {
    final now  = DateTime.now();
    final init = isStart
        ? (_startAt ?? now)
        : (_endAt   ?? (_startAt?.add(const Duration(hours: 2)) ?? now));

    final date = await showDatePicker(
      context:     context,
      initialDate: init,
      firstDate:   now,
      lastDate:    now.add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary:   EBColors.brand,
            onPrimary: Colors.white,
            surface:   EBColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context:     context,
      initialTime: TimeOfDay.fromDateTime(init),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary:   EBColors.brand,
            onPrimary: Colors.white,
            surface:   EBColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    final combined = DateTime(
      date.year, date.month, date.day,
      time.hour, time.minute,
    );

    setState(() {
      if (isStart) {
        _startAt = combined;
        if (_endAt != null && _endAt!.isBefore(combined)) _endAt = null;
      } else {
        _endAt = combined;
      }
    });
  }

  String _fmtDateTime(DateTime? dt) {
    if (dt == null) return 'Pick date & time';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h  = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m  = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  ·  $h:$m $ap';
  }

  // ─────────────────────────────────────────────────────────
  //  PUBLISH — POST /api/v1/events/
  //
  //  banner_image is a base64 data-URI string, sent directly
  //  in the body — no separate upload endpoint, no CDN URL
  //  needed.  Backend decodes and stores it.
  //
  //  Payload shape:
  //  {
  //    "title":        string,
  //    "category":     string,
  //    "mode":         string,
  //    "start_at":     ISO-8601,
  //    "end_at":       ISO-8601 | omitted,
  //    "location":     string   | omitted,
  //    "capacity":     int      | omitted,
  //    "banner_url":   "data:image/jpeg;base64,…" | omitted,
  //    "description":  string   | omitted,
  //  }
  // ─────────────────────────────────────────────────────────
  Future<void> _publish() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty)    { _snack('Please enter an event title.');      return; }
    if (_startAt == null) { _snack('Please pick a start date & time.'); return; }

    if (_endAt != null && !_endAt!.isAfter(_startAt!)) {
      _snack('End time must be after start time.');
      return;
    }

    setState(() => _publishing = true);

    try {
      final body = <String, dynamic>{
        'title':    title,
        'category': _category,
        'mode':     _mode.toLowerCase(),
        'start_at': _startAt!.toUtc().toIso8601String(),
        if (_endAt != null)
          'end_at': _endAt!.toUtc().toIso8601String(),
        if (_venueCtrl.text.trim().isNotEmpty)
          'location': _venueCtrl.text.trim(),
        if (_capacityCtrl.text.trim().isNotEmpty)
          'capacity': int.tryParse(_capacityCtrl.text.trim()),
        // Banner as base64 data-URI — same pattern as market's image_data.
        // Field name kept as banner_url to match the existing backend contract.
        // Omitted entirely when no banner was selected.
        if (_bannerBase64 != null)
          'banner_url': _bannerBase64,
        if (_descCtrl.text.trim().isNotEmpty)
          'description': _descCtrl.text.trim(),
      };

      dev.log('[CreateEvent] POST /events/ payload keys: ${body.keys}');

      final res = await ApiClient.post('/api/v1/events/', body: body);

      dev.log('[CreateEvent] POST /events/ → ${res.statusCode}');
      dev.log('[CreateEvent] body: ${res.body}');

      if (!mounted) return;

      if (res.statusCode == 201 || res.statusCode == 200) {
        final json      = jsonDecode(res.body) as Map<String, dynamic>;
        final eventData = json['data'] as Map<String, dynamic>? ?? json;
        final eventId   = eventData['id']?.toString() ?? '';

        _showRsvpSheet(eventId: eventId, eventTitle: title);
      } else {
        final respBody = jsonDecode(res.body) as Map<String, dynamic>?;
        final errBlock = respBody?['error'] as Map<String, dynamic>?;
        final msg      = errBlock?['message']?.toString()
                      ?? respBody?['detail']?.toString()
                      ?? respBody?['message']?.toString()
                      ?? 'Could not publish event (${res.statusCode}).';
        _snack(msg);
      }
    } catch (e) {
      dev.log('[CreateEvent] error: $e');
      if (mounted) _snack('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  RSVP SHEET
  // ─────────────────────────────────────────────────────────
  void _showRsvpSheet({required String eventId, required String eventTitle}) {
    const appBase = 'https://eventboard.app';
    final rsvpUrl = '$appBase/events/$eventId/rsvp/';

    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _RsvpShareSheet(
        eventTitle: eventTitle,
        rsvpUrl:    rsvpUrl,
        onDone: () {
          Navigator.pop(context);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:         Text('✅ Event published!'),
              backgroundColor: EBColors.brand,
            ),
          );
        },
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content:         Text(msg),
        backgroundColor: EBColors.brand,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EBColors.surface2,
      appBar: AppBar(
        backgroundColor: EBColors.surface,
        elevation:       0,
        leading: IconButton(
          icon:      const Icon(Icons.close, color: EBColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Event',
          style: TextStyle(
            fontSize:   16,
            fontWeight: FontWeight.w800,
            color:      EBColors.text,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _publishing ? null : _publish,
            child: _publishing
                ? const SizedBox(
                    width:  18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color:       EBColors.brand,
                    ),
                  )
                : const Text(
                    'Publish',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color:      EBColors.brand,
                    ),
                  ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: EBColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Intro ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Text(
                'Create an event and invite your community 🎉',
                style: TextStyle(fontSize: 13, color: EBColors.text2),
              ),
            ),

            // ── Banner picker ──────────────────────────
            _BannerPickerTile(
              bannerFile: _bannerFile,
              picking:    _pickingBanner,
              onPick:     _pickingBanner ? null : _pickBanner,
              onRemove:   _removeBanner,
            ),

            // ── Title ──────────────────────────────────
            _SectionLabel('Event Details'),
            _FormInput(
              label:      'Event Title *',
              hint:       'e.g. Annual Science Fair 2026',
              controller: _titleCtrl,
            ),

            // ── Category ───────────────────────────────
            _SectionLabel('Category'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8, runSpacing: 8,
                children: _cats.map((c) {
                  final selected = _category == c.$2;
                  return _CategoryChip(
                    emoji:    c.$1,
                    label:    c.$3,
                    selected: selected,
                    onTap:    () => setState(() => _category = c.$2),
                  );
                }).toList(),
              ),
            ),

            // ── Date & Time ────────────────────────────
            _SectionLabel('Date & Time'),
            _DateTimeTile(
              label:   'Starts',
              icon:    Icons.calendar_today_outlined,
              value:   _fmtDateTime(_startAt),
              isEmpty: _startAt == null,
              onTap:   () => _pickDateTime(isStart: true),
            ),
            const SizedBox(height: 8),
            _DateTimeTile(
              label:   'Ends',
              icon:    Icons.access_time_outlined,
              value:   _fmtDateTime(_endAt),
              isEmpty: _endAt == null,
              onTap:   () => _pickDateTime(isStart: false),
            ),
            const SizedBox(height: 4),

            // ── Venue ──────────────────────────────────
            _SectionLabel('Location'),
            _FormInput(
              label:      'Venue',
              hint:       'e.g. Innovation Hub, UoN',
              controller: _venueCtrl,
            ),

            // ── Event mode ─────────────────────────────
            _SectionLabel('Event Mode'),
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection:  Axis.horizontal,
                padding:          const EdgeInsets.symmetric(horizontal: 16),
                itemCount:        _modes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 7),
                itemBuilder: (_, i) => EBChip(
                  label:  _modes[i],
                  active: _mode == _modes[i],
                  onTap:  () => setState(() => _mode = _modes[i]),
                ),
              ),
            ),

            // ── Capacity ───────────────────────────────
            _SectionLabel('Capacity'),
            _FormInput(
              label:           'Max Attendees (optional)',
              hint:            'e.g. 150',
              controller:      _capacityCtrl,
              keyboardType:    TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),

            // ── Description ────────────────────────────
            _FormInput(
              label:      'Description',
              hint:       'Describe the event, what attendees can expect…',
              controller: _descCtrl,
              multiline:  true,
            ),

            const SizedBox(height: 6),

            // ── Auto-reminder notice ────────────────────
            Container(
              margin:  const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        EBColors.brandPale,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: EBColors.brandLight, width: 1.5),
              ),
              child: Row(children: [
                const Text('🔔', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-reminders enabled',
                      style: TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w700,
                        color:      EBColors.brand,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Attendees get 24h and 1h reminders automatically.',
                      style: TextStyle(fontSize: 11, color: EBColors.text2),
                    ),
                  ],
                )),
              ]),
            ),

            // ── Publish button ─────────────────────────
            EBPrimaryButton(
              label: _publishing ? 'Publishing…' : '🎉 Publish Event',
              onTap: _publishing ? null : _publish,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BANNER PICKER TILE
//
//  Shows the picked image via Image.file() (no base64 decode
//  needed for display — that's what the File is for).
//  The remove (×) button mirrors the image remove pattern
//  used in CMCreateListingScreen.
// ─────────────────────────────────────────────────────────────
class _BannerPickerTile extends StatelessWidget {
  final File?        bannerFile;
  final bool         picking;
  final VoidCallback? onPick;
  final VoidCallback  onRemove;

  const _BannerPickerTile({
    required this.bannerFile,
    required this.picking,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: onPick,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height:   110,
              decoration: BoxDecoration(
                color:        bannerFile != null ? null : EBColors.brandPale,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: bannerFile != null
                      ? EBColors.brand
                      : EBColors.brandLight,
                  width: 1.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: picking
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width:  22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color:       EBColors.brand,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Loading image…',
                            style: TextStyle(
                              fontSize:   12,
                              color:      EBColors.brand,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : bannerFile != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(bannerFile!, fit: BoxFit.cover),
                            // Dark overlay + "change" label
                            Container(
                              color: Colors.black.withOpacity(0.35),
                              child: const Center(
                                child: Text(
                                  '✏️  Change banner',
                                  style: TextStyle(
                                    fontSize:   13,
                                    fontWeight: FontWeight.w700,
                                    color:      Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🖼', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 10),
                            Column(
                              mainAxisSize:       MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upload Event Banner',
                                  style: TextStyle(
                                    fontSize:   13,
                                    fontWeight: FontWeight.w700,
                                    color:      EBColors.brand,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'JPG, PNG · max 20 MB',
                                  style: TextStyle(
                                    fontSize: 11, color: EBColors.text3),
                                ),
                              ],
                            ),
                          ],
                        ),
            ),
          ),

          // Remove button — only visible when a banner is picked.
          // Mirrors the × button on market image thumbnails.
          if (bannerFile != null && !picking)
            Positioned(
              top:   -6,
              right: -6,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width:  22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(
                    Icons.close_rounded, size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  RSVP SHARE SHEET  (unchanged)
// ─────────────────────────────────────────────────────────────
class _RsvpShareSheet extends StatefulWidget {
  final String       eventTitle;
  final String       rsvpUrl;
  final VoidCallback onDone;

  const _RsvpShareSheet({
    required this.eventTitle,
    required this.rsvpUrl,
    required this.onDone,
  });

  @override
  State<_RsvpShareSheet> createState() => _RsvpShareSheetState();
}

class _RsvpShareSheetState extends State<_RsvpShareSheet> {
  bool _copied = false;

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.rsvpUrl));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color:        EBColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width:  36,
            height: 4,
            decoration: BoxDecoration(
              color:        EBColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text('🎉', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text(
            'Event Published!',
            style: TextStyle(
              fontSize:   20,
              fontWeight: FontWeight.w800,
              color:      EBColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Share this RSVP link with your community',
            style: TextStyle(fontSize: 13, color: EBColors.text2),
          ),
          const SizedBox(height: 20),

          // QR code
          Container(
            padding:    const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        EBColors.surface2,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data:            widget.rsvpUrl,
              version:         QrVersions.auto,
              size:            160,
              backgroundColor: EBColors.surface2,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color:    EBColors.text,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color:           EBColors.text,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Copyable link
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color:        EBColors.brandPale,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EBColors.brandLight, width: 1.5),
            ),
            child: Row(children: [
              Expanded(
                child: Text(
                  widget.rsvpUrl,
                  style: TextStyle(
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                    color:      EBColors.brand,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _copyLink,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:        _copied ? EBColors.brand : EBColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: EBColors.brandLight, width: 1.5),
                  ),
                  child: Text(
                    _copied ? '✓ Copied' : 'Copy',
                    style: TextStyle(
                      fontSize:   11,
                      fontWeight: FontWeight.w700,
                      color:      _copied ? Colors.white : EBColors.brand,
                    ),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: EBColors.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DATE / TIME TILE  (unchanged)
// ─────────────────────────────────────────────────────────────
class _DateTimeTile extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final String       value;
  final bool         isEmpty;
  final VoidCallback onTap;

  const _DateTimeTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.isEmpty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:        EBColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEmpty ? EBColors.border : EBColors.brand,
              width: isEmpty ? 1.5 : 2,
            ),
          ),
          child: Row(children: [
            Icon(icon,
              size:  18,
              color: isEmpty ? EBColors.text3 : EBColors.brand),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize:      10,
                    fontWeight:    FontWeight.w700,
                    color:         EBColors.text3,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                    color:      isEmpty ? EBColors.text3 : EBColors.text,
                  ),
                ),
              ],
            )),
            Icon(Icons.chevron_right,
              size:  18,
              color: isEmpty ? EBColors.text3 : EBColors.brand),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CATEGORY CHIP  (unchanged)
// ─────────────────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String       emoji;
  final String       label;
  final bool         selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color:        selected ? EBColors.brand : EBColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? EBColors.brand : EBColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w700,
                color:      selected ? Colors.white : EBColors.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SECTION LABEL  (unchanged)
// ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
    child: Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize:      11,
        fontWeight:    FontWeight.w700,
        color:         EBColors.text3,
        letterSpacing: 0.8,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  FORM INPUT  (unchanged)
// ─────────────────────────────────────────────────────────────
class _FormInput extends StatelessWidget {
  final String                    label;
  final String                    hint;
  final TextEditingController     controller;
  final bool                      multiline;
  final TextInputType             keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _FormInput({
    required this.label,
    required this.hint,
    required this.controller,
    this.multiline        = false,
    this.keyboardType     = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w700,
              color:      EBColors.text2,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller:      controller,
            keyboardType:    keyboardType,
            maxLines:        multiline ? 4 : 1,
            inputFormatters: inputFormatters,
            style: TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w600,
              color:      EBColors.text,
            ),
            decoration: InputDecoration(
              hintText:  hint,
              hintStyle: TextStyle(fontSize: 13, color: EBColors.text3),
              filled:    true,
              fillColor: EBColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:   BorderSide(color: EBColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:   BorderSide(color: EBColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: EBColors.brand, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}