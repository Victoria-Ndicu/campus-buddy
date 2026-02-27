// campus_market/screens/cm_donations_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cm_constants.dart';
import '../widgets/cm_widgets.dart';
import 'cm_post_screen.dart';
import 'cm_listings_screen.dart';

// ─────────────────────────────────────────────────────────────
//  DATA
// ─────────────────────────────────────────────────────────────
class _DonationData {
  final String emoji, title, category, location, postedBy, time;
  final Color gradA, gradB;
  const _DonationData({
    required this.emoji, required this.title, required this.category,
    required this.location, required this.postedBy, required this.time,
    required this.gradA, required this.gradB,
  });
}

const _kDonations = [
  _DonationData(
    emoji: '📚', title: 'Calculus & Linear Algebra Textbooks (2nd yr)',
    category: 'Books', location: 'Main Campus, Gate 2',
    postedBy: 'Ann W.', time: '1h ago',
    gradA: Color(0xFFEEF1FD), gradB: Color(0xFFC7D2FA),
  ),
  _DonationData(
    emoji: '👔', title: 'Men\'s Clothes Bundle — 4 items',
    category: 'Clothing', location: 'Halls of Residence, Block C',
    postedBy: 'Michael O.', time: '3h ago',
    gradA: Color(0xFFECFDF5), gradB: Color(0xFFA7F3D0),
  ),
  _DonationData(
    emoji: '🖥', title: 'Old Dell Monitor 19"',
    category: 'Electronics', location: 'Near Chiromo Campus',
    postedBy: 'Beatrice K.', time: '6h ago',
    gradA: Color(0xFFFFFBEB), gradB: Color(0xFFFDE68A),
  ),
  _DonationData(
    emoji: '🪴', title: 'Desk Plants — 3 pots',
    category: 'Other', location: 'Student Centre',
    postedBy: 'Zara A.', time: '1d ago',
    gradA: Color(0xFFF0FDF4), gradB: Color(0xFFBBF7D0),
  ),
  _DonationData(
    emoji: '🎒', title: 'Backpack — Slightly worn',
    category: 'Clothing', location: 'Main Campus',
    postedBy: 'Dennis N.', time: '2d ago',
    gradA: Color(0xFFFDF0EC), gradB: Color(0xFFEED5CC),
  ),
];

// ─────────────────────────────────────────────────────────────
//  SCREEN 1: DONATIONS BROWSE
// ─────────────────────────────────────────────────────────────
class CMDonationsScreen extends StatefulWidget {
  const CMDonationsScreen({super.key});
  @override
  State<CMDonationsScreen> createState() => _CMDonationsScreenState();
}

class _CMDonationsScreenState extends State<CMDonationsScreen> {
  int _filter = 0;
  final _filters = ['All', 'Books', 'Electronics', 'Clothing', 'Other'];

  List<_DonationData> get _filtered {
    final cat = _filters[_filter];
    return _kDonations.where((d) => cat == 'All' || d.category == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CMColors.surface2,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 160,
          pinned: true,
          backgroundColor: CMColors.green,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => CMCreateListingScreen(type: 'Donate for Free'))),
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              label: const Text('Donate', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF34D399), Color(0xFF10B981), Color(0xFF0D9488)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('🎁 Free Donations',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                              color: Colors.white70, letterSpacing: 1.2)),
                      const SizedBox(height: 4),
                      const Text('Free items near campus',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      Text('${_kDonations.length} items available right now',
                          style: TextStyle(fontSize: 12,
                              color: Colors.white.withOpacity(0.8))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Search
        SliverToBoxAdapter(child: CMSearchBar(hint: 'Search free items…')),

        // Filter chips
        SliverToBoxAdapter(
          child: SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _GreenChip(
                label: _filters[i],
                active: _filter == i,
                onTap: () => setState(() => _filter = i),
              ),
            ),
          ),
        ),

        // Count
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('${_filtered.length} items available for free',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: CMColors.text3)),
          ),
        ),

        // Donation cards
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => _DonationCard(
              donation: _filtered[i],
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => CMDonationDetailScreen(donation: _filtered[i]),
              )),
            ),
            childCount: _filtered.length,
          ),
        ),

        // CTA to donate
        SliverToBoxAdapter(
          child: _DonateBanner(onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => CMCreateListingScreen(type: 'Donate for Free')))),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 2: DONATION DETAIL
