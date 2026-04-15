// campus_market/models/cm_constants.dart
import 'dart:convert';
import 'dart:typed_data';
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
//  IMAGE HELPER — decode base64 to bytes
// ─────────────────────────────────────────────────────────────
Uint8List? decodeBase64Image(String base64String) {
  try {
    String cleanString = base64String.trim();
    
    // Remove data-URI prefix if present (backward compatibility)
    if (cleanString.contains(',')) {
      final parts = cleanString.split(',');
      if (parts.length > 1 && parts[0].contains('base64')) {
        cleanString = parts[1];
      }
    }
    
    // Remove quotes if present
    cleanString = cleanString.replaceAll('"', '').replaceAll("'", '');
    
    return base64Decode(cleanString);
  } catch (e) {
    debugPrint('Failed to decode image: $e');
    return null;
  }
}

// ─────────────────────────────────────────────────────────────
//  MODEL — CMListing
// ─────────────────────────────────────────────────────────────
class CMListing {
  final String id;
  final String title;
  final String description;
  final String price;
  final String category;
  final String condition;
  final String location;
  final String seller;
  final String sellerId;
  final double sellerRating;
  final String time;
  final String emoji;
  final Color gradA;
  final Color gradB;
  final bool isFree;
  final bool isFeatured;
  final bool isSaved;
  final String listingType;   // "sale" | "donation"
  final List<String> imageUrls;    // Clean base64 strings (no data-URI prefix)

  const CMListing({
    required this.id,
    required this.title,
    this.description = '',
    required this.price,
    required this.category,
    this.condition = '',
    this.location = '',
    required this.seller,
    this.sellerId = '',
    this.sellerRating = 0.0,
    this.time = '',
    this.emoji = '📦',
    this.gradA = const Color(0xFFEEF2FF),
    this.gradB = const Color(0xFFE0E7FF),
    this.isFree = false,
    this.isFeatured = false,
    this.isSaved = false,
    this.listingType = 'sale',
    this.imageUrls = const [],
  });

  // ─────────────────────────────────────────────────────────
  //  fromJson — parses the /api/v1/market/listings/ response
  //  Expected format from backend:
  //  {
  //    "id": "...",
  //    "title": "...",
  //    "imageData": ["/9j/4QBqRXhpZgA...", "..."]  // Clean base64
  //  }
  // ─────────────────────────────────────────────────────────
  factory CMListing.fromJson(Map<String, dynamic> j) {
    // ── price ─────────────────────────────────────────────
    final rawPrice = j['price'];
    final priceNum = double.tryParse(rawPrice?.toString() ?? '0') ?? 0;
    final isFree = (j['listingType']?.toString() == 'donation') ||
                   (j['isFree'] == true) ||
                   priceNum == 0;
    final priceStr = isFree ? 'FREE' : 'KES ${priceNum.toStringAsFixed(0)}';

    // ── imageData ─────────────────────────────────────────
    // Backend now returns: ["base64string1", "base64string2", ...]
    List<String> images = [];
    final rawImages = j['imageData'];
    
    if (rawImages is List) {
      // Clean each base64 string (remove any potential data-URI prefixes)
      images = rawImages.whereType<String>().map((img) {
        String clean = img.trim();
        if (clean.contains(',') && clean.startsWith('data:')) {
          clean = clean.split(',').last;
        }
        return clean.replaceAll('"', '').replaceAll("'", '');
      }).toList();
    } else if (rawImages is String && rawImages.isNotEmpty) {
      // Handle case where it's a JSON string
      try {
        final decoded = jsonDecode(rawImages);
        if (decoded is List) {
          images = decoded.whereType<String>().map((img) {
            String clean = img.trim();
            if (clean.contains(',') && clean.startsWith('data:')) {
              clean = clean.split(',').last;
            }
            return clean.replaceAll('"', '').replaceAll("'", '');
          }).toList();
        }
      } catch (_) {
        // If it's a single base64 string
        String clean = rawImages.trim();
        if (clean.contains(',') && clean.startsWith('data:')) {
          clean = clean.split(',').last;
        }
        images = [clean.replaceAll('"', '').replaceAll("'", '')];
      }
    }

    // ── gradient colours (fallback when no photo) ─────────
    final cat = (j['category']?.toString() ?? '').toLowerCase();
    final (gradA, gradB, emoji) = switch (cat) {
      'electronics' => (const Color(0xFFEFF6FF), const Color(0xFFDBEAFE), '💻'),
      'books' => (const Color(0xFFFFF7ED), const Color(0xFFFED7AA), '📚'),
      'furniture' => (const Color(0xFFF0FDF4), const Color(0xFFBBF7D0), '🪑'),
      'clothing' => (const Color(0xFFFDF4FF), const Color(0xFFE9D5FF), '👕'),
      'sports' => (const Color(0xFFFFFBEB), const Color(0xFFFDE68A), '⚽'),
      _ => (const Color(0xFFF8FAFC), const Color(0xFFE2E8F0), '📦'),
    };

    return CMListing(
      id: j['id']?.toString() ?? '',
      title: j['title']?.toString() ?? 'Untitled',
      description: j['description']?.toString() ?? '',
      price: priceStr,
      category: j['category']?.toString() ?? 'Other',
      condition: j['condition']?.toString() ?? '',
      location: j['location']?.toString() ?? 'Campus',
      seller: _sellerName(j),
      sellerId: _sellerId(j),
      sellerRating: _sellerRating(j),
      time: _relativeTime(j['createdAt']?.toString()),
      emoji: emoji,
      gradA: gradA,
      gradB: gradB,
      isFree: isFree,
      isFeatured: j['isFeatured'] == true,
      isSaved: j['isSaved'] == true,
      listingType: j['listingType']?.toString() ?? 'sale',
      imageUrls: images,
    );
  }

