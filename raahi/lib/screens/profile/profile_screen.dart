// ============================================================
// lib/screens/profile/profile_screen.dart
// Real data — loaded from SharedPreferences, no dummy values
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../services/helper_prefs_service.dart';
import '../../widgets/ui_components.dart';
import '../safety/emergency_contacts_screen.dart';
import '../safety/aadhaar_verify_screen.dart';
import '../safety/selfie_verify_screen.dart';
import '../admin/selfie_review_screen.dart';

// ── SharedPrefs keys ─────────────────────────────────────────
const _kName            = 'user_name';
const _kPhone           = 'user_phone';
const _kCarModel        = 'car_model';
const _kCarReg          = 'car_reg';
const _kCarFuel         = 'car_fuel';
const _kCarYear         = 'car_year';
const _kCarOdo          = 'car_odometer';
const _kCarLastService  = 'car_last_service_km';
const _kDiagEngine      = 'diag_engine';
const _kDiagBattery     = 'diag_battery';
const _kDiagTyres       = 'diag_tyres';
const _kDiagBrakes      = 'diag_brakes';
const _kDiagFuel        = 'diag_fuel_level';
const _kDiagCoolant     = 'diag_coolant';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {

  // User
  String _name  = '';
  String _phone = '';

  // Car
  String? _carModel;
  String? _carReg;
  String  _carFuel = 'Petrol';
  String  _carYear = '';
  String  _carOdo  = '';
  String  _carLastService = '';

  // Diagnostics
  String? _diagEngine;
  String? _diagBattery;
  String? _diagTyres;
  String? _diagBrakes;
  String? _diagFuel;
  String? _diagCoolant;

  bool _helperMode = false;
  bool _loading    = true;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _loadAll() async {
    final p = await SharedPreferences.getInstance();
    final hm = await HelperPrefsService().isHelperMode();
    if (!mounted) return;
    setState(() {
      _name          = p.getString(_kName)  ?? '';
      _phone         = p.getString(_kPhone) ?? '';
      _carModel      = p.getString(_kCarModel);
      _carReg        = p.getString(_kCarReg);
      _carFuel       = p.getString(_kCarFuel) ?? 'Petrol';
      _carYear       = p.getString(_kCarYear) ?? '';
      _carOdo        = p.getString(_kCarOdo)  ?? '';
      _carLastService= p.getString(_kCarLastService) ?? '';
      _diagEngine    = p.getString(_kDiagEngine);
      _diagBattery   = p.getString(_kDiagBattery);
      _diagTyres     = p.getString(_kDiagTyres);
      _diagBrakes    = p.getString(_kDiagBrakes);
      _diagFuel      = p.getString(_kDiagFuel);
      _diagCoolant   = p.getString(_kDiagCoolant);
      _helperMode    = hm;
      _loading       = false;
    });
  }

  Future<void> _save(Map<String, String?> kvs) async {
    final p = await SharedPreferences.getInstance();
    for (final e in kvs.entries) {
      if (e.value != null && e.value!.isNotEmpty) {
        await p.setString(e.key, e.value!);
      }
    }
  }

  // ── Health score from diagnostics ──────────────────────────
  int? get _healthScore {
    if (_carModel == null) return null;
    int score = 100;
    score -= _penalty(_diagEngine,  {'Warning': 10, 'Check Engine': 25});
    score -= _penalty(_diagBattery, {'Low': 10, 'Dead': 20});
    score -= _penalty(_diagTyres,   {'Low Pressure': 5, 'Replace': 15});
    score -= _penalty(_diagBrakes,  {'Worn': 8, 'Check': 15});
    score -= _penalty(_diagCoolant, {'Low': 8, 'Check': 12});
    return score.clamp(0, 100);
  }

  int _penalty(String? val, Map<String, int> map) {
    if (val == null) return 0;
    return map[val] ?? 0;
  }

  Color _scoreColor(int s) {
    if (s >= 80) return AppTheme.green;
    if (s >= 60) return AppTheme.yellow;
    return AppTheme.red;
  }

  String _scoreLabel(int s) {
    if (s >= 80) return 'Good Condition';
    if (s >= 60) return 'Needs Attention';
    return 'Poor Condition';
  }

  // ── Maintenance reminders from odometer ───────────────────
  List<_Maint> get _maintenanceItems {
    final odo = int.tryParse(_carOdo.replaceAll(',', '').replaceAll(' km', '')) ?? 0;
    final lastSvc = int.tryParse(_carLastService.replaceAll(',', '').replaceAll(' km', '')) ?? 0;
    if (odo == 0) return [];
    final base = lastSvc > 0 ? lastSvc : (odo ~/ 5000) * 5000;
    List<_Maint> items = [];

    void add(String name, int interval, Color c, IconData icon) {
      final nextAt = ((base ~/ interval) + 1) * interval;
      final kmLeft = nextAt - odo;
      if (kmLeft <= 0) {
        items.add(_Maint(name, 'Overdue!', c, icon, true));
      } else {
        items.add(_Maint(name, '${_fmt(kmLeft)} km away', c, icon, false));
      }
    }

    add('Oil Change',     5000,  AppTheme.yellow, Icons.oil_barrel_rounded);
    add('Air Filter',     10000, AppTheme.cyan,   Icons.air_rounded);
    add('Tyre Rotation',  8000,  AppTheme.green,  Icons.tire_repair_rounded);
    add('Coolant Flush',  40000, AppTheme.red,    Icons.thermostat_rounded);
    return items;
  }

  String _fmt(int n) {
    final s = n.toString();
    if (s.length > 3) return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
    return s;
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
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

  // ── Sliver Header ─────────────────────────────────────────
  Widget _buildSliverHeader() {
    final initials = _name.isNotEmpty ? _name[0].toUpperCase() : '?';
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
          child: SafeArea(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  width: 68, height: 68,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle, gradient: AppTheme.primaryGradient),
                  child: Center(child: Text(initials,
                    style: const TextStyle(color: Colors.white, fontSize: 28,
                      fontWeight: FontWeight.w800, fontFamily: 'Rajdhani'))),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    _name.isNotEmpty ? _name : 'Apna naam daalo',
                    style: TextStyle(
                      fontFamily: 'Rajdhani', color: AppTheme.textPrimary,
                      fontSize: 22, fontWeight: FontWeight.w700,
                      fontStyle: _name.isEmpty ? FontStyle.italic : FontStyle.normal),
                  ),
                  Text(
                    _phone.isNotEmpty ? _phone : 'Phone number set nahi',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  const Row(children: [
                    StatusBadge(label: 'Verified', color: AppTheme.green,
                      icon: Icons.verified_rounded),
                  ]),
                ])),
                Pressable(
                  onTap: _showEditProfileSheet,
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
              Row(children: [
                _HeroStat(label: 'Total Helps', value: '0',   color: AppTheme.green),
                _HeroStatDivider(),
                _HeroStat(label: 'Earned',      value: '₹0',  color: AppTheme.cyan),
                _HeroStatDivider(),
                _HeroStat(label: 'Rating',       value: '—',   color: AppTheme.yellow),
                _HeroStatDivider(),
                _HeroStat(label: 'Trips',        value: '0',   color: AppTheme.primary),
              ]),
            ]),
          )),
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
        tabs: const [Tab(text: 'CAR HEALTH'), Tab(text: 'PROFILE')],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 1: CAR HEALTH
  // ══════════════════════════════════════════════════════════
  Widget _buildCarHealthTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _carModel == null ? _buildAddCarPrompt() : _buildCarModelCard(),
        const SizedBox(height: 16),
        if (_carModel != null) ...[
          _buildHealthScore(),
          const SizedBox(height: 24),
          Row(children: [
            const Expanded(child: SectionLabel('QUICK DIAGNOSTICS')),
            Pressable(
              onTap: _showDiagnosticsSheet,
              child: const Text('Update',
                style: TextStyle(color: AppTheme.primary,
                  fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ]),
          _buildDiagnosticsGrid(),
          const SizedBox(height: 24),
          if (_maintenanceItems.isNotEmpty) ...[
            const SectionLabel('UPCOMING MAINTENANCE'),
            _buildMaintenanceList(),
            const SizedBox(height: 24),
          ] else if (_carOdo.isEmpty) ...[
            _buildOdometerPrompt(),
            const SizedBox(height: 24),
          ],
        ],
      ],
    );
  }

  Widget _buildAddCarPrompt() {
    return Pressable(
      onTap: _showCarSetupSheet,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary.withOpacity(0.12), AppTheme.cardBg],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(AppTheme.r14),
          border: Border.all(color: AppTheme.primary.withOpacity(0.35),
            style: BorderStyle.solid),
        ),
        child: Column(children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.directions_car_rounded,
              color: AppTheme.primary, size: 34)),
          const SizedBox(height: 16),
          const Text('Apni Gaadi Add Karo',
            style: TextStyle(fontFamily: 'Rajdhani', fontSize: 20,
              fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text(
            'Car model, registration, fuel type aur\nodometer — yahan save karo',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12)),
            child: const Text('+ Gaadi Add Karo',
              style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ]),
      ),
    );
  }

  Widget _buildOdometerPrompt() {
    return Pressable(
      onTap: _showCarSetupSheet,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.r14),
          border: Border.all(color: AppTheme.yellow.withOpacity(0.3)),
        ),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.yellow, size: 20),
          SizedBox(width: 12),
          Expanded(child: Text(
            'Odometer reading daalo to maintenance reminders milenge',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
          Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 18),
        ]),
      ),
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
          Text(_carModel ?? '—',
            style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 22,
              fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Row(children: [
            Text(_carReg ?? '—',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            if (_carFuel.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.cyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(5)),
                child: Text(_carFuel,
                  style: const TextStyle(color: AppTheme.cyan,
                    fontSize: 10, fontWeight: FontWeight.w700))),
            ],
          ]),
          if (_carYear.isNotEmpty || _carOdo.isNotEmpty) ...[
            const SizedBox(height: 12),
            if (_carYear.isNotEmpty)
              InfoRow(icon: Icons.calendar_today_rounded,
                label: 'Year', value: _carYear),
            if (_carYear.isNotEmpty && _carOdo.isNotEmpty)
              const Divider(color: AppTheme.cardBorder, height: 16),
            if (_carOdo.isNotEmpty)
              InfoRow(icon: Icons.speed_rounded,
                label: 'Odometer', value: '${_carOdo} km'),
          ],
        ])),
        const SizedBox(width: 16),
        Pressable(
          onTap: _showCarSetupSheet,
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.directions_car_rounded,
              color: AppTheme.primary, size: 40)),
        ),
      ]),
    );
  }

  Widget _buildHealthScore() {
    final score = _healthScore;
    if (score == null) return const SizedBox.shrink();
    final c = _scoreColor(score);
    return AppCard(
      gradient: LinearGradient(
        colors: [c.withOpacity(0.06), AppTheme.cardBg],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderColor: c.withOpacity(0.25),
      child: Row(children: [
        SizedBox(
          width: 72, height: 72,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: score / 100,
              backgroundColor: AppTheme.cardBorder,
              valueColor: AlwaysStoppedAnimation(c),
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
            ),
            Text('$score',
              style: TextStyle(fontFamily: 'Rajdhani', color: c,
                fontSize: 22, fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Car Health Score',
            style: TextStyle(fontFamily: 'Rajdhani', fontSize: 17,
              fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          StatusBadge(label: _scoreLabel(score), color: c, pulse: score >= 80),
          if (_carOdo.isNotEmpty && _maintenanceItems.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _maintenanceItems.first.overdue
                  ? 'Service overdue!'
                  : 'Next service in ${_maintenanceItems.first.dueIn}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ],
        ])),
      ]),
    );
  }

  Widget _buildDiagnosticsGrid() {
    final diags = [
      _DiagInfo('Engine',  _diagEngine,  AppTheme.green,  Icons.settings_rounded,
        {'Normal': AppTheme.green, 'Warning': AppTheme.yellow, 'Check Engine': AppTheme.red}),
      _DiagInfo('Battery', _diagBattery, AppTheme.yellow, Icons.battery_charging_full_rounded,
        {'Good': AppTheme.green, 'Low': AppTheme.yellow, 'Dead': AppTheme.red}),
      _DiagInfo('Tyres',   _diagTyres,   AppTheme.green,  Icons.tire_repair_rounded,
        {'Good': AppTheme.green, 'Low Pressure': AppTheme.yellow, 'Replace': AppTheme.red}),
      _DiagInfo('Brakes',  _diagBrakes,  AppTheme.cyan,   Icons.stop_circle_rounded,
        {'Normal': AppTheme.green, 'Worn': AppTheme.yellow, 'Check': AppTheme.red}),
      _DiagInfo('Fuel',    _diagFuel,    AppTheme.primary, Icons.local_gas_station_rounded,
        {'Full': AppTheme.green, '3/4 Full': AppTheme.green, 'Half': AppTheme.yellow,
         'Low': const Color(0xFFFF6B00), 'Empty': AppTheme.red}),
      _DiagInfo('Coolant', _diagCoolant, AppTheme.red,    Icons.thermostat_rounded,
        {'OK': AppTheme.green, 'Low': AppTheme.yellow, 'Check': AppTheme.red}),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10,
        childAspectRatio: 0.95),
      itemCount: diags.length,
      itemBuilder: (_, i) => _DiagCard(
        info: diags[i],
        onTap: _showDiagnosticsSheet,
      ),
    );
  }

  Widget _buildMaintenanceList() {
    final items = _maintenanceItems;
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
                borderRadius: BorderRadius.circular(AppTheme.r12)),
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

  // ══════════════════════════════════════════════════════════
  // TAB 2: PROFILE
  // ══════════════════════════════════════════════════════════
  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildHelperModeCard(),
        const SizedBox(height: 24),

        _buildMenuSection('ACCOUNT', [
          _MenuEntry(Icons.person_outline_rounded, 'Edit Profile',   AppTheme.cyan,    _showEditProfileSheet),
          _MenuEntry(Icons.directions_car_rounded, 'My Car / Change', AppTheme.primary, _showCarSetupSheet),
          _MenuEntry(Icons.language_rounded,       'Language',        AppTheme.purple,  () {}),
        ]),
        const SizedBox(height: 16),

        _buildMenuSection('SAFETY & SECURITY', [
          _MenuEntry(Icons.contacts_rounded, 'Emergency Contacts', AppTheme.red,
            () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()))),
          _MenuEntry(Icons.face_rounded, 'Selfie Verify (FREE)', AppTheme.cyan,
            () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SelfieVerifyScreen()))),
          _MenuEntry(Icons.verified_user_rounded, 'Aadhaar Verify', AppTheme.green,
            () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AadhaarVerifyScreen()))),
          _MenuEntry(Icons.admin_panel_settings_rounded, 'Admin — Selfie Review', AppTheme.purple,
            () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SelfieReviewScreen()))),
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
          _MenuEntry(Icons.help_outline_rounded,     'Help & FAQ',       AppTheme.textSecondary, () {}),
          _MenuEntry(Icons.privacy_tip_outlined,     'Privacy Policy',   AppTheme.textSecondary, () {}),
          _MenuEntry(Icons.description_outlined,     'Terms of Service', AppTheme.textSecondary, () {}),
        ]),
        const SizedBox(height: 16),

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
              border: Border.all(color: AppTheme.red.withOpacity(0.2))),
            child: const Row(children: [
              Icon(Icons.logout_rounded, color: AppTheme.red, size: 20),
              SizedBox(width: 12),
              Text('Logout', style: TextStyle(color: AppTheme.red,
                fontWeight: FontWeight.w700, fontSize: 14)),
              Spacer(),
              Icon(Icons.chevron_right_rounded, color: AppTheme.red, size: 18),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        const Center(child: Text('Raahi v1.0.0 · Built with ❤️ in India',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 11))),
        const SizedBox(height: 24),
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
          color: _helperMode ? AppTheme.green.withOpacity(0.35) : AppTheme.cardBorder,
          width: _helperMode ? 1.5 : 1),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (_helperMode ? AppTheme.green : AppTheme.textMuted).withOpacity(0.14),
            borderRadius: BorderRadius.circular(AppTheme.r12)),
          child: Icon(Icons.handshake_rounded,
            color: _helperMode ? AppTheme.green : AppTheme.textMuted, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Helper Mode',
            style: TextStyle(color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 3),
          Text(
            _helperMode
              ? 'Active — aas-paas ke requests aa rahe hain'
              : 'Off — on karo aur doosron ki madad karke kamao',
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
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
          border: Border.all(color: AppTheme.cardBorder)),
        child: Column(children: items.asMap().entries.map((e) {
          final item   = e.value;
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
                      borderRadius: BorderRadius.circular(10)),
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
            if (!isLast) Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Divider(color: AppTheme.cardBorder, height: 1)),
          ]);
        }).toList()),
      ),
    ]);
  }

  // ══════════════════════════════════════════════════════════
  // BOTTOM SHEETS
  // ══════════════════════════════════════════════════════════

  // ── Edit Profile ──────────────────────────────────────────
  void _showEditProfileSheet() {
    final nameCtrl  = TextEditingController(text: _name);
    final phoneCtrl = TextEditingController(text: _phone);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20,
          20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _SheetHandle(),
          const Text('Edit Profile',
            style: TextStyle(fontFamily: 'Rajdhani', fontSize: 20,
              fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 20),
          _Field(ctrl: nameCtrl, label: 'Apna Naam', icon: Icons.person_rounded),
          const SizedBox(height: 14),
          _Field(ctrl: phoneCtrl, label: 'Phone Number',
            icon: Icons.phone_rounded, keyboard: TextInputType.phone),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await _save({
                  _kName:  nameCtrl.text.trim(),
                  _kPhone: phoneCtrl.text.trim(),
                });
                setState(() {
                  _name  = nameCtrl.text.trim();
                  _phone = phoneCtrl.text.trim();
                });
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Save Karo',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            )),
        ]),
      ),
    );
  }

  // ── Car Setup ─────────────────────────────────────────────
  void _showCarSetupSheet() {
    final modelCtrl = TextEditingController(text: _carModel ?? '');
    final regCtrl   = TextEditingController(text: _carReg   ?? '');
    final odoCtrl   = TextEditingController(text: _carOdo);
    final lastCtrl  = TextEditingController(text: _carLastService);
    String fuel     = _carFuel;
    String year     = _carYear.isNotEmpty ? _carYear : '${DateTime.now().year}';

    final fuels = ['Petrol', 'Diesel', 'CNG', 'Electric'];
    final years = List.generate(
      DateTime.now().year - 1999,
      (i) => '${DateTime.now().year - i}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20,
            20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _SheetHandle(),
            const Text('Gaadi Ki Jaankari',
              style: TextStyle(fontFamily: 'Rajdhani', fontSize: 20,
                fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            const Text('Apni car ke baare mein batao',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),

            _Field(ctrl: modelCtrl,
              label: 'Car ka naam (jaise Maruti Swift, Honda City)',
              icon: Icons.directions_car_rounded),
            const SizedBox(height: 14),
            _Field(ctrl: regCtrl,
              label: 'Registration Number (jaise DL 01 AB 1234)',
              icon: Icons.confirmation_number_rounded),
            const SizedBox(height: 14),

            // Fuel type chips
            Align(alignment: Alignment.centerLeft,
              child: Text('Fuel Type',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12,
                  fontWeight: FontWeight.w600))),
            const SizedBox(height: 8),
            Row(children: fuels.map((f) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setSt(() => fuel = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: fuel == f
                      ? AppTheme.primary.withOpacity(0.15) : AppTheme.surfaceHigh,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: fuel == f ? AppTheme.primary : AppTheme.cardBorder)),
                  child: Text(f,
                    style: TextStyle(
                      color: fuel == f ? AppTheme.primary : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            )).toList()),
            const SizedBox(height: 14),

            // Year dropdown
            Align(alignment: Alignment.centerLeft,
              child: Text('Manufacturing Year',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12,
                  fontWeight: FontWeight.w600))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorder)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: year,
                  isExpanded: true,
                  dropdownColor: AppTheme.cardBg,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  onChanged: (v) => setSt(() => year = v!),
                  items: years.map((y) => DropdownMenuItem(
                    value: y,
                    child: Text(y),
                  )).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _Field(ctrl: odoCtrl,
              label: 'Current Odometer (km mein)',
              icon: Icons.speed_rounded,
              keyboard: TextInputType.number),
            const SizedBox(height: 14),
            _Field(ctrl: lastCtrl,
              label: 'Last Service Reading (optional, km mein)',
              icon: Icons.build_circle_rounded,
              keyboard: TextInputType.number),
            const SizedBox(height: 24),

            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _save({
                    _kCarModel:       modelCtrl.text.trim(),
                    _kCarReg:         regCtrl.text.trim().toUpperCase(),
                    _kCarFuel:        fuel,
                    _kCarYear:        year,
                    _kCarOdo:         odoCtrl.text.trim(),
                    _kCarLastService: lastCtrl.text.trim(),
                  });
                  setState(() {
                    _carModel       = modelCtrl.text.trim().isNotEmpty
                      ? modelCtrl.text.trim() : _carModel;
                    _carReg         = regCtrl.text.trim().toUpperCase();
                    _carFuel        = fuel;
                    _carYear        = year;
                    _carOdo         = odoCtrl.text.trim();
                    _carLastService = lastCtrl.text.trim();
                  });
                  if (context.mounted) Navigator.pop(context);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('✅ Gaadi ki jaankari save ho gayi!'),
                    backgroundColor: AppTheme.green,
                    duration: Duration(seconds: 2),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Save Karo',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              )),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  // ── Diagnostics Sheet ─────────────────────────────────────
  void _showDiagnosticsSheet() {
    String? engine  = _diagEngine;
    String? battery = _diagBattery;
    String? tyres   = _diagTyres;
    String? brakes  = _diagBrakes;
    String? fuel    = _diagFuel;
    String? coolant = _diagCoolant;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20,
            20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _SheetHandle(),
            const Text('Car Health Update',
              style: TextStyle(fontFamily: 'Rajdhani', fontSize: 20,
                fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            const Text('Aaj ki gaadi ki condition batao',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),

            _DiagPicker('Engine', engine,
              ['Normal', 'Warning', 'Check Engine'],
              [AppTheme.green, AppTheme.yellow, AppTheme.red],
              (v) => setSt(() => engine = v)),
            _DiagPicker('Battery', battery,
              ['Good', 'Low', 'Dead'],
              [AppTheme.green, AppTheme.yellow, AppTheme.red],
              (v) => setSt(() => battery = v)),
            _DiagPicker('Tyres', tyres,
              ['Good', 'Low Pressure', 'Replace'],
              [AppTheme.green, AppTheme.yellow, AppTheme.red],
              (v) => setSt(() => tyres = v)),
            _DiagPicker('Brakes', brakes,
              ['Normal', 'Worn', 'Check'],
              [AppTheme.green, AppTheme.yellow, AppTheme.red],
              (v) => setSt(() => brakes = v)),
            _DiagPicker('Fuel Level', fuel,
              ['Full', '3/4 Full', 'Half', 'Low', 'Empty'],
              [AppTheme.green, AppTheme.green, AppTheme.yellow,
               AppTheme.primary, AppTheme.red],
              (v) => setSt(() => fuel = v)),
            _DiagPicker('Coolant', coolant,
              ['OK', 'Low', 'Check'],
              [AppTheme.green, AppTheme.yellow, AppTheme.red],
              (v) => setSt(() => coolant = v)),

            const SizedBox(height: 20),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _save({
                    _kDiagEngine:  engine,
                    _kDiagBattery: battery,
                    _kDiagTyres:   tyres,
                    _kDiagBrakes:  brakes,
                    _kDiagFuel:    fuel,
                    _kDiagCoolant: coolant,
                  });
                  setState(() {
                    _diagEngine  = engine;
                    _diagBattery = battery;
                    _diagTyres   = tyres;
                    _diagBrakes  = brakes;
                    _diagFuel    = fuel;
                    _diagCoolant = coolant;
                  });
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Save Karo',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              )),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// LOCAL WIDGETS
// ══════════════════════════════════════════════════════════

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40, height: 4,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(2))));
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType keyboard;
  const _Field({required this.ctrl, required this.label, required this.icon,
    this.keyboard = TextInputType.text});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    keyboardType: keyboard,
    style: const TextStyle(color: AppTheme.textPrimary),
    inputFormatters: keyboard == TextInputType.number
      ? [FilteringTextInputFormatter.digitsOnly] : null,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 18),
      filled: true,
      fillColor: AppTheme.surfaceHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.cardBorder)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.cardBorder)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
    ),
  );
}

