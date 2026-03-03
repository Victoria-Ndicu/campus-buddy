import 'package:flutter/material.dart';
import '../models/hh_constants.dart';
import '../widgets/hh_widgets.dart';
import 'hh_listings_screen.dart';

// ═════════════════════════════════════════════════════════════
//  MAP SCREEN
// ═════════════════════════════════════════════════════════════

class HHMapScreen extends StatefulWidget {
  const HHMapScreen({super.key});
  @override
  State<HHMapScreen> createState() => _HHMapScreenState();
}

class _HHMapScreenState extends State<HHMapScreen> {
  int _selectedPin = 0;

  static const _pins = [
    (emoji: '🏠', label: 'KES 28k • 2BR', type: 'Apartment', color: HHColors.brand,
      title: 'Spacious 2-Bedroom — Westlands', price: 'KES 28,000'),
    (emoji: '🛏', label: 'KES 9.5k', type: 'Single Room', color: HHColors.blue,
      title: 'Self-Contained Room — Parklands', price: 'KES 9,500'),
    (emoji: '🏘', label: 'KES 6k', type: 'Shared', color: HHColors.green,
      title: 'Shared Flat — CBD', price: 'KES 6,000'),
    (emoji: '🏣', label: 'KES 7.5k', type: 'Bedsitter', color: HHColors.amber,
      title: 'Bedsitter — Ngara', price: 'KES 7,500'),
  ];

  @override
  Widget build(BuildContext context) {
    final pin = _pins[_selectedPin];
    return Scaffold(
      backgroundColor: HHColors.surface2,
      body: Stack(children: [
        // ── Simulated map background ─────────────────────────
        Positioned.fill(child: _MapBackground(selectedPin: _selectedPin, onPinTap: (i) => setState(() => _selectedPin = i))),

        // ── Floating search bar ──────────────────────────────
        Positioned(top: MediaQuery.of(context).padding.top + 8, left: 14, right: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: HHColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HHColors.border, width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Row(children: [
              IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: HHColors.text),
                onPressed: () => Navigator.pop(context)),
              const SizedBox(width: 10),
              const Text('🔍', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(child: Text('Search location near campus...', style: TextStyle(fontSize: 13, color: HHColors.text3))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: HHColors.brandPale, borderRadius: BorderRadius.circular(8)),
                child: Text('Filter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: HHColors.brand))),
            ]),
          )),

        // ── Map controls ─────────────────────────────────────
        Positioned(top: MediaQuery.of(context).padding.top + 74, right: 14,
          child: Column(children: [
            _MapControl('+'),
            const SizedBox(height: 5),
            _MapControl('−'),
            const SizedBox(height: 5),
            _MapControl('⊕'),
          ])),

        // ── Legend ───────────────────────────────────────────
        Positioned(bottom: 160, left: 14,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: HHColors.surface, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              _LegendItem(color: HHColors.brand, label: 'Apartment'),
              const SizedBox(height: 4),
              _LegendItem(color: HHColors.blue, label: 'Single Room'),
              const SizedBox(height: 4),
              _LegendItem(color: HHColors.green, label: 'Shared'),
              const SizedBox(height: 4),
              _LegendItem(color: HHColors.amber, label: 'Bedsitter'),
            ]),
          )),

        // ── Bottom drawer (selected listing) ─────────────────
        Positioned(bottom: 0, left: 0, right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: HHColors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(top: BorderSide(color: HHColors.border)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 30, offset: const Offset(0, -8))],
            ),
            padding: EdgeInsets.only(left: 16, right: 16, top: 14, bottom: MediaQuery.of(context).padding.bottom + 14),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: HHColors.border, borderRadius: BorderRadius.circular(2))),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text('🏠 ${pin.title}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: HHColors.text))),
                Text(pin.price, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: HHColors.brand)),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 6, children: [
                HHTag('1.2km from UoN', bg: HHColors.brandPale, fg: HHColors.brand),
                HHTag(pin.type, bg: HHColors.greenPale, fg: HHColors.green),
                HHTag('WiFi', bg: HHColors.tealPale, fg: HHColors.teal),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton(
                  style: OutlinedButton.styleFrom(side: BorderSide(color: HHColors.brand), foregroundColor: HHColors.brand,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () {},
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800)))),
                const SizedBox(width: 10),
                Expanded(flex: 3, child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: HHColors.brand, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0, shadowColor: HHColors.brand.withOpacity(0.3)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const HHListingDetailScreen())),
                  child: const Text('View Full Listing →', style: TextStyle(fontWeight: FontWeight.w800)))),
              ]),
            ]),
          )),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════
//  ALERTS SCREEN
// ═════════════════════════════════════════════════════════════

