// campus_market/screens/cm_donations_screen.dart
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cm_constants.dart';
import '../widgets/cm_widgets.dart';
import '../../../core/api_client.dart';
import 'cm_post_screen.dart';

// ─────────────────────────────────────────────────────────────
//  API ENDPOINTS  (all under /api/v1/market/)
//
//  GET    /api/v1/market/listings/?listing_type=donation      → donations only
//  GET    /api/v1/market/listings/?listing_type=donation
//                                 &category=<cat>&search=<q>  → filtered
//  GET    /api/v1/market/listings/<uuid>/                      → detail
//  POST   /api/v1/market/donations/<uuid>/claim/              → submit claim
//  GET    /api/v1/market/donations/<uuid>/claims/<uuid>/      → claim status
//  PATCH  /api/v1/market/donations/<uuid>/claims/<uuid>/      → approve / reject
// ─────────────────────────────────────────────────────────────

const _kDonationFilters = ['All', 'Books', 'Electronics', 'Clothing', 'Other'];

// ─────────────────────────────────────────────────────────────
//  IMAGE HELPER — decode a data-URI to raw bytes
// ─────────────────────────────────────────────────────────────
Uint8List? _decodeDataUri(String uri) {
  try {
    final comma = uri.indexOf(',');
    if (comma == -1) return null;
    return base64Decode(uri.substring(comma + 1));
  } catch (_) {
    return null;
  }
}

// ─────────────────────────────────────────────────────────────
//  DONATION IMAGE WIDGET
//  Shows the first real photo; falls back to gradient + emoji.
// ─────────────────────────────────────────────────────────────
class _DonationImage extends StatelessWidget {
  final CMListing listing;
  final double    height;
  final double    width;
  final BorderRadius? borderRadius;

  const _DonationImage({
    required this.listing,
    required this.height,
    this.width        = double.infinity,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final urls = listing.imageUrls;
    if (urls.isNotEmpty) {
      final bytes = _decodeDataUri(urls.first);
      if (bytes != null) {
        final img = Image.memory(
          bytes,
          height: height,
          width:  width,
          fit:    BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _fallback(),
        );
        return borderRadius != null
            ? ClipRRect(borderRadius: borderRadius!, child: img)
            : img;
      }
    }
    return _fallback();
  }

  Widget _fallback() => Container(
    height:      height,
    width:       width,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end:   Alignment.bottomRight,
        colors: [listing.gradA, listing.gradB],
      ),
      borderRadius: borderRadius,
    ),
    child: Center(
      child: Text(listing.emoji,
        style: TextStyle(fontSize: height * 0.40))),
  );
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 1: DONATIONS BROWSE  (listing_type = donation)
//  GET /api/v1/market/listings/?listing_type=donation&category=<cat>&search=<q>
// ─────────────────────────────────────────────────────────────
class CMDonationsScreen extends StatefulWidget {
  const CMDonationsScreen({super.key});
  @override
  State<CMDonationsScreen> createState() => _CMDonationsScreenState();
}

class _CMDonationsScreenState extends State<CMDonationsScreen> {
  int    _filter = 0;
  String _query  = '';

  List<CMListing> _donations = [];
  bool            _loading   = true;
  String?         _error;

  DateTime _lastSearch = DateTime(0);

  @override
  void initState() {
    super.initState();
    _loadDonations();
  }

