import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/hh_constants.dart';
import '../widgets/hh_widgets.dart';

// ─────────────────────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────────────────────
class _Listing {
  final String emoji, type, title, price, location, availability;
  final Color gradA, gradB, typeColor;
  final List<String> tags;
  const _Listing({
    required this.emoji, required this.type, required this.title,
    required this.price, required this.location, required this.availability,
    required this.gradA, required this.gradB, required this.typeColor,
    required this.tags,
  });
}

const _kListings = [
  _Listing(
    emoji: '🏠', type: 'Apartment', title: 'Spacious 2-Bedroom Apartment — Westlands',
    price: 'KES 28,000', location: '📍 Westlands · 1.2 km from UoN',
    availability: 'Available March 1, 2026',
    gradA: Color(0xFFFDF0EC), gradB: Color(0xFFF4C5B5), typeColor: HHColors.brandDark,
    tags: ['WiFi ✓', 'Water ✓', 'Parking ✓', '2 Beds', 'Furnished'],
  ),
  _Listing(
    emoji: '🛏', type: 'Single Room', title: 'Self-Contained Room — Parklands',
    price: 'KES 9,500', location: '📍 Parklands · 0.8 km from UoN',
    availability: 'Available Now',
    gradA: Color(0xFFF0F4FF), gradB: Color(0xFFDDE6FF), typeColor: HHColors.blue,
    tags: ['WiFi ✓', 'En-suite', 'Furnished'],
  ),
  _Listing(
    emoji: '🏘', type: 'Shared', title: 'Shared Flat — CBD',
    price: 'KES 6,000', location: '📍 CBD · 2.1 km from UoN',
    availability: 'Available Now',
    gradA: Color(0xFFECFDF5), gradB: Color(0xFFA7F3D0), typeColor: HHColors.teal,
    tags: ['3 rooms', 'Shared kitchen'],
  ),
  _Listing(
    emoji: '🏣', type: 'Bedsitter', title: 'Bedsitter — Ngara',
    price: 'KES 7,500', location: '📍 Ngara · 0.6 km from UoN',
    availability: 'Available Now',
    gradA: Color(0xFFFFF3E0), gradB: Color(0xFFFFCC80), typeColor: HHColors.amber,
    tags: ['Studio', 'Self-contained'],
  ),
];

// ─────────────────────────────────────────────────────────────
//  SCREEN 1 — Browse Listings
// ─────────────────────────────────────────────────────────────
class HHListingsScreen extends StatefulWidget {
  const HHListingsScreen({super.key});
  @override
  State<HHListingsScreen> createState() => _HHListingsScreenState();
}

class _HHListingsScreenState extends State<HHListingsScreen> {
  int _filter = 0;
  final _filters = ['All', '🏠 Apartment', '🛏 Single Room', '🏘 Shared', '🏣 Bedsitter'];

  List<_Listing> get _filtered {
    if (_filter == 0) return _kListings;
    final types = ['', 'Apartment', 'Single Room', 'Shared', 'Bedsitter'];
    return _kListings.where((l) => l.type == types[_filter]).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HHColors.surface2,
      appBar: AppBar(
        backgroundColor: HHColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: HHColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Housing Hub', style: TextStyle(
            fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w900,
            color: HHColors.brandDark, fontStyle: FontStyle.italic)),
          Text('Nairobi · 64 listings available',
              style: TextStyle(fontSize: 11, color: HHColors.text3)),
        ]),
        titleSpacing: 0,
        actions: [
          Container(margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: HHColors.brandPale, borderRadius: BorderRadius.circular(11)),
            child: Text('🔔', style: TextStyle(fontSize: 18, color: HHColors.brand))),
          Container(margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: HHColors.brand, borderRadius: BorderRadius.circular(11)),
            child: const Text('👤', style: TextStyle(fontSize: 18))),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
          child: Divider(color: HHColors.border, height: 1)),
      ),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: HHSearchBar()),
        // filter chips
        SliverToBoxAdapter(
          child: SizedBox(height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (_, i) => HHChip(
                label: _filters[i],
                active: _filter == i,
                onTap: () => setState(() => _filter = i),
              ),
            )),
        ),
        SliverToBoxAdapter(
          child: HHSectionLabel(title: 'Latest Listings', action: 'Map view →',
              onAction: () {}),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              if (i >= _filtered.length) return const SizedBox(height: 100);
              final l = _filtered[i];
              return _ListingCard(
                listing: l,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => HHListingDetailScreen(
                    title: l.title, price: l.price,
                    location: l.location, type: l.type, emoji: l.emoji,
                  ))),
              );
            },
            childCount: _filtered.length + 1,
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: HHColors.brand,
        foregroundColor: Colors.white,
        icon: const Text('🏠', style: TextStyle(fontSize: 18)),
        label: const Text('Post Listing', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HHPostListingScreen())),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 2 — Listing Detail
