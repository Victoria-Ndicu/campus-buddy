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
//  GET  /api/v1/housing/module/                           → module state
//  GET  /api/v1/housing/listings/                         → all listings
//  GET  /api/v1/housing/listings/?tags=apartment          → filtered
//  GET  /api/v1/housing/listings/<uuid>/                  → detail
//  POST /api/v1/housing/listings/<uuid>/save/             → toggle save
//
//  RESPONSE SHAPE (StandardPagination):
//  { "success": true, "data": [...], "meta": { "page", "limit", "total", "totalPages" } }
//
//  FIELD NAMES (HousingListingSerializer — camelCase):
//  rentPerMonth, locationName, imageUrls, availableFrom, landlordId, createdAt
// ─────────────────────────────────────────────────────────────

class HousingListing {
  final String id;
  final String title;
  final String rentPerMonth;
  final String locationName;
  final String status;
  final List<String> tags;
  final List<String> amenities;
  final List<String> imageUrls;
  final int?    bedrooms;
  final int?    bathrooms;
  final String? availableFrom;
  final String? description;

  const HousingListing({
    required this.id,
    required this.title,
    required this.rentPerMonth,
    required this.locationName,
    required this.status,
    required this.tags,
    required this.amenities,
    required this.imageUrls,
    this.bedrooms,
    this.bathrooms,
    this.availableFrom,
    this.description,
  });

