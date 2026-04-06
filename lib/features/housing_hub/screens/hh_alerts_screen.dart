import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/hh_constants.dart';
import '../widgets/hh_widgets.dart';
import '../../../core/api_client.dart';
import 'hh_listings_screen.dart';

// ─────────────────────────────────────────────────────────────
//  API ENDPOINTS
//
//  GET    /api/v1/user/preferences/                        → fetch module state
//  PATCH  /api/v1/user/preferences/                        → toggle module on/off
//  GET    /api/v1/housing/alerts/                          → list alert rules
//  POST   /api/v1/housing/alerts/                          → create alert rule
//  PATCH  /api/v1/housing/alerts/<uuid>/                   → toggle alert rule
//  DELETE /api/v1/housing/alerts/<uuid>/                   → delete alert rule
//  GET    /api/v1/housing/alerts/notifications/            → inbox
//  PATCH  /api/v1/housing/alerts/notifications/<uuid>/     → mark read
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
//  LOCAL MODELS
// ─────────────────────────────────────────────────────────────
class _AlertRule {
  final String  id;
  String        label;
  final String  ruleType;
  final String? area;
  final int?    maxPrice;
  final List<String> propertyTypes;
  bool isActive;

  _AlertRule({
    required this.id,
    required this.label,
    required this.ruleType,
    this.area,
    this.maxPrice,
    this.propertyTypes = const [],
    this.isActive = true,
  });

  factory _AlertRule.fromJson(Map<String, dynamic> j) => _AlertRule(
    id:            j['id']?.toString() ?? '',
    label:         j['label']?.toString() ?? '',
    ruleType:      j['rule_type']?.toString() ?? 'new_listing',
    area:          j['area']?.toString(),
    maxPrice:      (j['max_price'] as num?)?.toInt(),
    propertyTypes: (j['property_types'] as List?)
        ?.map((e) => e.toString()).toList() ?? [],
    isActive:      j['is_active'] as bool? ?? true,
  );
}

class _InboxItem {
  final String  id;
  final String  message;
  final String  emoji;
  final String  time;
  final String? listingTitle;
  final String? listingId;
  bool   isRead;

  _InboxItem({
    required this.id,
    required this.message,
    required this.emoji,
    required this.time,
    this.listingTitle,
    this.listingId,
    this.isRead = false,
  });

  factory _InboxItem.fromJson(Map<String, dynamic> j) => _InboxItem(
    id:           j['id']?.toString() ?? '',
    message:      j['message']?.toString() ?? '',
    emoji:        j['emoji']?.toString() ?? '🔔',
    time:         j['created_at']?.toString() ?? '',
    listingTitle: j['listing_title']?.toString(),
    listingId:    j['listing']?.toString(),
    isRead:       j['is_read'] as bool? ?? false,
  );
}

// ─────────────────────────────────────────────────────────────
//  MAIN SCREEN
//  Flat layout — no tabs.
//  Structure:
//    ┌──────────────────────┐
//    │  Header app bar      │
//    │  Module toggle card  │
//    │  ── when ON ──       │
//    │  Notifications       │
//    │  Alert rules         │
//    │  [+ Create alert]    │
//    └──────────────────────┘
// ─────────────────────────────────────────────────────────────
class HHAlertsScreen extends StatefulWidget {
  const HHAlertsScreen({super.key});
  @override
  State<HHAlertsScreen> createState() => _HHAlertsScreenState();
}

class _HHAlertsScreenState extends State<HHAlertsScreen> {

  // Module toggle state — persists in DB, loaded on every open
  bool    _moduleEnabled = false;
  bool    _loadingPrefs  = true;
  bool    _savingPrefs   = false;

  List<_AlertRule> _rules        = [];
  bool             _loadingRules = true;
  String?          _rulesError;

  List<_InboxItem> _inbox        = [];
  bool             _loadingInbox = true;
  String?          _inboxError;

  int get _unreadCount => _inbox.where((n) => !n.isRead).length;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() => Future.wait([
    _fetchPreferences(),
    _fetchRules(),
    _fetchInbox(),
  ]);

