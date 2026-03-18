// ============================================================
//  CampusBuddy — profile_screen.dart
//  lib/features/profile/screens/profile_screen.dart
//
//  Sections (top → bottom):
//    1. Wavy blue header  (back btn, edit btn, avatar)
//    2. Name + verified badge + university + email
//    3. Account Settings  (personal info, password,
//                          privacy, notifications, dark mode, language)
//    4. Support           (help, feedback, terms, app version)
//    5. Danger zone       (sign out · delete account)
//    6. Bottom navigation bar
//
//  Navigation:
//  ┌──────────────────────────────────────────┐
//  │ ← Back                → Navigator.pop() │
//  │ ✏ Edit Profile        → /profile/edit   │
//  │ Personal Information  → /profile/info   │
//  │ Change Password       → /profile/password│
//  │ Privacy & Security    → /profile/privacy │
//  │ Language              → /profile/language│
//  │ Help & Support        → /support         │
//  │ Send Feedback         → /feedback        │
//  │ Terms & Privacy Policy→ /terms           │
//  │ Sign Out              → dialog → /sign-in│
//  │ Delete Account        → dialog → /sign-in│
//  │ Bottom nav tabs       → module routes    │
//  └──────────────────────────────────────────┘
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────
//  BRAND COLOURS
// ─────────────────────────────────────────────────────────────
class _C {
  static const brand      = Color(0xFF667EEA);
  static const brandD     = Color(0xFF4A5FCC);
  static const brandPale  = Color(0xFFEEF1FD);
  static const terra      = Color(0xFFE07A5F);
  static const terraPale  = Color(0xFFFDF0EC);
  static const violet     = Color(0xFF7C3AED);
  static const violetPale = Color(0xFFF5F3FF);
  static const green      = Color(0xFF10B981);
  static const greenPale  = Color(0xFFECFDF5);
  static const amberPale  = Color(0xFFFFFBEB);
  static const coral      = Color(0xFFEF4444);
  static const offWhite   = Color(0xFFF5F4F0);
  static const surf       = Color(0xFFFFFFFF);
  static const text       = Color(0xFF1A1A2E);
  static const text3      = Color(0xFF9999BB);
  static const border     = Color(0xFFE1E5F7);
}

// ─────────────────────────────────────────────────────────────
//  ROUTE CONSTANTS
// ─────────────────────────────────────────────────────────────
class _R {
  static const editProfile = '/profile/edit';
  static const personalInfo = '/profile/info';
  static const changePassword = '/profile/password';
  static const privacy     = '/profile/privacy';
  static const language    = '/profile/language';
  static const support     = '/support';
  static const feedback    = '/feedback';
  static const terms       = '/terms';
  static const signIn      = '/sign-in';
  // module routes
  static const home        = '/home';
  static const studyBuddy  = '/study-buddy';
  static const market      = '/market';
  static const housing     = '/housing';
  static const events      = '/events';
}