  // Serializer outputs camelCase — match exactly
  factory HousingListing.fromJson(Map<String, dynamic> j) => HousingListing(
    id:            j['id']?.toString() ?? '',
    title:         j['title']?.toString() ?? '',
    rentPerMonth:  j['rentPerMonth']?.toString() ?? '',   // ← camelCase
    locationName:  j['locationName']?.toString() ?? '',   // ← camelCase
    status:        j['status']?.toString() ?? 'active',
    tags:          (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
    amenities:     (j['amenities'] as List?)?.map((e) => e.toString()).toList() ?? [],
    imageUrls:     (j['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? [],  // ← camelCase
    bedrooms:      j['bedrooms'] as int?,
    bathrooms:     j['bathrooms'] as int?,
    availableFrom: j['availableFrom']?.toString(),        // ← camelCase
    description:   j['description']?.toString(),
  );

  String get primaryTag => tags.isNotEmpty ? tags.first : '';

  String get emoji => switch (primaryTag) {
    'apartment'   => '🏠',
    'single_room' => '🛏',
    'shared_room' => '🏘',
    'bedsitter'   => '🏣',
    'hostel'      => '🏫',
    _             => '🏠',
  };

  String get tagLabel => switch (primaryTag) {
    'apartment'   => 'Apartment',
    'single_room' => 'Single Room',
    'shared_room' => 'Shared Room',
    'bedsitter'   => 'Bedsitter',
    'hostel'      => 'Hostel',
    _             => 'Listing',
  };

  static String labelFor(String tag) => switch (tag) {
    'apartment'   => 'Apartment',
    'single_room' => 'Single Room',
    'shared_room' => 'Shared Room',
    'bedsitter'   => 'Bedsitter',
    'hostel'      => 'Hostel',
    _             => tag,
  };

  Color get gradA => switch (primaryTag) {
    'apartment'   => const Color(0xFFFDF0EC),
    'single_room' => const Color(0xFFF0F4FF),
    'shared_room' => const Color(0xFFECFDF5),
    'bedsitter'   => const Color(0xFFFFF3E0),
    'hostel'      => const Color(0xFFF3EEFF),
    _             => const Color(0xFFF8F9FF),
  };

  Color get gradB => switch (primaryTag) {
    'apartment'   => const Color(0xFFF4C5B5),
    'single_room' => const Color(0xFFDDE6FF),
    'shared_room' => const Color(0xFFA7F3D0),
    'bedsitter'   => const Color(0xFFFFCC80),
    'hostel'      => const Color(0xFFD8C8F8),
    _             => const Color(0xFFE1E5F7),
  };

  Color get typeColor => switch (primaryTag) {
    'apartment'   => HHColors.brandDark,
    'single_room' => HHColors.blue,
    'shared_room' => HHColors.teal,
    'bedsitter'   => HHColors.amber,
    'hostel'      => const Color(0xFF7C4DFF),
    _             => HHColors.text2,
  };

  Color get typePale => switch (primaryTag) {
    'apartment'   => HHColors.brandPale,
    'single_room' => HHColors.bluePale,
    'shared_room' => HHColors.tealPale,
    'bedsitter'   => HHColors.amberPale,
    'hostel'      => const Color(0xFFF3EEFF),
    _             => HHColors.surface2,
  };
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 1 — Browse Listings
// ─────────────────────────────────────────────────────────────
class HHListingsScreen extends StatefulWidget {
  const HHListingsScreen({super.key});

  @override
  State<HHListingsScreen> createState() => _HHListingsScreenState();
}

class _HHListingsScreenState extends State<HHListingsScreen> {
  int    _filter        = 0;
  bool   _loading       = true;
  bool   _moduleEnabled = true;
  String? _error;
  List<HousingListing> _listings = [];

  static const _filterLabels = [
    'All',
    '🏠 Apartment',
    '🛏 Single Room',
    '🏘 Shared Room',
    '🏣 Bedsitter',
    '🏫 Hostel',
  ];
  static const _filterTags = [
    '',
    'apartment',
    'single_room',
    'shared_room',
    'bedsitter',
    'hostel',
  ];

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await _checkModule();
    if (_moduleEnabled && mounted) await _loadListings();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _checkModule() async {
    try {
      final res = await ApiClient.get('/api/v1/housing/module/');
      dev.log('[HH] module → ${res.statusCode}');
      if (!mounted) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      // Shape: { "success": true, "data": { "enabled": true, ... } }
      final data = body?['data'];
      _moduleEnabled = (data is Map ? data['enabled'] : body?['enabled']) as bool? ?? true;
    } catch (e) {
      dev.log('[HH] module check error: $e');
      _moduleEnabled = true;
    }
  }

  Future<void> _loadListings() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    final tag = _filterTags[_filter];
    final qs  = tag.isNotEmpty ? '?tags=$tag' : '';
    try {
      final res = await ApiClient.get('/api/v1/housing/listings/$qs');
      dev.log('[HH] listings$qs → ${res.statusCode}');
      dev.log('[HH] body → ${res.body}');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        // StandardPagination always returns:
        // { "success": true, "data": [...], "meta": { ... } }
        List<dynamic> raw = [];
        if (decoded is List) {
          raw = decoded;
        } else if (decoded is Map) {
          final d = decoded['data'];
          if (d is List) {
            raw = d;                                    // ← our shape ✓
          } else if (d is Map) {
            raw = (d['results'] as List?) ?? [];
          } else {
            raw = (decoded['results'] as List?) ?? [];
          }
        }

        dev.log('[HH] parsed ${raw.length} listings');

        setState(() {
          _listings = raw
              .whereType<Map<String, dynamic>>()
              .map(HousingListing.fromJson)
              .toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error   = 'Could not load listings (${res.statusCode}).';
          _loading = false;
        });
      }
    } catch (e, s) {
      dev.log('[HH] listings error: $e', stackTrace: s);
      if (mounted) setState(() {
        _error   = 'Network error. Pull to refresh.';
        _loading = false;
      });
    }
  }

  Widget _maybeGrey(Widget child) {
    if (_moduleEnabled) return child;
    return Stack(children: [
      ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: child,
      ),
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => HapticFeedback.heavyImpact(),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 22),
              decoration: BoxDecoration(
                color: HHColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24),
                ]),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('🔒', style: TextStyle(fontSize: 34)),
                const SizedBox(height: 10),
                Text('Housing Hub unavailable',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: HHColors.text)),
                const SizedBox(height: 4),
                Text('This module has been temporarily\ndisabled. Check back soon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: HHColors.text3)),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HHColors.surface2,
      appBar: _buildAppBar(),
      body: _maybeGrey(
        RefreshIndicator(
          color: HHColors.brand,
          onRefresh: _moduleEnabled ? _loadListings : () async {},
          child: CustomScrollView(slivers: [

            SliverToBoxAdapter(child: _buildFilterRow()),

            SliverToBoxAdapter(
              child: HHSectionLabel(
                title: _filter == 0
                    ? 'All listings'
                    : _filterLabels[_filter],
                action: _listings.isNotEmpty
                    ? '${_listings.length} found'
                    : null,
              )),

            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: HHColors.brand)))

            else if (_error != null)
              SliverFillRemaining(child: _buildError())

            else if (_listings.isEmpty)
              SliverFillRemaining(child: _buildEmpty())

            else ...[
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _ListingCard(
                    listing: _listings[i],
                    onTap: () => _openDetail(_listings[i]),
                  ),
                  childCount: _listings.length,
                )),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ]),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: HHColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
          size: 18, color: HHColors.text),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Housing Hub',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: HHColors.brandDark,
              fontStyle: FontStyle.italic)),
          Text(
            _moduleEnabled
              ? (_loading
                  ? 'Loading…'
                  : '${_listings.length} listing${_listings.length == 1 ? '' : 's'} available')
              : 'Currently unavailable',
            style: TextStyle(fontSize: 11, color: HHColors.text3)),
        ]),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(color: HHColors.border, height: 1)),
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        itemCount: _filterLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (_, i) => HHChip(
          label: _filterLabels[i],
          active: _filter == i,
          onTap: _moduleEnabled ? () {
            setState(() => _filter = i);
            _loadListings();
          } : null,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: HHColors.text3)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _loadListings,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: HHColors.brandPale,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: HHColors.brand)),
                child: Text('Retry',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: HHColors.brand)),
              )),
          ])));
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏚', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text('No listings found',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: HHColors.text)),
          const SizedBox(height: 4),
          Text('Try a different filter',
            style: TextStyle(fontSize: 12, color: HHColors.text3)),
        ]));
  }

  void _openDetail(HousingListing l) {
    Navigator.push(context,
      MaterialPageRoute(
        builder: (_) => HHListingDetailScreen(listing: l)));
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 2 — Listing Detail
// ─────────────────────────────────────────────────────────────
class HHListingDetailScreen extends StatefulWidget {
  final HousingListing listing;
  const HHListingDetailScreen({super.key, required this.listing});

  @override
  State<HHListingDetailScreen> createState() =>
      _HHListingDetailScreenState();
}

class _HHListingDetailScreenState extends State<HHListingDetailScreen> {
  Map<String, dynamic>? _detail;
  bool _loadingDetail = true;
  bool _saved  = false;
  bool _saving = false;

  HousingListing get l => widget.listing;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    if (l.id.isEmpty) {
      if (mounted) setState(() => _loadingDetail = false);
      return;
    }
    try {
      final res = await ApiClient.get('/api/v1/housing/listings/${l.id}/');
      dev.log('[HHDetail] GET → ${res.statusCode}');
      dev.log('[HHDetail] body → ${res.body}');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>?;
        // Shape: { "success": true, "data": { ...listing... } }
        // or just the flat listing object
        final data = (body?['data'] is Map
            ? body!['data'] as Map<String, dynamic>
            : body) ?? {};
        setState(() {
          _detail        = data;
          _saved         = data['isSaved'] as bool? ?? false;  // ← camelCase
          _loadingDetail = false;
        });
      } else {
        setState(() => _loadingDetail = false);
      }
    } catch (e) {
      dev.log('[HHDetail] error: $e');
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  Future<void> _toggleSave() async {
    if (_saving || l.id.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() { _saved = !_saved; _saving = true; });
    try {
      final res = await ApiClient.post(
        '/api/v1/housing/listings/${l.id}/save/');
      dev.log('[HHDetail] POST /save/ → ${res.statusCode}');
      if (!mounted) return;
      if (res.statusCode != 200 && res.statusCode != 201) {
        setState(() => _saved = !_saved);
        _snack('Could not save listing.', color: HHColors.coral);
      } else {
        _snack(_saved ? 'Saved to your list ❤️' : 'Removed from saved',
          color: HHColors.teal);
      }
    } catch (e) {
      dev.log('[HHDetail] save error: $e');
      if (mounted) setState(() => _saved = !_saved);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
        style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color ?? HHColors.brand,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ));
  }

  // camelCase keys — matches HousingListingSerializer exactly
  String _f(String key, String fallback) =>
    _detail?[key]?.toString() ?? fallback;

  List<String> _listField(String key, List<String> fallback) =>
    (_detail?[key] as List?)?.map((e) => e.toString()).toList() ?? fallback;

  @override
  Widget build(BuildContext context) {
    final title     = _f('title',         l.title);
    final rent      = _f('rentPerMonth',  l.rentPerMonth);   // ← camelCase
    final location  = _f('locationName',  l.locationName);   // ← camelCase
    final about     = _f('description',   l.description ?? '');
    final available = _f('availableFrom', l.availableFrom ?? '');  // ← camelCase
    final bedrooms  = _detail?['bedrooms']?.toString() ?? l.bedrooms?.toString() ?? '—';
    final bathrooms = _detail?['bathrooms']?.toString() ?? l.bathrooms?.toString() ?? '—';
    final amenities = _listField('amenities', l.amenities);
    final tags      = _listField('tags',      l.tags);
    final imageUrls = _listField('imageUrls', l.imageUrls);  // ← camelCase

    return Scaffold(
      backgroundColor: HHColors.surface2,
      body: CustomScrollView(slivers: [

        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: l.gradA,
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _saved ? '❤️' : '🤍',
                      key: ValueKey(_saved),
                      style: const TextStyle(fontSize: 18)))))),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [l.gradA, l.gradB],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)),
              child: Stack(children: [
                if (imageUrls.isNotEmpty)
                  Positioned.fill(
                    child: ClipRRect(
                      child: Image.network(
                        imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(l.emoji,
                            style: const TextStyle(fontSize: 100))))))
                else
                  Center(child: Text(l.emoji,
                    style: const TextStyle(fontSize: 100))),

                Positioned(bottom: 16, left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: l.typeColor,
                      borderRadius: BorderRadius.circular(20)),
                    child: Text(l.tagLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)))),
                Positioned(bottom: 16, right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12)),
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: rent.isNotEmpty ? 'KES $rent' : '—',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: HHColors.brand)),
                        TextSpan(
                          text: '/mo',
                          style: TextStyle(
                            fontSize: 10,
                            color: HHColors.text3)),
                      ])))),
              ]),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: _loadingDetail
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(
                  child: CircularProgressIndicator(color: HHColors.brand)))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: HHColors.text,
                        height: 1.2,
                        fontStyle: FontStyle.italic))),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      const Text('📍', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Expanded(child: Text(location,
                        style: TextStyle(fontSize: 12, color: HHColors.text3))),
                    ])),

                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(spacing: 6, runSpacing: 6,
                        children: tags.map((tag) => HHTag(
                          HousingListing.labelFor(tag),
                          bg: l.typePale,
                          fg: l.typeColor,
                        )).toList())),
                  ],

                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      _StatChip(value: bedrooms,  label: 'Bedrooms'),
                      const SizedBox(width: 8),
                      _StatChip(value: bathrooms, label: 'Bathrooms'),
                      const SizedBox(width: 8),
                      _StatChip(
                        value: available.isNotEmpty ? available : 'Now',
                        label: 'Available',
                        small: available.length > 6),
                    ])),

                  if (amenities.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    HHSectionLabel(title: 'Amenities'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(spacing: 8, runSpacing: 8,
                        children: amenities.map((a) => HHTag(a,
                          bg: HHColors.greenPale,
                          fg: HHColors.teal,
                        )).toList())),
                  ],

                  if (about.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    HHSectionLabel(title: 'About this listing'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(about,
                        style: TextStyle(
                          fontSize: 13,
                          color: HHColors.text2,
                          height: 1.65))),
                  ],

                  if (imageUrls.length > 1) ...[
                    const SizedBox(height: 4),
                    HHSectionLabel(title: 'Photos'),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemCount: imageUrls.length,
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imageUrls[i],
                            width: 130,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 130,
                              color: HHColors.surface2,
                              child: const Center(
                                child: Text('🖼',
                                  style: TextStyle(fontSize: 28)))))))),
                  ],

                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      GestureDetector(
                        onTap: _toggleSave,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: _saved ? HHColors.brandPale : HHColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _saved ? HHColors.brand : HHColors.border,
                              width: 1.5)),
                          child: Text(
                            _saved ? '❤️  Saved' : '🤍  Save',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _saved ? HHColors.brand : HHColors.text2)))),
                      const SizedBox(width: 10),
                      Expanded(child: GestureDetector(
                        onTap: () => _snack('Contacting agent…', color: HHColors.teal),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: HHColors.brand,
                            borderRadius: BorderRadius.circular(14)),
                          child: const Center(
                            child: Text('Contact Agent',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)))))),
                    ])),

                  const SizedBox(height: 48),
                ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Private widgets