  // ── GET /api/v1/user/preferences/ ────────────────────────────────────────
  // The module state lives in the DB — never in local storage.
  // This means it is exactly the same whether the user just signed in
  // for the first time or returned after months away.
  Future<void> _fetchPreferences() async {
    if (mounted) setState(() => _loadingPrefs = true);
    try {
      final res = await ApiClient.get('/api/v1/user/preferences/');
      dev.log('[Alerts] GET /user/preferences/ → ${res.statusCode}');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        // Handle both { data: {...} } and flat { housing_module_enabled: ... }
        final decoded = (body is Map && body.containsKey('data'))
            ? body['data'] as Map<String, dynamic>?
            : body as Map<String, dynamic>?;
        setState(() {
          _moduleEnabled = decoded?['housing_module_enabled'] as bool? ?? false;
          _loadingPrefs  = false;
        });
      } else {
        setState(() => _loadingPrefs = false);
      }
    } catch (e) {
      dev.log('[Alerts] preferences error: $e');
      if (mounted) setState(() => _loadingPrefs = false);
    }
  }

  // ── PATCH /api/v1/user/preferences/ ─────────────────────────────────────
  // Only called by the user explicitly tapping the toggle.
  // The backend stores the value and returns it on every subsequent GET —
  // so signing out and back in restores the exact state the user set.
  Future<void> _toggleModule(bool value) async {
    HapticFeedback.mediumImpact();
    // Optimistic update
    setState(() { _moduleEnabled = value; _savingPrefs = true; });
    try {
      final res = await ApiClient.patch(
        '/api/v1/user/preferences/',
        body: {'housing_module_enabled': value},
      );
      dev.log('[Alerts] PATCH preferences → ${res.statusCode}');
      if (!mounted) return;
      if (res.statusCode != 200 && res.statusCode != 204) {
        // Revert on failure
        setState(() => _moduleEnabled = !value);
        _snack('Could not save. Please try again.');
      }
    } catch (e) {
      dev.log('[Alerts] toggle error: $e');
      if (mounted) {
        setState(() => _moduleEnabled = !value);
        _snack('Network error. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _savingPrefs = false);
    }
  }

  // ── GET /api/v1/housing/alerts/ ──────────────────────────────────────────
  Future<void> _fetchRules() async {
    if (mounted) setState(() { _loadingRules = true; _rulesError = null; });
    try {
      final res = await ApiClient.get('/api/v1/housing/alerts/');
      dev.log('[Alerts] GET /housing/alerts/ → ${res.statusCode}');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final raw = decoded is List
            ? decoded
            : (decoded['results'] as List?) ?? [];
        setState(() {
          _rules        = raw.whereType<Map<String, dynamic>>()
              .map(_AlertRule.fromJson).toList();
          _loadingRules = false;
        });
      } else {
        setState(() {
          _rulesError   = 'Could not load alerts (${res.statusCode}).';
          _loadingRules = false;
        });
      }
    } catch (e, s) {
      dev.log('[Alerts] rules error: $e', stackTrace: s);
      if (mounted) setState(() {
        _rulesError   = 'Network error. Pull to refresh.';
        _loadingRules = false;
      });
    }
  }

  // ── GET /api/v1/housing/alerts/notifications/ ────────────────────────────
  Future<void> _fetchInbox() async {
    if (mounted) setState(() { _loadingInbox = true; _inboxError = null; });
    try {
      final res = await ApiClient.get('/api/v1/housing/alerts/notifications/');
      dev.log('[Alerts] GET notifications → ${res.statusCode}');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final raw = decoded is List
            ? decoded
            : (decoded['results'] as List?) ?? [];
        setState(() {
          _inbox        = raw.whereType<Map<String, dynamic>>()
              .map(_InboxItem.fromJson).toList();
          _loadingInbox = false;
        });
      } else {
        setState(() {
          _inboxError   = 'Could not load notifications (${res.statusCode}).';
          _loadingInbox = false;
        });
      }
    } catch (e, s) {
      dev.log('[Alerts] inbox error: $e', stackTrace: s);
      if (mounted) setState(() {
        _inboxError   = 'Network error. Pull to refresh.';
        _loadingInbox = false;
      });
    }
  }

  // ── PATCH /api/v1/housing/alerts/<uuid>/ ─────────────────────────────────
  Future<void> _toggleRule(_AlertRule rule, bool value) async {
    HapticFeedback.selectionClick();
    setState(() => rule.isActive = value);
    try {
      final res = await ApiClient.patch(
        '/api/v1/housing/alerts/${rule.id}/',
        body: {'is_active': value},
      );
      dev.log('[Alerts] PATCH alert ${rule.id} → ${res.statusCode}');
      if (!mounted) return;
      if (res.statusCode != 200 && res.statusCode != 204) {
        setState(() => rule.isActive = !value);
        _snack('Could not update alert.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => rule.isActive = !value);
        _snack('Network error.');
      }
    }
  }

  // ── DELETE /api/v1/housing/alerts/<uuid>/ ────────────────────────────────
  Future<void> _deleteRule(_AlertRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Alert', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Remove "${rule.label}"?', style: TextStyle(color: HHColors.text2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: HHColors.coral))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _rules.remove(rule));
    try {
      final res = await ApiClient.delete('/api/v1/housing/alerts/${rule.id}/');
      dev.log('[Alerts] DELETE alert ${rule.id} → ${res.statusCode}');
      if (!mounted) return;
      if (res.statusCode != 204 && res.statusCode != 200) {
        setState(() => _rules.insert(0, rule));
        _snack('Could not delete alert.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _rules.insert(0, rule));
        _snack('Network error.');
      }
    }
  }

  // ── PATCH /api/v1/housing/alerts/notifications/<uuid>/ ───────────────────
  Future<void> _markRead(_InboxItem item) async {
    if (item.isRead) return;
    setState(() => item.isRead = true);
    try {
      final res = await ApiClient.patch(
        '/api/v1/housing/alerts/notifications/${item.id}/',
        body: {'is_read': true},
      );
      if (!mounted) return;
      if (res.statusCode != 200 && res.statusCode != 204) {
        setState(() => item.isRead = false);
      }
    } catch (_) {
      if (mounted) setState(() => item.isRead = false);
    }
  }

  void _openListing(String id, String title) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => HHListingDetailScreen(
        listing: HousingListing(
          id:           id,
          title:        title,
          rentPerMonth: '',
          locationName: '',
          status:       'active',
          tags:         const [],
          amenities:    const [],
          imageUrls:    const [],
        ),
      ),
    ));
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: HHColors.brandDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HHColors.surface2,
      appBar: AppBar(
        backgroundColor: HHColors.amber,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Alerts & Notifications',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        actions: [
          if (_unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_unreadCount unread',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white.withOpacity(0.15)),
        ),
      ),

      body: RefreshIndicator(
        color: HHColors.amber,
        onRefresh: _fetchAll,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 60),
          children: [

            // ── Module toggle card ────────────────────────────────────────
            _ModuleToggleCard(
              enabled: _moduleEnabled,
              loading: _savingPrefs || _loadingPrefs,
              onToggle: _toggleModule,
            ),

            // ── When module is OFF — show a simple "turn on" prompt ───────
            if (!_loadingPrefs && !_moduleEnabled)
              _ModuleOffState(onEnable: () => _toggleModule(true)),

            // ── When module is ON — show notifications then alert rules ───
            if (!_loadingPrefs && _moduleEnabled) ...[

              // Notifications section
              _SectionHeader(
                title: 'Notifications',
                trailing: _unreadCount > 0 ? '$_unreadCount new' : null,
              ),

              if (_loadingInbox)
                const _LoadingRow()
              else if (_inboxError != null)
                _ErrorRow(message: _inboxError!, onRetry: _fetchInbox)
              else if (_inbox.isEmpty)
                const _EmptyRow(emoji: '🎉', message: 'All caught up! Alerts will appear here.')
              else
                ..._buildInboxItems(),

              const SizedBox(height: 8),

              // Alert rules section
              _SectionHeader(
                title: 'My Alert Rules',
                trailing: '${_rules.length} rule${_rules.length == 1 ? '' : 's'}',
              ),

              if (_loadingRules)
                const _LoadingRow()
              else if (_rulesError != null)
                _ErrorRow(message: _rulesError!, onRetry: _fetchRules)
              else if (_rules.isEmpty)
                const _EmptyRow(
                  emoji: '➕',
                  message: 'No alert rules yet.\nCreate one to get notified about new listings.',
                )
              else
                ..._rules.map((r) => _AlertRuleCard(
                  rule: r,
                  onToggle:  (v) => _toggleRule(r, v),
                  onDelete:  ()  => _deleteRule(r),
                )),

              // Create alert button
              _CreateAlertButton(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HHCreateAlertScreen(
                      onSaved: (rule) {
                        setState(() => _rules.insert(0, rule));
                        _snack('✅ Alert "${rule.label}" created');
                      },
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildInboxItems() {
    final unread = _inbox.where((n) => !n.isRead).toList();
    final read   = _inbox.where((n) =>  n.isRead).toList();
    return [
      if (unread.isNotEmpty) ...[
        _subLabel('New', HHColors.amber),
        ...unread.map((n) => _InboxCard(
          item:   n,
          onTap:  () {
            _markRead(n);
            if (n.listingId != null && n.listingTitle != null) {
              _openListing(n.listingId!, n.listingTitle!);
            }
          },
        )),
      ],
      if (read.isNotEmpty) ...[
        _subLabel('Earlier', HHColors.text3),
        ...read.map((n) => _InboxCard(item: n, onTap: () {})),
      ],
    ];
  }

  Widget _subLabel(String text, Color color) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
    child: Text(text, style: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w700,
      color: color, letterSpacing: 0.6)),
  );
}

// ─────────────────────────────────────────────────────────────
//  MODULE TOGGLE CARD
// ─────────────────────────────────────────────────────────────
class _ModuleToggleCard extends StatelessWidget {
  final bool enabled, loading;
  final ValueChanged<bool> onToggle;
  const _ModuleToggleCard({
    required this.enabled,
    required this.loading,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFFFFBEB) : HHColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: enabled ? HHColors.amber.withOpacity(0.5) : HHColors.border,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: enabled
                ? HHColors.amber.withOpacity(0.15)
                : HHColors.surface3,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(child: Text(
              enabled ? '🏠' : '😴',
              style: const TextStyle(fontSize: 22),
            )),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                enabled ? 'Housing Module Active' : 'Housing Module Off',
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w900,
                  color: enabled ? HHColors.text : HHColors.text3),
              ),
              const SizedBox(height: 2),
              Text(
                enabled
                  ? 'You\'re actively looking for housing'
                  : 'Turn on when you need accommodation',
                style: TextStyle(fontSize: 12, color: HHColors.text3),
              ),
            ],
          )),
          const SizedBox(width: 8),
          loading
            ? SizedBox(
                width: 44, height: 28,
                child: Center(child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: HHColors.amber),
                )),
              )
            : Switch.adaptive(
                value: enabled,
                onChanged: onToggle,
                activeColor: HHColors.amber,
                activeTrackColor: HHColors.amber.withOpacity(0.3),
              ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MODULE OFF STATE  — shown below toggle when module is off
// ─────────────────────────────────────────────────────────────
class _ModuleOffState extends StatelessWidget {
  final VoidCallback onEnable;
  const _ModuleOffState({required this.onEnable});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HHColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HHColors.border),
      ),
      child: Column(children: [
        const Text('😴', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 14),
        Text(
          'Housing alerts are paused',
          style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w800, color: HHColors.text),
        ),
        const SizedBox(height: 8),
        Text(
          'Enable the Housing Module above to start receiving '
          'notifications about new listings, price drops, and '
          'roommate matches.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: HHColors.text2, height: 1.5),
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: onEnable,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: HHColors.amber,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '🏠 Enable Housing Module',
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your preferences are saved — they\'ll be exactly as you left them.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: HHColors.text3),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SECTION HEADER
// ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w900, color: HHColors.text)),
        if (trailing != null)
          Text(trailing!, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: HHColors.text3)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  INBOX CARD
// ─────────────────────────────────────────────────────────────
class _InboxCard extends StatelessWidget {
  final _InboxItem   item;
  final VoidCallback onTap;
  const _InboxCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead ? HHColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isRead
              ? HHColors.border
              : HHColors.amber.withOpacity(0.4),
            width: item.isRead ? 1 : 1.5,
          ),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: item.isRead ? HHColors.surface3 : HHColors.amberPale,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(item.emoji,
              style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.message, style: TextStyle(
                fontSize: 13,
                fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                color: item.isRead ? HHColors.text2 : HHColors.text,
                height: 1.35,
              )),
              if (item.listingTitle != null) ...[
                const SizedBox(height: 3),
                Text(item.listingTitle!, style: TextStyle(
                  fontSize: 11, color: HHColors.brand,
                  fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 4),
              Text(item.time, style: TextStyle(
                fontSize: 10, color: HHColors.text3)),
            ],
          )),
          if (!item.isRead)
            Container(
              width: 8, height: 8,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: HHColors.amber,
              ),
            ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ALERT RULE CARD
// ─────────────────────────────────────────────────────────────
class _AlertRuleCard extends StatelessWidget {
  final _AlertRule rule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _AlertRuleCard({
    required this.rule,
    required this.onToggle,
    required this.onDelete,
  });

  String get _emoji => switch (rule.ruleType) {
    'area'              => '📍',
    'price_drop'        => '💰',
    'listing_available' => '🔓',
    _                   => '🆕',
  };

  String get _typeLabel => switch (rule.ruleType) {
    'area'              => 'Area Alert',
    'price_drop'        => 'Price Alert',
    'listing_available' => 'Availability Alert',
    _                   => 'New Listing Alert',
  };

  Color get _color => switch (rule.ruleType) {
    'area'              => HHColors.blue,
    'price_drop'        => HHColors.teal,
    'listing_available' => HHColors.brand,
    _                   => HHColors.amber,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rule.isActive
            ? _color.withOpacity(0.25) : HHColors.border,
        ),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: rule.isActive
                  ? _color.withOpacity(0.1) : HHColors.surface3,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(_emoji,
                style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule.label, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: rule.isActive ? HHColors.text : HHColors.text3,
                )),
                const SizedBox(height: 3),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: rule.isActive
                        ? _color.withOpacity(0.08) : HHColors.surface3,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(_typeLabel, style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      color: rule.isActive ? _color : HHColors.text3,
                    )),
                  ),
                  if (rule.area != null) ...[
                    const SizedBox(width: 5),
                    Text('· ${rule.area}', style: TextStyle(
                      fontSize: 10, color: HHColors.text3)),
                  ],
                  if (rule.maxPrice != null) ...[
                    const SizedBox(width: 5),
                    Text('· ≤ KES ${rule.maxPrice}', style: TextStyle(
                      fontSize: 10, color: HHColors.text3)),
                  ],
                ]),
              ],
            )),
            Switch.adaptive(
              value: rule.isActive,
              onChanged: onToggle,
              activeColor: _color,
              activeTrackColor: _color.withOpacity(0.25),
            ),
          ]),
        ),
        if (rule.propertyTypes.isNotEmpty) ...[
          Divider(color: HHColors.border, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Row(children: [
              Expanded(child: Wrap(spacing: 5, runSpacing: 4,
                children: rule.propertyTypes.map((t) => HHTag(t,
                  bg: rule.isActive
                    ? _color.withOpacity(0.07) : HHColors.surface3,
                  fg: rule.isActive ? _color : HHColors.text3,
                )).toList())),
              GestureDetector(
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.delete_outline_rounded,
                    size: 18, color: HHColors.text3),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CREATE ALERT BUTTON
// ─────────────────────────────────────────────────────────────
class _CreateAlertButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateAlertButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: HHColors.amber.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_circle_outline_rounded, color: HHColors.amber, size: 20),
        const SizedBox(width: 8),
        Text('Create New Alert', style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w800, color: HHColors.amber)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  LOADING / EMPTY / ERROR ROWS
// ─────────────────────────────────────────────────────────────
class _LoadingRow extends StatelessWidget {
  const _LoadingRow();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _EmptyRow extends StatelessWidget {
  final String emoji, message;
  const _EmptyRow({required this.emoji, required this.message});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: HHColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HHColors.border),
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text(message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: HHColors.text2, height: 1.5)),
      ]),
    ),
  );
}