  CMListing copyWith({
    String? id,
    String? title,
    String? description,
    String? price,
    String? category,
    String? condition,
    String? location,
    String? seller,
    String? sellerId,
    double? sellerRating,
    String? time,
    String? emoji,
    Color? gradA,
    Color? gradB,
    bool? isFree,
    bool? isFeatured,
    bool? isSaved,
    String? listingType,
    List<String>? imageUrls,
  }) {
    return CMListing(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      seller: seller ?? this.seller,
      sellerId: sellerId ?? this.sellerId,
      sellerRating: sellerRating ?? this.sellerRating,
      time: time ?? this.time,
      emoji: emoji ?? this.emoji,
      gradA: gradA ?? this.gradA,
      gradB: gradB ?? this.gradB,
      isFree: isFree ?? this.isFree,
      isFeatured: isFeatured ?? this.isFeatured,
      isSaved: isSaved ?? this.isSaved,
      listingType: listingType ?? this.listingType,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Private helpers
  // ─────────────────────────────────────────────────────────
  static String _sellerName(Map<String, dynamic> j) {
    final seller = j['seller'];
    if (seller is Map) return seller['username']?.toString() ?? 'Unknown';
    if (seller is String) return seller;
    return j['sellerName']?.toString() ?? 'Unknown';
  }

  static String _sellerId(Map<String, dynamic> j) {
    final seller = j['seller'];
    if (seller is Map) return seller['id']?.toString() ?? '';
    return j['sellerId']?.toString() ?? '';
  }

  static double _sellerRating(Map<String, dynamic> j) {
    final seller = j['seller'];
    if (seller is Map) {
      return double.tryParse(seller['rating']?.toString() ?? '0') ?? 0;
    }
    return double.tryParse(j['sellerRating']?.toString() ?? '0') ?? 0;
  }

  static String _relativeTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
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
    this.newListings = 0,
    this.freeItems = 0,
    this.activeSellers = 0,
    this.dealsToday = 0,
  });

  factory CMStats.fromListings(List<CMListing> listings) => CMStats(
    newListings: listings.length,
    freeItems: listings.where((l) => l.isFree).length,
    activeSellers: listings.map((l) => l.seller).toSet().length,
    dealsToday: listings.where((l) {
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
  final bool isMine;

  const CMMessage({
    required this.id,
    required this.body,
    this.senderId = '',
    this.senderName = '',
    this.createdAt = '',
    this.isMine = false,
  });

  factory CMMessage.fromJson(Map<String, dynamic> j) => CMMessage(
    id: j['id']?.toString() ?? '',
    body: j['body']?.toString() ?? '',
    senderId: j['senderId']?.toString() ?? '',
    senderName: j['senderName']?.toString() ?? '',
    createdAt: j['createdAt']?.toString() ?? '',
    isMine: j['isMine'] as bool? ?? false,
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
    this.rating = 5.0,
    this.comment = '',
    this.createdAt = '',
  });

  factory CMReview.fromJson(Map<String, dynamic> j) => CMReview(
    id: j['id']?.toString() ?? '',
    reviewerName: j['reviewerName']?.toString() ?? '',
    rating: (j['rating'] as num?)?.toDouble() ?? 5.0,
    comment: j['comment']?.toString() ?? '',
    createdAt: j['createdAt']?.toString() ?? '',
  );
}