  // ─────────────────────────────────────────────────────────
  //  READ: GET /api/v1/market/listings/?listing_type=donation
  // ─────────────────────────────────────────────────────────
  Future<void> _loadDonations() async {
    if (mounted) setState(() { _loading = true; _error = null; });

    // Always scope to donation listings only
    final params = <String>['listing_type=donation'];
    final cat = _kDonationFilters[_filter];
    if (cat != 'All') params.add('category=${Uri.encodeComponent(cat)}');
    if (_query.isNotEmpty) params.add('search=${Uri.encodeComponent(_query)}');
    final qs = '?${params.join('&')}';

    try {
      final res = await ApiClient.get('/api/v1/market/listings/$qs');
      dev.log('[Donations] GET /listings$qs → ${res.statusCode}');
      dev.log('[Donations] body snippet: ${res.body.length > 200 ? res.body.substring(0, 200) : res.body}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final raw = decoded is List
            ? decoded
            : (decoded['results'] as List?) ?? [];

        setState(() {
          _donations = raw
              .whereType<Map<String, dynamic>>()
              .map(CMListing.fromJson)
              // extra client-side guard: only donation type
              .where((l) => l.listingType == 'donation')
              .toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error   = 'Could not load donations (${res.statusCode}).';
          _loading = false;
        });
      }
    } catch (e, s) {
      dev.log('[Donations] error: $e', stackTrace: s);
      if (mounted) setState(() {
        _error   = 'Network error. Pull to refresh.';
        _loading = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CMColors.surface2,
      body: RefreshIndicator(
        color: CMColors.green,
        onRefresh: _loadDonations,
        child: CustomScrollView(slivers: [

          // ── Hero app bar ─────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: CMColors.green,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
              onPressed: () => Navigator.pop(context)),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute(
                    builder: (_) => const CMCreateListingScreen(
                      displayType: 'Donate for Free',
                      listingType: 'donation',
                    ))).then((_) => _loadDonations()),
                icon: const Icon(Icons.add_rounded,
                  color: Colors.white, size: 18),
                label: const Text('Donate',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF34D399),
                      Color(0xFF10B981),
                      Color(0xFF0D9488),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('🎁 Free Donations', style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: Colors.white70, letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        const Text('Free items near campus', style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w900,
                          color: Colors.white)),
                        Text(
                          _loading
                            ? 'Loading…'
                            : '${_donations.length} items available right now',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Search bar ────────────────────────────────
          SliverToBoxAdapter(
            child: CMSearchBar(
              hint: 'Search free items…',
              onChanged: (v) {
                setState(() => _query = v);
                final now = DateTime.now();
                _lastSearch = now;
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_lastSearch == now) _loadDonations();
                });
              },
            )),

          // ── Filter chips ──────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                itemCount: _kDonationFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _GreenChip(
                  label: _kDonationFilters[i],
                  active: _filter == i,
                  onTap: () {
                    setState(() => _filter = i);
                    _loadDonations();
                  },
                ),
              ),
            )),

          // ── Results count ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: _loading
                ? const SizedBox.shrink()
                : Text('${_donations.length} items available for free',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CMColors.text3)),
            )),

          // ── Loading / error / list ────────────────────
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
                    onPressed: _loadDonations,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry')),
                ])))
          else if (_donations.isEmpty)
            SliverFillRemaining(
              child: Center(child: Text('No donations available.',
                style: TextStyle(fontSize: 13, color: CMColors.text3))))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _DonationCard(
                  donation: _donations[i],
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                      builder: (_) => CMDonationDetailScreen(
                        listingId: _donations[i].id,
                        snapshot:  _donations[i],
                      ))).then((_) => _loadDonations()),
                ),
                childCount: _donations.length,
              )),

          // ── Donate CTA banner ─────────────────────────
          SliverToBoxAdapter(
            child: _DonateBanner(
              onTap: () => Navigator.push(context,
                MaterialPageRoute(
                  builder: (_) => const CMCreateListingScreen(
                    displayType: 'Donate for Free',
                    listingType: 'donation',
                  ))).then((_) => _loadDonations()),
            )),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 2: DONATION DETAIL
//  GET  /api/v1/market/listings/<uuid>/
//  POST /api/v1/market/donations/<uuid>/claim/
// ─────────────────────────────────────────────────────────────
class CMDonationDetailScreen extends StatefulWidget {
  final String     listingId;
  final CMListing? snapshot;

  const CMDonationDetailScreen({
    super.key,
    required this.listingId,
    this.snapshot,
  });

  @override
  State<CMDonationDetailScreen> createState() =>
      _CMDonationDetailScreenState();
}

