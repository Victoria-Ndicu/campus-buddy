// ============================================================
//  CampusBuddy — profile_screen.dart
//  Uses ApiClient (lib/core/api_client.dart) for all requests
//  — automatic token refresh, no more surprise logouts
// ============================================================

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api_client.dart';

import '../../study_buddy/study_buddy.dart';
import '../../campus_market/campus_market.dart';
import '../../housing_hub/housing.dart';
import '../../event_board/event.dart';
import '../../auth/screens/auth_login_screen.dart';

// ─────────────────────────────────────────────────────────────
//  THEME
// ─────────────────────────────────────────────────────────────
class _T {
  const _T();

  Color get bg        => const Color(0xFFF5F4F0);
  Color get surf      => Colors.white;
  Color get surf2     => const Color(0xFFF0F0F8);
  Color get border    => const Color(0xFFE1E5F7);
  Color get text      => const Color(0xFF1A1A2E);
  Color get text2     => const Color(0xFF555577);
  Color get text3     => const Color(0xFF9999BB);

  static const brand      = Color(0xFF667EEA);
  static const brandD     = Color(0xFF4A5FCC);
  static const brandPale  = Color(0xFFEEF1FD);
  static const terra      = Color(0xFFE07A5F);
  static const terraPale  = Color(0xFFFDF0EC);
  static const violet     = Color(0xFF7C3AED);
  static const violetPale = Color(0xFFF5F3FF);
  static const green      = Color(0xFF10B981);
  static const greenPale  = Color(0xFFECFDF5);
  static const coral      = Color(0xFFEF4444);

  Color get iconBrandBg  => brandPale;
  Color get iconGreenBg  => greenPale;
  Color get iconVioletBg => violetPale;
  Color get iconTerraBg  => terraPale;
  Color get dangerBorder => const Color(0xFFFFE4E4);
  Color get dangerBg     => const Color(0xFFFEF2F2);
}

// ─────────────────────────────────────────────────────────────
//  USER MODEL
// ─────────────────────────────────────────────────────────────
class _UserProfile {
  final String id, email, phone, role;
  final bool isVerified;
  final String fullName, university, degree, yearOfStudy;

  const _UserProfile({
    required this.id,
    required this.email,
    required this.phone,
    required this.role,
    required this.isVerified,
    this.fullName    = '',
    this.university  = '',
    this.degree      = '',
    this.yearOfStudy = '',
  });

