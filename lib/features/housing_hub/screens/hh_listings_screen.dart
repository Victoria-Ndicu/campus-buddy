import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/hh_constants.dart';
import '../widgets/hh_widgets.dart';
import '../../../core/api_client.dart';

// ─────────────────────────────────────────────────────────────
//  API ENDPOINTS
//
//  GET    /api/v1/housing/listings/                        → browse listings
//  GET    /api/v1/housing/listings/?type=<t>&search=<q>   → filtered browse
//  GET    /api/v1/housing/listings/<uuid>/                 → listing detail
//  POST   /api/v1/housing/listings/<uuid>/save/            → toggle save
//  POST   /api/v1/housing/uploads/                         → upload photo
//  POST   /api/v1/housing/listings/                        → create listing
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────────────────────
class _Listing {
  final String id, type, title, price, location, availability;
  final List<String> tags;
  final String? imageUrl;

  const _Listing({
    required this.id,
    required this.type,
    required this.title,
    required this.price,
    required this.location,
    required this.availability,
    required this.tags,
    this.imageUrl,
  });

  factory _Listing.fromJson(Map<String, dynamic> j) => _Listing(
    id:           j['id']?.toString() ?? '',
    type:         j['type']?.toString() ?? 'Other',
    title:        j['title']?.toString() ?? '',
    price:        j['price']?.toString() ?? '',
    location:     j['location']?.toString() ?? '',
    availability: j['availability']?.toString() ?? '',
    tags:         (j['tags'] as List?)
        ?.map((e) => e.toString()).toList() ?? [],
    imageUrl:     j['image_url']?.toString(),
  );

  // Derive emoji and gradient from type (no hardcoded data)
  String get emoji => switch (type) {
    'Apartment'   => '🏠',
    'Single Room' => '🛏',
    'Shared'      => '🏘',
    'Bedsitter'   => '🏣',
    _             => '🏠',
  };

  Color get gradA => switch (type) {
    'Apartment'   => const Color(0xFFFDF0EC),
    'Single Room' => const Color(0xFFF0F4FF),
    'Shared'      => const Color(0xFFECFDF5),
    'Bedsitter'   => const Color(0xFFFFF3E0),
    _             => const Color(0xFFF8F9FF),
  };

  Color get gradB => switch (type) {
    'Apartment'   => const Color(0xFFF4C5B5),
    'Single Room' => const Color(0xFFDDE6FF),
    'Shared'      => const Color(0xFFA7F3D0),
    'Bedsitter'   => const Color(0xFFFFCC80),
    _             => const Color(0xFFE1E5F7),
  };

  Color get typeColor => switch (type) {
    'Apartment'   => HHColors.brandDark,
    'Single Room' => HHColors.blue,
    'Shared'      => HHColors.teal,
    'Bedsitter'   => HHColors.amber,
    _             => HHColors.text2,
  };
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 1 — Browse Listings
//  GET /api/v1/housing/listings/?type=<t>&search=<q>
// ─────────────────────────────────────────────────────────────
class HHListingsScreen extends StatefulWidget {
  const HHListingsScreen({super.key});
  @override
  State<HHListingsScreen> createState() => _HHListingsScreenState();
}

class _HHListingsScreenState extends State<HHListingsScreen> {
  int     _filter  = 0;
  String  _query   = '';
  List<_Listing> _listings  = [];
  bool    _loading = true;
  String? _error;
  DateTime _lastSearch = DateTime(0);

  static const _filters = [
    'All', '🏠 Apartment', '🛏 Single Room', '🏘 Shared', '🏣 Bedsitter',
  ];
  static const _filterTypes = [
    '', 'Apartment', 'Single Room', 'Shared', 'Bedsitter',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ─────────────────────────────────────────────────────────
  //  GET /api/v1/housing/listings/
  // ─────────────────────────────────────────────────────────
  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });

    final params = <String>[];
    final type = _filterTypes[_filter];
    if (type.isNotEmpty) params.add('type=${Uri.encodeComponent(type)}');
    if (_query.isNotEmpty) params.add('search=${Uri.encodeComponent(_query)}');
    final qs = params.isEmpty ? '' : '?${params.join('&')}';