class HHAlertsScreen extends StatefulWidget {
  const HHAlertsScreen({super.key});
  @override
  State<HHAlertsScreen> createState() => _HHAlertsScreenState();
}

class _HHAlertsScreenState extends State<HHAlertsScreen> {
  bool _alertsOn = true;

  static const _alerts = [
    _AlertData(emoji: '🏠', name: '2-Bedroom Apartment',
      criteria: '📍 Westlands / Parklands · KES 20k–35k/mo\nFurnished · WiFi required',
      status: '● Active · 3 matches today', active: true),
    _AlertData(emoji: '🛏', name: 'Single Room — Near Campus',
      criteria: '📍 Within 1km of UoN · KES 8k–12k/mo\nAny condition',
      status: '● Active · 1 match today', active: true),
    _AlertData(emoji: '🏘', name: 'Shared Housing — Budget',
      criteria: '📍 Any location · Under KES 7,000/mo\nShared kitchen okay',
      status: '⏸ Paused', active: false),
  ];

  static const _matches = [
    _MatchNotif(emoji: '🏠', bg: HHColors.brandPale,
      title: 'New match: 2BR Apartment in Westlands — KES 26,000/mo',
      sub: 'Posted 15 mins ago · Matches your "2-Bedroom" alert', unread: true),
    _MatchNotif(emoji: '🛏', bg: HHColors.bluePale,
      title: 'New match: Self-contained room in Parklands — KES 10,500/mo',
      sub: 'Posted 2h ago · Matches your "Single Room" alert', unread: true),
    _MatchNotif(emoji: '🏠', bg: HHColors.surface3,
      title: 'Westlands apartment updated — Price dropped to KES 24,000',
      sub: 'Yesterday · Listing you saved', unread: false),
  ];

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
        title: Row(children: [
          const Text('My Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: HHColors.text)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: HHColors.brand, borderRadius: BorderRadius.circular(8)),
            child: const Text('3 Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white))),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: HHColors.brand, borderRadius: BorderRadius.circular(10)),
            child: const Text('+ New', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white))),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(color: HHColors.border, height: 1)),
      ),
      body: CustomScrollView(slivers: [
        // alerts ON banner
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: HHColors.brandPale,
              border: Border.all(color: HHColors.brandDark, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Text('🔔', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Alerts are ON', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: HHColors.brand)),
                const SizedBox(height: 2),
                Text("You'll be notified instantly when new listings match your saved alerts.",
                    style: TextStyle(fontSize: 11, color: HHColors.text2, height: 1.4)),
              ])),
              Switch(value: _alertsOn, onChanged: (v) => setState(() => _alertsOn = v), activeColor: HHColors.brand),
            ]),
          ),
        ),
        SliverToBoxAdapter(child: HHSectionLabel(title: 'Your Saved Alerts')),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              if (i >= _alerts.length) return null;
              return _AlertCard(alert: _alerts[i]);
            },
            childCount: _alerts.length,
          ),
        ),
        SliverToBoxAdapter(child: HHSectionLabel(title: 'Recent Matches')),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              if (i >= _matches.length) return null;
              return _MatchCard(notif: _matches[i]);
            },
            childCount: _matches.length,
          ),
        ),
        // create new alert
        SliverToBoxAdapter(child: HHSectionLabel(title: 'Create New Alert')),
        SliverToBoxAdapter(
          child: GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alert creation coming soon...'))),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HHColors.surface,
                border: Border.all(color: HHColors.brand, style: BorderStyle.solid, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(children: [
                const Text('🔔', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text('Set Up a New Alert', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: HHColors.text)),
                const SizedBox(height: 4),
                Text('Choose your criteria and get notified the moment a matching property is listed.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: HHColors.text3, height: 1.5)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: HHColors.brand, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('+ Create Alert', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
              ]),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Private data + helper widgets
// ─────────────────────────────────────────────────────────────

class _AlertData {
  final String emoji, name, criteria, status;
  final bool active;
  const _AlertData({required this.emoji, required this.name, required this.criteria, required this.status, required this.active});
}

class _MatchNotif {
  final String emoji, title, sub;
  final Color bg;
  final bool unread;
  const _MatchNotif({required this.emoji, required this.bg, required this.title, required this.sub, required this.unread});
}

class _AlertCard extends StatelessWidget {
  final _AlertData alert;
  const _AlertCard({required this.alert});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: HHTheme.cardSm,
      child: Row(children: [
        Container(width: 38, height: 38,
          decoration: BoxDecoration(color: HHColors.brandPale, borderRadius: BorderRadius.circular(11)),
          child: Center(child: Text(alert.emoji, style: const TextStyle(fontSize: 18)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(alert.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: HHColors.text)),
          const SizedBox(height: 2),
          Text(alert.criteria, style: TextStyle(fontSize: 11, color: HHColors.text3, height: 1.4)),
          const SizedBox(height: 4),
          Text(alert.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: alert.active ? HHColors.green : HHColors.amber)),
        ])),
        Text(alert.active ? '🔔' : '🔕',
            style: TextStyle(fontSize: 20, color: alert.active ? HHColors.brand : HHColors.text3.withOpacity(0.4))),
      ]),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final _MatchNotif notif;
  const _MatchCard({required this.notif});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: notif.unread ? HHColors.brandXp : HHColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: notif.unread ? HHColors.brand.withOpacity(0.3) : HHColors.border),
      ),
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: notif.bg, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(notif.emoji, style: const TextStyle(fontSize: 16)))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(notif.title, style: TextStyle(fontSize: 12, fontWeight: notif.unread ? FontWeight.w800 : FontWeight.w600, color: HHColors.text)),
          const SizedBox(height: 2),
          Text(notif.sub, style: TextStyle(fontSize: 10, color: HHColors.text3)),
        ])),
        if (notif.unread) Container(width: 8, height: 8, decoration: BoxDecoration(color: HHColors.brand, shape: BoxShape.circle)),
      ]),
    );
  }
}

