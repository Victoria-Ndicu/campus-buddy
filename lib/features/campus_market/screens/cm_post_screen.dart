// campus_market/screens/cm_post_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cm_constants.dart';
import '../widgets/cm_widgets.dart';

const _kCategories = ['Electronics', 'Books', 'Furniture', 'Clothing', 'Sports', 'Other'];
const _kConditions = ['New', 'Like New', 'Used — Excellent', 'Used — Good', 'Used — Fair'];

// ─────────────────────────────────────────────────────────────
//  SCREEN 1: POST ITEM (Type selector hub)
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
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [CMColors.brand, CMColors.brandDark],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                  color: CMColors.brand.withOpacity(0.3),
                  blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(children: [
              const Text('🛍', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 10),
              const Text('What would you like to post?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                      color: Colors.white)),
              const SizedBox(height: 6),
              Text('Reach hundreds of campus buyers instantly',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
            ]),
          ),

          const SizedBox(height: 24),
          CMSectionLabel(title: '📋 Choose a type'),

          // Listing type cards
          ...[
            ('🏷', 'Sell an Item', 'Set a price & find buyers fast', CMColors.brand),
            ('🎁', 'Donate for Free', 'Give away items you no longer need', CMColors.green),
            ('🔄', 'Swap / Exchange', 'Trade items with other students', CMColors.violet),
          ].map<Widget>((t) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PostTypeCard(
              emoji: t.$1, title: t.$2, subtitle: t.$3, color: t.$4,
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => CMCreateListingScreen(type: t.$2))),
            ),
          )),

          const SizedBox(height: 8),

          // Tips card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CMColors.brandPale,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CMColors.brand.withOpacity(0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('💡 Selling tips', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: CMColors.text)),
              const SizedBox(height: 8),
              ...['Add clear photos for 3× more interest',
                  'Price competitively — check similar listings',
                  'Respond quickly to messages'].map<Widget>((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(children: [
                  Text('•', style: TextStyle(color: CMColors.brand, fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tip, style: TextStyle(
                      fontSize: 12, color: CMColors.text2))),
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
//  SCREEN 2: LISTING PREVIEW (detail before publish)
// ─────────────────────────────────────────────────────────────
class CMListingPreviewScreen extends StatelessWidget {
  final String title, price, category, condition, description, type;
  const CMListingPreviewScreen({
    super.key,
    this.title = 'My Item',
    this.price = 'KES 0',
    this.category = 'General',
    this.condition = 'Used',
    this.description = '',
    this.type = 'Sell an Item',
  });

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
              Container(
                height: 180, width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  color: CMColors.brandPale,
                ),
                child: const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('📷', style: TextStyle(fontSize: 56)),
                    SizedBox(height: 8),
                    Text('No photo added', style: TextStyle(fontSize: 12, color: Color(0xFF9999BB))),
                  ],
                )),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(title, style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900, color: CMColors.text))),
                    Text(price, style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900, color: CMColors.brand)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    CMTag(category),
                    const SizedBox(width: 8),
                    CMTag(condition),
                  ]),
                  const SizedBox(height: 12),
                  if (description.isNotEmpty)
                    Text(description, style: TextStyle(
                        fontSize: 13, color: CMColors.text2, height: 1.5)),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 20),
          CMSectionLabel(title: '👁 How it looks to buyers'),
          Text('Your listing will appear in Browse Listings and in search results.',
              style: TextStyle(fontSize: 12, color: CMColors.text2)),

          const SizedBox(height: 24),
          CMPrimaryButton(
            label: '🚀 Publish Listing',
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.popUntil(context, (route) => route.isFirst || 
                  route.settings.name == '/market');
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Your listing "$title" is live! ✅'),
                backgroundColor: CMColors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 3),
              ));
            },
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN 3: CREATE LISTING (form)
// ─────────────────────────────────────────────────────────────
class CMCreateListingScreen extends StatefulWidget {
  final String type;
  const CMCreateListingScreen({super.key, this.type = 'Sell an Item'});
  @override
  State<CMCreateListingScreen> createState() => _CMCreateListingScreenState();
}

class _CMCreateListingScreenState extends State<CMCreateListingScreen> {
  int _categoryIdx = 0;
  int _conditionIdx = 0;
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  bool _isDonation = false;

  @override
  void initState() {
    super.initState();
    _isDonation = widget.type.contains('Donate') || widget.type.contains('Free');
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _priceCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
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
        title: Text(widget.type,
            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Photo placeholder
          GestureDetector(
            onTap: () => HapticFeedback.selectionClick(),
            child: Container(
              width: double.infinity, height: 140,
              decoration: BoxDecoration(
                color: CMColors.brandPale,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CMColors.brand.withOpacity(0.3),
                    style: BorderStyle.solid),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('📷', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 8),
                Text('Tap to add photos', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: CMColors.brand)),
                Text('Up to 5 photos', style: TextStyle(
                    fontSize: 11, color: CMColors.text3)),
              ]),
            ),
          ),

          CMSectionLabel(title: '📝 Item details'),

          // Title
          _InputField(
            label: 'Item Title *',
            hint: 'e.g. HP Laptop 15" i5 8GB',
            controller: _titleCtrl,
          ),

          // Category chips
          Text('Category *', style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: CMColors.text2)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8,
            children: List.generate(_kCategories.length, (i) => CMChip(
              label: _kCategories[i],
              active: _categoryIdx == i,
              onTap: () => setState(() => _categoryIdx = i),
            )),
          ),

          const SizedBox(height: 16),
          Text('Condition *', style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: CMColors.text2)),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _kConditions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => CMChip(
                label: _kConditions[i],
                active: _conditionIdx == i,
                onTap: () => setState(() => _conditionIdx = i),
              ),
            ),
          ),

          if (!_isDonation) ...[
            const SizedBox(height: 16),
            _InputField(
              label: 'Price (KES) *',
              hint: 'e.g. 3500',
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
            ),
          ],

          const SizedBox(height: 4),
          _InputField(
            label: 'Description',
            hint: 'Describe your item — include size, age, any defects…',
            controller: _descCtrl,
            maxLines: 4,
          ),

          const SizedBox(height: 24),
          CMPrimaryButton(
            label: 'Preview Listing →',
            onTap: () {
              if (_titleCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Please add a title'),
                  backgroundColor: CMColors.accent2,
                  behavior: SnackBarBehavior.floating,
                ));
                return;
              }
              HapticFeedback.mediumImpact();
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => CMListingPreviewScreen(
                  title: _titleCtrl.text.trim(),
                  price: _isDonation ? 'FREE'
                      : 'KES ${_priceCtrl.text.trim().isEmpty ? "0" : _priceCtrl.text.trim()}',
                  category: _kCategories[_categoryIdx],
                  condition: _kConditions[_conditionIdx],
                  description: _descCtrl.text.trim(),
                  type: widget.type,
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
//  PRIVATE HELPERS
// ─────────────────────────────────────────────────────────────
class _PostTypeCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _PostTypeCard({
    required this.emoji, required this.title, required this.subtitle,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [BoxShadow(
            color: color.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: CMColors.text)),
            const SizedBox(height: 3),
            Text(subtitle, style: TextStyle(fontSize: 12, color: CMColors.text3)),
          ])),
          Icon(Icons.chevron_right_rounded, color: color),
        ]),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  const _InputField({
    required this.label, required this.hint, required this.controller,
    this.maxLines = 1, this.keyboardType,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CMColors.border),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 13, color: CMColors.text3),
              contentPadding: const EdgeInsets.all(14),
              border: InputBorder.none,
            ),
          ),
        ),
      ]),
    );
  }
}