    try {
      final res = await ApiClient.get('/api/v1/housing/listings/$qs');
      dev.log('[Listings] GET /housing/listings/$qs → ${res.statusCode}');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final raw = decoded is List
            ? decoded
            : (decoded['results'] as List?) ?? [];
        setState(() {
          _listings = raw.whereType<Map<String, dynamic>>()
              .map(_Listing.fromJson).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error   = 'Could not load listings (${res.statusCode}).';
          _loading = false;
        });
      }
    } catch (e, s) {
      dev.log('[Listings] error: $e', stackTrace: s);
      if (mounted) setState(() {
        _error   = 'Network error. Pull to refresh.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HHColors.surface2,
      appBar: AppBar(
        backgroundColor: HHColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: HHColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Housing Hub', style: TextStyle(
              fontFamily: 'serif', fontSize: 18,
              fontWeight: FontWeight.w900,
              color: HHColors.brandDark,
              fontStyle: FontStyle.italic)),
            Text(
              _loading
                ? 'Loading…'
                : '${_listings.length} listing${_listings.length == 1 ? '' : 's'} available',
              style: TextStyle(
                fontSize: 11, color: HHColors.text3)),
          ]),
        titleSpacing: 0,
        actions: [
          Container(margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: HHColors.brandPale,
              borderRadius: BorderRadius.circular(11)),
            child: Text('🔔', style: TextStyle(
              fontSize: 18, color: HHColors.brand))),
          Container(margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: HHColors.brand,
              borderRadius: BorderRadius.circular(11)),
            child: const Text('👤',
              style: TextStyle(fontSize: 18))),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: HHColors.border, height: 1)),
      ),
      body: RefreshIndicator(
        color: HHColors.brand,
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          // ── Inline search bar (replaces HHSearchBar which lacks onChanged) ──
          SliverToBoxAdapter(
            child: _HHInlineSearchBar(
              hint: 'Search location, type, price...',
              onChanged: (v) {
                setState(() => _query = v);
                final now = DateTime.now();
                _lastSearch = now;
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_lastSearch == now) _load();
                });
              },
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                itemCount: _filters.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 7),
                itemBuilder: (_, i) => HHChip(
                  label: _filters[i],
                  active: _filter == i,
                  onTap: () {
                    setState(() => _filter = i);
                    _load();
                  },
                ),
              )),
          ),

          SliverToBoxAdapter(
            child: HHSectionLabel(title: 'Latest Listings')),

          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            SliverFillRemaining(
              child: Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13, color: HHColors.text3)),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded,
                      size: 16),
                    label: const Text('Retry')),
                ])))
          else if (_listings.isEmpty)
            SliverFillRemaining(
              child: Center(child: Text('No listings found.',
                style: TextStyle(
                  fontSize: 13, color: HHColors.text3))))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  if (i == _listings.length) {
                    return const SizedBox(height: 100);
                  }
                  final l = _listings[i];
                  return _ListingCard(
                    listing: l,
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                        builder: (_) => HHListingDetailScreen(
                          listingId: l.id,
                          title:     l.title,
                          price:     l.price,
                          location:  l.location,
                          type:      l.type,
                          emoji:     l.emoji,
                        ))),
                  );
                },
                childCount: _listings.length + 1,
              )),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: HHColors.brand,
        foregroundColor: Colors.white,
        icon: const Text('🏠', style: TextStyle(fontSize: 18)),
        label: const Text('Post Listing',
          style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const HHPostListingScreen())),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 2 — Listing Detail
//  GET  /api/v1/housing/listings/<uuid>/
//  POST /api/v1/housing/listings/<uuid>/save/
// ─────────────────────────────────────────────────────────────
class HHListingDetailScreen extends StatefulWidget {
  final String  listingId;
  final String  title, price, location, type, emoji;

  const HHListingDetailScreen({
    super.key,
    this.listingId = '',
    this.title     = '',
    this.price     = '',
    this.location  = '',
    this.type      = 'Apartment',
    this.emoji     = '🏠',
  });

  @override
  State<HHListingDetailScreen> createState() =>
      _HHListingDetailScreenState();
}