class _ErrorRow extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRow({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(child: Text(message, style: TextStyle(
        fontSize: 12, color: HHColors.text3))),
      TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 14),
        label: const Text('Retry', style: TextStyle(fontSize: 12))),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────
//  SCREEN — CREATE ALERT
//  POST /api/v1/housing/alerts/
// ─────────────────────────────────────────────────────────────
class HHCreateAlertScreen extends StatefulWidget {
  final ValueChanged<_AlertRule> onSaved;
  const HHCreateAlertScreen({super.key, required this.onSaved});
  @override
  State<HHCreateAlertScreen> createState() => _HHCreateAlertScreenState();
}

class _HHCreateAlertScreenState extends State<HHCreateAlertScreen> {
  String _ruleType = 'new_listing';
  String _area     = 'Westlands';
  int    _maxPrice = 15000;
  bool   _saving   = false;

  final Set<String> _selTypes = {'Apartment', 'Single Room'};
  final _labelCtrl = TextEditingController();

  static const _areas = [
    'Westlands', 'Parklands', 'CBD',
    'Ngara', 'Highridge', 'Kilimani',
  ];
  static const _propTypes = [
    'Apartment', 'Single Room', 'Shared', 'Bedsitter',
  ];
  static const _ruleTypes = [
    ('area',              '📍', 'Area Alert',   'New listings in a specific area'),
    ('price_drop',        '💰', 'Price Alert',  'Listings under your budget'),
    ('listing_available', '🔓', 'Availability', 'When a full listing reopens'),
    ('new_listing',       '🆕', 'New Listing',  'First to see matching listings'),
  ];