class _CMDonationDetailScreenState extends State<CMDonationDetailScreen> {
  CMListing? _listing;
  bool       _loading  = true;
  String?    _error;
  bool       _claiming = false;
  int        _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.snapshot != null) {
      _listing = widget.snapshot;
      _loading = false;
    }
    _fetchDetail();
  }

  // ─────────────────────────────────────────────────────────
  //  READ: GET /api/v1/market/listings/<uuid>/
  // ─────────────────────────────────────────────────────────
  Future<void> _fetchDetail() async {
    if (_listing == null && mounted) setState(() => _loading = true);
    try {
      final res = await ApiClient.get(
          '/api/v1/market/listings/${widget.listingId}/');
      dev.log('[DonationDetail] GET /listings/${widget.listingId}/ → ${res.statusCode}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          setState(() {
            _listing    = CMListing.fromJson(decoded);
            _loading    = false;
            _error      = null;
            _imageIndex = 0;
          });
        }
      } else if (_listing == null) {
        setState(() {
          _error   = 'Could not load item (${res.statusCode}).';
          _loading = false;
        });
      }
    } catch (e, s) {
      dev.log('[DonationDetail] error: $e', stackTrace: s);
      if (mounted && _listing == null) {
        setState(() {
          _error   = 'Network error.';
          _loading = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  //  CREATE CLAIM → delegates to CMDonationClaimScreen
  //  POST /api/v1/market/donations/<uuid>/claim/
  // ─────────────────────────────────────────────────────────
  Future<void> _claimItem() async {
    HapticFeedback.mediumImpact();

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => CMDonationClaimScreen(
          listingId: widget.listingId,
          itemTitle: _listing?.title ?? 'this item',
        ),
      ),
    );

    if (result != null && mounted) {
      final claimId = result['claim_id']?.toString() ??
                      result['id']?.toString() ?? '';
      if (claimId.isNotEmpty) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => CMDonationClaimScreen(
            listingId: widget.listingId,
            itemTitle: _listing?.title ?? 'this item',
            claimId:   claimId,
          ),
        ));
      }
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: CMColors.green,
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
          backgroundColor: CMColors.green,
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
      appBar: AppBar(
        backgroundColor: CMColors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white),
          onPressed: () => Navigator.pop(context)),
        title: const Text('Free Item', style: TextStyle(
          fontWeight: FontWeight.w800, color: Colors.white))),
      body: l == null
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(children: [

              // ── Hero photo/banner ─────────────────
              SizedBox(
                height: 240,
                width:  double.infinity,
                child: Stack(children: [
                  // Swipeable if multiple photos
                  l.imageUrls.length > 1
                    ? PageView.builder(
                        itemCount: l.imageUrls.length,
                        onPageChanged: (i) =>
                            setState(() => _imageIndex = i),
                        itemBuilder: (_, i) {
                          final bytes = _decodeDataUri(l.imageUrls[i]);
                          if (bytes == null) {
                            return _donationFallback(l);
                          }
                          return Image.memory(bytes,
                            fit:    BoxFit.cover,
                            width:  double.infinity,
                            height: 240,
                            gaplessPlayback: true,
                            errorBuilder: (_, __, ___) =>
                                _donationFallback(l));
                        })
                    : _DonationImage(listing: l, height: 240),

                  // FREE badge
                  Positioned(
                    top: 16, left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: CMColors.green,
                        borderRadius: BorderRadius.circular(8)),
                      child: const Text('🎁 FREE', style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w900,
                        color: Colors.white)))),

                  // Dot indicators (multiple photos)
                  if (l.imageUrls.length > 1)
                    Positioned(
                      bottom: 10, left: 0, right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(l.imageUrls.length, (i) =>
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width:  _imageIndex == i ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _imageIndex == i
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(3)),
                          )))),
                ]),
              ),

              // ── Body ─────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.title, style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900,
                      color: CMColors.text)),
                    const SizedBox(height: 8),
                    Row(children: [
                      _GreenTag(l.category),
                      const SizedBox(width: 8),
                      const _GreenTag('Free'),
                    ]),
                    const SizedBox(height: 16),

                    // Donor card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: CMTheme.card,
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CMColors.green.withOpacity(0.15)),
                          child: Center(child: Text(
                            l.seller.isNotEmpty ? l.seller[0] : 'U',
                            style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900,
                              color: CMColors.green)))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.seller, style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800,
                              color: CMColors.text)),
                            Text('Posted ${l.time}',
                              style: TextStyle(
                                fontSize: 11, color: CMColors.text3)),
                          ])),
                      ])),
                    const SizedBox(height: 16),

                    CMFormField(
                      label: 'Pickup Location',
                      value: '📍 ${l.location}'),
                    CMFormField(label: 'Category', value: l.category),
                    CMFormField(
                      label: 'Description',
                      value: l.description.isNotEmpty
                        ? l.description
                        : 'Available now — first come, first served.',
                      multiline: true),
                    const SizedBox(height: 24),

                    // ── Claim CTA ─────────────────────
                    GestureDetector(
                      onTap: _claiming ? null : _claimItem,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _claiming
                              ? [CMColors.green.withOpacity(0.5),
                                 CMColors.green.withOpacity(0.5)]
                              : const [
                                  Color(0xFF34D399),
                                  Color(0xFF10B981),
                                ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(
                            color: CMColors.green.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4))]),
                        child: Center(child: Text(
                          _claiming ? 'Submitting…' : '🙌 Claim this Item',
                          style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800,
                            color: Colors.white))))),
                  ],
                ),
              ),
            ]),
          ),
    );
  }

  Widget _donationFallback(CMListing l) => Container(
    height: 240, width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [l.gradA, l.gradB])),
    child: Center(child: Text(l.emoji,
      style: const TextStyle(fontSize: 90))));
}

