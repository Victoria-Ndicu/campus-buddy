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
//  GET    /api/v1/user/preferences/                        → fetch prefs
//  PATCH  /api/v1/user/preferences/                        → update prefs
//  GET    /api/v1/housing/alerts/                          → list alert rules
//  POST   /api/v1/housing/alerts/                          → create alert rule
//  PATCH  /api/v1/housing/alerts/<uuid>/                   → update alert rule
//  DELETE /api/v1/housing/alerts/<uuid>/                   → delete alert rule
//  GET    /api/v1/housing/alerts/notifications/            → inbox (paginated)
//  PATCH  /api/v1/housing/alerts/notifications/<uuid>/     → mark read
//
//  BACKEND NOTES:
//  ─────────────────────────────────────────────────────────
//  UserPreferences model (add field):
//    housing_module_enabled: BooleanField(default=True)
//
//  AlertRule model:
//    id: UUIDField(pk, default=uuid4)
//    user: ForeignKey(User, on_delete=CASCADE)
//    rule_type: CharField(choices=['area','price_drop','listing_available','new_listing'])
//    label: CharField(max_length=120)
//    area: CharField(null=True, blank=True)
//    max_price: IntegerField(null=True, blank=True)
//    property_types: ArrayField(CharField()) e.g. ["Apartment","Single Room"]
//    is_active: BooleanField(default=True)
//    created_at: DateTimeField(auto_now_add=True)
//    last_triggered: DateTimeField(null=True)
//
//  AlertNotification model:
//    id: UUIDField(pk, default=uuid4)
//    user: ForeignKey(User, on_delete=CASCADE)
//    rule: ForeignKey(AlertRule, null=True, on_delete=SET_NULL)
//    listing: ForeignKey(HousingListing, null=True, on_delete=SET_NULL)
//    listing_title: CharField (denormalised — survives listing deletion)
//    message: TextField
//    emoji: CharField(max_length=8, default='🔔')
//    is_read: BooleanField(default=False)
//    created_at: DateTimeField(auto_now_add=True)
//
//  Delivery: Django signal on HousingListing.save() →
//    iterate active AlertRules → match area/type/price →
//    create AlertNotification + send push notification
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
//  LOCAL MODELS  (mirror API response shape)
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
    ruleType:      j['rule_type']?.toString() ?? 'area',
    area:          j['area']?.toString(),
    maxPrice:      j['max_price'] as int?,
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
// ─────────────────────────────────────────────────────────────
class HHAlertsScreen extends StatefulWidget {
  const HHAlertsScreen({super.key});
  @override
  State<HHAlertsScreen> createState() => _HHAlertsScreenState();
}