class _HHListingDetailScreenState
    extends State<HHListingDetailScreen> {
  Map<String, dynamic>? _detail;
  bool    _loadingDetail = true;
  bool    _saved         = false;
  bool    _saving        = false;

  @override
  void initState() {
    super.initState();
    if (widget.listingId.isNotEmpty) _fetchDetail();
    else setState(() => _loadingDetail = false);
  }

  // ─────────────────────────────────────────────────────────
  //  GET /api/v1/housing/listings/<uuid>/
  // ─────────────────────────────────────────────────────────
  Future<void> _fetchDetail() async {
    try {
      final res = await ApiClient.get(
          '/api/v1/housing/listings/${widget.listingId}/');
      dev.log('[ListingDetail] GET → ${res.statusCode}');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final decoded =
            jsonDecode(res.body) as Map<String, dynamic>?;
        setState(() {
          _detail        = decoded;
          _saved         = decoded?['is_saved'] as bool? ?? false;
          _loadingDetail = false;
        });
      } else {
        setState(() => _loadingDetail = false);
      }
    } catch (e) {
      dev.log('[ListingDetail] error: $e');
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  POST /api/v1/housing/listings/<uuid>/save/
  // ─────────────────────────────────────────────────────────
  Future<void> _toggleSave() async {
    if (widget.listingId.isEmpty || _saving) return;
    HapticFeedback.selectionClick();
    setState(() { _saved = !_saved; _saving = true; });
    try {
      final res = await ApiClient.post(
          '/api/v1/housing/listings/${widget.listingId}/save/');
      dev.log('[ListingDetail] POST /save/ → ${res.statusCode}');
      if (!mounted) return;
      if (res.statusCode != 200 && res.statusCode != 201) {
        setState(() => _saved = !_saved);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not save listing.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_saved
            ? 'Listing saved ❤️' : 'Listing removed'),
          backgroundColor: HHColors.teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      dev.log('[ListingDetail] save error: $e');
      if (mounted) setState(() => _saved = !_saved);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _field(String key, String fallback) =>
      _detail?[key]?.toString() ?? fallback;

  @override
  Widget build(BuildContext context) {
    final title    = _field('title',    widget.title);
    final price    = _field('price',    widget.price);
    final location = _field('location', widget.location);
    final type     = _field('type',     widget.type);
    final emoji    = widget.emoji;

    final amenities = (_detail?['amenities'] as List?)
        ?.map((e) => e.toString()).toList() ?? [];
    final contact   = _field('contact',     '');
    final caretaker = _field('caretaker',   '');
    final available = _field('availability','');
    final about     = _field('description', '');
    final bedrooms  = _field('bedrooms',    '—');
    final bathrooms = _field('bathrooms',   '—');
    final size      = _field('size_sqm',    '—');
    final floor     = _field('floor',       '—');

    return Scaffold(
      backgroundColor: HHColors.surface2,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 230,
          pinned: false,
          backgroundColor: Colors.transparent,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.88),
                borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.arrow_back_ios_new,
                size: 16, color: HHColors.text))),
          actions: [
            GestureDetector(
              onTap: _toggleSave,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(11)),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(_saved ? '❤️' : '🤍',
                    style: const TextStyle(fontSize: 18))))),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFDF0EC), Color(0xFFF4C5B5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)),
              child: Stack(children: [
                Center(child: Text(emoji,
                  style: const TextStyle(fontSize: 90))),
                Positioned(bottom: 10, right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8)),
                    child: const Text('1 / 5', style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800,
                      color: Colors.white)))),
              ]),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: _loadingDetail
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16, 14, 16, 0),
                      child: Row(
                        crossAxisAlignment:
                          CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: HHColors.text,
                              height: 1.25,
                              fontStyle: FontStyle.italic))),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment:
                              CrossAxisAlignment.end,
                            children: [
                              Text(price, style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: HHColors.brand)),
                              Text('/month', style: TextStyle(
                                fontSize: 11,
                                color: HHColors.text3)),
                            ]),
                        ])),

                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                      child: Wrap(spacing: 6, runSpacing: 6,
                        children: [
                          HHTag('🏠 $type',
                            bg: HHColors.brandPale,
                            fg: HHColors.brand),
                          HHTag('Available',
                            bg: HHColors.greenPale,
                            fg: HHColors.green),
                        ])),

                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                      child: Text(location, style: TextStyle(
                        fontSize: 12, color: HHColors.text3))),

                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                      child: Row(children: [
                        _InfoChip(label: bedrooms,
                          sub: 'Bedrooms'),
                        const SizedBox(width: 8),
                        _InfoChip(label: bathrooms,
                          sub: 'Bathroom'),
                        const SizedBox(width: 8),
                        _InfoChip(label: size,    sub: 'sq.m'),
                        const SizedBox(width: 8),
                        _InfoChip(label: floor,   sub: 'Floor'),
                      ])),

                    if (amenities.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      HHSectionLabel(title: 'Amenities'),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16),
                        child: Wrap(spacing: 8, runSpacing: 8,
                          children: amenities.map((a) =>
                            HHTag(a,
                              bg: HHColors.greenPale,
                              fg: HHColors.green)
                          ).toList())),
                    ],

                    const SizedBox(height: 14),
                    if (about.isNotEmpty)
                      HHFormField(
                        label: 'About this listing',
                        value: about,
                        multiline: true),
                    if (contact.isNotEmpty)
                      HHFormField(
                        label: 'Contact',
                        value: '📞 $contact'),
                    if (caretaker.isNotEmpty)
                      HHFormField(
                        label: 'Caretaker',
                        value: caretaker),
                    if (available.isNotEmpty)
                      HHFormField(
                        label: 'Available from',
                        value: available),

                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                      child: Row(children: [
                        Expanded(child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: HHColors.brand),
                            foregroundColor: HHColors.brand,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14)),
                          onPressed: _toggleSave,
                          child: Text(
                            _saved ? 'Saved ❤️' : 'Save',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800)))),
                        const SizedBox(width: 10),
                        Expanded(flex: 3,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: HHColors.brand,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                  BorderRadius.circular(12)),
                              padding:
                                const EdgeInsets.symmetric(
                                  vertical: 14)),
                            onPressed: () =>
                              ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                                  content: Text(
                                    'Contacting agent...'))),
                            child: const Text('Contact Agent',
                              style: TextStyle(
                                fontWeight: FontWeight.w800)))),
                      ])),
                    const SizedBox(height: 40),
                  ]),
              ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 3 — Post Listing
