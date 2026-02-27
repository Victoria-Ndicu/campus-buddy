// campus_market/screens/cm_listings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cm_constants.dart';
import '../widgets/cm_widgets.dart';

// ─────────────────────────────────────────────────────────────
//  DATA
// ─────────────────────────────────────────────────────────────
class _ListingData {
  final String emoji, title, price, category, condition, seller, time;
  final Color gradA, gradB;
  final bool isFeatured;
  const _ListingData({
    required this.emoji, required this.title, required this.price,
    required this.category, required this.condition, required this.seller,
    required this.time, required this.gradA, required this.gradB,
    this.isFeatured = false,
  });
}

const _kListings = [
  _ListingData(
    emoji: '💻', title: 'HP Laptop 15" i5 8GB RAM', price: 'KES 32,000',
    category: 'Electronics', condition: 'Used — Good', seller: 'James M.',
    time: '2h ago', gradA: Color(0xFFFDF0EC), gradB: Color(0xFFEED5CC),
    isFeatured: true,
  ),
  _ListingData(
    emoji: '📚', title: 'Engineering Textbooks Set (3 books)', price: 'KES 800',
    category: 'Books', condition: 'Like New', seller: 'Amina K.',
    time: '4h ago', gradA: Color(0xFFEEF1FD), gradB: Color(0xFFC7D2FA),
  ),
  _ListingData(
    emoji: '🎧', title: 'Sony WH-1000X Wireless Headphones', price: 'KES 4,500',
    category: 'Electronics', condition: 'Used — Excellent', seller: 'Kevin O.',
    time: '6h ago', gradA: Color(0xFFECFDF5), gradB: Color(0xFFA7F3D0),
  ),
  _ListingData(
    emoji: '🪑', title: 'Study Chair — Ergonomic', price: 'KES 3,200',
    category: 'Furniture', condition: 'Used — Fair', seller: 'Grace N.',
    time: '1d ago', gradA: Color(0xFFFFFBEB), gradB: Color(0xFFFDE68A),
  ),
  _ListingData(
    emoji: '📷', title: 'Canon DSLR Camera EOS 200D', price: 'KES 28,000',
    category: 'Electronics', condition: 'Used — Excellent', seller: 'David K.',
    time: '1d ago', gradA: Color(0xFFF5F3FF), gradB: Color(0xFFDDD6FE),
    isFeatured: true,
  ),
  _ListingData(
    emoji: '👕', title: 'UoN Hoodie — Size M', price: 'KES 900',
    category: 'Clothing', condition: 'Like New', seller: 'Fatuma H.',
    time: '2d ago', gradA: Color(0xFFF0FDF4), gradB: Color(0xFFBBF7D0),
  ),
];

const _kFilters = ['All', 'Electronics', 'Books', 'Furniture', 'Clothing', 'Free'];

// ─────────────────────────────────────────────────────────────
//  SCREEN 1: BROWSE LISTINGS
// ─────────────────────────────────────────────────────────────
class CMListingsScreen extends StatefulWidget {
  const CMListingsScreen({super.key});
  @override
  State<CMListingsScreen> createState() => _CMListingsScreenState();
}

class _CMListingsScreenState extends State<CMListingsScreen> {
  int _filter = 0;
  String _query = '';

  List<_ListingData> get _filtered {
    final cat = _kFilters[_filter];
    return _kListings.where((l) {
      final matchCat = cat == 'All' || l.category == cat ||
          (cat == 'Free' && l.price == 'FREE');
      final matchQ = _query.isEmpty ||
          l.title.toLowerCase().contains(_query.toLowerCase()) ||
          l.category.toLowerCase().contains(_query.toLowerCase());
      return matchCat && matchQ;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CMColors.surface2,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: CMColors.brand,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Browse Listings',
              style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
                onPressed: () => HapticFeedback.selectionClick(),
              ),
            ),
          ],
        ),

        // Search
        SliverToBoxAdapter(
          child: CMSearchBar(
            hint: 'Search listings…',
            onChanged: (v) => setState(() => _query = v),
          ),
        ),

        // Filter chips
        SliverToBoxAdapter(
          child: SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              itemCount: _kFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => CMChip(
                label: _kFilters[i],
                active: _filter == i,
                onTap: () => setState(() => _filter = i),
              ),
            ),
          ),
        ),

        // Results count
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('${_filtered.length} listings found',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: CMColors.text3)),
          ),
        ),

        // Listings grid
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
                listing: _filtered[i],
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CMListingDetailScreen(
                    title: _filtered[i].title,
                    price: _filtered[i].price,
                    category: _filtered[i].category,
                    condition: _filtered[i].condition,
                    seller: _filtered[i].seller,
                    emoji: _filtered[i].emoji,
                  ),
                )),
              ),
              childCount: _filtered.length,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 2: LISTING DETAIL
