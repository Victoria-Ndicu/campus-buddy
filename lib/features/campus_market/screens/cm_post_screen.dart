// campus_market/screens/cm_post_screen.dart
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/cm_constants.dart';
import '../widgets/cm_widgets.dart';
import '../../../core/api_client.dart';

// ─────────────────────────────────────────────────────────────
//  API ENDPOINTS  (all under /api/v1/market/)
//
//  POST   /api/v1/market/listings/                         → create listing
//                                                            (images sent as
//                                                             base64 in body)
//  PATCH  /api/v1/market/listings/<uuid>/                  → update listing
//  DELETE /api/v1/market/listings/<uuid>/                  → delete listing
//  POST   /api/v1/market/donations/<uuid>/claim/           → submit claim
//  GET    /api/v1/market/donations/<uuid>/claims/<uuid>/   → claim status
// ─────────────────────────────────────────────────────────────

const _kCategories = [
  'Electronics', 'Books', 'Furniture', 'Clothing', 'Sports', 'Other',
];

// Backend choices: new | like_new | good | fair
// "Mtumba" maps to "fair" (affordable second-hand / thrift)
const _kConditions = [
  ('New',       'new'),
  ('Like New',  'like_new'),
  ('Good',      'good'),
  ('Fair',      'fair'),
  ('Mtumba 🛍', 'fair'),   // local thrift label — also maps to "fair"
];

// ─────────────────────────────────────────────────────────────
//  HELPER — encode a file to a data-URI base64 string
// ─────────────────────────────────────────────────────────────
Future<String> _fileToBase64(File file) async {
  final bytes  = await file.readAsBytes();
  final ext    = file.path.split('.').last.toLowerCase();
  final mime   = switch (ext) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png'           => 'image/png',
    'gif'           => 'image/gif',
    'webp'          => 'image/webp',
    _               => 'image/jpeg',
  };
  return 'data:$mime;base64,${base64Encode(bytes)}';
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 1 — POST TYPE SELECTOR HUB
// ─────────────────────────────────────────────────────────────
class CMPostScreen extends StatelessWidget {
  const CMPostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CMColors.surface2,
      appBar: AppBar(
        backgroundColor: CMColors.brand,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Post an Item',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const SizedBox(height: 8),

          // Hero banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
                colors: [CMColors.brand, CMColors.brandDark],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color:      CMColors.brand.withOpacity(0.3),
                blurRadius: 16,
                offset:     const Offset(0, 6),
              )],
            ),
            child: Column(children: [
              const Text('🛍', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 10),
              const Text(
                'What would you like to post?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'Reach hundreds of campus buyers instantly',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
              ),
            ]),
          ),

          const SizedBox(height: 24),
          CMSectionLabel(title: '📋 Choose a type'),

          // Only Sale and Donation — Swap removed
          ...[
            ('🏷', 'Sell an Item',    'Set a price & find buyers fast',     CMColors.brand,  'sale'),
            ('🎁', 'Donate for Free', 'Give away items you no longer need', CMColors.green,  'donation'),
          ].map<Widget>((t) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PostTypeCard(
              emoji:    t.$1,
              title:    t.$2,
              subtitle: t.$3,
              color:    t.$4,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => CMCreateListingScreen(
                  displayType: t.$2,
                  listingType: t.$5,   // "sale" | "donation"
                ),
              )),
            ),
          )),

          const SizedBox(height: 8),

          // Tips card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        CMColors.brandPale,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CMColors.brand.withOpacity(0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('💡 Selling tips', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: CMColors.text)),
              const SizedBox(height: 8),
              ...[
                'Add clear photos for 3× more interest',
                'Price competitively — check similar listings',
                'Respond quickly to messages',
              ].map<Widget>((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(children: [
                  Text('•', style: TextStyle(color: CMColors.brand, fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tip,
                    style: TextStyle(fontSize: 12, color: CMColors.text2))),
                ]),
              )),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 2 — CREATE LISTING FORM