class _HHAlertsScreenState extends State<HHAlertsScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabs;

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
    _tabs = TabController(length: 2, vsync: this);
    _fetchPreferences();
    _fetchRules();
    _fetchInbox();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  //  GET /api/v1/user/preferences/
  // ─────────────────────────────────────────────────────────
  Future<void> _fetchPreferences() async {
    if (mounted) setState(() => _loadingPrefs = true);
    try {
      final res = await ApiClient.get('/api/v1/user/preferences/');
      dev.log('[Alerts] GET /user/preferences/ → ${res.statusCode}');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>?;
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

  // ─────────────────────────────────────────────────────────
  //  PATCH /api/v1/user/preferences/
  // ─────────────────────────────────────────────────────────
  Future<void> _toggleModule(bool value) async {
    HapticFeedback.mediumImpact();
    setState(() { _moduleEnabled = value; _savingPrefs = true; });
    try {
      final res = await ApiClient.patch('/api/v1/user/preferences/',
          body: {'housing_module_enabled': value});
      dev.log('[Alerts] PATCH preferences → ${res.statusCode}');
      if (!mounted) return;
      if (res.statusCode != 200 && res.statusCode != 204) {
        setState(() => _moduleEnabled = !value);
        _snack('Could not save preference. Try again.');
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

  // ─────────────────────────────────────────────────────────
  //  GET /api/v1/housing/alerts/
  // ─────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────
  //  GET /api/v1/housing/alerts/notifications/
  // ─────────────────────────────────────────────────────────
  Future<void> _fetchInbox() async {
    if (mounted) setState(() { _loadingInbox = true; _inboxError = null; });
    try {
      final res = await ApiClient.get(
          '/api/v1/housing/alerts/notifications/');
      dev.log('[Alerts] GET /housing/alerts/notifications/ → ${res.statusCode}');
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

  // ─────────────────────────────────────────────────────────
  //  PATCH /api/v1/housing/alerts/<uuid>/
  // ─────────────────────────────────────────────────────────
  Future<void> _toggleRule(_AlertRule rule, bool value) async {
    HapticFeedback.selectionClick();
    setState(() => rule.isActive = value);
    try {
      final res = await ApiClient.patch(
          '/api/v1/housing/alerts/${rule.id}/',
          body: {'is_active': value});
      dev.log('[Alerts] PATCH /housing/alerts/${rule.id}/ → ${res.statusCode}');
      if (!mounted) return;
      if (res.statusCode != 200 && res.statusCode != 204) {
        setState(() => rule.isActive = !value);
        _snack('Could not update alert.');
      }
    } catch (e) {
      dev.log('[Alerts] toggle rule error: $e');
      if (mounted) {
        setState(() => rule.isActive = !value);
        _snack('Network error.');
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  //  DELETE /api/v1/housing/alerts/<uuid>/
  // ─────────────────────────────────────────────────────────
  Future<void> _deleteRule(_AlertRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Alert',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Remove "${rule.label}"?',
            style: TextStyle(color: HHColors.text2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete',
                  style: TextStyle(color: HHColors.coral))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _rules.remove(rule));
    try {
      final res = await ApiClient.delete(
          '/api/v1/housing/alerts/${rule.id}/');
      dev.log('[Alerts] DELETE /housing/alerts/${rule.id}/ → ${res.statusCode}');
      if (!mounted) return;
      if (res.statusCode != 204 && res.statusCode != 200) {
        setState(() => _rules.insert(0, rule));
        _snack('Could not delete alert.');
      }
    } catch (e) {
      dev.log('[Alerts] delete error: $e');
      if (mounted) {
        setState(() => _rules.insert(0, rule));
        _snack('Network error.');
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  //  PATCH /api/v1/housing/alerts/notifications/<uuid>/
  // ─────────────────────────────────────────────────────────
  Future<void> _markRead(_InboxItem item) async {
    if (item.isRead) return;
    setState(() => item.isRead = true);
    try {
      final res = await ApiClient.patch(
          '/api/v1/housing/alerts/notifications/${item.id}/',
          body: {'is_read': true});
      dev.log('[Alerts] PATCH notification ${item.id} → ${res.statusCode}');
      if (!mounted) return;
      if (res.statusCode != 200 && res.statusCode != 204) {
        setState(() => item.isRead = false);
      }
    } catch (e) {
      dev.log('[Alerts] mark read error: $e');
      if (mounted) setState(() => item.isRead = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: HHColors.brandDark,
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
      backgroundColor: HHColors.surface2,
      body: RefreshIndicator(
        color: HHColors.amber,
        onRefresh: () async => Future.wait([
          _fetchPreferences(),
          _fetchRules(),
          _fetchInbox(),
        ]),
        child: CustomScrollView(slivers: [

          // ── Hero App Bar ─────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            stretch: true,
            backgroundColor: HHColors.amber,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$_unreadCount unread',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(children: [
                  Positioned(top: -30, right: -20,
                    child: Container(width: 140, height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08)))),
                  Positioned(bottom: -20, left: -20,
                    child: Container(width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05)))),
                  Positioned(bottom: 20, left: 16, right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔔 ALERTS & SETTINGS',
                          style: TextStyle(fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                            letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        const Text('Housing Notifications',
                          style: TextStyle(fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                        Text(
                          _loadingPrefs
                            ? 'Loading…'
                            : _moduleEnabled
                              ? 'Module active · Watching for your perfect home'
                              : 'Module off · Turn on when you need housing',
                          style: TextStyle(fontSize: 12,
                            color: Colors.white.withOpacity(0.8))),
                      ],
                    )),
                ]),
              ),
            ),
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800),
              tabs: [
                Tab(text: _unreadCount > 0
                    ? 'Inbox ($_unreadCount)' : 'Inbox'),
                const Tab(text: 'My Alerts'),
              ],
            ),
          ),

          // ── Module Toggle Card ────────────────────────────
          SliverToBoxAdapter(child: _ModuleToggleCard(
            enabled: _moduleEnabled,
            loading: _savingPrefs || _loadingPrefs,
            onToggle: _toggleModule,
          )),

          // ── Tab content ───────────────────────────────────
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabs,
              children: [
                _loadingInbox
                  ? const Center(child: CircularProgressIndicator())
                  : _inboxError != null
                    ? _ErrorView(
                        message: _inboxError!,
                        onRetry: _fetchInbox)
                    : _InboxTab(
                        inbox: _inbox,
                        moduleEnabled: _moduleEnabled,
                        onMarkRead: _markRead,
                        onTapListing: (id, title) =>
                          Navigator.push(context,
                            MaterialPageRoute(
                              builder: (_) => HHListingDetailScreen(
                                title: title))),
                      ),

                _loadingRules
                  ? const Center(child: CircularProgressIndicator())
                  : _rulesError != null
                    ? _ErrorView(
                        message: _rulesError!,
                        onRetry: _fetchRules)
                    : _AlertsTab(
                        rules: _rules,
                        moduleEnabled: _moduleEnabled,
                        onToggle: _toggleRule,
                        onDelete: _deleteRule,
                        onAdd: () => Navigator.push(context,
                          MaterialPageRoute(
                            builder: (_) => HHCreateAlertScreen(
                              onSaved: (rule) {
                                setState(() =>
                                    _rules.insert(0, rule));
                                _snack(
                                  '✅ Alert "${rule.label}" created');
                              },
                            ))),
                      ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
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
      duration: const Duration(milliseconds: 350),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: enabled
            ? [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)]
            : [HHColors.surface3, HHColors.surface3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: enabled
            ? HHColors.amber.withOpacity(0.4) : HHColors.border,
          width: 1.5,
        ),
        boxShadow: enabled ? [BoxShadow(
          color: HHColors.amber.withOpacity(0.15),
          blurRadius: 16, offset: const Offset(0, 4))] : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: enabled
                    ? HHColors.amber.withOpacity(0.15)
                    : HHColors.border,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(
                  enabled ? '🏠' : '😴',
                  style: const TextStyle(fontSize: 24)))),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enabled
                      ? 'Housing Module Active'
                      : 'Housing Module Off',
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w900,
                      color: enabled
                        ? HHColors.text : HHColors.text3)),
                  const SizedBox(height: 2),
                  Text(
                    enabled
                      ? 'You\'re actively looking for housing'
                      : 'Turn on when you need accommodation',
                    style: TextStyle(fontSize: 12,
                      color: enabled
                        ? HHColors.text2 : HHColors.text3)),
                ])),
              loading
                ? SizedBox(width: 44, height: 28,
                    child: Center(child: SizedBox(width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: HHColors.amber))))
                : Switch.adaptive(
                    value: enabled,
                    onChanged: onToggle,
                    activeColor: HHColors.amber,
                    activeTrackColor:
                      HHColors.amber.withOpacity(0.3)),
            ]),
            const SizedBox(height: 14),
            Divider(
              color: enabled
                ? HHColors.amber.withOpacity(0.2) : HHColors.border,
              height: 1),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(enabled ? '💡' : '💤',
                  style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  enabled
                    ? 'The Housing Hub is active. Turn it off once '
                      'you\'ve found your place — it keeps your app '
                      'focused on what actually matters to you right now.'
                    : 'Enable the Housing Module only when you\'re '
                      'actively searching for accommodation. This keeps '
                      'your home screen clean and your alerts relevant. '
                      'It will reappear on your home screen once activated.',
                  style: TextStyle(
                    fontSize: 12, color: HHColors.text2,
                    height: 1.5))),
              ]),
            if (enabled) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 6, runSpacing: 6, children: [
                _BenefitChip('🔔 Real-time alerts'),
                _BenefitChip('📍 Area watching'),
                _BenefitChip('💰 Price alerts'),
                _BenefitChip('🔓 Availability alerts'),
              ]),
            ],
          ]),
      ),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  final String label;
  const _BenefitChip(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: HHColors.amber.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: HHColors.amber.withOpacity(0.25)),
    ),
    child: Text(label, style: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w700,
      color: HHColors.amber)),
  );
}