class _MapBackground extends StatelessWidget {
  final int selectedPin;
  final ValueChanged<int> onPinTap;
  const _MapBackground({required this.selectedPin, required this.onPinTap});

  @override
  Widget build(BuildContext context) {
    // Simulated map with custom painter
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFE0E8F5), Color(0xFFD2DCF0), Color(0xFFDFE7F4)],
            begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: CustomPaint(painter: _MapGridPainter(), child: Stack(children: [
        // Campus block
        Positioned(top: MediaQuery.of(context).size.height * 0.38, left: MediaQuery.of(context).size.width * 0.35,
          child: Container(width: 100, height: 70,
            decoration: BoxDecoration(color: const Color(0xFF667EEA).withOpacity(0.12),
                border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.3), width: 2),
                borderRadius: BorderRadius.circular(10)),
            child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('🎓', style: TextStyle(fontSize: 18)),
              Text('UoN Main\nCampus', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFF667EEA))),
            ]))),
        // Map pins
        _pin(context, top: 0.22, left: 0.18, pin: (emoji: '🏠', label: 'KES 28k', color: HHColors.brand), idx: 0),
        _pin(context, top: 0.15, right: 0.24, pin: (emoji: '🛏', label: 'KES 9.5k', color: HHColors.blue), idx: 1),
        _pin(context, top: 0.68, left: 0.50, pin: (emoji: '🏘', label: 'KES 6k', color: HHColors.green), idx: 2),
        _pin(context, top: 0.50, right: 0.15, pin: (emoji: '🏣', label: 'KES 7.5k', color: HHColors.amber), idx: 3),
      ])),
    );
  }

  Widget _pin(BuildContext context, {double? top, double? left, double? right, required ({String emoji, String label, Color color}) pin, required int idx}) {
    final size = MediaQuery.of(context).size;
    return Positioned(
      top: top != null ? size.height * top : null,
      left: left != null ? size.width * left : null,
      right: right != null ? size.width * right : null,
      child: GestureDetector(
        onTap: () => onPinTap(idx),
        child: Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: selectedPin == idx ? 36 : 30,
            height: selectedPin == idx ? 36 : 30,
            decoration: BoxDecoration(
              color: pin.color,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(50), topRight: Radius.circular(50), bottomRight: Radius.circular(50)),
              boxShadow: [BoxShadow(color: pin.color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Center(child: Text(pin.emoji, style: const TextStyle(fontSize: 14))),
          ),
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]),
            child: Text(pin.label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: pin.color)),
          ),
        ]),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = const Color(0xFF667EEA).withOpacity(0.07)..strokeWidth = 1;
    final rp = Paint()..color = Colors.white.withOpacity(0.7);
    // grid
    for (double x = 0; x < s.width; x += 30) canvas.drawLine(Offset(x, 0), Offset(x, s.height), p);
    for (double y = 0; y < s.height; y += 30) canvas.drawLine(Offset(0, y), Offset(s.width, y), p);
    // roads
    canvas.drawRect(Rect.fromLTWH(0, s.height * 0.30, s.width, 14), rp);
    canvas.drawRect(Rect.fromLTWH(0, s.height * 0.60, s.width, 10), rp);
    canvas.drawRect(Rect.fromLTWH(s.width * 0.33, 0, 14, s.height), rp);
    canvas.drawRect(Rect.fromLTWH(s.width * 0.72, 0, 10, s.height), rp);
  }
  @override bool shouldRepaint(_) => false;
}

class _MapControl extends StatelessWidget {
  final String label;
  const _MapControl(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: HHColors.surface, borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
      child: Center(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: HHColors.text))),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: HHColors.text2)),
    ]);
  }
}