//  Images are picked locally, converted to base64, and sent
//  together with the listing payload to:
//  POST /api/v1/market/listings/
// ─────────────────────────────────────────────────────────────
class CMCreateListingScreen extends StatefulWidget {
  /// Human-readable label shown in the AppBar ("Sell an Item" / "Donate for Free")
  final String displayType;
  /// Backend value sent in the payload ("sale" | "donation")
  final String listingType;

  const CMCreateListingScreen({
    super.key,
    this.displayType = 'Sell an Item',
    this.listingType = 'sale',
  });

  @override
  State<CMCreateListingScreen> createState() => _CMCreateListingScreenState();
}

class _CMCreateListingScreenState extends State<CMCreateListingScreen> {
  int  _categoryIdx  = 0;
  int  _conditionIdx = 0;
  bool _pickingImage = false;

  /// Selected images as File objects (for local preview)
  final List<File>   _imageFiles   = [];
  /// Same images encoded as base64 data-URI strings (sent to backend)
  final List<String> _imageDataB64 = [];

  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();

  static const int _maxImages = 5;
  bool get _isDonation => widget.listingType == 'donation';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  //  Pick image(s) from gallery → encode to base64
  // ─────────────────────────────────────────────────────────
  Future<void> _pickImages() async {
    if (_imageFiles.length >= _maxImages) {
      _snack('Maximum $_maxImages photos allowed.'); return;
    }
    HapticFeedback.selectionClick();
    setState(() => _pickingImage = true);

    try {
      final picker  = ImagePicker();
      final picked  = await picker.pickMultiImage(imageQuality: 75);
      if (picked.isEmpty || !mounted) return;

      final remaining = _maxImages - _imageFiles.length;
      final selected  = picked.take(remaining).toList();

      // Encode each to base64 in parallel
      final encoded = await Future.wait(
        selected.map((xf) => _fileToBase64(File(xf.path))),
      );

      setState(() {
        _imageFiles  .addAll(selected.map((xf) => File(xf.path)));
        _imageDataB64.addAll(encoded);
      });
    } catch (e) {
      dev.log('[Post] image pick error: $e');
      if (mounted) _snack('Could not pick image. Please try again.');
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles  .removeAt(index);
      _imageDataB64.removeAt(index);
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content:          Text(msg),
        backgroundColor:  CMColors.brandDark,
        behavior:         SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CMColors.surface2,
      appBar: AppBar(
        backgroundColor: CMColors.brand,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.displayType,
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Photo picker ──────────────────────────────────
          CMSectionLabel(title: '📷 Photos (up to $_maxImages)'),
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [

                // Thumbnails of selected images
                ..._imageFiles.asMap().entries.map((entry) {
                  final i    = entry.key;
                  final file = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(file,
                            width: 100, height: 100, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: -6, right: -6,
                          child: GestureDetector(
                            onTap: () => _removeImage(i),
                            child: Container(
                              width: 22, height: 22,
                              decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded,
                                size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Add button (hidden when at max)
                if (_imageFiles.length < _maxImages)
                  GestureDetector(
                    onTap: _pickingImage ? null : _pickImages,
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color:        CMColors.brandPale,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: CMColors.brand.withOpacity(0.4),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: _pickingImage
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded,
                                color: CMColors.brand, size: 28),
                              const SizedBox(height: 6),
                              Text('Add photo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:      CMColors.brand,
                                  fontWeight: FontWeight.w600)),
                            ],
                          ),
                    ),
                  ),
              ],
            ),
          ),

          CMSectionLabel(title: '📝 Item details'),

          // Title
          _InputField(
            label:      'Item Title *',
            hint:       'e.g. HP Laptop 15" i5 8GB',
            controller: _titleCtrl,
          ),

          // Category chips
          Text('Category *', style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: CMColors.text2)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: List.generate(_kCategories.length, (i) => CMChip(
              label:  _kCategories[i],
              active: _categoryIdx == i,
              onTap:  () => setState(() => _categoryIdx = i),
            )),
          ),