// ─────────────────────────────────────────────────────────────
//  INBOX TAB
// ─────────────────────────────────────────────────────────────
class _InboxTab extends StatelessWidget {
  final List<_InboxItem> inbox;
  final bool moduleEnabled;
  final ValueChanged<_InboxItem> onMarkRead;
  final Function(String id, String title) onTapListing;

  const _InboxTab({
    required this.inbox,
    required this.moduleEnabled,
    required this.onMarkRead,
    required this.onTapListing,
  });

  @override
  Widget build(BuildContext context) {
    if (!moduleEnabled) return const _Placeholder(
      emoji: '🔕',
      title: 'Notifications paused',
      subtitle: 'Enable the Housing Module above\nto start receiving alerts.',
    );
    if (inbox.isEmpty) return const _Placeholder(
      emoji: '🎉',
      title: 'All caught up!',
      subtitle: 'New housing alerts will appear here.',
    );

    final unread = inbox.where((n) => !n.isRead).toList();
    final read   = inbox.where((n) =>  n.isRead).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        if (unread.isNotEmpty) ...[
          _sectionLabel('New · ${unread.length}', HHColors.amber),
          ...unread.map((n) => _InboxCard(
            item: n,
            onTap: () {
              onMarkRead(n);
              if (n.listingId != null && n.listingTitle != null) {
                onTapListing(n.listingId!, n.listingTitle!);
              }
            },
          )),
        ],
        if (read.isNotEmpty) ...[
          _sectionLabel('Earlier', HHColors.text3),
          ...read.map((n) => _InboxCard(item: n, onTap: () {})),
        ],
      ],
    );
  }
}

