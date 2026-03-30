// campus_market/models/cm_constants.dart
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  COLORS
// ─────────────────────────────────────────────────────────────
class CMColors {
  static const Color brand      = Color(0xFFE07A5F);
  static const Color brandDark  = Color(0xFFC4674E);
  static const Color brandLight = Color(0xFFEA9A84);
  static const Color brandPale  = Color(0xFFFDF0EC);
  static const Color surface2   = Color(0xFFF5F4F0);
  static const Color surface3   = Color(0xFFF1F3F5);
  static const Color border     = Color(0xFFE8D8D3);
  static const Color text       = Color(0xFF1A1A2E);
  static const Color text2      = Color(0xFF555577);
  static const Color text3      = Color(0xFF9999BB);
  static const Color green      = Color(0xFF10B981);
  static const Color accent     = Color(0xFFF59E0B);
  static const Color accent2    = Color(0xFFEF4444);
  static const Color violet     = Color(0xFF7C3AED);
}

// ─────────────────────────────────────────────────────────────
//  THEME HELPERS
// ─────────────────────────────────────────────────────────────
class CMTheme {
  static BoxDecoration get card => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: CMColors.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );

  static BoxDecoration brandGradient() => const BoxDecoration(
    gradient: LinearGradient(
      colors: [CMColors.brand, CMColors.brandDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
  );

  static BoxDecoration get headerGradient => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEA9A84), CMColors.brand, CMColors.brandDark],
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  MODEL — CMListing
// ─────────────────────────────────────────────────────────────
class CMListing {
  final String id;
  final String emoji;
  final String title;
  final String price;
  final String category;
  final String condition;
  final String seller;
  final String sellerId;
  final String sellerRating;
  final String time;
  final String location;
  final String description;
  final bool   isFeatured;
  final bool   isSaved;
  final bool   isFree;
  final Color  gradA;
  final Color  gradB;

  const CMListing({
    required this.id,
    required this.title,
    this.emoji        = '📦',
    this.price        = 'KES 0',
    this.category     = '',
    this.condition    = '',
    this.seller       = '',
    this.sellerId     = '',
    this.sellerRating = '4.8',
    this.time         = '',
    this.location     = 'Near Main Gate, UoN',
    this.description  = '',
    this.isFeatured   = false,
    this.isSaved      = false,
    this.isFree       = false,
    this.gradA        = const Color(0xFFFDF0EC),
    this.gradB        = const Color(0xFFEED5CC),
  });

  CMListing copyWith({bool? isSaved}) => CMListing(
    id:           id,
    title:        title,
    emoji:        emoji,
    price:        price,
    category:     category,
    condition:    condition,
    seller:       seller,
    sellerId:     sellerId,
    sellerRating: sellerRating,
    time:         time,
    location:     location,
    description:  description,
    isFeatured:   isFeatured,
    isFree:       isFree,
    isSaved:      isSaved ?? this.isSaved,
    gradA:        gradA,
    gradB:        gradB,
  );