  String get _firstName => fullName.trim().split(' ').first;
  String get _lastName {
    final parts = fullName.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  String get displayName =>
      fullName.trim().isEmpty ? email.split('@')[0] : fullName.trim();

  String get initials {
    final f = _firstName;
    final l = _lastName;
    if (f.isNotEmpty && l.isNotEmpty) return '${f[0]}${l[0]}'.toUpperCase();
    if (f.isNotEmpty) return f[0].toUpperCase();
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  /// Safely unwrap the JSON regardless of whether the server returns a flat
  /// object `{id, email, ...}` or a nested one `{user: {id, email, ...}}`.
  factory _UserProfile.fromJson(Map<String, dynamic> raw) {
    // If the payload is wrapped in a "user" or "data" key, unwrap it.
    final j = (raw['user'] is Map<String, dynamic>
            ? raw['user']
            : raw['data'] is Map<String, dynamic>
                ? raw['data']
                : raw)
        as Map<String, dynamic>;

    // Accept both String and num for any field
    String str(String key) {
      final v = j[key];
      if (v == null) return '';
      return v.toString();
    }

    // isVerified can come back as bool or int (0/1)
    bool boolVal(String key) {
      final v = j[key];
      if (v is bool)   return v;
      if (v is int)    return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
      return false;
    }

    return _UserProfile(
      id:          str('id'),
      email:       str('email'),
      phone:       str('phone'),
      role:        str('role').isEmpty ? 'student' : str('role'),
      isVerified:  boolVal('isVerified'),
      fullName:    str('fullName'),
      university:  str('university'),
      degree:      str('degree'),
      yearOfStudy: str('yearOfStudy'),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PROFILE SCREEN
// ─────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _t = _T();

  _UserProfile? _user;
  bool    _loadingUser = true;
  String? _fetchError;       // shown in _NameBlock with a retry button
  int     _navIndex    = 0;

  @override
  void initState() {
    super.initState();
    _fetchMe();
  }

  // ── READ ───────────────────────────────────────────────────
  Future<void> _fetchMe() async {
    // One atomic setState — avoids double-rebuild race between
    // setting _loadingUser=true and the later _user= assignment.
    if (mounted) setState(() { _loadingUser = true; _fetchError = null; });

    try {
      final res = await ApiClient.get('/api/v1/profile/me/');

      // Log for debugging — visible in flutter logs / DevTools
      dev.log('[ProfileScreen] GET /profile/me → ${res.statusCode}');
      dev.log('[ProfileScreen] body: ${res.body}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        dynamic decoded;
        try {
          decoded = jsonDecode(res.body);
        } catch (e) {
          setState(() {
            _fetchError  = 'Could not parse server response.';
            _loadingUser = false;
          });
          return;
        }

        if (decoded is! Map<String, dynamic>) {
          setState(() {
            _fetchError  = 'Unexpected response format from server.';
            _loadingUser = false;
          });
          return;
        }

        // Single setState — _user and _loadingUser flip together
        setState(() {
          _user        = _UserProfile.fromJson(decoded);
          _loadingUser = false;
          _fetchError  = null;
        });

      } else if (res.statusCode == 401) {
        setState(() => _loadingUser = false);
        _goToLogin();
      } else {
        setState(() {
          _fetchError  = 'Server error (${res.statusCode}). Please try again.';
          _loadingUser = false;
        });
      }
    } catch (e, stack) {
      dev.log('[ProfileScreen] _fetchMe error: $e', stackTrace: stack);
      if (mounted) {
        setState(() {
          _fetchError  = 'Could not load profile. Check your connection.';
          _loadingUser = false;
        });
      }
    }
  }

  // ── UPDATE ─────────────────────────────────────────────────
  Future<bool> _updateProfile(Map<String, dynamic> fields) async {
    try {
      final res = await ApiClient.patch('/api/v1/profile/me/', body: fields);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic> && mounted) {
          setState(() => _user = _UserProfile.fromJson(decoded));
        }
        return true;
      }
      final err = _parseError(res.body);
      if (mounted) _snack(err ?? 'Could not save changes. Please try again.');
      return false;
    } catch (_) {
      if (mounted) _snack('Network error. Please try again.');
      return false;
    }
  }

  // ── CHANGE PASSWORD ────────────────────────────────────────
  Future<void> _changePassword(String current, String next) async {
    try {
      final res = await ApiClient.patch('/api/v1/profile/password/', body: {
        'currentPassword': current,
        'newPassword': next,
      });
      if (res.statusCode == 200) {
        if (mounted) _snack('Password updated successfully!');
        return;
      }
      final err = _parseError(res.body);
      if (mounted) _snack(err ?? 'Could not update password.');
    } catch (_) {
      if (mounted) _snack('Network error. Please try again.');
    }
  }

  // ── SIGN OUT ───────────────────────────────────────────────
  Future<void> _confirmSignOut() async {
    final ok = await _showConfirmDialog(
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign Out',
      confirmColor: _T.coral,
    );
    if (ok != true || !mounted) return;

    try {
      final prefs   = await SharedPreferences.getInstance();
      final refresh = prefs.getString('refreshToken') ?? '';
      await ApiClient.post('/api/v1/auth/logout/', body: {'refresh': refresh});
      await ApiClient.clearTokens();
      await prefs.clear();
    } catch (_) { /* proceed regardless */ }

    _goToLogin();
  }

  // ── CHANGE PASSWORD MODAL ──────────────────────────────────
  void _showChangePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _t.surf,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          builder: (_, ctrl) => SingleChildScrollView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dragHandle(),
                const SizedBox(height: 20),
                Text('Change Password', style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900,
                  color: _t.text, letterSpacing: -0.3)),
                const SizedBox(height: 20),
                _editField('Current Password', currentCtrl, obscure: true),
                _editField('New Password', newCtrl, obscure: true),
                _editField('Confirm New Password', confirmCtrl, obscure: true),
                const SizedBox(height: 20),
                _primaryBtn('Update Password', () async {
                  if (newCtrl.text != confirmCtrl.text) {
                    _snack('Passwords do not match.'); return;
                  }
                  if (newCtrl.text.length < 8) {
                    _snack('Password must be at least 8 characters.'); return;
                  }
                  Navigator.pop(ctx);
                  await _changePassword(
                    currentCtrl.text.trim(), newCtrl.text.trim());
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── EDIT PROFILE MODAL ─────────────────────────────────────
  void _showEditProfile() {
    final user       = _user;
    final nameParts  = (user?.fullName ?? '').trim().split(' ');
    final firstCtrl  = TextEditingController(text: nameParts.first);
    final lastCtrl   = TextEditingController(
        text: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '');
    final phoneCtrl  = TextEditingController(text: user?.phone      ?? '');
    final uniCtrl    = TextEditingController(text: user?.university  ?? '');
    final degreeCtrl = TextEditingController(text: user?.degree      ?? '');
    final yearCtrl   = TextEditingController(text: user?.yearOfStudy ?? '');
    final emailCtrl  = TextEditingController(text: user?.email       ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _t.surf,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          builder: (_, ctrl) => SingleChildScrollView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dragHandle(),
                const SizedBox(height: 20),
                Text('Edit Profile', style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900,
                  color: _t.text, letterSpacing: -0.3)),
                const SizedBox(height: 20),
                _editField('First Name', firstCtrl),
                _editField('Last Name', lastCtrl),
                _editField('Phone', phoneCtrl, type: TextInputType.phone),
                _editField('University', uniCtrl),
                _editField('Course / Programme', degreeCtrl),
                _editField('Year of Study', yearCtrl,
                  type: TextInputType.number),
                const SizedBox(height: 8),
                _editField('Email (cannot change)', emailCtrl, readOnly: true),
                const SizedBox(height: 20),
                _primaryBtn('Save Changes', () async {
                  final first    = firstCtrl.text.trim();
                  final last     = lastCtrl.text.trim();
                  final combined = [first, last]
                      .where((s) => s.isNotEmpty).join(' ');

                  final success = await _updateProfile({
                    'fullName':    combined,
                    'phone':       phoneCtrl.text.trim(),
                    'university':  uniCtrl.text.trim(),
                    'degree':      degreeCtrl.text.trim(),
                    'yearOfStudy': yearCtrl.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (success && mounted) _snack('Profile updated!');
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── TERMS MODAL ────────────────────────────────────────────
  void _showTerms() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _t.surf,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dragHandle(),
              const SizedBox(height: 20),
              Text('Terms & Privacy Policy', style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900,
                color: _t.text, letterSpacing: -0.3)),
              const SizedBox(height: 4),
              Container(width: 40, height: 3,
                decoration: BoxDecoration(
                  color: _T.brand,
                  borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              _termsSection('1. Acceptance of Terms',
                'By accessing or using CampusBuddy, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the app.'),
              _termsSection('2. University Email Requirement',
                'CampusBuddy is exclusively for students, staff, and faculty of verified Kenyan universities. You must register with a valid institutional email address. Misrepresentation of your affiliation may result in immediate account termination.'),
              _termsSection('3. User Conduct',
                'You agree not to use CampusBuddy to post false, misleading, or harmful content; harass, abuse, or harm other users; engage in fraudulent transactions on the marketplace; or violate any applicable Kenyan law or regulation.'),
              _termsSection('4. Marketplace & Housing',
                'CampusBuddy facilitates connections between users but is not a party to any transaction. We are not responsible for the quality, safety, or legality of items listed. Users transact at their own risk.'),
              _termsSection('5. Data & Privacy',
                'We collect your email, profile information, and usage data to provide and improve our services. We do not sell your personal data to third parties. Your data is stored securely and processed in accordance with applicable data protection laws.'),
              _termsSection('6. Account Deletion',
                'You may delete your account at any time from the Profile screen. Upon deletion, all your personal data, listings, and content will be permanently removed from our systems within 30 days.'),
              _termsSection('7. Changes to Terms',
                'We reserve the right to modify these terms at any time. Continued use of CampusBuddy after changes constitutes acceptance of the new terms. We will notify users of significant changes via email.'),
              _termsSection('8. Contact',
                'For questions about these terms, please contact us at support@campusbuddy.co.ke'),
              const SizedBox(height: 20),
              Text('Last updated: March 2026',
                style: TextStyle(fontSize: 11, color: _t.text3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _termsSection(String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w800, color: _t.text)),
      const SizedBox(height: 6),
      Text(body, style: TextStyle(
        fontSize: 13, color: _t.text2, height: 1.6)),
    ]),
  );

  // ── BOTTOM NAV ─────────────────────────────────────────────
  void _onNavTap(int i) {
    if (i == _navIndex) return;
    HapticFeedback.mediumImpact();
    setState(() => _navIndex = i);
    final routes = <int, Widget Function()>{
      1: () => StudyBuddyHome(),
      2: () => CampusMarketHome(),
      3: () => HousingHubHome(),
      4: () => EventBoardHome(),
    };
    final builder = routes[i];
    if (builder != null) {
      Navigator.push(context,
        MaterialPageRoute(builder: (_) => builder()));
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthLoginScreen()),
      (_) => false,
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) _snack('Could not open link.');
    }
  }

  String? _parseError(String body) {
    try {
      final j = jsonDecode(body) as Map<String, dynamic>;
      final err = j['error'];
      if (err is Map) return err['message'] as String?;
      return j['detail'] as String?;
    } catch (_) { return null; }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    Color? titleColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _t.surf,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: TextStyle(
          fontWeight: FontWeight.w900, fontSize: 18,
          color: titleColor ?? _t.text)),
        content: Text(message, style: TextStyle(
          fontSize: 13, color: _t.text2, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(
              color: _t.text3, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: _T.brandD,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      ));
  }

  // ── SHARED WIDGETS ─────────────────────────────────────────
  Widget _dragHandle() => Center(
    child: Container(
      width: 40, height: 4,
      decoration: BoxDecoration(
        color: _t.border,
        borderRadius: BorderRadius.circular(2)),
    ),
  );

  Widget _primaryBtn(String label, VoidCallback onPressed) =>
    SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _T.brand,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w800)),
      ),
    );

  Widget _editField(
    String label,
    TextEditingController ctrl, {
    TextInputType type = TextInputType.text,
    bool readOnly = false,
    bool obscure  = false,
  }) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700, color: _t.text2)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          readOnly: readOnly,
          obscureText: obscure,
          style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: _t.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? _t.surf2 : _t.surf,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _t.border)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _t.border)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _T.brand, width: 2)),
          ),
        ),
      ]),
    );

  // ── BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _t.bg,
        extendBody: true,
        body: CustomScrollView(
          slivers: [

            // 1. Header
            SliverToBoxAdapter(
              child: _Header(
                user: _user,
                loading: _loadingUser,
                onEdit: _showEditProfile,
              ),
            ),

            // 2. Name / info block
            SliverToBoxAdapter(
              child: _NameBlock(
                user: _user,
                loading: _loadingUser,
                error: _fetchError,
                onRetry: _fetchMe,
              ),
            ),

            // 3. Account Settings
            SliverToBoxAdapter(child: _SecLabel('⚙️ Account Settings')),
            SliverToBoxAdapter(
              child: _SettingsCard(rows: [
                _SRow('👤', 'Personal Information', _t.iconBrandBg,
                  onTap: _showEditProfile),
                _SRow('🔑', 'Change Password', _t.iconBrandBg,
                  onTap: _showChangePassword),
                _SRow('🌍', 'Language', _t.iconTerraBg,
                  value: 'English',
                  onTap: () => _snack('Language settings — coming soon!')),
              ]),
            ),

            // 4. Support
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(child: _SecLabel('🛟 Support')),
            SliverToBoxAdapter(
              child: _SettingsCard(rows: [
                _SRow('❓', 'Help & Support', _t.iconBrandBg,
                  onTap: () => _launchUrl('https://support.google.com')),
                _SRow('💬', 'Send Feedback', _t.iconGreenBg,
                  onTap: () => _launchUrl('https://www.google.com')),
                _SRow('📄', 'Terms & Privacy Policy', _t.iconVioletBg,
                  onTap: _showTerms),
                _SRow('ℹ️', 'App Version', _t.iconBrandBg, value: 'v1.0.0'),
              ]),
            ),

            // 5. Sign out
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(
              child: _SecLabel('⚠️ Account', labelColor: _T.coral)),
            SliverToBoxAdapter(
              child: _DangerCard(onSignOut: _confirmSignOut)),

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          selected: _navIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final _UserProfile? user;
  final bool loading;
  final VoidCallback onEdit;
  static const _t = _T();

  const _Header({
    required this.user,
    required this.loading,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 210,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8096F0), _T.brand, _T.brandD],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: CustomPaint(
            painter: _TopoPainter(),
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: CustomPaint(
            size: const Size(double.infinity, 52),
            painter: _WavePainter(_t.bg),
          ),
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: _glassBtn(
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 15)),
                  ),
                  GestureDetector(
                    onTap: onEdit,
                    child: _glassBtn(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                      child: const Row(children: [
                        Icon(Icons.edit_rounded,
                          color: Colors.white, size: 13),
                        SizedBox(width: 5),
                        Text('Edit Profile', style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -46, left: 0, right: 0,
          child: Center(
            child: Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 92, height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _t.bg, width: 4),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_T.brandPale, _T.brand],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _T.brand.withOpacity(0.30),
                      blurRadius: 24,
                      offset: const Offset(0, 8)),
                  ],
                ),
                child: Center(
                  child: loading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : Text(
                        user?.initials ?? '?',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white),
                      ),
                ),
              ),
              if (user?.isVerified == true)
                Positioned(
                  bottom: 2, right: 2,
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _T.green,
                      border: Border.all(color: _t.bg, width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.check_rounded,
                        color: Colors.white, size: 13)),
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _glassBtn({required Widget child, EdgeInsets? padding}) => Container(
    padding: padding ?? const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: Colors.white.withOpacity(0.28)),
    ),
    child: child,
  );
}

