// campus_market/screens/cm_listings_screen.dart
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cm_constants.dart';
import '../widgets/cm_widgets.dart';
import '../../../core/api_client.dart';

// ─────────────────────────────────────────────────────────────
//  API ENDPOINTS  (all under /api/v1/market/)
//
//  GET    /api/v1/market/listings/                             → list / filter
//  GET    /api/v1/market/listings/?category=<cat>&search=<q>  → filtered list
//  GET    /api/v1/market/listings/<uuid>/                      → detail
//  POST   /api/v1/market/saved/          { listingId }        → save
//  DELETE /api/v1/market/saved/          { listingId }        → unsave
//  GET    /api/v1/market/messages/<uuid>/                      → conversation
//  POST   /api/v1/market/messages/       { listingId, body }  → send message
//  GET    /api/v1/market/reviews/        ?sellerId=<id>        → seller reviews
//  POST   /api/v1/market/reviews/        { listingId, ... }   → post review
// ─────────────────────────────────────────────────────────────

// NOTE: CMListing, CMStats, CMMessage, CMReview are all imported
//       from ../models/cm_constants.dart — do NOT redefine them here.

const _kFilters = ['All', 'Electronics', 'Books', 'Furniture', 'Clothing', 'Free'];

// ─────────────────────────────────────────────────────────────
//  SCREEN 1 — BROWSE LISTINGS
//  GET /api/v1/market/listings/?category=<cat>&search=<q>
// ─────────────────────────────────────────────────────────────
class CMListingsScreen extends StatefulWidget {
  const CMListingsScreen({super.key});
  @override
  State<CMListingsScreen> createState() => _CMListingsScreenState();
}

class _CMListingsScreenState extends State<CMListingsScreen> {
  int    _filter = 0;
  String _query  = '';

  List<CMListing> _listings = [];
  bool            _loading  = true;
  String?         _error;

  DateTime _lastSearch = DateTime(0);

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  // ─────────────────────────────────────────────────────────
  //  READ: GET /api/v1/market/listings/
  // ─────────────────────────────────────────────────────────
  Future<void> _loadListings() async {
    if (mounted) setState(() { _loading = true; _error = null; });

    final params = <String>[];
    final cat = _kFilters[_filter];
    if (cat == 'Free') {
      params.add('isFree=true');
    } else if (cat != 'All') {
      params.add('category=$cat');
    }
    if (_query.isNotEmpty) params.add('search=${Uri.encodeComponent(_query)}');
    final qs = params.isEmpty ? '' : '?${params.join('&')}';

    try {
      final res = await ApiClient.get('/api/v1/market/listings/$qs');
      dev.log('[Listings] GET /listings$qs → ${res.statusCode}');
      dev.log('[Listings] body: ${res.body}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final raw = decoded is List
            ? decoded
            : (decoded['results'] as List?) ?? [];

        setState(() {
          _listings = raw
              .whereType<Map<String, dynamic>>()
              .map(CMListing.fromJson)
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
      dev.log('[Listings] error: $e', stackTrace: s);
      if (mounted) setState(() {
        _error   = 'Network error. Pull to refresh.';
        _loading = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────
  //  UPDATE: Save / unsave
  // ─────────────────────────────────────────────────────────
  Future<void> _toggleSave(CMListing l) async {
    final wasSaved = l.isSaved;
    setState(() {
      _listings = _listings.map((x) =>
          x.id == l.id ? x.copyWith(isSaved: !wasSaved) : x).toList();
    });

    try {
      final res = wasSaved
          ? await ApiClient.delete('/api/v1/market/saved/',
              body: {'listingId': l.id})
          : await ApiClient.post('/api/v1/market/saved/',
              body: {'listingId': l.id});

      dev.log('[Listings] Save ${l.id} → ${res.statusCode}');

      final ok = res.statusCode == 200 ||
                 res.statusCode == 201 ||
                 res.statusCode == 204;
      if (!ok) {
        setState(() {
          _listings = _listings.map((x) =>
              x.id == l.id ? x.copyWith(isSaved: wasSaved) : x).toList();
        });
        _snack('Could not save listing. Please try again.');
      } else {
        _snack(wasSaved ? 'Listing unsaved.' : '❤️ Saved to wishlist!');
      }
    } catch (_) {
      setState(() {
        _listings = _listings.map((x) =>
            x.id == l.id ? x.copyWith(isSaved: wasSaved) : x).toList();
      });
      _snack('Network error. Please try again.');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: CMColors.brandDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      ));
  }

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CMColors.surface2,
      body: RefreshIndicator(
        color: CMColors.brand,
        onRefresh: _loadListings,
        child: CustomScrollView(slivers: [

          // ── App bar ──────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: CMColors.brand,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
              onPressed: () => Navigator.pop(context)),
            title: const Text('Browse Listings', style: TextStyle(
              fontWeight: FontWeight.w800, color: Colors.white)),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: IconButton(
                  icon: const Icon(Icons.filter_list_rounded,
                    color: Colors.white),
                  onPressed: () => HapticFeedback.selectionClick())),
            ],
          ),

          // ── Search bar ────────────────────────────────
          SliverToBoxAdapter(
            child: CMSearchBar(
              hint: 'Search listings…',
              onChanged: (v) {
                setState(() => _query = v);
                final now = DateTime.now();
                _lastSearch = now;
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_lastSearch == now) _loadListings();
                });
              },
            )),

          // ── Filter chips ──────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                itemCount: _kFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => CMChip(
                  label: _kFilters[i],
                  active: _filter == i,
                  onTap: () {
                    setState(() => _filter = i);
                    _loadListings();
                  }),
              ))),

          // ── Results count ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: _loading
                ? const SizedBox.shrink()
                : Text('${_listings.length} listings found',
                    style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CMColors.text3)),
            )),

          // ── Loading / error / grid ────────────────────
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            SliverFillRemaining(
              child: Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: CMColors.text3)),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _loadListings,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry')),
                ])))
          else if (_listings.isEmpty)
            SliverFillRemaining(
              child: Center(child: Text('No listings found.',
                style: TextStyle(fontSize: 13, color: CMColors.text3))))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _ListingGridCard(
                    listing: _listings[i],
                    onSaveTap: () => _toggleSave(_listings[i]),
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                        builder: (_) => CMListingDetailScreen(
                          listingId: _listings[i].id,
                          snapshot:  _listings[i],
                        ))).then((_) => _loadListings()),
                  ),
                  childCount: _listings.length,
                ),
              )),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 2 — LISTING DETAIL