Widget _sectionLabel(String title, Color color) => Padding(
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
  child: Text(title, style: TextStyle(
    fontSize: 11, fontWeight: FontWeight.w800,
    color: color, letterSpacing: 0.8)),
);

class _InboxCard extends StatelessWidget {
  final _InboxItem  item;
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
              : HHColors.amber.withOpacity(0.35),
            width: item.isRead ? 1 : 1.5),
          boxShadow: item.isRead ? [] : [BoxShadow(
            color: HHColors.amber.withOpacity(0.08),
            blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: item.isRead
                  ? HHColors.surface3 : HHColors.amberPale,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(item.emoji,
                style: const TextStyle(fontSize: 20)))),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.message, style: TextStyle(
                  fontSize: 13,
                  fontWeight: item.isRead
                    ? FontWeight.w500 : FontWeight.w700,
                  color: item.isRead
                    ? HHColors.text2 : HHColors.text,
                  height: 1.35)),
                if (item.listingTitle != null) ...[
                  const SizedBox(height: 3),
                  Text(item.listingTitle!, style: TextStyle(
                    fontSize: 11, color: HHColors.brand,
                    fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 4),
                Text(item.time, style: TextStyle(
                  fontSize: 10, color: HHColors.text3)),
              ])),
            if (!item.isRead)
              Container(width: 8, height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HHColors.amber)),
          ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ALERTS TAB
// ─────────────────────────────────────────────────────────────
class _AlertsTab extends StatelessWidget {
  final List<_AlertRule> rules;
  final bool moduleEnabled;
  final Function(_AlertRule, bool) onToggle;
  final Function(_AlertRule) onDelete;
  final VoidCallback onAdd;

  const _AlertsTab({
    required this.rules,
    required this.moduleEnabled,
    required this.onToggle,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        const _AlertTypeExplainer(),
        if (!moduleEnabled)
          const _Placeholder(
            emoji: '🔔',
            title: 'Alerts paused',
            subtitle: 'Enable the Housing Module above\nto activate your alert rules.',
          )
        else if (rules.isEmpty)
          const _Placeholder(
            emoji: '➕',
            title: 'No alerts yet',
            subtitle: 'Create your first alert to get notified\nwhen matching listings appear.',
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              '${rules.length} alert rule${rules.length == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 11,
                fontWeight: FontWeight.w600,
                color: HHColors.text3)),
          ),
          ...rules.map((r) => _AlertRuleCard(
            rule: r,
            moduleEnabled: moduleEnabled,
            onToggle: (v) => onToggle(r, v),
            onDelete: () => onDelete(r),
          )),
        ],
        if (moduleEnabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: HHColors.amber.withOpacity(0.4),
                    width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline_rounded,
                      color: HHColors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text('Create New Alert',
                      style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: HHColors.amber)),
                  ]),
              ),
            )),
      ],
    );
  }
}

class _AlertTypeExplainer extends StatelessWidget {
  const _AlertTypeExplainer();