// ─────────────────────────────────────────────────────────────
//  NAME BLOCK
// ─────────────────────────────────────────────────────────────
class _NameBlock extends StatelessWidget {
  final _UserProfile? user;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  static const _t = _T();

  const _NameBlock({
    required this.user,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      decoration: BoxDecoration(
        color: _t.surf,
        border: Border(bottom: BorderSide(color: _t.border)),
      ),
      child: _body(),
    );
  }

  Widget _body() {
    // Loading state
    if (loading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Error state — shows message + retry button
    if (error != null) {
      return SizedBox(
        height: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _t.text2)),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Null guard — should not happen after a clean 200 but keeps UI safe
    if (user == null) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text('No profile data.',
            style: TextStyle(fontSize: 13, color: _t.text3)),
        ),
      );
    }

    // ── Happy path ──────────────────────────────────────────
    return Column(
      children: [
        // Name + verified badge
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                user!.displayName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900,
                  color: _t.text, letterSpacing: -0.3),
              ),
            ),
            if (user!.isVerified) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _t.iconBrandBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded,
                      color: _T.brand, size: 11),
                    SizedBox(width: 3),
                    Text('Verified', style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: _T.brand)),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),

        // Info pills: degree · year · university
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (user!.degree.isNotEmpty)
              _InfoPill(
                icon: Icons.school_rounded,
                label: user!.degree,
                bg: _T.brandPale, color: _T.brand),
            if (user!.yearOfStudy.isNotEmpty)
              _InfoPill(
                icon: Icons.calendar_today_rounded,
                label: 'Year ${user!.yearOfStudy}',
                bg: _T.greenPale, color: _T.green),
            if (user!.university.isNotEmpty)
              _InfoPill(
                icon: Icons.location_city_rounded,
                label: user!.university,
                bg: _T.terraPale, color: _T.terra),
          ],
        ),

        const SizedBox(height: 10),
        Text(user!.email,
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: _t.text2)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  INFO PILL
// ─────────────────────────────────────────────────────────────
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg, color;

  const _InfoPill({
    required this.icon, required this.label,
    required this.bg,   required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────────────────────
class _SecLabel extends StatelessWidget {
  final String label;
  final Color? labelColor;
  static const _t = _T();
  const _SecLabel(this.label, {this.labelColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
    child: Text(label, style: TextStyle(
      fontSize: 14, fontWeight: FontWeight.w800,
      color: labelColor ?? _t.text)),
  );
}

// ─────────────────────────────────────────────────────────────
//  SETTING ROW MODEL
// ─────────────────────────────────────────────────────────────
class _SRow {
  final String emoji, label;
  final Color  iconBg;
  final String? value;
  final bool   isToggle;
  final bool?  toggleVal;
  final VoidCallback?       onTap;
  final ValueChanged<bool>? onToggle;

  const _SRow(this.emoji, this.label, this.iconBg, {
    this.value, this.isToggle = false, this.toggleVal,
    this.onTap, this.onToggle,
  });
}

// ─────────────────────────────────────────────────────────────
//  SETTINGS CARD
// ─────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<_SRow> rows;
  static const _t = _T();
  const _SettingsCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _t.surf,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _t.border),
        boxShadow: [
          BoxShadow(
            color: _T.brand.withOpacity(0.06),
            blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final r    = rows[i];
          final last = i == rows.length - 1;
          return GestureDetector(
            onTap: r.isToggle
              ? (r.onToggle != null
                  ? () => r.onToggle!(!(r.toggleVal ?? false))
                  : null)
              : r.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                border: last
                  ? null
                  : Border(bottom: BorderSide(color: _t.border)),
                borderRadius: last
                  ? const BorderRadius.vertical(
                      bottom: Radius.circular(18))
                  : (i == 0
                    ? const BorderRadius.vertical(
                        top: Radius.circular(18))
                    : null),
              ),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: r.iconBg,
                    borderRadius: BorderRadius.circular(11)),
                  child: Center(child: Text(r.emoji,
                    style: const TextStyle(fontSize: 16))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(r.label, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: _t.text))),
                if (r.value != null) ...[
                  Text(r.value!, style: TextStyle(
                    fontSize: 12, color: _t.text3)),
                  const SizedBox(width: 4),
                ],
                if (r.isToggle)
                  _Toggle(on: r.toggleVal ?? false,
                    onChanged: r.onToggle ?? (_) {})
                else if (r.onTap != null)
                  Icon(Icons.chevron_right_rounded,
                    size: 18, color: _t.text3),
              ]),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ANIMATED TOGGLE