//  POST /api/v1/housing/uploads/    → upload photo
//  POST /api/v1/housing/listings/   → create listing
// ─────────────────────────────────────────────────────────────
class HHPostListingScreen extends StatefulWidget {
  const HHPostListingScreen({super.key});
  @override
  State<HHPostListingScreen> createState() =>
      _HHPostListingScreenState();
}

class _HHPostListingScreenState extends State<HHPostListingScreen> {
  String _type     = 'Apartment';
  String _location = 'Westlands';
  bool   _wifi     = true;
  bool   _parking  = false;
  bool   _furnished= true;
  bool   _publishing = false;
  String _uploadedImageUrl = '';

  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _contactCtrl = TextEditingController();

  static const _types = [
    'Apartment', 'Single Room', 'Shared', 'Bedsitter',
  ];
  static const _locations = [
    'Westlands', 'Parklands', 'CBD', 'Ngara', 'Highridge',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  //  POST /api/v1/housing/uploads/
  // ─────────────────────────────────────────────────────────
  Future<void> _uploadPhoto() async {
    HapticFeedback.selectionClick();
    // TODO: pick file via image_picker, send as multipart
    try {
      final res = await ApiClient.post(
          '/api/v1/housing/uploads/',
          body: {'placeholder': true});
      dev.log('[PostListing] POST /uploads/ → ${res.statusCode}');
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        final decoded =
            jsonDecode(res.body) as Map<String, dynamic>?;
        setState(() =>
            _uploadedImageUrl =
              decoded?['url']?.toString() ?? '');
      }
    } catch (e) {
      dev.log('[PostListing] upload error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  POST /api/v1/housing/listings/
  // ─────────────────────────────────────────────────────────
  Future<void> _publish() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please add a listing title.')));
      return;
    }
    if (_priceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter the monthly rent.')));
      return;
    }

    setState(() => _publishing = true);
    try {
      final amenities = <String>[
        if (_wifi) 'WiFi',
        if (_parking) 'Parking',
        if (_furnished) 'Furnished',
      ];
      final payload = <String, dynamic>{
        'type':        _type,
        'title':       _titleCtrl.text.trim(),
        'price':       _priceCtrl.text.trim(),
        'location':    _location,
        'description': _descCtrl.text.trim(),
        'contact':     _contactCtrl.text.trim(),
        'amenities':   amenities,
        if (_uploadedImageUrl.isNotEmpty)
          'image_url': _uploadedImageUrl,
      };

      final res = await ApiClient.post(
          '/api/v1/housing/listings/', body: payload);
      dev.log('[PostListing] POST /listings/ → ${res.statusCode}');

      if (!mounted) return;
      if (res.statusCode == 201 || res.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            '✅ "${_titleCtrl.text.trim()}" is live!'),
          backgroundColor: HHColors.teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3)));
      } else {
        final errBody =
            jsonDecode(res.body) as Map<String, dynamic>?;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errBody?['detail']?.toString()
            ?? 'Could not publish (${res.statusCode}).'),
          backgroundColor: HHColors.brandDark,
        ));
      }
    } catch (e) {
      dev.log('[PostListing] error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Network error. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  String _typeEmoji(String t) => switch (t) {
    'Apartment'   => '🏠',
    'Single Room' => '🛏',
    'Shared'      => '🏘',
    'Bedsitter'   => '🏣',
    _             => '🏠',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HHColors.surface2,
      appBar: AppBar(
        backgroundColor: HHColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: HHColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Post a Listing', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w800,
          color: HHColors.text)),
        actions: [
          TextButton(
            onPressed: _publishing ? null : _publish,
            child: Text(
              _publishing ? 'Publishing…' : 'Publish',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _publishing
                  ? HHColors.text3 : HHColors.brand)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: HHColors.border, height: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Text(
                'Create a listing and reach students near campus 🏠',
                style: TextStyle(
                  fontSize: 13, color: HHColors.text2))),

            // Photo upload
            GestureDetector(
              onTap: _uploadPhoto,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                height: 100,
                decoration: BoxDecoration(
                  color: _uploadedImageUrl.isNotEmpty
                    ? HHColors.greenPale : HHColors.brandPale,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _uploadedImageUrl.isNotEmpty
                      ? HHColors.green.withOpacity(0.4)
                      : HHColors.brand.withOpacity(0.3))),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_uploadedImageUrl.isNotEmpty
                      ? '✅' : '📷',
                      style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 6),
                    Text(
                      _uploadedImageUrl.isNotEmpty
                        ? 'Photo uploaded — tap to replace'
                        : 'Tap to add photos',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: _uploadedImageUrl.isNotEmpty
                          ? HHColors.green : HHColors.brand)),
                  ]),
              )),

            HHSectionLabel(title: 'Property Type'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8, crossAxisSpacing: 8,
                childAspectRatio: 2.5,
                children: _types.map<Widget>((t) =>
                  GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _type == t
                          ? HHColors.brandPale : HHColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _type == t
                            ? HHColors.brand : HHColors.border,
                          width: 1.5)),
                      child: Row(children: [
                        Text(_typeEmoji(t),
                          style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(t, style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _type == t
                            ? HHColors.brand : HHColors.text2)),
                      ]),
                    ),
                  )).toList(),
              )),
            const SizedBox(height: 14),

            _TextInputField(
              label: 'Listing Title *',
              hint: 'e.g. Spacious 2BR — Westlands',
              controller: _titleCtrl),
            _TextInputField(
              label: 'Monthly Rent (KES) *',
              hint: 'e.g. 28,000',
              controller: _priceCtrl,
              keyboardType: TextInputType.number),

            HHSectionLabel(title: 'Location'),
            SizedBox(height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _locations.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 7),
                itemBuilder: (_, i) => HHChip(
                  label: _locations[i],
                  active: _location == _locations[i],
                  onTap: () => setState(
                    () => _location = _locations[i]),
                ),
              )),
            const SizedBox(height: 14),

            HHSectionLabel(title: 'Amenities'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: HHTheme.cardSm,
              child: Column(children: [
                HHToggleRow(
                  label: '📶 WiFi included',
                  subtitle: 'Landlord provides internet',
                  value: _wifi,
                  onChanged: (v) => setState(() => _wifi = v)),
                Divider(color: HHColors.border, height: 1),
                HHToggleRow(
                  label: '🅿️ Parking',
                  subtitle: 'Secure parking available',
                  value: _parking,
                  onChanged: (v) =>
                      setState(() => _parking = v)),
                Divider(color: HHColors.border, height: 1),
                HHToggleRow(
                  label: '🪑 Furnished',
                  subtitle: 'Basic furniture included',
                  value: _furnished,
                  onChanged: (v) =>
                      setState(() => _furnished = v)),
              ])),
            const SizedBox(height: 14),

            _TextInputField(
              label: 'Description',
              hint: 'Describe the property, nearby landmarks, transport…',
              controller: _descCtrl,
              maxLines: 4),
            _TextInputField(
              label: 'Contact Number *',
              hint: '07XX XXX XXX',
              controller: _contactCtrl,
              keyboardType: TextInputType.phone),

            HHPrimaryButton(
              label: _publishing
                ? '⏳ Publishing…' : '🏠 Publish Listing',
              onTap: _publishing ? null : _publish,
            ),
          ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Private helpers