          // Condition chips — includes Mtumba
          const SizedBox(height: 16),
          Text('Condition *', style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: CMColors.text2)),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection:  Axis.horizontal,
              itemCount:        _kConditions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => CMChip(
                label:  _kConditions[i].$1,
                active: _conditionIdx == i,
                onTap:  () => setState(() => _conditionIdx = i),
              ),
            ),
          ),

          // Price (hidden for donations)
          if (!_isDonation) ...[
            const SizedBox(height: 16),
            _InputField(
              label:        'Price (KES) *',
              hint:         'e.g. 3500',
              controller:   _priceCtrl,
              keyboardType: TextInputType.number,
            ),
          ],

          const SizedBox(height: 4),
          _InputField(
            label:    'Description',
            hint:     'Describe your item — include size, age, any defects…',
            controller: _descCtrl,
            maxLines: 4,
          ),

          const SizedBox(height: 24),

          CMPrimaryButton(
            label: 'Preview Listing →',
            onTap: () {
              if (_titleCtrl.text.trim().isEmpty) {
                _snack('Please add a title.'); return;
              }
              if (!_isDonation && _priceCtrl.text.trim().isEmpty) {
                _snack('Please enter a price.'); return;
              }
              HapticFeedback.mediumImpact();
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => CMListingPreviewScreen(
                  title:        _titleCtrl.text.trim(),
                  priceDisplay: _isDonation
                      ? 'FREE'
                      : 'KES ${_priceCtrl.text.trim()}',
                  priceValue:   _isDonation
                      ? null
                      : double.tryParse(
                          _priceCtrl.text.trim().replaceAll(RegExp(r'[^0-9.]'), '')),
                  category:     _kCategories[_categoryIdx],
                  conditionDisplay: _kConditions[_conditionIdx].$1,
                  conditionValue:   _kConditions[_conditionIdx].$2,
                  description:  _descCtrl.text.trim(),
                  listingType:  widget.listingType,
                  imageFiles:   List.unmodifiable(_imageFiles),
                  imageDataB64: List.unmodifiable(_imageDataB64),
                  isDonation:   _isDonation,
                ),
              ));
            },
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 3 — LISTING PREVIEW + PUBLISH
//
//  POST /api/v1/market/listings/
//  Payload:
//  {
//    "title":        string,
//    "category":     string,
//    "condition":    "new"|"like_new"|"good"|"fair",
//    "description":  string,
//    "listing_type": "sale"|"donation",
//    "price":        number | null,
//    "image_data":   ["data:image/jpeg;base64,...", ...]   ← base64 list
//  }
// ─────────────────────────────────────────────────────────────
class CMListingPreviewScreen extends StatefulWidget {
  final String       title;
  final String       priceDisplay;       // "KES 3500" or "FREE"
  final double?      priceValue;         // null for donations
  final String       category;
  final String       conditionDisplay;   // "Mtumba 🛍", "New", …
  final String       conditionValue;     // "new" | "like_new" | "good" | "fair"
  final String       description;
  final String       listingType;        // "sale" | "donation"
  final List<File>   imageFiles;
  final List<String> imageDataB64;       // base64 data-URIs
  final bool         isDonation;

  const CMListingPreviewScreen({
    super.key,
    this.title            = 'My Item',
    this.priceDisplay     = 'KES 0',
    this.priceValue,
    this.category         = 'General',
    this.conditionDisplay = 'Used',
    this.conditionValue   = 'fair',
    this.description      = '',
    this.listingType      = 'sale',
    this.imageFiles       = const [],
    this.imageDataB64     = const [],
    this.isDonation       = false,
  });

  @override
  State<CMListingPreviewScreen> createState() => _CMListingPreviewScreenState();
}

class _CMListingPreviewScreenState extends State<CMListingPreviewScreen> {
  bool    _publishing = false;
  String? _publishedId;