  factory CMListing.fromJson(Map<String, dynamic> raw) {
    final j = (raw['listing'] is Map<String, dynamic>
        ? raw['listing'] : raw) as Map<String, dynamic>;

    String str(String k) => j[k]?.toString() ?? '';
    bool   boo(String k) {
      final v = j[k];
      if (v is bool)   return v;
      if (v is int)    return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
      return false;
    }

    Color gradA = const Color(0xFFFDF0EC);
    Color gradB = const Color(0xFFEED5CC);
    final cat = str('category').toLowerCase();
    if (cat.contains('book')) {
      gradA = const Color(0xFFEEF1FD);
      gradB = const Color(0xFFC7D2FA);
    } else if (cat.contains('electronic')) {
      gradA = const Color(0xFFECFDF5);
      gradB = const Color(0xFFA7F3D0);
    } else if (cat.contains('furniture')) {
      gradA = const Color(0xFFFFFBEB);
      gradB = const Color(0xFFFDE68A);
    } else if (cat.contains('cloth') || cat.contains('fashion')) {
      gradA = const Color(0xFFF0FDF4);
      gradB = const Color(0xFFBBF7D0);
    }

    final priceStr = str('price');
    final isFree   = boo('isFree') ||
        priceStr.isEmpty ||
        priceStr == '0' ||
        priceStr.toLowerCase() == 'free';

    return CMListing(
      id:           str('id'),
      title:        str('title'),
      emoji:        str('emoji').isEmpty        ? '📦'                  : str('emoji'),
      price:        priceStr.isEmpty            ? 'Free'                : priceStr,
      category:     str('category'),
      condition:    str('condition'),
      seller:       str('seller').isEmpty       ? str('sellerName')     : str('seller'),
      sellerId:     str('sellerId'),
      sellerRating: str('sellerRating').isEmpty ? '4.8'                 : str('sellerRating'),
      time:         str('time').isEmpty         ? str('createdAt')      : str('time'),
      location:     str('location').isEmpty     ? 'Near Main Gate, UoN' : str('location'),
      description:  str('description'),
      isFeatured:   boo('isFeatured'),
      isSaved:      boo('isSaved'),
      isFree:       isFree,
      gradA:        gradA,
      gradB:        gradB,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MODEL — CMStats
// ─────────────────────────────────────────────────────────────
class CMStats {
  final int newListings;
  final int freeItems;
  final int activeSellers;
  final int dealsToday;

  const CMStats({
    this.newListings   = 0,
    this.freeItems     = 0,
    this.activeSellers = 0,
    this.dealsToday    = 0,
  });

  factory CMStats.fromListings(List<CMListing> listings) => CMStats(
    newListings:   listings.length,
    freeItems:     listings.where((l) => l.isFree).length,
    activeSellers: listings.map((l) => l.seller).toSet().length,
    dealsToday:    listings.where((l) {
      if (!l.price.contains('KES')) return false;
      final n = int.tryParse(l.price.replaceAll(RegExp(r'[^0-9]'), ''));
      return n != null && n < 1000;
    }).length,
  );
}

// ─────────────────────────────────────────────────────────────
//  MODEL — CMMessage
// ─────────────────────────────────────────────────────────────
class CMMessage {
  final String id;
  final String body;
  final String senderId;
  final String senderName;
  final String createdAt;
  final bool   isMine;

  const CMMessage({
    required this.id,
    required this.body,
    this.senderId   = '',
    this.senderName = '',
    this.createdAt  = '',
    this.isMine     = false,
  });

  factory CMMessage.fromJson(Map<String, dynamic> j) => CMMessage(
    id:         j['id']?.toString()         ?? '',
    body:       j['body']?.toString()       ?? '',
    senderId:   j['senderId']?.toString()   ?? '',
    senderName: j['senderName']?.toString() ?? '',
    createdAt:  j['createdAt']?.toString()  ?? '',
    isMine:     j['isMine'] as bool?        ?? false,
  );
}

// ─────────────────────────────────────────────────────────────
//  MODEL — CMReview
// ─────────────────────────────────────────────────────────────
class CMReview {
  final String id;
  final String reviewerName;
  final double rating;
  final String comment;
  final String createdAt;

  const CMReview({
    required this.id,
    required this.reviewerName,
    this.rating    = 5.0,
    this.comment   = '',
    this.createdAt = '',
  });

  factory CMReview.fromJson(Map<String, dynamic> j) => CMReview(
    id:           j['id']?.toString()               ?? '',
    reviewerName: j['reviewerName']?.toString()     ?? '',
    rating:       (j['rating'] as num?)?.toDouble() ?? 5.0,
    comment:      j['comment']?.toString()          ?? '',
    createdAt:    j['createdAt']?.toString()        ?? '',
  );
}