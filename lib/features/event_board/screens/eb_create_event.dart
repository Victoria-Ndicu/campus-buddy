import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import '../models/eb_constants.dart';
import '../widgets/eb_widgets.dart';
import '../../../core/api_client.dart';

// ─────────────────────────────────────────────────────────────
//  SCREEN — Create Event
//
//  API endpoints used:
//  POST /api/v1/events/uploads/banner/  → upload banner (multipart)
//  POST /api/v1/events/                 → create & publish event
// ─────────────────────────────────────────────────────────────
class EBCreateEventScreen extends StatefulWidget {
  const EBCreateEventScreen({super.key});

  @override
  State<EBCreateEventScreen> createState() => _EBCreateEventScreenState();
}

class _EBCreateEventScreenState extends State<EBCreateEventScreen> {
  // ── Form state ────────────────────────────────────────────
  String  _category      = 'academic';
  String  _mode          = 'In-Person';
  bool    _publishing    = false;

  // Banner
  String? _bannerBase64;       // local preview (data URI)
  String? _bannerUrl;          // returned by upload endpoint (or base64 fallback)
  bool    _bannerUploading = false;

  // Date/time (stored as DateTime, displayed formatted)
  DateTime? _startAt;
  DateTime? _endAt;

  final _titleCtrl    = TextEditingController();
  final _venueCtrl    = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _descCtrl     = TextEditingController();

  // ── Category options ─────────────────────────────────────
  static const _cats = [
    ('📚', 'academic',  'Academic'),
    ('🎵', 'social',    'Social'),
    ('⚽', 'sports',    'Sports'),
    ('🛠',  'career',    'Career'),
    ('🎭', 'other',     'Other'),
  ];

  // ── Event mode options ───────────────────────────────────
  static const _modes = ['In-Person', 'Online', 'Hybrid'];

  // ─────────────────────────────────────────────────────────
  @override
  void dispose() {
    _titleCtrl.dispose();
    _venueCtrl.dispose();
    _capacityCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  //  BANNER — POST /api/v1/events/uploads/banner/
  //
  //  Flow:
  //  1. Open image picker
  //  2. Read file as bytes → base64 (for local preview)
  //  3. POST multipart to upload endpoint using ApiClient.uploadMultipart()
  //  4. Store returned URL in _bannerUrl
  //  5. If upload fails, fall back to base64 data URI
  // ─────────────────────────────────────────────────────────
  Future<void> _pickBanner() async {
    final picker = ImagePicker();
    final file   = await picker.pickImage(
      source:     ImageSource.gallery,
      maxWidth:   1920,
      maxHeight:  1080,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes  = await file.readAsBytes();
    final base64 = base64Encode(bytes);
    final ext    = file.name.split('.').last.toLowerCase();
    final mime   = ext == 'png' ? 'image/png' : 'image/jpeg';
    final dataUri = 'data:$mime;base64,$base64';

    setState(() {
      _bannerBase64    = dataUri;
      _bannerUploading = true;
    });

    try {
      // Use the new uploadMultipart method from ApiClient
      final response = await ApiClient.uploadMultipart(
        '/api/v1/events/uploads/banner/',
        files: [
          await http.MultipartFile.fromBytes(
            'file',  // field name expected by your backend
            bytes,
            filename: file.name,
          ),
        ],
        requiresAuth: true,
      );

      dev.log('[Banner] POST /uploads/banner/ → ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        // Try to get URL from different possible response formats
        _bannerUrl = body['data']?['bannerUrl'] as String? 
                     ?? body['bannerUrl'] as String?
                     ?? body['url'] as String?
                     ?? dataUri;
      } else {
        // Fallback: store base64 directly as banner_url
        // The DB banner_url URLField(max_length=500) accepts data URIs
        _bannerUrl = dataUri;
        dev.log('[Banner] upload failed (${response.statusCode}), using base64 fallback');
      }
    } catch (e) {
      _bannerUrl = dataUri;
      dev.log('[Banner] network error: $e — using base64 fallback');
    } finally {
      if (mounted) setState(() => _bannerUploading = false);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  DATE / TIME PICKERS
  // ─────────────────────────────────────────────────────────
  Future<void> _pickDateTime({required bool isStart}) async {
    final now  = DateTime.now();
    final init = isStart
        ? (_startAt ?? now)
        : (_endAt   ?? (_startAt?.add(const Duration(hours: 2)) ?? now));

    // Calendar
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
    if (date == null) return;

    // Clock
    if (!mounted) return;
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
        // Auto-advance end date if it's now before start
        if (_endAt != null && _endAt!.isBefore(combined)) _endAt = null;
      } else {
        _endAt = combined;
      }
    });
  }

  String _fmtDateTime(DateTime? dt) {
    if (dt == null) return 'Pick date & time';
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final h  = dt.hour   > 12  ? dt.hour   - 12  : (dt.hour   == 0 ? 12 : dt.hour);
    final m  = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  ·  $h:$m $ap';
  }

  // ─────────────────────────────────────────────────────────
  //  PUBLISH — POST /api/v1/events/
  //
  //  Payload matches CreateEventSerializer fields exactly.
  //  campus_id has been removed from model & serializer.
  // ─────────────────────────────────────────────────────────
  Future<void> _publish() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) { _snack('Please enter an event title.'); return; }
    if (_startAt == null) { _snack('Please pick a start date & time.'); return; }