  // ─────────────────────────────────────────────────────────
  //  CREATE: POST /api/v1/market/listings/
  // ─────────────────────────────────────────────────────────
  Future<void> _publish() async {
    setState(() => _publishing = true);

    try {
      final payload = <String, dynamic>{
        'title':        widget.title,
        'category':     widget.category.toLowerCase(),
        'condition':    widget.conditionValue,          // "new"|"like_new"|"good"|"fair"
        'description':  widget.description,
        'listing_type': widget.listingType,             // "sale" | "donation"
        'price':        widget.isDonation ? null : widget.priceValue,
        // Images as a list of base64 data-URI strings — no separate upload call needed
        'image_data':   widget.imageDataB64,
      };

      dev.log('[Preview] POST /listings/ payload keys: ${payload.keys}');

      final res = await ApiClient.post('/api/v1/market/listings/', body: payload);

      dev.log('[Preview] POST /listings/ → ${res.statusCode}');
      dev.log('[Preview] body: ${res.body}');

      if (!mounted) return;

      if (res.statusCode == 201 || res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>?;
        final data    = decoded?['data'] as Map<String, dynamic>?;
        setState(() => _publishedId = data?['id']?.toString() ?? '');

        Navigator.popUntil(context,
          (route) => route.isFirst || route.settings.name == '/market');

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text('Your listing "${widget.title}" is live! ✅'),
          backgroundColor: CMColors.green,
          behavior:        SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ));
      } else {
        final errBody = jsonDecode(res.body) as Map<String, dynamic>?;
        final errMap  = errBody?['error'] as Map<String, dynamic>?;
        _snack(errMap?['message']?.toString()
            ?? errBody?['detail']?.toString()
            ?? 'Could not publish listing (${res.statusCode}).');
      }
    } catch (e) {
      dev.log('[Preview] publish error: $e');
      if (mounted) _snack('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content:         Text(msg),
        backgroundColor: CMColors.brandDark,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CMColors.surface2,
      appBar: AppBar(
        backgroundColor: CMColors.brand,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Preview Listing',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          // Preview card
          Container(
            decoration: CMTheme.card,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Image strip
              if (widget.imageFiles.isNotEmpty)
                SizedBox(
                  height: 180,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                    child: PageView.builder(
                      itemCount: widget.imageFiles.length,
                      itemBuilder: (_, i) => Image.file(
                        widget.imageFiles[i], fit: BoxFit.cover),
                    ),
                  ),
                )
              else
                Container(
                  height: 180, width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                    color: CMColors.brandPale,
                  ),
                  child: const _PhotoPlaceholder(),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(widget.title,
                          style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900,
                            color: CMColors.text))),
                        Text(widget.priceDisplay, style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900,
                          color: widget.isDonation ? CMColors.green : CMColors.brand)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      CMTag(widget.category),
                      const SizedBox(width: 8),
                      CMTag(widget.conditionDisplay),
                      if (widget.isDonation) ...[
                        const SizedBox(width: 8),
                        CMTag('Free 🎁'),
                      ],
                    ]),
                    if (widget.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(widget.description, style: TextStyle(
                        fontSize: 13, color: CMColors.text2, height: 1.5)),
                    ],
                  ],
                ),
              ),
            ]),
          ),

          const SizedBox(height: 20),
          CMSectionLabel(title: '👁 How it looks to buyers'),
          Text(
            'Your listing will appear in Browse Listings and in search results.',
            style: TextStyle(fontSize: 12, color: CMColors.text2)),

          const SizedBox(height: 16),
          _PublishChecklist(
            hasPhoto:       widget.imageFiles.isNotEmpty,
            hasDescription: widget.description.isNotEmpty,
            hasPrice:       !widget.isDonation,
          ),

          const SizedBox(height: 24),

          CMPrimaryButton(
            label: _publishing ? 'Publishing…' : '🚀 Publish Listing',
            onTap: _publishing ? null : _publish,
          ),

          if (_publishing)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 4 — DONATION CLAIM
//  POST /api/v1/market/donations/<uuid>/claim/
//  GET  /api/v1/market/donations/<uuid>/claims/<claimId>/
// ─────────────────────────────────────────────────────────────
class CMDonationClaimScreen extends StatefulWidget {
  final String  listingId;
  final String  itemTitle;
  final String? claimId;

  const CMDonationClaimScreen({
    super.key,
    required this.listingId,
    this.itemTitle = 'this item',
    this.claimId,
  });