// ─────────────────────────────────────────────────────────────
class HHListingDetailScreen extends StatelessWidget {
  final String title, price, location, type, emoji;
  const HHListingDetailScreen({
    super.key,
    this.title   = 'Spacious 2-Bedroom Apartment — Westlands',
    this.price   = 'KES 28,000',
    this.location= 'Westlands, Nairobi · 1.2 km from UoN Main Campus',
    this.type    = 'Apartment',
    this.emoji   = '🏠',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HHColors.surface2,
      body: CustomScrollView(slivers: [
        // photo hero
        SliverAppBar(
          expandedHeight: 230,
          pinned: false,
          backgroundColor: Colors.transparent,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.88), borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: HHColors.text)),
          ),
          actions: [
            GestureDetector(
              onTap: () {},
              child: Container(margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.88), borderRadius: BorderRadius.circular(11)),
                child: const Padding(padding: EdgeInsets.all(8), child: Text('🤍', style: TextStyle(fontSize: 18)))),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFFDF0EC), Color(0xFFF4C5B5)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: Stack(children: [
                Center(child: Text(emoji, style: const TextStyle(fontSize: 90))),
                Positioned(bottom: 10, right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                    child: const Text('1 / 5', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)))),
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(title, style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900,
                    color: HHColors.text, height: 1.25,
                    fontStyle: FontStyle.italic,
                  ))),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(price, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: HHColors.brand)),
                    Text('/month', style: TextStyle(fontSize: 11, color: HHColors.text3)),
                  ]),
                ]),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(spacing: 6, runSpacing: 6, children: [
                  HHTag('🏠 $type', bg: HHColors.brandPale, fg: HHColors.brand),
                  HHTag('2 Bedrooms', bg: HHColors.bluePale, fg: HHColors.blue),
                  HHTag('Available Now', bg: HHColors.greenPale, fg: HHColors.green),
                ]),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(location, style: TextStyle(fontSize: 12, color: HHColors.text3)),
              ),
              const SizedBox(height: 14),
              // amenities info grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  _InfoChip(label: '2', sub: 'Bedrooms'),
                  const SizedBox(width: 8),
                  _InfoChip(label: '1', sub: 'Bathroom'),
                  const SizedBox(width: 8),
                  _InfoChip(label: '65', sub: 'sq.m'),
                  const SizedBox(width: 8),
                  _InfoChip(label: '1st', sub: 'Floor'),
                ]),
              ),
              const SizedBox(height: 14),
              HHSectionLabel(title: 'Amenities'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  HHTag('📶 WiFi', bg: HHColors.greenPale, fg: HHColors.green),
                  HHTag('💧 Running Water', bg: HHColors.skyPale, fg: HHColors.sky),
                  HHTag('🅿️ Parking', bg: HHColors.brandPale, fg: HHColors.brand),
                  HHTag('🪑 Furnished', bg: HHColors.amberPale, fg: HHColors.amber),
                  HHTag('🔒 Security', bg: HHColors.surface3, fg: HHColors.text2),
                  HHTag('♻️ Garbage', bg: HHColors.surface3, fg: HHColors.text2),
                ]),
              ),
              const SizedBox(height: 14),
              HHFormField(label: 'About this listing',
                  value: 'Beautiful, fully furnished 2-bedroom apartment in Westlands. Close to UoN, supermarkets, and public transport. Quiet neighborhood perfect for students.',
                  multiline: true),
              HHFormField(label: 'Contact',       value: '📞 0712 345 678 · James Kamau'),
              HHFormField(label: 'Caretaker',     value: 'Mrs. Wanjiru — On-site'),
              HHFormField(label: 'Available from', value: 'March 1, 2026'),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: HHColors.brand),
                      foregroundColor: HHColors.brand,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Listing saved ❤️'))),
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800)))),
                  const SizedBox(width: 10),
                  Expanded(flex: 3, child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HHColors.brand,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contacting agent...'))),
                    child: const Text('Contact Agent', style: TextStyle(fontWeight: FontWeight.w800)))),
                ]),
              ),
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
// ─────────────────────────────────────────────────────────────
class HHPostListingScreen extends StatefulWidget {
  const HHPostListingScreen({super.key});
  @override
  State<HHPostListingScreen> createState() => _HHPostListingScreenState();
}

class _HHPostListingScreenState extends State<HHPostListingScreen> {
  String _type    = 'Apartment';
  String _price   = '';
  String _location= 'Westlands';
  bool _wifi    = true;
  bool _parking = false;
  bool _furnished = true;