//  GET    /api/v1/market/listings/<uuid>/
//  POST   /api/v1/market/saved/
//  DELETE /api/v1/market/saved/
//  GET    /api/v1/market/reviews/?sellerId=<id>
// ─────────────────────────────────────────────────────────────
class CMListingDetailScreen extends StatefulWidget {
  final String     listingId;
  final CMListing? snapshot;

  const CMListingDetailScreen({
    super.key,
    required this.listingId,
    this.snapshot,
  });

  @override
  State<CMListingDetailScreen> createState() => _CMListingDetailScreenState();
}

class _CMListingDetailScreenState extends State<CMListingDetailScreen> {
  CMListing?     _listing;
  List<CMReview> _reviews = [];
  bool           _loading = true;
  String?        _error;

  @override
  void initState() {
    super.initState();
    if (widget.snapshot != null) {
      _listing = widget.snapshot;
      _loading = false;
    }
    _fetchDetail();
    if (widget.snapshot?.sellerId.isNotEmpty == true) {
      _fetchReviews(widget.snapshot!.sellerId);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  READ: GET /api/v1/market/listings/<uuid>/
  // ─────────────────────────────────────────────────────────
  Future<void> _fetchDetail() async {
    if (_listing == null && mounted) setState(() => _loading = true);
    try {
      final res = await ApiClient.get(
          '/api/v1/market/listings/${widget.listingId}/');
      dev.log('[Detail] GET /listings/${widget.listingId}/ → ${res.statusCode}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          final fresh = CMListing.fromJson(decoded);
          setState(() {
            _listing = fresh;
            _loading = false;
            _error   = null;
          });
          if (fresh.sellerId.isNotEmpty) _fetchReviews(fresh.sellerId);
        }
      } else if (_listing == null) {
        setState(() {
          _error   = 'Could not load listing (${res.statusCode}).';
          _loading = false;
        });
      }
    } catch (e, s) {
      dev.log('[Detail] error: $e', stackTrace: s);
      if (mounted && _listing == null) {
        setState(() {
          _error   = 'Network error.';
          _loading = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  //  READ: GET /api/v1/market/reviews/?sellerId=<id>
  // ─────────────────────────────────────────────────────────
  Future<void> _fetchReviews(String sellerId) async {
    try {
      final res = await ApiClient.get(
          '/api/v1/market/reviews/?sellerId=$sellerId');
      dev.log('[Detail] GET /reviews?sellerId=$sellerId → ${res.statusCode}');

      if (!mounted || res.statusCode != 200) return;
      final decoded = jsonDecode(res.body);
      final raw = decoded is List
          ? decoded
          : (decoded['results'] as List?) ?? [];

      setState(() {
        _reviews = raw
            .whereType<Map<String, dynamic>>()
            .map(CMReview.fromJson)
            .toList();
      });
    } catch (e) {
      dev.log('[Detail] fetchReviews error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  UPDATE: Save / unsave
  // ─────────────────────────────────────────────────────────
  Future<void> _toggleSave() async {
    if (_listing == null) return;
    final wasSaved = _listing!.isSaved;
    setState(() => _listing = _listing!.copyWith(isSaved: !wasSaved));

    try {
      final res = wasSaved
          ? await ApiClient.delete('/api/v1/market/saved/',
              body: {'listingId': widget.listingId})
          : await ApiClient.post('/api/v1/market/saved/',
              body: {'listingId': widget.listingId});

      dev.log('[Detail] Save → ${res.statusCode}');

      final ok = res.statusCode == 200 ||
                 res.statusCode == 201 ||
                 res.statusCode == 204;
      if (!ok) {
        setState(() => _listing = _listing!.copyWith(isSaved: wasSaved));
        _snack('Could not save listing.');
      } else {
        _snack(wasSaved ? 'Listing unsaved.' : 'Saved to wishlist ❤️');
      }
    } catch (_) {
      setState(() => _listing = _listing!.copyWith(isSaved: wasSaved));
      _snack('Network error. Please try again.');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: CMColors.brandDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      ));
  }

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_error != null && _listing == null) {
      return Scaffold(
        backgroundColor: CMColors.surface2,
        appBar: AppBar(
          backgroundColor: CMColors.brand,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
            onPressed: () => Navigator.pop(context))),
        body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: CMColors.text3)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _fetchDetail,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry')),
          ])),
      );
    }

    final l = _listing;

    return Scaffold(
      backgroundColor: CMColors.surface2,
      body: CustomScrollView(slivers: [

        // ── Hero app bar ─────────────────────────────
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          backgroundColor: CMColors.brand,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
            onPressed: () => Navigator.pop(context)),
          actions: [
            IconButton(
              icon: Icon(
                l?.isSaved == true
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
                color: Colors.white),
              onPressed: _toggleSave),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: l == null
              ? Container(color: CMColors.brandPale,
                  child: const Center(child: CircularProgressIndicator()))
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [l.gradA, l.gradB])),
                  child: Stack(children: [
                    Positioned.fill(child: Center(
                      child: Text(l.emoji,
                        style: const TextStyle(fontSize: 100)))),
                    Positioned(bottom: 16, left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: CMColors.brand,
                          borderRadius: BorderRadius.circular(8)),
                        child: Text(l.category, style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w800,
                          color: Colors.white)))),
                  ])),
          ),
        ),

        // ── Body ─────────────────────────────────────
        SliverToBoxAdapter(
          child: l == null
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()))
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(l.title, style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900,
                          color: CMColors.text))),
                        const SizedBox(width: 12),
                        Text(l.price, style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900,
                          color: l.isFree ? CMColors.green : CMColors.brand)),
                      ]),
                    const SizedBox(height: 12),

                    // Tags
                    Row(children: [
                      CMTag(l.condition),
                      const SizedBox(width: 8),
                      CMTag(l.category),
                    ]),
                    const SizedBox(height: 20),

                    // Seller card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: CMTheme.card,
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [CMColors.brand, CMColors.brandDark])),
                          child: Center(child: Text(
                            l.seller.isNotEmpty ? l.seller[0] : 'U',
                            style: const TextStyle(fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.seller, style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800,
                              color: CMColors.text)),
                            Text(
                              'Verified campus seller  ⭐ ${l.sellerRating}',
                              style: TextStyle(
                                fontSize: 11, color: CMColors.text3)),
                          ])),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: CMColors.brandPale,
                            borderRadius: BorderRadius.circular(8)),
                          child: Text('View profile', style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: CMColors.brand))),
                      ])),
                    const SizedBox(height: 16),

                    // Item details
                    CMSectionLabel(title: '📋 Item Details'),
                    CMFormField(label: 'Condition',   value: l.condition),
                    CMFormField(label: 'Category',    value: l.category),
                    CMFormField(label: 'Location',    value: '📍 ${l.location}'),
                    CMFormField(
                      label: 'Description',
                      value: l.description.isNotEmpty
                        ? l.description
                        : 'Well maintained ${l.title}. Available for pickup '
                          'or delivery within campus.',
                      multiline: true),

                    // Seller reviews
                    if (_reviews.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      CMSectionLabel(title: '⭐ Seller Reviews'),
                      ..._reviews.take(3).map((r) => _ReviewTile(review: r)),
                    ],

                    const SizedBox(height: 20),

                    // CTA buttons
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => CMContactSellerScreen(
                                listingId:  widget.listingId,
                                sellerName: l.seller,
                                itemTitle:  l.title,
                                itemPrice:  l.price,
                              ))).then((_) => _fetchDetail());
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [CMColors.brand, CMColors.brandDark]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(
                                color: CMColors.brand.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4))]),
                            child: const Center(child: Text(
                              '📨 Contact Seller',
                              style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white))))),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: CMColors.border),
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white),
                        child: const Text('🔗',
                          style: TextStyle(fontSize: 20))),
                    ]),
                  ]))),

        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 3 — CONTACT SELLER