  @override
  State<CMDonationClaimScreen> createState() => _CMDonationClaimScreenState();
}

class _CMDonationClaimScreenState extends State<CMDonationClaimScreen> {
  final _msgCtrl = TextEditingController();
  bool  _sending = false;

  bool    _loadingStatus = false;
  String  _claimStatus   = '';
  String? _statusError;

  bool get _isStatusMode => widget.claimId != null;

  @override
  void initState() {
    super.initState();
    if (_isStatusMode) _fetchStatus();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  //  READ: GET /api/v1/market/donations/<uuid>/claims/<claimId>/
  // ─────────────────────────────────────────────────────────
  Future<void> _fetchStatus() async {
    if (mounted) setState(() { _loadingStatus = true; _statusError = null; });
    try {
      final res = await ApiClient.get(
        '/api/v1/market/donations/${widget.listingId}'
        '/claims/${widget.claimId}/');
      dev.log('[Claim] GET status → ${res.statusCode}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>?;
        setState(() {
          _claimStatus   = decoded?['status']?.toString() ?? 'pending';
          _loadingStatus = false;
        });
      } else {
        setState(() {
          _statusError   = 'Could not load claim status (${res.statusCode}).';
          _loadingStatus = false;
        });
      }
    } catch (e) {
      dev.log('[Claim] status error: $e');
      if (mounted) setState(() {
        _statusError   = 'Network error.';
        _loadingStatus = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────
  //  CREATE: POST /api/v1/market/donations/<uuid>/claim/
  //  Body: { "message": string }
  // ─────────────────────────────────────────────────────────
  Future<void> _submitClaim() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty) { _snack('Please write a short message.'); return; }

    setState(() => _sending = true);
    try {
      final res = await ApiClient.post(
        '/api/v1/market/donations/${widget.listingId}/claim/',
        body: {'message': msg},
      );
      dev.log('[Claim] POST /claim/ → ${res.statusCode}');

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>?;
        Navigator.pop(context, decoded ?? {});
      } else {
        final errBody = jsonDecode(res.body) as Map<String, dynamic>?;
        final errMap  = errBody?['error'] as Map<String, dynamic>?;
        _snack(errMap?['message']?.toString()
            ?? errBody?['detail']?.toString()
            ?? 'Could not submit claim (${res.statusCode}).');
      }
    } catch (e) {
      dev.log('[Claim] submit error: $e');
      if (mounted) _snack('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content:         Text(msg),
        backgroundColor: CMColors.green,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CMColors.surface2,
      appBar: AppBar(
        backgroundColor: CMColors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isStatusMode ? 'Claim Status' : 'Claim Item',
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
      body: _isStatusMode ? _buildStatusView() : _buildClaimForm(),
    );
  }

  Widget _buildStatusView() {
    if (_loadingStatus) return const Center(child: CircularProgressIndicator());
    if (_statusError != null) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_statusError!, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: CMColors.text3)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _fetchStatus,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ));
    }

    // Backend uses "confirmed" | "rejected" | "pending"
    final (emoji, label, color) = switch (_claimStatus.toLowerCase()) {
      'confirmed' => ('✅', 'Claim Approved!',  CMColors.green),
      'rejected'  => ('❌', 'Claim Rejected',   CMColors.accent2),
      _           => ('⏳', 'Claim Pending…',   CMColors.accent),
    };

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 40),
        Text(emoji, style: const TextStyle(fontSize: 72)),
        const SizedBox(height: 20),
        Text(label, style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 12),
        Text('Item: ${widget.itemTitle}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: CMColors.text2)),
        const SizedBox(height: 8),
        Text(
          switch (_claimStatus.toLowerCase()) {
            'confirmed' => 'The donor has approved your claim. '
                'Contact them to arrange pickup.',
            'rejected'  => 'Unfortunately your claim was not selected. '
                'Check other free items!',
            _           => 'Your claim is being reviewed by the donor. '
                "You'll be notified of the decision.",
          },
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: CMColors.text3, height: 1.5),
        ),
        const SizedBox(height: 32),
        if (_claimStatus.toLowerCase() == 'pending')
          TextButton.icon(
            onPressed: _fetchStatus,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh status'),
          ),
      ]),
    );
  }

  Widget _buildClaimForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:        CMColors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CMColors.green.withOpacity(0.3)),
          ),
          child: Row(children: [
            const Text('🎁', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.itemTitle, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: CMColors.text)),
                Text('Free — claim before someone else does!',
                  style: TextStyle(fontSize: 11, color: CMColors.green)),
              ],
            )),
          ]),
        ),

        const SizedBox(height: 20),
        CMSectionLabel(title: '✍️ Why do you want this item?'),

        Container(
          decoration: CMTheme.card,
          child: TextField(
            controller: _msgCtrl,
            maxLines:   5,
            decoration: InputDecoration(
              hintText: "Tell the donor a little about yourself and "
                  "why you'd like this item…",
              hintStyle:      TextStyle(fontSize: 13, color: CMColors.text3),
              contentPadding: const EdgeInsets.all(14),
              border:         InputBorder.none,
            ),
          ),
        ),

        const SizedBox(height: 8),
        Text(
          'The donor will review your request and approve or reject it.',
          style: TextStyle(fontSize: 11, color: CMColors.text3),
        ),

        const SizedBox(height: 24),

        GestureDetector(
          onTap: _sending ? null : _submitClaim,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _sending
                  ? [CMColors.green.withOpacity(0.5),
                     CMColors.green.withOpacity(0.5)]
                  : const [Color(0xFF34D399), Color(0xFF10B981)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                color:      CMColors.green.withOpacity(0.3),
                blurRadius: 12,
                offset:     const Offset(0, 4),
              )],
            ),
            child: Center(child: Text(
              _sending ? 'Submitting…' : '🙌 Submit Claim',
              style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
            )),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PUBLISH CHECKLIST
