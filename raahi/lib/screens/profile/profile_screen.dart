// ============================================================
// lib/screens/profile/profile_screen.dart  — Production v3
// Car Health Dashboard + Profile + Helper Mode
// ============================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../services/helper_prefs_service.dart';
import '../../widgets/ui_components.dart';
import '../safety/emergency_contacts_screen.dart';
import '../safety/aadhaar_verify_screen.dart';
import '../safety/selfie_verify_screen.dart';
import '../admin/selfie_review_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _helperMode = false;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    HelperPrefsService().isHelperMode().then((v) {
      if (mounted) setState(() => _helperMode = v);
    });
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildSliverHeader()],
        body: Column(children: [
          _buildTabBar(),
          Expanded(child: TabBarView(
            controller: _tabCtrl,
            physics: const BouncingScrollPhysics(),
            children: [_buildCarHealthTab(), _buildProfileTab()],
          )),
        ]),
      ),
    );
  }

  // ── Sliver AppBar / Profile Hero ───────────────────────────
  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 200,
      backgroundColor: AppTheme.navyLight,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A2840), AppTheme.bg],
              begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Row(children: [
                    // Avatar
                    Container(
                      width: 68, height: 68,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.primaryGradient),
                      child: const Center(child: Text('R',
                        style: TextStyle(color: Colors.white, fontSize: 28,
                          fontWeight: FontWeight.w800, fontFamily: 'Rajdhani'))),
                    ),
                    const SizedBox(width: 16),

                    // Info
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ramesh Kumar',
                          style: TextStyle(
                            fontFamily: 'Rajdhani', color: AppTheme.textPrimary,
                            fontSize: 22, fontWeight: FontWeight.w700)),
                        const Text('+91 98765 43210',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        const SizedBox(height: 6),
                        Row(children: [
                          const StatusBadge(label: 'Verified', color: AppTheme.green,
                            icon: Icons.verified_rounded),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.yellow.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.star_rounded, color: AppTheme.yellow, size: 12),
                              SizedBox(width: 3),
                              Text('4.8', style: TextStyle(color: AppTheme.yellow,
                                fontSize: 11, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ]),
                      ],
                    )),
                    Pressable(
                      onTap: () {},
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: const Icon(Icons.edit_rounded,
                          color: AppTheme.textMuted, size: 16)),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // Stats
                  Row(children: [
                    _HeroStat(label: 'Total Helps', value: '12', color: AppTheme.green),
                    _HeroStatDivider(),
                    _HeroStat(label: 'Earned', value: '₹480', color: AppTheme.cyan),
                    _HeroStatDivider(),
                    _HeroStat(label: 'Rating', value: '4.8 ⭐', color: AppTheme.yellow),
                    _HeroStatDivider(),
                    _HeroStat(label: 'Trips', value: '47', color: AppTheme.primary),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: AppTheme.navyLight,
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 2.5,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: const TextStyle(
          fontFamily: 'Rajdhani', fontSize: 14,
          fontWeight: FontWeight.w700, letterSpacing: 0.5),
        tabs: const [
          Tab(text: 'CAR HEALTH'),
          Tab(text: 'PROFILE'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 1: CAR HEALTH DASHBOARD
  // ══════════════════════════════════════════════════════════
  Widget _buildCarHealthTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        // Car model card
        _buildCarModelCard(),
        const SizedBox(height: 16),
        // Health score
        _buildHealthScore(),
        const SizedBox(height: 24),
        // Quick diagnostics
        const SectionLabel('QUICK DIAGNOSTICS'),
        _buildDiagnosticsGrid(),
        const SizedBox(height: 24),
        // Maintenance reminders
        const SectionLabel('UPCOMING MAINTENANCE'),
        _buildMaintenanceList(),
        const SizedBox(height: 24),
        // Mileage tracker
        const SectionLabel('MILEAGE'),
        _buildMileageCard(),
      ],
    );
  }

  Widget _buildCarModelCard() {
    return AppCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF1A2840), AppTheme.cardBg],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderColor: AppTheme.primary.withOpacity(0.2),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('MY CAR',
            style: TextStyle(fontFamily: 'Rajdhani', fontSize: 11,
              color: AppTheme.textMuted, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          const Text('Maruti Swift Dzire',
            style: TextStyle(fontFamily: 'Rajdhani', fontSize: 22,
              fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Row(children: [
            const Text('DL 01 AB 1234',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.cyan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text('Petrol',
                style: TextStyle(color: AppTheme.cyan, fontSize: 10,
                  fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 12),
          InfoRow(icon: Icons.calendar_today_rounded,
            label: 'Year', value: '2021'),
          const Divider(color: AppTheme.cardBorder, height: 16),
          InfoRow(icon: Icons.speed_rounded,
            label: 'Odometer', value: '48,320 km'),
        ])),
        const SizedBox(width: 16),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.directions_car_rounded,
            color: AppTheme.primary, size: 40)),
      ]),
    );
  }

  Widget _buildHealthScore() {
    return AppCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF0A2010), AppTheme.cardBg],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderColor: AppTheme.green.withOpacity(0.25),
      child: Row(children: [
        // Score ring
        SizedBox(
          width: 72, height: 72,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: 0.82,
              backgroundColor: AppTheme.cardBorder,
              valueColor: const AlwaysStoppedAnimation(AppTheme.green),
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
            ),
            const Text('82',
              style: TextStyle(
                fontFamily: 'Rajdhani', color: AppTheme.green,
                fontSize: 22, fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Car Health Score',
            style: TextStyle(fontFamily: 'Rajdhani', fontSize: 17,
              fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          const StatusBadge(label: 'Good Condition', color: AppTheme.green, pulse: true),
          const SizedBox(height: 6),
          const Text('Next service in 1,680 km',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ])),
      ]),
    );
  }

  Widget _buildDiagnosticsGrid() {
    final diags = [
      _Diag('Engine', AppTheme.green, Icons.settings_rounded, 'Normal'),
      _Diag('Battery', AppTheme.yellow, Icons.battery_charging_full_rounded, '11.8V'),
      _Diag('Tyres', AppTheme.green, Icons.tire_repair_rounded, 'Good'),
      _Diag('Brakes', AppTheme.cyan, Icons.stop_circle_rounded, 'Normal'),
      _Diag('Fuel', AppTheme.primary, Icons.local_gas_station_rounded, '3/4 Full'),
      _Diag('Coolant', AppTheme.red, Icons.thermostat_rounded, 'Check'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10,
        childAspectRatio: 0.95),
      itemCount: diags.length,
      itemBuilder: (_, i) => _DiagCard(diag: diags[i]),
    );
  }

  Widget _buildMaintenanceList() {
    final items = [
      _Maint('Oil Change', '1,680 km away', AppTheme.yellow, Icons.oil_barrel_rounded, false),
      _Maint('Air Filter', '3,200 km away', AppTheme.cyan, Icons.air_rounded, false),
      _Maint('Tyre Rotation', '5,680 km away', AppTheme.green, Icons.tire_repair_rounded, false),
      _Maint('Coolant Flush', 'Overdue!', AppTheme.red, Icons.thermostat_rounded, true),
    ];
    return Column(
      children: items.map((m) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          padding: const EdgeInsets.all(14),
          borderColor: m.overdue ? AppTheme.red.withOpacity(0.3) : AppTheme.cardBorder,
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: m.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppTheme.r12),
              ),
              child: Icon(m.icon, color: m.color, size: 20)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.service,
                style: const TextStyle(color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 3),
              Text(m.dueIn,
                style: TextStyle(
                  color: m.overdue ? AppTheme.red : AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: m.overdue ? FontWeight.w700 : FontWeight.w400)),
            ])),
            if (m.overdue)
              const StatusBadge(label: 'URGENT', color: AppTheme.red),
          ]),
        ),
      )).toList(),
    );
  }

  Widget _buildMileageCard() {
    return AppCard(
      child: Column(children: [
        Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Monthly Average',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11, letterSpacing: 0.5)),
            SizedBox(height: 4),
            Text('1,840 km',
              style: TextStyle(fontFamily: 'Rajdhani', color: AppTheme.textPrimary,
                fontSize: 24, fontWeight: FontWeight.w700)),
          ])),
          const StatusBadge(label: 'Above avg', color: AppTheme.primary),
        ]),
        const SizedBox(height: 16),
        // Simple bar chart
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: ['Jan','Feb','Mar','Apr','May','Jun'].asMap().entries.map((e) {
            final heights = [1400.0, 1620.0, 1350.0, 1900.0, 1750.0, 1840.0];
            final maxH = heights.reduce((a, b) => a > b ? a : b);
            final h = (heights[e.key] / maxH) * 60;
            final isLast = e.key == 5;
            return Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 400 + e.key * 80),
                  height: h, width: double.infinity,
                  decoration: BoxDecoration(
                    color: isLast ? AppTheme.primary : AppTheme.surfaceHigh,
                    borderRadius: BorderRadius.circular(4),
                    border: isLast ? null
                        : Border.all(color: AppTheme.cardBorder),
                  ),
                ),
                const SizedBox(height: 4),
                Text(e.value,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
              ]),
            ));
          }).toList(),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 2: PROFILE
  // ══════════════════════════════════════════════════════════
  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        // Helper Mode toggle
        _buildHelperModeCard(),
        const SizedBox(height: 24),

        // Menu sections
        _buildMenuSection('ACCOUNT', [
          _MenuEntry(Icons.person_outline_rounded, 'Edit Profile', AppTheme.cyan, () {}),
          _MenuEntry(Icons.directions_car_rounded, 'Change Car', AppTheme.primary, () {}),
          _MenuEntry(Icons.language_rounded, 'Language', AppTheme.purple, () {}),
        ]),
        const SizedBox(height: 16),

        _buildMenuSection('SAFETY & SECURITY', [
          _MenuEntry(Icons.contacts_rounded, 'Emergency Contacts', AppTheme.red,
            () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const EmergencyContactsScreen()))),
          _MenuEntry(Icons.face_rounded, 'Selfie Verify (FREE)', AppTheme.cyan,
            () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const SelfieVerifyScreen()))),
          _MenuEntry(Icons.verified_user_rounded, 'Aadhaar Verify', AppTheme.green,
            () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const AadhaarVerifyScreen()))),
          _MenuEntry(Icons.admin_panel_settings_rounded, 'Admin — Selfie Review', AppTheme.purple,
            () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const SelfieReviewScreen()))),
        ]),
        const SizedBox(height: 16),

        _buildMenuSection('MECHANIC', [
          _MenuEntry(Icons.store_rounded, 'Register as Mechanic', AppTheme.cyan,
            () => context.push('/mechanic-register')),
          _MenuEntry(Icons.workspace_premium_rounded, 'Pro Subscription', AppTheme.yellow,
            () => context.push('/subscription')),
        ]),
        const SizedBox(height: 16),

        _buildMenuSection('SUPPORT', [
          _MenuEntry(Icons.help_outline_rounded, 'Help & FAQ', AppTheme.textSecondary, () {}),
          _MenuEntry(Icons.privacy_tip_outlined, 'Privacy Policy', AppTheme.textSecondary, () {}),
          _MenuEntry(Icons.description_outlined, 'Terms of Service', AppTheme.textSecondary, () {}),
        ]),
        const SizedBox(height: 16),

        // Logout
        Pressable(
          onTap: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('auth_token');
            if (context.mounted) context.go('/login');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.red.withOpacity(0.06),
              borderRadius: BorderRadius.circular(AppTheme.r14),
              border: Border.all(color: AppTheme.red.withOpacity(0.2)),
            ),
            child: const Row(children: [
              Icon(Icons.logout_rounded, color: AppTheme.red, size: 20),
              SizedBox(width: 12),
              Text('Logout',
                style: TextStyle(color: AppTheme.red,
                  fontWeight: FontWeight.w700, fontSize: 14)),
              Spacer(),
              Icon(Icons.chevron_right_rounded, color: AppTheme.red, size: 18),
            ]),
          ),
        ),
        const SizedBox(height: 24),

        const Center(child: Text('Raahi v1.0.0 · Built with ❤️ in India',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 11))),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHelperModeCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _helperMode ? AppTheme.green.withOpacity(0.07) : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.r14),
        border: Border.all(
          color: _helperMode
              ? AppTheme.green.withOpacity(0.35) : AppTheme.cardBorder,
          width: _helperMode ? 1.5 : 1),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (_helperMode ? AppTheme.green : AppTheme.textMuted).withOpacity(0.14),
            borderRadius: BorderRadius.circular(AppTheme.r12),
          ),
          child: Icon(Icons.handshake_rounded,
            color: _helperMode ? AppTheme.green : AppTheme.textMuted, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Helper Mode',
            style: TextStyle(color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 3),
          Text(
            _helperMode
                ? 'Active — you\'ll receive nearby requests'
                : 'Off — enable to earn money helping others',
            style: TextStyle(
              color: _helperMode ? AppTheme.green : AppTheme.textMuted,
              fontSize: 12)),
        ])),
        Switch(
          value: _helperMode,
          activeColor: AppTheme.green,
          onChanged: (v) async {
            await HelperPrefsService().setHelperMode(v);
            setState(() => _helperMode = v);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(v ? '✅ Helper mode on!' : 'Helper mode off'),
              backgroundColor: v ? AppTheme.green : AppTheme.surfaceHigh,
              duration: const Duration(seconds: 2),
            ));
          },
        ),
      ]),
    );
  }

  Widget _buildMenuSection(String title, List<_MenuEntry> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionLabel(title),
      Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.r14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Column(children: [
            Pressable(
              onTap: item.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: item.color, size: 18)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item.label,
                    style: const TextStyle(color: AppTheme.textPrimary,
                      fontSize: 14, fontWeight: FontWeight.w500))),
                  const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textMuted, size: 18),
                ]),
              ),
            ),
            if (!isLast)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Divider(color: AppTheme.cardBorder, height: 1)),
          ]);
        }).toList()),
      ),
    ]);
  }
}

// ── Local sub-widgets ──────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _HeroStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(value, style: TextStyle(
      fontFamily: 'Rajdhani', color: color,
      fontSize: 17, fontWeight: FontWeight.w800)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
      textAlign: TextAlign.center),
  ]));
}

class _HeroStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
    Container(width: 1, height: 28, color: AppTheme.cardBorder,
      margin: const EdgeInsets.symmetric(horizontal: 4));
}

class _Diag {
  final String name, value;
  final Color color;
  final IconData icon;
  const _Diag(this.name, this.color, this.icon, this.value);
}

class _DiagCard extends StatelessWidget {
  final _Diag diag;
  const _DiagCard({super.key, required this.diag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.r14),
        border: Border.all(color: diag.color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: diag.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(diag.icon, color: diag.color, size: 20)),
          const SizedBox(height: 8),
          Text(diag.name,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          const SizedBox(height: 3),
          Text(diag.value,
            style: TextStyle(color: diag.color,
              fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Maint {
  final String service, dueIn;
  final Color color;
  final IconData icon;
  final bool overdue;
  const _Maint(this.service, this.dueIn, this.color, this.icon, this.overdue);
}

class _MenuEntry {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MenuEntry(this.icon, this.label, this.color, this.onTap);
}