// ─────────────────────────────────────────────────────────────

/// Inline search bar used in place of HHSearchBar when live
/// text input (onChanged) is required. Does NOT touch hh_widgets.dart.
class _HHInlineSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _HHInlineSearchBar({
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 13, 16, 0),
      decoration: BoxDecoration(
        color: HHColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HHColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        const Padding(
          padding: EdgeInsets.only(left: 14),
          child: Text('🔍', style: TextStyle(fontSize: 16))),
        Expanded(
          child: TextField(
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 13, color: HHColors.text3),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 11),
              border: InputBorder.none),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(
            horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: HHColors.brandPale,
            borderRadius: BorderRadius.circular(8)),
          child: Text('Filter', style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w800,
            color: HHColors.brand)),
        ),
      ]),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final _Listing listing;
  final VoidCallback onTap;
  const _ListingCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: HHTheme.card,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 130,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [listing.gradA, listing.gradB],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18)),
              ),
              child: Stack(children: [
                Center(child: Text(listing.emoji,
                  style: const TextStyle(fontSize: 52))),
                Positioned(top: 10, left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8)),
                    child: Text(listing.type, style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: listing.typeColor)))),
                Positioned(top: 10, right: 10,
                  child: Container(width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle),
                    child: const Center(child: Text('🤍',
                      style: TextStyle(fontSize: 13))))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.title, style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800,
                    color: HHColors.text)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(listing.price, style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900,
                      color: HHColors.brand)),
                    Text(' /month', style: TextStyle(
                      fontSize: 11, color: HHColors.text3)),
                  ]),
                  const SizedBox(height: 3),
                  Text(listing.location, style: TextStyle(
                    fontSize: 11, color: HHColors.text3)),
                  if (listing.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 5, runSpacing: 5,
                      children: listing.tags.map<Widget>((t) =>
                        HHTag(t,
                          bg: HHColors.greenPale,
                          fg: HHColors.teal)
                      ).toList()),
                  ],
                  const SizedBox(height: 10),
                  Divider(color: HHColors.border, height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                    children: [
                      Text('📅 ${listing.availability}',
                        style: TextStyle(
                          fontSize: 11, color: HHColors.text3)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: HHColors.brand,
                          borderRadius: BorderRadius.circular(9)),
                        child: const Text('View →', style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white))),
                    ]),
                ]),
            ),
          ]),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label, sub;
  const _InfoChip({required this.label, required this.sub});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: HHColors.brandPale,
      borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(label, style: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w900,
        color: HHColors.brand)),
      Text(sub, style: TextStyle(
        fontSize: 10, color: HHColors.text3)),
    ]),
  ));
}

class _TextInputField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  const _TextInputField({
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: HHColors.text2)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HHColors.border)),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 13, color: HHColors.text3),
              contentPadding: const EdgeInsets.all(14),
              border: InputBorder.none))),
      ]));
}