// ─────────────────────────────────────────────────────────────
//  SAFE NAVIGATOR
// ─────────────────────────────────────────────────────────────
void _go(BuildContext ctx, String route) {
  Navigator.pushNamed(ctx, route).catchError((_) {
    ScaffoldMessenger.of(ctx)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('$route — coming soon!'),
        backgroundColor: _C.brandD,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ));
    return null;
  });
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
  bool _notificationsOn = true;
  bool _darkModeOn      = false;
  int  _navIndex        = 0;

  void _onNavTap(int i) {
    if (i == _navIndex) return;
    setState(() => _navIndex = i);
    const routes = [_R.home, _R.studyBuddy, _R.market, _R.housing, _R.events];
    _go(context, routes[i]);
  }

  Future<void> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: 'Sign Out',
        message: 'Are you sure you want to sign out?',
        confirmLabel: 'Sign Out',
        confirmColor: _C.coral,
      ),
    );
    if (ok == true && mounted) {
      // TODO: FirebaseAuth.instance.signOut()
      Navigator.pushNamedAndRemoveUntil(
          context, _R.signIn, (_) => false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: 'Delete Account',
        titleColor: _C.coral,
        message:
            'This is irreversible. All your CampusBuddy data will be '
            'permanently deleted.',
        confirmLabel: 'Delete',
        confirmColor: _C.coral,
      ),
    );
    if (ok == true && mounted) {
      // TODO: call delete API, then sign out
      Navigator.pushNamedAndRemoveUntil(
          context, _R.signIn, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.offWhite,
        extendBody: true,
        body: CustomScrollView(
          slivers: [

            // 1. Header
            SliverToBoxAdapter(child: _Header()),

            // 2. Name block
            const SliverToBoxAdapter(child: _NameBlock()),

            // 3. Account Settings
            const SliverToBoxAdapter(
                child: _SecLabel('⚙️ Account Settings')),
            SliverToBoxAdapter(
              child: _SettingsCard(
                rows: [
                  _SRow('👤', 'Personal Information', _C.brandPale,
                      route: _R.personalInfo),
                  _SRow('🔑', 'Change Password', _C.brandPale,
                      route: _R.changePassword),
                  _SRow('🔒', 'Privacy & Security', _C.violetPale,
                      route: _R.privacy),
                  _SRow('🔔', 'Notifications', _C.greenPale,
                      isToggle: true),
                  _SRow('🌙', 'Dark Mode', _C.amberPale,
                      isToggle: true),
                  _SRow('🌍', 'Language', _C.terraPale,
                      value: 'English', route: _R.language),
                ],
                notificationsOn: _notificationsOn,
                darkModeOn: _darkModeOn,
                onToggle: (index, val) => setState(() {
                  if (index == 3) _notificationsOn = val;
                  if (index == 4) _darkModeOn = val;
                }),
              ),
            ),

            // 4. Support
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            const SliverToBoxAdapter(child: _SecLabel('🛟 Support')),
            SliverToBoxAdapter(
              child: _SettingsCard(
                rows: [
                  _SRow('❓', 'Help & Support',        _C.brandPale,
                      route: _R.support),
                  _SRow('💬', 'Send Feedback',         _C.greenPale,
                      route: _R.feedback),
                  _SRow('📄', 'Terms & Privacy Policy', _C.violetPale,
                      route: _R.terms),
                  _SRow('ℹ️', 'App Version',           _C.brandPale,
                      value: 'v1.0.0'),
                ],
                notificationsOn: _notificationsOn,
                darkModeOn: _darkModeOn,
                onToggle: (_, __) {},
              ),
            ),

            // 5. Danger zone
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            const SliverToBoxAdapter(
                child: _SecLabel('⚠️ Account',
                    labelColor: _C.coral)),
            SliverToBoxAdapter(
              child: _DangerCard(
                onSignOut: _confirmSignOut,
                onDelete:  _confirmDelete,
              ),
            ),

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
//  1. HEADER
// ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [

        // Gradient + topo
        Container(
          height: 210,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8096F0), _C.brand, _C.brandD],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: CustomPaint(
            painter: _TopoPainter(),
            child: const SizedBox.expand(),
          ),
        ),

        // Wave cutout
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: CustomPaint(
            size: const Size(double.infinity, 52),
            painter: _WavePainter(),
          ),
        ),

        // Back + Edit buttons
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
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.28)),
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 15),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _go(context, _R.editProfile),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.28)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.edit_rounded,
                              color: Colors.white, size: 13),
                          SizedBox(width: 5),
                          Text('Edit Profile',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Avatar overlapping wave
        Positioned(
          bottom: -46, left: 0, right: 0,
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 92, height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.offWhite, width: 4),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_C.brandPale, _C.brand],
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: _C.brand.withOpacity(0.30),
                          blurRadius: 24,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Center(
                    child: Text('👩🏾',
                        style: TextStyle(fontSize: 44)),
                  ),
                ),
                Positioned(
                  bottom: 2, right: 2,
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _C.green,
                      border: Border.all(color: _C.offWhite, width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.check_rounded,
                          color: Colors.white, size: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  2. NAME BLOCK
// ─────────────────────────────────────────────────────────────
class _NameBlock extends StatelessWidget {
  const _NameBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: const BoxDecoration(
        color: _C.surf,
        border: Border(bottom: BorderSide(color: _C.border)),
      ),
      child: Column(
        children: [

          // Name + verified badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Sarah Kamau',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _C.text,
                      letterSpacing: -0.3)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _C.brandPale,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded,
                        color: _C.brand, size: 11),
                    SizedBox(width: 3),
                    Text('Verified',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _C.brand)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // University line
          const Text(
            '🎓 BSc Computer Science · Year 3 · University of Nairobi',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _C.text3),
          ),

          const SizedBox(height: 4),

          // Email
          const Text(
            'sarah.kamau@students.uon.ac.ke',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555577)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────────────────────
class _SecLabel extends StatelessWidget {
  final String label;
  final Color  labelColor;
  const _SecLabel(this.label, {this.labelColor = _C.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
    child: Text(label,
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: labelColor)),
  );
}

// ─────────────────────────────────────────────────────────────
//  SETTING ROW MODEL
// ─────────────────────────────────────────────────────────────
class _SRow {
  final String  emoji, label;
  final Color   iconBg;
  final String? value, route;
  final bool    isToggle;
  const _SRow(this.emoji, this.label, this.iconBg,
      {this.value, this.route, this.isToggle = false});
}

// ─────────────────────────────────────────────────────────────
//  3 & 4. SETTINGS CARD  (shared for both groups)
// ─────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<_SRow>          rows;
  final bool                 notificationsOn, darkModeOn;
  final void Function(int, bool) onToggle;

  const _SettingsCard({
    required this.rows,
    required this.notificationsOn,
    required this.darkModeOn,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _C.surf,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
              color: _C.brand.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final r    = rows[i];
          final last = i == rows.length - 1;

          // resolve which toggle this row controls
          bool isOn = false;
          if (r.isToggle && r.emoji == '🔔') isOn = notificationsOn;
          if (r.isToggle && r.emoji == '🌙') isOn = darkModeOn;

          return GestureDetector(
            onTap: r.isToggle
                ? () => onToggle(i, !isOn)
                : (r.route != null
                    ? () => _go(context, r.route!)
                    : null),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                border: last
                    ? null
                    : const Border(
                        bottom: BorderSide(color: _C.border)),
                borderRadius: last
                    ? const BorderRadius.vertical(
                        bottom: Radius.circular(18))
                    : (i == 0
                        ? const BorderRadius.vertical(
                            top: Radius.circular(18))
                        : null),
              ),
              child: Row(
                children: [

                  // Icon bubble
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: r.iconBg,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Center(
                      child: Text(r.emoji,
                          style: const TextStyle(fontSize: 16)),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Label
                  Expanded(
                    child: Text(r.label,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _C.text)),
                  ),

                  // Value (e.g. "English", "v1.0.0")
                  if (r.value != null) ...[
                    Text(r.value!,
                        style: const TextStyle(
                            fontSize: 12, color: _C.text3)),
                    const SizedBox(width: 4),
                  ],

                  // Toggle OR chevron
                  if (r.isToggle)
                    _Toggle(
                      on: isOn,
                      onChanged: (v) => onToggle(i, v),
                    )
                  else if (r.route != null)
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: _C.text3),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Animated toggle
class _Toggle extends StatelessWidget {
  final bool on;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.on, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!on),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38, height: 22,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: on ? _C.brand : _C.border,
          borderRadius: BorderRadius.circular(11),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment:
              on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16, height: 16,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  5. DANGER CARD
// ─────────────────────────────────────────────────────────────
class _DangerCard extends StatelessWidget {
  final VoidCallback onSignOut, onDelete;
  const _DangerCard({required this.onSignOut, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _C.surf,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFFFFE4E4), width: 1.5),
      ),
      child: Column(
        children: [

          // Sign Out
          GestureDetector(
            onTap: onSignOut,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 13),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Color(0xFFFFE4E4))),
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Center(
                      child: Text('🚪',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Sign Out',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _C.text)),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: _C.text3),
                ],
              ),
            ),
          ),

          // Delete Account
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 13),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Center(
                      child: Text('🗑',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Delete Account',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _C.coral)),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: _C.coral),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CONFIRM DIALOG  (reusable for sign out + delete)
// ─────────────────────────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  final String title, message, confirmLabel;
  final Color  confirmColor;
  final Color  titleColor;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    this.titleColor = _C.text,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: titleColor)),
      content: Text(message,
          style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF555577),
              height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel',
              style: TextStyle(
                  color: _C.text3, fontWeight: FontWeight.w700)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel,
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  6. BOTTOM NAV
// ─────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.selected, required this.onTap});

  static const _items = [
    (emoji: '🏠', label: 'Home',    c: _C.brand),
    (emoji: '📚', label: 'Study',   c: _C.brand),
    (emoji: '🛒', label: 'Market',  c: _C.terra),
    (emoji: '🏘', label: 'Housing', c: _C.green),
    (emoji: '🎉', label: 'Events',  c: _C.violet),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _C.border)),
        boxShadow: [
          BoxShadow(
              color: Color(0x10667EEA),
              blurRadius: 20,
              offset: Offset(0, -4)),
        ],
      ),
      padding: EdgeInsets.only(
          top: 10,
          bottom: MediaQuery.of(context).padding.bottom + 10,
          left: 4,
          right: 4),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(it.emoji,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 3),
                  Text(it.label,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: active ? it.c : _C.text3)),
                ],
              ),
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
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s.width * 0.16, s.height * 0.25),
          width: r.$1 * 2, height: r.$2 * 2,
        ),
        p,
      );
    }
    for (final r in [(85.0, 46.0), (58.0, 31.0), (33.0, 17.0)]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s.width * 0.848, s.height * 0.657),
          width: r.$1 * 2, height: r.$2 * 2,
        ),
        p,
      );
    }

    final thin = Paint()
      ..color = Colors.white.withOpacity(0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    void curve(List<double> v) => canvas.drawPath(
      Path()
        ..moveTo(v[0], v[1])
        ..cubicTo(v[2], v[3], v[4], v[5], v[6], v[7]),
      thin,
    );

    curve([0, s.height * .15, s.width * .21, s.height * .04,
           s.width * .48, s.height * .20, s.width, s.height * .16]);
    curve([0, s.height * .40, s.width * .19, s.height * .27,
           s.width * .46, s.height * .42, s.width, s.height * .38]);
    curve([0, s.height * .66, s.width * .24, s.height * .56,
           s.width * .50, s.height * .68, s.width, s.height * .64]);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _WavePainter extends CustomPainter {
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
      Paint()..color = _C.offWhite,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}