  @override
  Widget build(BuildContext context) {
    const types = [
      ('📍', 'Area Alert',    'Notified when new listings appear in a specific neighbourhood'),
      ('💰', 'Price Alert',   'Alert when listings drop below your target price'),
      ('🔓', 'Availability',  'Know when a previously full listing has a new opening'),
      ('🆕', 'New Listing',   'First to hear about listings matching your criteria'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HHColors.amberPale,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HHColors.amber.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What can I be alerted about?', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w800,
            color: HHColors.text)),
          const SizedBox(height: 10),
          ...types.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.$1, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.$2, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: HHColors.text)),
                    Text(t.$3, style: TextStyle(
                      fontSize: 11, color: HHColors.text2,
                      height: 1.3)),
                  ])),
              ]),
          )),
        ]),
    );
  }
}

class _AlertRuleCard extends StatelessWidget {
  final _AlertRule rule;
  final bool moduleEnabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _AlertRuleCard({
    required this.rule,
    required this.moduleEnabled,
    required this.onToggle,
    required this.onDelete,
  });

  String get _typeEmoji => switch (rule.ruleType) {
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
  Color get _typeColor => switch (rule.ruleType) {
    'area'              => HHColors.blue,
    'price_drop'        => HHColors.teal,
    'listing_available' => HHColors.brand,
    _                   => HHColors.amber,
  };

  @override
  Widget build(BuildContext context) {
    final isOn = rule.isActive && moduleEnabled;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOn
            ? _typeColor.withOpacity(0.25) : HHColors.border),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: isOn
                  ? _typeColor.withOpacity(0.1)
                  : HHColors.surface3,
                borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(_typeEmoji,
                style: const TextStyle(fontSize: 18)))),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule.label, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: isOn ? HHColors.text : HHColors.text3)),
                const SizedBox(height: 2),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isOn
                        ? _typeColor.withOpacity(0.08)
                        : HHColors.surface3,
                      borderRadius: BorderRadius.circular(5)),
                    child: Text(_typeLabel, style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      color: isOn ? _typeColor : HHColors.text3))),
                  if (rule.area != null) ...[
                    const SizedBox(width: 5),
                    Text('· ${rule.area}', style: TextStyle(
                      fontSize: 10, color: HHColors.text3)),
                  ],
                  if (rule.maxPrice != null) ...[
                    const SizedBox(width: 5),
                    Text('· ≤ KES ${rule.maxPrice}',
                      style: TextStyle(
                        fontSize: 10, color: HHColors.text3)),
                  ],
                ]),
              ])),
            Switch.adaptive(
              value: rule.isActive,
              onChanged: moduleEnabled ? onToggle : null,
              activeColor: _typeColor,
              activeTrackColor: _typeColor.withOpacity(0.25),
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
                  bg: isOn
                    ? _typeColor.withOpacity(0.07)
                    : HHColors.surface3,
                  fg: isOn ? _typeColor : HHColors.text3)
                ).toList())),
              GestureDetector(
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.delete_outline_rounded,
                    size: 18, color: HHColors.text3))),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCREEN — CREATE ALERT
//  POST /api/v1/housing/alerts/
// ─────────────────────────────────────────────────────────────
class HHCreateAlertScreen extends StatefulWidget {
  final ValueChanged<_AlertRule> onSaved;
  const HHCreateAlertScreen({super.key, required this.onSaved});
  @override
  State<HHCreateAlertScreen> createState() =>
      _HHCreateAlertScreenState();
}

class _HHCreateAlertScreenState extends State<HHCreateAlertScreen> {
  String _ruleType = 'area';
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