// ─────────────────────────────────────────────────────────────
class _PublishChecklist extends StatelessWidget {
  final bool hasPhoto, hasDescription, hasPrice;
  const _PublishChecklist({
    required this.hasPhoto,
    required this.hasDescription,
    required this.hasPrice,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (hasPhoto,       '📷 Photo added',       'Listings with photos get 3× views'),
      (hasDescription, '📝 Description added', 'Help buyers understand the item'),
      (hasPrice,       '💰 Price set',          'Clear pricing attracts buyers'),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: CMColors.border),
      ),
      child: Column(
        children: items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Text(item.$1 ? '✅' : '⚠️', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.$2, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: item.$1 ? CMColors.text : CMColors.text3)),
                Text(item.$3, style: TextStyle(fontSize: 11, color: CMColors.text3)),
              ],
            )),
          ]),
        )).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PRIVATE HELPERS
// ─────────────────────────────────────────────────────────────
class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('📷', style: TextStyle(fontSize: 56)),
        SizedBox(height: 8),
        Text('No photo added',
          style: TextStyle(fontSize: 12, color: Color(0xFF9999BB))),
      ],
    ),
  );
}

class _PostTypeCard extends StatelessWidget {
  final String     emoji, title, subtitle;
  final Color      color;
  final VoidCallback onTap;
  const _PostTypeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [BoxShadow(
            color: color.withOpacity(0.08), blurRadius: 10,
            offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color:        color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(emoji,
              style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: CMColors.text)),
              const SizedBox(height: 3),
              Text(subtitle, style: TextStyle(fontSize: 12, color: CMColors.text3)),
            ],
          )),
          Icon(Icons.chevron_right_rounded, color: color),
        ]),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String              label, hint;
  final TextEditingController controller;
  final int                 maxLines;
  final TextInputType?      keyboardType;
  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines    = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700, color: CMColors.text2)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: CMColors.border),
          ),
          child: TextField(
            controller:   controller,
            maxLines:     maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText:       hint,
              hintStyle:      TextStyle(fontSize: 13, color: CMColors.text3),
              contentPadding: const EdgeInsets.all(14),
              border:         InputBorder.none,
            ),
          ),
        ),
      ]),
    );
  }
}