// ─────────────────────────────────────────────────────────────
//  PRIVATE WIDGETS
// ─────────────────────────────────────────────────────────────

class _GreenChip extends StatelessWidget {
  final String     label;
  final bool       active;
  final VoidCallback? onTap;
  const _GreenChip({required this.label, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? CMColors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? CMColors.green : CMColors.border)),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: active ? Colors.white : CMColors.text2)),
      ),
    );
  }
}

class _GreenTag extends StatelessWidget {
  final String label;
  const _GreenTag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CMColors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(
        fontSize: 10, fontWeight: FontWeight.w700,
        color: CMColors.green)),
    );
  }
}

// Row card in the browse list — thumbnail uses real photo
class _DonationCard extends StatelessWidget {
  final CMListing   donation;
  final VoidCallback onTap;
  const _DonationCard({required this.donation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = donation;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CMColors.border),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(children: [

          // Thumbnail — real photo or gradient fallback
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16)),
            child: _DonationImage(
              listing:      d,
              height:       88,
              width:        88,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16)),
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: CMColors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5)),
                      child: Text('FREE 🎁', style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w800,
                        color: CMColors.green))),
                    const SizedBox(width: 6),
                    Text(d.category,
                      style: TextStyle(fontSize: 10, color: CMColors.text3)),
                  ]),
                  const SizedBox(height: 5),
                  Text(d.title, maxLines: 2, style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800,
                    color: CMColors.text, height: 1.3)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Text('📍 ', style: TextStyle(fontSize: 10)),
                    Expanded(child: Text(d.location, maxLines: 1,
                      style: TextStyle(
                        fontSize: 10, color: CMColors.text3))),
                  ]),
                  const SizedBox(height: 3),
                  Text('By ${d.seller} · ${d.time}',
                    style: TextStyle(fontSize: 10, color: CMColors.text3)),
                ],
              ))),

          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.chevron_right_rounded, color: CMColors.text3)),
        ]),
      ),
    );
  }
}

class _DonateBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _DonateBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CMColors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CMColors.green.withOpacity(0.3))),
        child: Row(children: [
          const Text('🤝', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Have something to give?', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800,
                color: CMColors.text)),
              Text('Help a fellow student by donating',
                style: TextStyle(fontSize: 11, color: CMColors.text2)),
            ])),
          Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: CMColors.green),
        ]),
      ),
    );
  }
}