// ─────────────────────────────────────────────────────────────
class _Toggle extends StatelessWidget {
  final bool on;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.on, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!on),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 38, height: 22,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: on ? _T.brand : const Color(0xFFE1E5F7),
        borderRadius: BorderRadius.circular(11),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 16, height: 16,
          decoration: const BoxDecoration(
            color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  DANGER CARD
// ─────────────────────────────────────────────────────────────
class _DangerCard extends StatelessWidget {
  final VoidCallback onSignOut;
  static const _t = _T();
  const _DangerCard({required this.onSignOut});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: _t.surf,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _t.dangerBorder, width: 1.5),
    ),
    child: GestureDetector(
      onTap: onSignOut,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(18))),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _t.dangerBg,
              borderRadius: BorderRadius.circular(11)),
            child: const Center(
              child: Text('🚪', style: TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('Sign Out', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: _t.text))),
          Icon(Icons.chevron_right_rounded, size: 18, color: _t.text3),
        ]),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  BOTTOM NAV
// ─────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  static const _t = _T();
  const _BottomNav({required this.selected, required this.onTap});

  static const _items = [
    (emoji: '🏠', label: 'Home',    c: _T.brand),
    (emoji: '📚', label: 'Study',   c: _T.brand),
    (emoji: '🛒', label: 'Market',  c: _T.terra),
    (emoji: '🏘', label: 'Housing', c: _T.green),
    (emoji: '🎉', label: 'Events',  c: _T.violet),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _t.surf,
        border: Border(top: BorderSide(color: _t.border)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10667EEA),
            blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      padding: EdgeInsets.only(
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
        left: 4, right: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final it     = _items[i];
          final active = i == selected;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active
                  ? it.c.withOpacity(0.10)
                  : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(it.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 3),
                Text(it.label, style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w700,
                  color: active ? it.c : _t.text3)),
              ]),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PAINTERS