//  GET    /api/v1/market/messages/<uuid>/
//  POST   /api/v1/market/messages/
// ─────────────────────────────────────────────────────────────
class CMContactSellerScreen extends StatefulWidget {
  final String listingId;
  final String sellerName;
  final String itemTitle;
  final String itemPrice;

  const CMContactSellerScreen({
    super.key,
    required this.listingId,
    this.sellerName = 'Seller',
    this.itemTitle  = 'Item',
    this.itemPrice  = 'KES 0',
  });

  @override
  State<CMContactSellerScreen> createState() => _CMContactSellerScreenState();
}

class _CMContactSellerScreenState extends State<CMContactSellerScreen> {
  String _channel = 'Chat';
  bool   _sending = false;

  final _msgCtrl   = TextEditingController();
  final _offerCtrl = TextEditingController();

  List<CMMessage> _thread       = [];
  bool            _loadingThread = true;

  @override
  void initState() {
    super.initState();
    _loadThread();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _offerCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  //  READ: GET /api/v1/market/messages/<uuid>/
  // ─────────────────────────────────────────────────────────
  Future<void> _loadThread() async {
    if (mounted) setState(() => _loadingThread = true);
    try {
      final res = await ApiClient.get(
          '/api/v1/market/messages/${widget.listingId}/');
      dev.log('[Contact] GET /messages/${widget.listingId}/ → ${res.statusCode}');

      if (!mounted) return;
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final raw = decoded is List
            ? decoded
            : (decoded['results'] as List?) ?? [];
        setState(() {
          _thread        = raw
              .whereType<Map<String, dynamic>>()
              .map(CMMessage.fromJson)
              .toList();
          _loadingThread = false;
        });
      } else {
        setState(() => _loadingThread = false);
      }
    } catch (e) {
      dev.log('[Contact] loadThread error: $e');
      if (mounted) setState(() => _loadingThread = false);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  CREATE: POST /api/v1/market/messages/
  // ─────────────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final body  = _msgCtrl.text.trim();
    final offer = _offerCtrl.text.trim();

    if (body.isEmpty) { _snack('Please enter a message.'); return; }

    setState(() => _sending = true);

    try {
      final payload = <String, dynamic>{
        'listingId': widget.listingId,
        'body':      body,
        'channel':   _channel,
      };
      if (offer.isNotEmpty) payload['offerPrice'] = offer;

      final res = await ApiClient.post(
          '/api/v1/market/messages/', body: payload);
      dev.log('[Contact] POST /messages/ → ${res.statusCode}');

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        _msgCtrl.clear();
        _offerCtrl.clear();
        await _loadThread();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Message sent to ${widget.sellerName} via $_channel ✓'),
          backgroundColor: CMColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12))));
      } else {
        final errBody = jsonDecode(res.body) as Map<String, dynamic>?;
        _snack(errBody?['detail']?.toString()
            ?? 'Could not send message (${res.statusCode}).');
      }
    } catch (e) {
      dev.log('[Contact] sendMessage error: $e');
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
        content: Text(msg),
        backgroundColor: CMColors.brandDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      ));
  }

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CMColors.surface2,
      appBar: AppBar(
        backgroundColor: CMColors.brand,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white),
          onPressed: () => Navigator.pop(context)),
        title: Text('Contact ${widget.sellerName}',
          style: const TextStyle(
            fontWeight: FontWeight.w800, color: Colors.white))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Item summary card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: CMTheme.card,
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: CMColors.brandPale,
                  borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('📦',
                  style: TextStyle(fontSize: 26)))),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.itemTitle, maxLines: 2,
                    style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: CMColors.text, height: 1.3)),
                  const SizedBox(height: 4),
                  Text(widget.itemPrice, style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900,
                    color: CMColors.brand)),
                ])),
            ])),

          // Existing thread
          if (_loadingThread)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_thread.isNotEmpty) ...[
            CMSectionLabel(title: '💬 Previous Messages'),
            Container(
              decoration: CMTheme.card,
              child: Column(
                children: _thread.map((m) =>
                  _MessageBubble(message: m)).toList())),
            const SizedBox(height: 8),
          ],

          CMSectionLabel(title: '📡 Contact via'),

          // Channel picker
          Row(children: ['Chat', 'WhatsApp', 'Email'].map<Widget>((c) =>
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: CMChip(
                label: c, active: _channel == c,
                onTap: () => setState(() => _channel = c))))).toList()),

          const SizedBox(height: 16),
          CMSectionLabel(title: '💬 Your message'),

          // Message input
          Container(
            decoration: CMTheme.card,
            child: TextField(
              controller: _msgCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Hi! I'm interested in your ${widget.itemTitle}. "
                    'Is it still available?',
                hintStyle: TextStyle(fontSize: 13, color: CMColors.text3),
                contentPadding: const EdgeInsets.all(14),
                border: InputBorder.none))),

          CMSectionLabel(title: '💰 Make an offer (optional)'),

          // Offer input
          Container(
            decoration: CMTheme.card,
            child: TextField(
              controller: _offerCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: widget.itemPrice
                    .replaceAll(RegExp(r'[^0-9]'), ''),
                hintStyle: TextStyle(fontSize: 13, color: CMColors.text3),
                prefixText: 'KES  ',
                prefixStyle: TextStyle(
                  fontWeight: FontWeight.w700, color: CMColors.text),
                contentPadding: const EdgeInsets.all(14),
                border: InputBorder.none))),

          const SizedBox(height: 24),

          // Send
          CMPrimaryButton(
            label: _sending ? 'Sending…' : 'Send Message via $_channel',
            onTap: _sending ? null : _sendMessage,
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  LISTING GRID CARD
// ─────────────────────────────────────────────────────────────
class _ListingGridCard extends StatelessWidget {
  final CMListing   listing;
  final VoidCallback onTap;
  final VoidCallback onSaveTap;
  const _ListingGridCard({
    required this.listing,
    required this.onTap,
    required this.onSaveTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = listing;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CMColors.border),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Banner
          Container(
            height: 110,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16)),
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [l.gradA, l.gradB])),
            child: Stack(children: [
              Center(child: Text(l.emoji,
                style: const TextStyle(fontSize: 46))),
              if (l.isFeatured)
                Positioned(top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: CMColors.accent,
                      borderRadius: BorderRadius.circular(6)),
                    child: const Text('🔥 Hot', style: TextStyle(
                      fontSize: 8, fontWeight: FontWeight.w800,
                      color: Colors.white)))),
              Positioned(top: 8, right: 8,
                child: GestureDetector(
                  onTap: onSaveTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: l.isSaved
                        ? Colors.red.withOpacity(0.85)
                        : Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle),
                    child: Center(child: Text(
                      l.isSaved ? '❤️' : '🤍',
                      style: const TextStyle(fontSize: 12)))))),
            ])),
          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.title, maxLines: 2, style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: CMColors.text, height: 1.3)),
                const SizedBox(height: 5),
                Text(l.price, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w900,
                  color: l.isFree ? CMColors.green : CMColors.brand)),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text(l.condition, maxLines: 1,
                      style: TextStyle(fontSize: 10, color: CMColors.text3))),
                    Text(l.time, style: TextStyle(
                      fontSize: 10, color: CMColors.text3)),
                  ]),
              ])),
        ])));
  }
}

// ─────────────────────────────────────────────────────────────
//  REVIEW TILE
// ─────────────────────────────────────────────────────────────
class _ReviewTile extends StatelessWidget {
  final CMReview review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: CMTheme.card,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CMColors.brandPale),
              child: Center(child: Text(
                review.reviewerName.isNotEmpty
                  ? review.reviewerName[0] : 'U',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: CMColors.brand)))),
            const SizedBox(width: 8),
            Expanded(child: Text(review.reviewerName,
              style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w700, color: CMColors.text))),
            Text('⭐ ${review.rating.toStringAsFixed(1)}',
              style: TextStyle(fontSize: 11, color: CMColors.text3)),
          ]),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.comment, style: TextStyle(
              fontSize: 11, color: CMColors.text2, height: 1.4)),
          ],
        ])));
  }
}

// ─────────────────────────────────────────────────────────────
//  MESSAGE BUBBLE
// ─────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final CMMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment:
          mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: mine ? CMColors.brand : CMColors.brandPale,
              borderRadius: BorderRadius.circular(12)),
            child: Text(message.body, style: TextStyle(
              fontSize: 12,
              color: mine ? Colors.white : CMColors.text,
              height: 1.4))),
        ]));
  }
}