// ─────────────────────────────────────────────────────────────
class _ListingCard extends StatelessWidget {
  final HousingListing listing;
  final VoidCallback onTap;
  const _ListingCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = listing;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: HHTheme.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [l.gradA, l.gradB],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18))),
              child: Stack(children: [
                if (l.imageUrls.isNotEmpty)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18)),
                      child: Image.network(
                        l.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(l.emoji,
                            style: const TextStyle(fontSize: 58))))))
                else
                  Center(child: Text(l.emoji,
                    style: const TextStyle(fontSize: 58))),

                Positioned(top: 10, left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: l.typeColor,
                      borderRadius: BorderRadius.circular(20)),
                    child: Text(l.tagLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)))),
                Positioned(top: 10, right: 10,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.90),
                      shape: BoxShape.circle),
                    child: const Center(
                      child: Text('🤍', style: TextStyle(fontSize: 14))))),
              ])),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(l.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: HHColors.text),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('KES ${l.rentPerMonth}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: HHColors.brand)),
                      const SizedBox(width: 3),
                      Text('/month',
                        style: TextStyle(fontSize: 11, color: HHColors.text3)),
                    ]),
                  const SizedBox(height: 4),

                  Row(children: [
                    const Text('📍', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 3),
                    Expanded(child: Text(l.locationName,
                      style: TextStyle(fontSize: 11, color: HHColors.text3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
                  ]),

                  if (l.tags.length > 1) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 5, runSpacing: 5,
                      children: l.tags.skip(1).map<Widget>((tag) =>
                        HHTag(HousingListing.labelFor(tag),
                          bg: l.typePale,
                          fg: l.typeColor)
                      ).toList()),
                  ],

                  if (l.amenities.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(spacing: 5, runSpacing: 5,
                      children: l.amenities
                          .take(3)
                          .map<Widget>((a) => HHTag(a,
                            bg: HHColors.surface2,
                            fg: HHColors.text2))
                          .toList()),
                  ],

                  const SizedBox(height: 10),
                  Divider(color: HHColors.border, height: 1),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Text('📅', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 4),
                        Text(
                          l.availableFrom ?? 'Available now',
                          style: TextStyle(
                            fontSize: 11,
                            color: l.availableFrom != null
                              ? HHColors.text3
                              : HHColors.green,
                            fontWeight: l.availableFrom == null
                              ? FontWeight.w700
                              : FontWeight.normal)),
                      ]),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: HHColors.brand,
                          borderRadius: BorderRadius.circular(10)),
                        child: const Text('View →',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white))),
                    ]),
                ])),
          ])),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final bool small;
  const _StatChip({
    required this.value,
    required this.label,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: HHColors.brandPale,
        borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(value,
          style: TextStyle(
            fontSize: small ? 12 : 16,
            fontWeight: FontWeight.w900,
            color: HHColors.brand)),
        const SizedBox(height: 2),
        Text(label,
          style: TextStyle(fontSize: 10, color: HHColors.text3)),
      ])));
}