// ─────────────────────────────────────────────────────────────
class CMListingDetailScreen extends StatelessWidget {
  final String title, price, category, condition, seller, emoji;
  const CMListingDetailScreen({
    super.key,
    this.title = 'Item Title',
    this.price = 'KES 0',
    this.category = 'General',
    this.condition = 'Used',
    this.seller = 'Campus User',
    this.emoji = '📦',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CMColors.surface2,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          backgroundColor: CMColors.brand,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.bookmark_border_rounded, color: Colors.white),
              onPressed: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Saved to wishlist ❤️'),
                  backgroundColor: CMColors.brandDark,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
              },
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFFFDF0EC), Color(0xFFEED5CC)],
                ),
              ),
              child: Stack(children: [
                Positioned.fill(
                  child: Center(child: Text(emoji,
                      style: const TextStyle(fontSize: 100))),
                ),
                if (true) // featured badge
                  Positioned(bottom: 16, left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: CMColors.brand,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(category, style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                    )),
              ]),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Title + price
              Row(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(title, style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900, color: CMColors.text)),
                  ),
                  const SizedBox(width: 12),
                  Text(price, style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900, color: CMColors.brand)),
                ]),
              const SizedBox(height: 12),

              // Tags
              Row(children: [
                CMTag(condition),
                const SizedBox(width: 8),
                CMTag(category),
              ]),
              const SizedBox(height: 20),

              // Seller info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: CMTheme.card,
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [CMColors.brand, CMColors.brandDark],
                      ),
                    ),
                    child: Center(child: Text(
                      seller.isNotEmpty ? seller[0] : 'U',
                      style: const TextStyle(fontSize: 18,
                          fontWeight: FontWeight.w900, color: Colors.white),
                    )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(seller, style: TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w800, color: CMColors.text)),
                      Text('Verified campus seller  ⭐ 4.8',
                          style: TextStyle(fontSize: 11, color: CMColors.text3)),
                    ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: CMColors.brandPale,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('View profile', style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: CMColors.brand)),
                  ),
                ]),
              ),

              const SizedBox(height: 16),

              // Details
              CMSectionLabel(title: '📋 Item Details'),
              CMFormField(label: 'Condition', value: condition),
              CMFormField(label: 'Category', value: category),
              CMFormField(label: 'Location', value: '📍 Near Main Gate, UoN'),
              CMFormField(label: 'Description',
                value: 'Well maintained $title. Available for pickup or delivery within campus. '
                    'Contact seller for more details and negotiation.',
                multiline: true),

              const SizedBox(height: 20),

              // CTA buttons
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => CMContactSellerScreen(
                          sellerName: seller, itemTitle: title, itemPrice: price),
                      ));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [CMColors.brand, CMColors.brandDark],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(
                          color: CMColors.brand.withOpacity(0.35),
                          blurRadius: 12, offset: const Offset(0, 4),
                        )],
                      ),
                      child: const Center(child: Text('📨 Contact Seller',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                              color: Colors.white))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: CMColors.border),
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white,
                  ),
                  child: const Text('🔗', style: TextStyle(fontSize: 20)),
                ),
              ]),
            ]),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 3: CONTACT SELLER
// ─────────────────────────────────────────────────────────────
class CMContactSellerScreen extends StatefulWidget {
  final String sellerName, itemTitle, itemPrice;
  const CMContactSellerScreen({
    super.key,
    this.sellerName = 'Seller',
    this.itemTitle = 'Item',
    this.itemPrice = 'KES 0',
  });
  @override
  State<CMContactSellerScreen> createState() => _CMContactSellerScreenState();
}

class _CMContactSellerScreenState extends State<CMContactSellerScreen> {
  String _channel = 'Chat';
  String _offer = '';
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

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
        title: Text('Contact ${widget.sellerName}',
            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
      ),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('📦', style: TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.itemTitle, maxLines: 2,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                          color: CMColors.text, height: 1.3)),
                  const SizedBox(height: 4),
                  Text(widget.itemPrice, style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w900, color: CMColors.brand)),
                ])),
            ]),
          ),

          CMSectionLabel(title: '📡 Contact via'),

          // Channel picker
          Row(children: ['Chat', 'WhatsApp', 'Email'].map<Widget>((c) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: CMChip(
                label: c,
                active: _channel == c,
                onTap: () => setState(() => _channel = c),
              ),
            ),
          )).toList()),

          const SizedBox(height: 16),
          CMSectionLabel(title: '💬 Your message'),

          Container(
            decoration: CMTheme.card,
            child: TextField(
              controller: _ctrl,
              maxLines: 4,
              onChanged: (v) => _offer = v,
              decoration: InputDecoration(
                hintText: 'Hi! I\'m interested in your ${widget.itemTitle}. Is it still available?',
                hintStyle: TextStyle(fontSize: 13, color: CMColors.text3),
                contentPadding: const EdgeInsets.all(14),
                border: InputBorder.none,
              ),
            ),
          ),

          CMSectionLabel(title: '💰 Make an offer (optional)'),
          Container(
            decoration: CMTheme.card,
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'KES ${widget.itemPrice.replaceAll(RegExp(r'[^0-9]'), '')}',
                hintStyle: TextStyle(fontSize: 13, color: CMColors.text3),
                prefixText: 'KES  ',
                prefixStyle: TextStyle(fontWeight: FontWeight.w700, color: CMColors.text),
                contentPadding: const EdgeInsets.all(14),
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 24),

          CMPrimaryButton(
            label: 'Send Message via $_channel',
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Message sent to ${widget.sellerName} via $_channel ✓'),
                backgroundColor: CMColors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PRIVATE: LISTING GRID CARD
// ─────────────────────────────────────────────────────────────
class _ListingGridCard extends StatelessWidget {
  final _ListingData listing;
  final VoidCallback onTap;
  const _ListingGridCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
          Container(
            height: 110,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [listing.gradA, listing.gradB],
              ),
            ),
            child: Stack(children: [
              Center(child: Text(listing.emoji, style: const TextStyle(fontSize: 46))),
              if (listing.isFeatured)
                Positioned(top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: CMColors.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('🔥 Hot',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  )),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(listing.title, maxLines: 2,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                      color: CMColors.text, height: 1.3)),
              const SizedBox(height: 5),
              Text(listing.price, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w900, color: CMColors.brand)),
              const SizedBox(height: 3),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(child: Text(listing.condition, maxLines: 1,
                    style: TextStyle(fontSize: 10, color: CMColors.text3))),
                Text(listing.time,
                    style: TextStyle(fontSize: 10, color: CMColors.text3)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}