    // Validate end date is after start
    if (_endAt != null && !_endAt!.isAfter(_startAt!)) {
      _snack('End time must be after start time.');
      return;
    }

    setState(() => _publishing = true);

    try {
      final body = <String, dynamic>{
        'title':       title,
        'category':    _category,
        'mode':        _mode.toLowerCase(),  // add mode field
        // ISO 8601 — Django DateTimeField accepts this directly
        'start_at':    _startAt!.toUtc().toIso8601String(),
        if (_endAt != null)
          'end_at':    _endAt!.toUtc().toIso8601String(),
        if (_venueCtrl.text.trim().isNotEmpty)
          'location':  _venueCtrl.text.trim(),
        if (_capacityCtrl.text.trim().isNotEmpty)
          'capacity':  int.tryParse(_capacityCtrl.text.trim()),
        if (_bannerUrl != null)
          'banner_url': _bannerUrl,
        if (_descCtrl.text.trim().isNotEmpty)
          'description': _descCtrl.text.trim(),
      };

      final res = await ApiClient.post('/api/v1/events/', body: body);
      dev.log('[CreateEvent] POST /events/ → ${res.statusCode}');

      if (!mounted) return;

      if (res.statusCode == 201 || res.statusCode == 200) {
        final json      = jsonDecode(res.body) as Map<String, dynamic>;
        final eventData = json['data'] as Map<String, dynamic>? ?? json;
        final eventId   = eventData['id']?.toString() ?? '';

        // Show RSVP sheet with QR + link
        _showRsvpSheet(eventId: eventId, eventTitle: title);
      } else {
        final body     = jsonDecode(res.body) as Map<String, dynamic>?;
        final errBlock = body?['error'] as Map<String, dynamic>?;
        final msg      = errBlock?['message']?.toString()
            ?? body?['detail']?.toString()
            ?? body?['message']?.toString()
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
  //  RSVP SHEET — QR code + shareable link
  //
  //  RSVP URL format:  https://<host>/events/<eventId>/rsvp/
  //  This matches the Django route: <uuid:pk>/rsvp/
  // ─────────────────────────────────────────────────────────
  void _showRsvpSheet({required String eventId, required String eventTitle}) {
    // Build the deep-link / web URL attendees use to RSVP
    // Replace with your actual app domain or use a universal link
    const appBase = 'https://eventboard.app';
    final rsvpUrl = '$appBase/events/$eventId/rsvp/';

    showModalBottomSheet(
      context:        context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RsvpShareSheet(
        eventTitle: eventTitle,
        rsvpUrl:    rsvpUrl,
        onDone: () {
          Navigator.pop(context);  // close sheet
          Navigator.pop(context);  // pop create screen
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

  // ─────────────────────────────────────────────────────────
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content:         Text(msg),
        backgroundColor: EBColors.brand,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
                    width: 18, height: 18,
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

            // ── Intro ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Text(
                'Create an event and invite your community 🎉',
                style: TextStyle(fontSize: 13, color: EBColors.text2),
              ),
            ),

            // ── Banner upload ────────────────────────────
            _BannerUploadTile(
              base64:    _bannerBase64,
              uploading: _bannerUploading,
              onTap:     _pickBanner,
            ),

            // ── Title ────────────────────────────────────
            _SectionLabel('Event Details'),
            _FormInput(
              label:      'Event Title *',
              hint:       'e.g. Annual Science Fair 2026',
              controller: _titleCtrl,
            ),

            // ── Category ─────────────────────────────────
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

            // ── Date & Time ──────────────────────────────
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

            // ── Venue ────────────────────────────────────
            _SectionLabel('Location'),
            _FormInput(
              label:      'Venue',
              hint:       'e.g. Innovation Hub, UoN',
              controller: _venueCtrl,
            ),

            // ── Event mode ───────────────────────────────
            _SectionLabel('Event Mode'),
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:         const EdgeInsets.symmetric(horizontal: 16),
                itemCount:       _modes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 7),
                itemBuilder: (_, i) => EBChip(
                  label:  _modes[i],
                  active: _mode == _modes[i],
                  onTap:  () => setState(() => _mode = _modes[i]),
                ),
              ),
            ),

            // ── Capacity ─────────────────────────────────
            _SectionLabel('Capacity'),
            _FormInput(
              label:       'Max Attendees (optional)',
              hint:        'e.g. 150',
              controller:  _capacityCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),

            // ── Description ──────────────────────────────
            _FormInput(
              label:      'Description',
              hint:       'Describe the event, what attendees can expect…',
              controller: _descCtrl,
              multiline:  true,
            ),

            const SizedBox(height: 6),

            // ── Auto-reminder notice ──────────────────────
            Container(
              margin:  const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        EBColors.brandPale,
                borderRadius: BorderRadius.circular(14),
                border:       Border.all(color: EBColors.brandLight, width: 1.5),
              ),
              child: Row(
                children: [
                  const Text('🔔', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
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
                    ),
                  ),
                ],
              ),
            ),

            // ── Publish button ───────────────────────────
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
//  RSVP SHARE SHEET  (QR code + copyable link)
// ─────────────────────────────────────────────────────────────
class _RsvpShareSheet extends StatefulWidget {
  final String eventTitle;
  final String rsvpUrl;
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
          // Handle
          Container(
            width: 36, height: 4,
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
              fontSize: 20, fontWeight: FontWeight.w800, color: EBColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Share this RSVP link with your community',
            style: TextStyle(fontSize: 13, color: EBColors.text2),
          ),
          const SizedBox(height: 20),