  static const _types = ['Apartment', 'Single Room', 'Shared', 'Bedsitter'];
  static const _locations = ['Westlands', 'Parklands', 'CBD', 'Ngara', 'Highridge'];

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
        title: const Text('Post a Listing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: HHColors.text)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('✅ Listing published!'),
                backgroundColor: HHColors.teal,
              ));
            },
            child: Text('Publish', style: TextStyle(fontWeight: FontWeight.w800, color: HHColors.brand)),
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
            child: Divider(color: HHColors.border, height: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text('Create a listing and reach students near campus 🏠',
                style: TextStyle(fontSize: 13, color: HHColors.text2)),
          ),
          HHSectionLabel(title: 'Property Type'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.5,
              children: _types.map<Widget>((t) => GestureDetector(
                onTap: () => setState(() => _type = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _type == t ? HHColors.brandPale : HHColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _type == t ? HHColors.brand : HHColors.border, width: 1.5),
                  ),
                  child: Row(children: [
                    Text(_typeEmoji(t), style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: _type == t ? HHColors.brand : HHColors.text2)),
                  ]),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 14),
          HHFormField(label: 'Listing Title', value: 'e.g. Spacious 2BR — Westlands', active: true),
          HHFormField(label: 'Monthly Rent (KES)', value: _price.isEmpty ? 'e.g. 28,000' : _price),
          HHSectionLabel(title: 'Location'),
          SizedBox(height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _locations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (_, i) => HHChip(
                label: _locations[i],
                active: _location == _locations[i],
                onTap: () => setState(() => _location = _locations[i]),
              ),
            )),
          const SizedBox(height: 14),
          HHSectionLabel(title: 'Amenities'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: HHTheme.cardSm,
            child: Column(children: [
              HHToggleRow(label: '📶 WiFi included', subtitle: 'Landlord provides internet', value: _wifi, onChanged: (v) => setState(() => _wifi = v)),
              Divider(color: HHColors.border, height: 1),
              HHToggleRow(label: '🅿️ Parking', subtitle: 'Secure parking available', value: _parking, onChanged: (v) => setState(() => _parking = v)),
              Divider(color: HHColors.border, height: 1),
              HHToggleRow(label: '🪑 Furnished', subtitle: 'Basic furniture included', value: _furnished, onChanged: (v) => setState(() => _furnished = v)),
            ]),
          ),
          const SizedBox(height: 14),
          HHFormField(label: 'Description', value: 'Describe the property, nearby landmarks, transport links...', multiline: true),
          HHFormField(label: 'Contact Number', value: '0712 345 678', active: true),
          HHPrimaryButton(
            label: '🏠 Publish Listing',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('✅ Listing published!'),
                backgroundColor: HHColors.teal,
              ));
            },
          ),
        ]),
      ),
    );
  }

  String _typeEmoji(String t) {
    switch(t) {
      case 'Apartment': return '🏠';
      case 'Single Room': return '🛏';
      case 'Shared': return '🏘';
      case 'Bedsitter': return '🏣';
      default: return '🏠';
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  Private helpers
// ─────────────────────────────────────────────────────────────

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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 130,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [listing.gradA, listing.gradB], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Stack(children: [
              Center(child: Text(listing.emoji, style: const TextStyle(fontSize: 52))),
              Positioned(top: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
                  child: Text(listing.type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: listing.typeColor)))),
              Positioned(top: 10, right: 10,
                child: Container(width: 28, height: 28,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                  child: const Center(child: Text('🤍', style: TextStyle(fontSize: 13))))),
            ]),
          ),
          Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(listing.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: HHColors.text)),
            const SizedBox(height: 4),
            Row(children: [
              Text(listing.price, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: HHColors.brand)),
              Text(' /month', style: TextStyle(fontSize: 11, color: HHColors.text3)),
            ]),
            const SizedBox(height: 3),
            Text(listing.location, style: TextStyle(fontSize: 11, color: HHColors.text3)),
            const SizedBox(height: 8),
            Wrap(spacing: 5, runSpacing: 5, children: listing.tags.map<Widget>((t) => HHTag(t, bg: HHColors.greenPale, fg: HHColors.teal)).toList()),
            const SizedBox(height: 10),
            Divider(color: HHColors.border, height: 1),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('📅 ${listing.availability}', style: TextStyle(fontSize: 11, color: HHColors.text3)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: HHColors.brand, borderRadius: BorderRadius.circular(9)),
                child: const Text('View →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white))),
            ]),
          ])),
        ]),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label, sub;
  const _InfoChip({required this.label, required this.sub});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: HHColors.brandPale, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: HHColors.brand)),
        Text(sub, style: TextStyle(fontSize: 10, color: HHColors.text3)),
      ]),
    ));
  }
}