  @override
  void dispose() { _labelCtrl.dispose(); super.dispose(); }

  String _buildAutoLabel() => switch (_ruleType) {
    'area'              => '$_area — Any',
    'price_drop'        => 'Under KES $_maxPrice',
    'listing_available' => 'Availability Watch',
    _                   => '$_area — New Listings',
  };

  Future<void> _save() async {
    if (_selTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select at least one property type.'),
        backgroundColor: HHColors.brandDark,
      ));
      return;
    }
    final label = _labelCtrl.text.trim().isNotEmpty
        ? _labelCtrl.text.trim()
        : _buildAutoLabel();

    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'rule_type':      _ruleType,
        'label':          label,
        'property_types': _selTypes.toList(),
        'is_active':      true,
        if (_ruleType == 'area' || _ruleType == 'new_listing') 'area': _area,
        if (_ruleType == 'price_drop') 'max_price': _maxPrice,
      };

      final res = await ApiClient.post('/api/v1/housing/alerts/', body: payload);
      dev.log('[CreateAlert] POST → ${res.statusCode}');
      if (!mounted) return;

      if (res.statusCode == 201 || res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final json = (decoded is Map && decoded.containsKey('data'))
            ? decoded['data'] as Map<String, dynamic>
            : decoded as Map<String, dynamic>? ?? {};
        final newRule = json.isNotEmpty
            ? _AlertRule.fromJson(json)
            : _AlertRule(
                id:            DateTime.now().millisecondsSinceEpoch.toString(),
                label:         label,
                ruleType:      _ruleType,
                area:          (_ruleType == 'area' || _ruleType == 'new_listing') ? _area : null,
                maxPrice:      _ruleType == 'price_drop' ? _maxPrice : null,
                propertyTypes: _selTypes.toList(),
                isActive:      true,
              );
        widget.onSaved(newRule);
        Navigator.pop(context);
      } else {
        final errBody = jsonDecode(res.body) as Map<String, dynamic>?;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errBody?['detail']?.toString()
              ?? 'Could not create alert (${res.statusCode}).'),
          backgroundColor: HHColors.brandDark,
        ));
      }
    } catch (e) {
      dev.log('[CreateAlert] error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: HHColors.brandDark,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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
        title: const Text('Create Alert', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w800, color: HHColors.text)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              _saving ? 'Saving…' : 'Save',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _saving ? HHColors.text3 : HHColors.amber),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: HHColors.border, height: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 60),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          HHSectionLabel(title: 'Alert Type'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8, crossAxisSpacing: 8,
              childAspectRatio: 2.4,
              children: _ruleTypes.map<Widget>((t) {
                final active = _ruleType == t.$1;
                return GestureDetector(
                  onTap: () => setState(() => _ruleType = t.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      color:  active ? HHColors.amberPale : HHColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active ? HHColors.amber : HHColors.border,
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      Text(t.$2, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 7),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(t.$3, style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w800,
                            color: active ? HHColors.amber : HHColors.text)),
                          Text(t.$4, style: TextStyle(
                            fontSize: 9, color: HHColors.text3, height: 1.2),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      )),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),

          if (_ruleType == 'area' || _ruleType == 'new_listing') ...[
            HHSectionLabel(title: 'Neighbourhood'),
            SizedBox(height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _areas.length,
                separatorBuilder: (_, __) => const SizedBox(width: 7),
                itemBuilder: (_, i) => HHChip(
                  label: _areas[i],
                  active: _area == _areas[i],
                  onTap: () => setState(() => _area = _areas[i]),
                ),
              )),
          ],

          if (_ruleType == 'price_drop') ...[
            HHSectionLabel(title: 'Maximum Price'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: HHColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HHColors.border),
                ),
                child: Column(children: [
                  Text('KES $_maxPrice', style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w900, color: HHColors.amber)),
                  Slider(
                    value: _maxPrice.toDouble(),
                    min: 3000, max: 30000, divisions: 27,
                    activeColor: HHColors.amber,
                    onChanged: (v) => setState(() => _maxPrice = (v / 1000).round() * 1000),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('KES 3,000', style: TextStyle(fontSize: 10, color: HHColors.text3)),
                    Text('KES 30,000', style: TextStyle(fontSize: 10, color: HHColors.text3)),
                  ]),
                ]),
              ),
            ),
          ],

          HHSectionLabel(title: 'Property Types'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(spacing: 8, runSpacing: 8,
              children: _propTypes.map<Widget>((t) {
                final active = _selTypes.contains(t);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (active) _selTypes.remove(t); else _selTypes.add(t);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? HHColors.amberPale : HHColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active ? HHColors.amber : HHColors.border,
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Text(t, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: active ? HHColors.amber : HHColors.text2)),
                  ),
                );
              }).toList(),
            ),
          ),

          HHSectionLabel(title: 'Label (optional)'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: HHColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HHColors.border),
              ),
              child: TextField(
                controller: _labelCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. "Westlands Budget" (auto-generated if blank)',
                  hintStyle: TextStyle(fontSize: 12, color: HHColors.text3),
                  contentPadding: const EdgeInsets.all(14),
                  border: InputBorder.none,
                ),
                style: TextStyle(fontSize: 13, color: HHColors.text),
              ),
            ),
          ),

          const SizedBox(height: 28),
          HHPrimaryButton(
            label: _saving ? '⏳ Saving…' : '🔔 Create Alert',
            onTap: _saving ? null : _save,
          ),
        ]),
      ),
    );
  }
}