// ─────────────────────────────────────────────────────────────
class CMDonationDetailScreen extends StatelessWidget {
  final _DonationData donation;
  const CMDonationDetailScreen({super.key, required this.donation});

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
        title: const Text('Free Item', style: TextStyle(
            fontWeight: FontWeight.w800, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // Hero
          Container(
            height: 220, width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [donation.gradA, donation.gradB],
              ),
            ),
            child: Stack(children: [
              Center(child: Text(donation.emoji, style: const TextStyle(fontSize: 90))),
              Positioned(top: 16, left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: CMColors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('🎁 FREE', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                )),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(donation.title, style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: CMColors.text)),
              const SizedBox(height: 8),
              Row(children: [
                _GreenTag(donation.category),
                const SizedBox(width: 8),
                _GreenTag('Free'),
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
                      color: CMColors.green.withOpacity(0.15),
                    ),
                    child: Center(child: Text(
                      donation.postedBy.isNotEmpty ? donation.postedBy[0] : 'U',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                          color: CMColors.green),
                    )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(donation.postedBy, style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800, color: CMColors.text)),
                      Text('Posted ${donation.time}',
                          style: TextStyle(fontSize: 11, color: CMColors.text3)),
                    ])),
                ]),
              ),

              const SizedBox(height: 16),
              CMFormField(label: 'Pickup Location', value: donation.location),
              CMFormField(label: 'Category', value: donation.category),
              CMFormField(label: 'Availability', value: 'Available now — first come, first served'),

              const SizedBox(height: 24),

              // Claim button
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('You\'ve claimed "${donation.title}" 🎁'),
                    backgroundColor: CMColors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 3),
                  ));
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF34D399), Color(0xFF10B981)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                      color: CMColors.green.withOpacity(0.35),
                      blurRadius: 12, offset: const Offset(0, 4),
                    )],
                  ),
                  child: const Center(child: Text('🙌 Claim this Item',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                          color: Colors.white))),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 3 — reuses CMCreateListingScreen from cm_post_screen.dart
//  (no duplicate needed — it already handles the 'Donate' type)
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
//  PRIVATE HELPERS
// ─────────────────────────────────────────────────────────────
class _GreenChip extends StatelessWidget {
  final String label;
  final bool active;
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
          border: Border.all(color: active ? CMColors.green : CMColors.border),
        ),
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
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700, color: CMColors.green)),
    );
  }
}

class _DonationCard extends StatelessWidget {
  final _DonationData donation;
  final VoidCallback onTap;
  const _DonationCard({required this.donation, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [donation.gradA, donation.gradB],
              ),
            ),
            child: Center(child: Text(donation.emoji,
                style: const TextStyle(fontSize: 38))),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: CMColors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text('FREE 🎁', style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w800, color: CMColors.green)),
                  ),
                  const SizedBox(width: 6),
                  Text(donation.category, style: TextStyle(
                      fontSize: 10, color: CMColors.text3)),
                ]),
                const SizedBox(height: 5),
                Text(donation.title, maxLines: 2, style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, color: CMColors.text,
                    height: 1.3)),
                const SizedBox(height: 4),
                Row(children: [
                  Text('📍 ', style: TextStyle(fontSize: 10)),
                  Expanded(child: Text(donation.location, maxLines: 1,
                      style: TextStyle(fontSize: 10, color: CMColors.text3))),
                ]),
                const SizedBox(height: 3),
                Text('By ${donation.postedBy} · ${donation.time}',
                    style: TextStyle(fontSize: 10, color: CMColors.text3)),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.chevron_right_rounded, color: CMColors.text3),
          ),
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
          border: Border.all(color: CMColors.green.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Text('🤝', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Have something to give?', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: CMColors.text)),
            Text('Help a fellow student by donating',
                style: TextStyle(fontSize: 11, color: CMColors.text2)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: CMColors.green),
        ]),
      ),
    );
  }
}