  // ─────────────────────────────────────────────────────────
  //  POST /api/v1/housing/alerts/
  // ─────────────────────────────────────────────────────────
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
        if (_ruleType == 'area' || _ruleType == 'new_listing')
          'area': _area,
        if (_ruleType == 'price_drop')
          'max_price': _maxPrice,
      };

      final res = await ApiClient.post(
          '/api/v1/housing/alerts/', body: payload);
      dev.log('[CreateAlert] POST /housing/alerts/ → ${res.statusCode}');
      dev.log('[CreateAlert] body: ${res.body}');

      if (!mounted) return;

      if (res.statusCode == 201 || res.statusCode == 200) {
        final decoded =
            jsonDecode(res.body) as Map<String, dynamic>?;
        final newRule = decoded != null
          ? _AlertRule.fromJson(decoded)
          : _AlertRule(
              id:   DateTime.now().millisecondsSinceEpoch.toString(),
              label:         label,
              ruleType:      _ruleType,
              area:          (_ruleType == 'area' ||
                              _ruleType == 'new_listing')
                              ? _area : null,
              maxPrice:      _ruleType == 'price_drop'
                              ? _maxPrice : null,
              propertyTypes: _selTypes.toList(),
              isActive:      true,
            );
        widget.onSaved(newRule);
        Navigator.pop(context);
      } else {
        final errBody =
            jsonDecode(res.body) as Map<String, dynamic>?;
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

  String _buildAutoLabel() => switch (_ruleType) {
    'area'              => '$_area — Any',
    'price_drop'        => 'Under KES $_maxPrice',
    'listing_available' => 'Availability Watch',
    _                   => '$_area — New Listings',
  };

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
          fontSize: 16, fontWeight: FontWeight.w800,
          color: HHColors.text)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _saving
                  ? HHColors.text3 : HHColors.amber)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: HHColors.border, height: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 60),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 9),
                      decoration: BoxDecoration(
                        color: active
                          ? HHColors.amberPale : HHColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active
                            ? HHColors.amber : HHColors.border,
                          width: active ? 1.5 : 1)),
                      child: Row(children: [
                        Text(t.$2,
                          style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 7),
                        Expanded(child: Column(
                          crossAxisAlignment:
                            CrossAxisAlignment.start,
                          mainAxisAlignment:
                            MainAxisAlignment.center,
                          children: [
                            Text(t.$3, style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: active
                                ? HHColors.amber : HHColors.text)),
                            Text(t.$4, style: TextStyle(
                              fontSize: 9,
                              color: HHColors.text3,
                              height: 1.2),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          ])),
                      ]),
                    ),
                  );
                }).toList(),
              )),

            if (_ruleType == 'area' ||
                _ruleType == 'new_listing') ...[
              HHSectionLabel(title: 'Neighbourhood'),
              SizedBox(height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16),
                  itemCount: _areas.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 7),
                  itemBuilder: (_, i) => HHChip(
                    label: _areas[i],
                    active: _area == _areas[i],
                    onTap: () =>
                        setState(() => _area = _areas[i]),
                  ),
                )),
            ],

            if (_ruleType == 'price_drop') ...[
              HHSectionLabel(title: 'Maximum Price'),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: HHColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: HHColors.border)),
                  child: Column(children: [
                    Text('KES ${_maxPrice.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: HHColors.amber)),
                    Slider(
                      value: _maxPrice.toDouble(),
                      min: 3000, max: 30000, divisions: 27,
                      activeColor: HHColors.amber,
                      onChanged: (v) => setState(
                        () => _maxPrice =
                          (v / 1000).round() * 1000)),
                    Row(
                      mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                      children: [
                        Text('KES 3,000', style: TextStyle(
                          fontSize: 10, color: HHColors.text3)),
                        Text('KES 30,000', style: TextStyle(
                          fontSize: 10, color: HHColors.text3)),
                      ]),
                  ])),
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
                      if (active) _selTypes.remove(t);
                      else _selTypes.add(t);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active
                          ? HHColors.amberPale : HHColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: active
                            ? HHColors.amber : HHColors.border,
                          width: active ? 1.5 : 1)),
                      child: Text(t, style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: active
                          ? HHColors.amber : HHColors.text2))),
                  );
                }).toList())),

            HHSectionLabel(title: 'Label (optional)'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: HHColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HHColors.border)),
                child: TextField(
                  controller: _labelCtrl,
                  decoration: InputDecoration(
                    hintText:
                      'e.g. "Westlands Budget" (auto-generated if blank)',
                    hintStyle: TextStyle(
                      fontSize: 12, color: HHColors.text3),
                    contentPadding: const EdgeInsets.all(14),
                    border: InputBorder.none),
                  style: TextStyle(
                    fontSize: 13, color: HHColors.text),
                ))),

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

// ─────────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────────
class _Placeholder extends StatelessWidget {
  final String emoji, title, subtitle;
  const _Placeholder({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      vertical: 48, horizontal: 32),
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 56)),
      const SizedBox(height: 16),
      Text(title, style: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w800,
        color: HHColors.text)),
      const SizedBox(height: 8),
      Text(subtitle,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13, color: HHColors.text3, height: 1.5)),
    ]),
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(message, textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13, color: HHColors.text3)),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Retry')),
      ]),
  );
}