// ─────────────────────────────────────────────────────────────
class _TopoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (final r in [(72.0, 38.0), (48.0, 25.0), (26.0, 14.0)]) {
      canvas.drawOval(Rect.fromCenter(
        center: Offset(s.width * 0.16, s.height * 0.25),
        width: r.$1 * 2, height: r.$2 * 2), p);
    }
    for (final r in [(85.0, 46.0), (58.0, 31.0), (33.0, 17.0)]) {
      canvas.drawOval(Rect.fromCenter(
        center: Offset(s.width * 0.848, s.height * 0.657),
        width: r.$1 * 2, height: r.$2 * 2), p);
    }
    final thin = Paint()
      ..color = Colors.white.withOpacity(0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    void curve(List<double> v) => canvas.drawPath(
      Path()
        ..moveTo(v[0], v[1])
        ..cubicTo(v[2], v[3], v[4], v[5], v[6], v[7]),
      thin);
    curve([0, s.height*.15, s.width*.21, s.height*.04,
           s.width*.48, s.height*.20, s.width, s.height*.16]);
    curve([0, s.height*.40, s.width*.19, s.height*.27,
           s.width*.46, s.height*.42, s.width, s.height*.38]);
    curve([0, s.height*.66, s.width*.24, s.height*.56,
           s.width*.50, s.height*.68, s.width, s.height*.64]);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _WavePainter extends CustomPainter {
  final Color color;
  const _WavePainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawPath(
      Path()
        ..moveTo(0, s.height * 0.19)
        ..quadraticBezierTo(s.width * 0.213, s.height * 1.06,
            s.width * 0.507, s.height * 0.577)
        ..quadraticBezierTo(s.width * 0.795, s.height * 0.154,
            s.width, s.height * 0.962)
        ..lineTo(s.width, s.height)
        ..lineTo(0, s.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}