          // QR code (qr_flutter package)
          Container(
            padding:     const EdgeInsets.all(16),
            decoration:  BoxDecoration(
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
            padding:    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color:        EBColors.brandPale,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: EBColors.brandLight, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.rsvpUrl,
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: EBColors.brand,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _copyLink,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:        _copied ? EBColors.brand : EBColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border:       Border.all(color: EBColors.brandLight, width: 1.5),
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
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Done
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: EBColors.brand,
                foregroundColor: Colors.white,
                padding:         const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
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
//  BANNER UPLOAD TILE
// ─────────────────────────────────────────────────────────────
class _BannerUploadTile extends StatelessWidget {
  final String?     base64;
  final bool        uploading;
  final VoidCallback onTap;

  const _BannerUploadTile({
    required this.base64,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: uploading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 110,
          decoration: BoxDecoration(
            color:        base64 != null ? null : EBColors.brandPale,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: base64 != null ? EBColors.brand : EBColors.brandLight,
              width: 1.5,
              style: base64 != null ? BorderStyle.solid : BorderStyle.none,
            ),
            image: base64 != null
                ? DecorationImage(
                    image: MemoryImage(base64Decode(
                      base64!.contains(',') ? base64!.split(',')[1] : base64!,
                    )),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: uploading
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: EBColors.brand,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Uploading banner…',
                        style: TextStyle(
                          fontSize: 12, color: EBColors.brand,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : base64 != null
                  ? Container(
                      decoration: BoxDecoration(
                        color:        Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          '✏️  Change banner',
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🖼', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisSize: MainAxisSize.min,
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
                              style: TextStyle(fontSize: 11, color: EBColors.text3),
                            ),
                          ],
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DATE / TIME TILE
// ─────────────────────────────────────────────────────────────
class _DateTimeTile extends StatelessWidget {
  final String     label;
  final IconData   icon;
  final String     value;
  final bool       isEmpty;
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
          padding:    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:        EBColors.surface,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(
              color: isEmpty ? EBColors.border : EBColors.brand,
              width: isEmpty ? 1.5 : 2,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: isEmpty ? EBColors.text3 : EBColors.brand),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: EBColors.text3, letterSpacing: 0.5,
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
                ),
              ),
              Icon(
                Icons.chevron_right,
                size:  18,
                color: isEmpty ? EBColors.text3 : EBColors.brand,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CATEGORY CHIP
// ─────────────────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String     emoji;
  final String     label;
  final bool       selected;
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
          border:       Border.all(
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
//  SECTION LABEL
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
//  FORM INPUT
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
    this.multiline         = false,
    this.keyboardType      = TextInputType.text,
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
              fontSize: 12, fontWeight: FontWeight.w700, color: EBColors.text2,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller:       controller,
            keyboardType:     keyboardType,
            maxLines:         multiline ? 4 : 1,
            inputFormatters:  inputFormatters,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: EBColors.text,
            ),
            decoration: InputDecoration(
              hintText:  hint,
              hintStyle: TextStyle(fontSize: 13, color: EBColors.text3),
              filled:    true,
              fillColor: EBColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12,
              ),
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
                borderSide:   const BorderSide(color: EBColors.brand, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