// Diagnostic picker row
class _DiagPicker extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final List<Color> colors;
  final ValueChanged<String?> onChanged;
  const _DiagPicker(this.label, this.value, this.options, this.colors, this.onChanged);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(
        color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (int i = 0; i < options.length; i++)
          GestureDetector(
            onTap: () => onChanged(value == options[i] ? null : options[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: value == options[i]
                  ? colors[i].withOpacity(0.15) : AppTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: value == options[i] ? colors[i] : AppTheme.cardBorder,
                  width: value == options[i] ? 1.5 : 1)),
              child: Text(options[i],
                style: TextStyle(
                  color: value == options[i] ? colors[i] : AppTheme.textSecondary,
                  fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
      ]),
    ]),
  );
}

class _DiagInfo {
  final String name;
  final String? value;
  final Color defaultColor;
  final IconData icon;
  final Map<String, Color> colorMap;
  const _DiagInfo(this.name, this.value, this.defaultColor, this.icon, this.colorMap);

  Color get color => value != null ? (colorMap[value] ?? defaultColor) : AppTheme.textMuted;
  String get display => value ?? '—';
}

class _DiagCard extends StatelessWidget {
  final _DiagInfo info;
  final VoidCallback onTap;
  const _DiagCard({super.key, required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.r14),
          border: Border.all(color: info.color.withOpacity(0.2))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: info.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(info.icon, color: info.color, size: 20)),
          const SizedBox(height: 8),
          Text(info.name,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          const SizedBox(height: 3),
          Text(info.display,
            style: TextStyle(color: info.color,
              fontWeight: FontWeight.w700, fontSize: 12),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _HeroStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(value, style: TextStyle(fontFamily: 'Rajdhani', color: color,
      fontSize: 17, fontWeight: FontWeight.w800)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
      textAlign: TextAlign.center),
  ]));
}

class _HeroStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 28, color: AppTheme.cardBorder,
    margin: const EdgeInsets.symmetric(horizontal: 4));
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
