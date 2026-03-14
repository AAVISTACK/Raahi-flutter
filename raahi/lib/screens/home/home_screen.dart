// ============================================================
// lib/screens/home/home_screen.dart  — Production v4
// Refined layout: Car Status → AI CTA hero → Quick 2x2 grid
// Staggered slide-up+fade animations on load
// ============================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/language_service.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../widgets/ui_components.dart';
import '../community/community_feed_screen.dart';
import '../fuel/fuel_rates_screen.dart';
import '../alerts/highway_alerts_screen.dart';
import '../tips/daily_tips_screen.dart';
import '../places/nearby_places_screen.dart';
import '../streak/streak_screen.dart';
import '../../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isAvailable = false;
  final _lang = LanguageService();

  // Staggered animation controllers for each section
  late List<AnimationController> _cardCtrls;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  static const _cardCount = 4; // header, car status, AI card, quick grid

  @override
  void initState() {
    super.initState();
    _cardCtrls = List.generate(_cardCount, (i) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    ));
    _fadeAnims = _cardCtrls.map((c) =>
        CurvedAnimation(parent: c, curve: Curves.easeOut)).toList();
    _slideAnims = _cardCtrls.map((c) =>
        Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic))).toList();

    // Stagger: 0ms, 120ms, 240ms, 360ms
    _runStaggered();
    NotificationService().init(); // FCM init
    NotificationService().subscribeToTips(); // Daily tips
  }

  Future<void> _runStaggered() async {
    for (int i = 0; i < _cardCount; i++) {
      await Future.delayed(Duration(milliseconds: i == 0 ? 80 : 120));
      if (mounted) _cardCtrls[i].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _cardCtrls) c.dispose();
    super.dispose();
  }

  Widget _animated(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnims[index],
      child: SlideTransition(position: _slideAnims[index], child: child),
    );
  }

  // ── Language Picker ────────────────────────────────────────
  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ListenableBuilder(
        listenable: _lang,
        builder: (ctx, __) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.cardBorder,
                    borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Bhasha / Language',
                style: TextStyle(fontFamily: 'Rajdhani', fontSize: 20,
                    fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              ...LanguageService.supported.map((lang) {
                final isSel = _lang.currentLanguage == lang;
                return Pressable(
                  onTap: () async {
                    await _lang.setLanguage(lang);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: isSel ? AppTheme.primary.withOpacity(0.1) : AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(AppTheme.r12),
                      border: Border.all(
                        color: isSel ? AppTheme.primary.withOpacity(0.6) : AppTheme.cardBorder,
                        width: isSel ? 1.5 : 1),
                    ),
                    child: Row(children: [
                      Text(lang.flag, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 14),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(lang.displayName,
                          style: TextStyle(
                            color: isSel ? AppTheme.primary : AppTheme.textPrimary,
                            fontWeight: FontWeight.w700, fontSize: 15)),
                        Text(lang.localeCode,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ]),
                      const Spacer(),
                      if (isSel)
                        Container(width: 22, height: 22,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: AppTheme.primary),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 13)),
                    ]),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _lang,
      builder: (context, _) => Scaffold(
        backgroundColor: AppTheme.bg,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Top header
              SliverToBoxAdapter(child: _animated(0, _buildHeader())),
              // ── Car Status Card
              SliverToBoxAdapter(child: _animated(1,
                Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildCarStatusCard()))),
              // ── AI Hero Card
              SliverToBoxAdapter(child: _animated(2,
                Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildAiHeroCard()))),
              // ── Quick 2x2 Actions
              SliverToBoxAdapter(child: _animated(3,
                Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _buildQuickGrid()))),
              // ── Helper toggle
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildHelperToggle())),
              // ── Daily section
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _buildDailySection())),
              // ── Ad
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: const AdBannerWidget())),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: AppTheme.bg,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_lang.t('greeting'),
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 1),
          const Text('RAAHI',
            style: TextStyle(fontFamily: 'Rajdhani', fontSize: 26,
              fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: 2)),
        ]),
        const Spacer(),
        Pressable(onTap: _showLanguagePicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_lang.currentLanguage.flag, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Text(_lang.currentLanguage.displayName,
                style: const TextStyle(color: AppTheme.primary, fontSize: 12,
                    fontWeight: FontWeight.w700)),
              const SizedBox(width: 3),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.primary, size: 15),
            ]),
          )),
        const SizedBox(width: 10),
        Pressable(onTap: () {},
          child: Container(width: 38, height: 38,
            decoration: BoxDecoration(color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.r12),
              border: Border.all(color: AppTheme.cardBorder)),
            child: const Icon(Icons.notifications_outlined,
                color: AppTheme.textSecondary, size: 19))),
        const SizedBox(width: 8),
        Pressable(onTap: () => context.push('/profile'),
          child: Container(width: 38, height: 38,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, gradient: AppTheme.primaryGradient),
            child: const Center(child: Text('R',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 16))))),
      ]),
    );
  }

  // ── Car Status Card ────────────────────────────────────────
  Widget _buildCarStatusCard() {
    return AppCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF152030), AppTheme.cardBg],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderColor: AppTheme.primary.withOpacity(0.2),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Top row
        Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.directions_car_rounded,
                color: AppTheme.primary, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Maruti Swift Dzire',
              style: TextStyle(fontFamily: 'Rajdhani', color: AppTheme.textPrimary,
                fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.cyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(5)),
                child: const Text('Petrol',
                  style: TextStyle(color: AppTheme.cyan, fontSize: 10,
                      fontWeight: FontWeight.w700))),
              const SizedBox(width: 6),
              const Text('DL 01 AB 1234',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ]),
          ])),
          const StatusBadge(label: 'Healthy', color: AppTheme.green, pulse: true),
        ]),
        const AppDivider(margin: EdgeInsets.symmetric(vertical: 12)),
        // Stats row
        Row(children: [
          _CarStat(icon: Icons.speed_rounded, label: 'Odometer',
              value: '48,320 km', color: AppTheme.cyan),
          _Divider(),
          _CarStat(icon: Icons.build_circle_outlined, label: 'Last Service',
              value: '2 mo ago', color: AppTheme.yellow),
          _Divider(),
          _CarStat(icon: Icons.local_gas_station_rounded, label: 'Fuel Type',
              value: 'Petrol', color: AppTheme.primary),
        ]),
      ]),
    );
  }

  // ── AI Hero Card ───────────────────────────────────────────
  Widget _buildAiHeroCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C2F48), AppTheme.cardBg],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(AppTheme.r16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.14),
            blurRadius: 28, offset: const Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Top: icon + label
          Row(children: [
            Container(width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.45),
                    blurRadius: 16, offset: const Offset(0, 6))]),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 26)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('AI Mechanic',
                style: TextStyle(fontFamily: 'Rajdhani', fontSize: 22,
                  fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                  letterSpacing: 0.3)),
              const Text('Instant car problem diagnosis',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.green.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                  decoration: const BoxDecoration(shape: BoxShape.circle,
                    color: AppTheme.green)),
                const SizedBox(width: 5),
                const Text('Online',
                  style: TextStyle(color: AppTheme.green, fontSize: 10,
                      fontWeight: FontWeight.w700)),
              ])),
          ]),

          const SizedBox(height: 16),

          // Feature chips
          Wrap(spacing: 8, runSpacing: 6, children: [
            _FeatureChip('🗣️ Voice Input'),
            _FeatureChip('🌐 6 Languages'),
            _FeatureChip('⚡ Instant'),
            _FeatureChip('🆓 Free'),
          ]),

          const SizedBox(height: 20),

          // Primary CTA
          GlowButton(
            label: 'Start Diagnosis',
            icon: Icons.search_rounded,
            height: 56,
            fontSize: 18,
            radius: AppTheme.r16,
            onTap: () => context.push('/ai-mechanic'),
          ),

          const SizedBox(height: 10),

          // Secondary hint
          Center(child: Text('Describe in Hindi, English, or any language',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11))),
        ]),
      ),
    );
  }

  // ── Quick 2x2 Grid ────────────────────────────────────────
  Widget _buildQuickGrid() {
    final items = [
      _QA('Roadside Help', Icons.emergency_rounded, AppTheme.primary,
          'Get help fast', '/request-help'),
      _QA('Nearby Mechanics', Icons.build_rounded, AppTheme.cyan,
          'Find workshops', '/mechanics'),
      _QA('Maintenance Tips', Icons.tips_and_updates_rounded, AppTheme.yellow,
          'Keep car healthy', '/ai-mechanic'),
      _QA('Car Health', Icons.favorite_rounded, AppTheme.green,
          'View diagnostics', '/profile'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionLabel('QUICK ACTIONS'),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10, crossAxisSpacing: 10,
          childAspectRatio: 1.75,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _QuickActionCard(item: items[i]),
      ),
    ]);
  }

  // ── Helper Toggle ─────────────────────────────────────────
  Widget _buildHelperToggle() {
    return Pressable(
      onTap: () => setState(() => _isAvailable = !_isAvailable),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: _isAvailable ? AppTheme.green.withOpacity(0.07) : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.r12),
          border: Border.all(
            color: _isAvailable
                ? AppTheme.green.withOpacity(0.4) : AppTheme.cardBorder)),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 9, height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isAvailable ? AppTheme.green : AppTheme.textMuted,
              boxShadow: _isAvailable
                  ? [BoxShadow(color: AppTheme.green.withOpacity(0.6), blurRadius: 6)]
                  : null)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_isAvailable ? 'Helper Mode — Active' : 'Helper Mode — Off',
              style: TextStyle(
                color: _isAvailable ? AppTheme.green : AppTheme.textPrimary,
                fontWeight: FontWeight.w700, fontSize: 13)),
            Text(_isAvailable ? 'Receiving nearby help requests'
                : 'Enable to earn by helping others',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ])),
          Switch(value: _isAvailable,
            onChanged: (v) => setState(() => _isAvailable = v),
            activeColor: AppTheme.green),
        ]),
      ),
    );
  }

  // ── Daily Section ─────────────────────────────────────────
  Widget _buildDailySection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionLabel('TODAY'),
      // Row 1: Fuel + Alerts
      Row(children: [
        Expanded(child: _DailyCard(
          emoji: '⛽', title: 'Fuel Rates',
          sub: 'Petrol/Diesel daily update',
          tag: 'Daily', tagColor: AppTheme.primary,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const FuelRatesScreen())))),
        const SizedBox(width: 10),
        Expanded(child: _DailyCard(
          emoji: '🚦', title: 'Highway Alerts',
          sub: 'Jam • Weather • Police',
          tag: 'Live', tagColor: AppTheme.red, badgeDot: true,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const HighwayAlertsScreen())))),
      ]),
      const SizedBox(height: 10),
      // Row 2: Tips + Places
      Row(children: [
        Expanded(child: _DailyCard(
          emoji: '💡', title: 'Aaj Ka Tip',
          sub: 'Raahi Bhaiya ka daily tip',
          tag: 'New', tagColor: AppTheme.yellow,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DailyTipsScreen())))),
        const SizedBox(width: 10),
        Expanded(child: _DailyCard(
          emoji: '🍽️', title: 'Nearby Places',
          sub: 'Dhaba • Parking • ATM',
          tag: 'GPS', tagColor: AppTheme.cyan,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NearbyPlacesScreen())))),
      ]),
      const SizedBox(height: 10),
      // Streak card - full width
      _buildStreakCard(),
    ]);
  }

  Widget _buildStreakCard() {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const StreakScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary.withOpacity(0.1), AppTheme.cardBg],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
        ),
        child: Row(children: [
          const Text('🔥', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Daily Streak', style: TextStyle(color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700, fontSize: 14)),
            Text('Roz aao, rewards kamao', style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Check-in', style: TextStyle(color: Colors.white,
                fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Local sub-widgets
// ═══════════════════════════════════════════════════════════

class _CarStat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _CarStat({required this.icon, required this.label,
    required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Container(width: 34, height: 34,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 17)),
    const SizedBox(height: 6),
    Text(value, style: const TextStyle(color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700, fontSize: 11)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
  ]));
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
    Container(width: 1, height: 36, color: AppTheme.cardBorder,
      margin: const EdgeInsets.symmetric(horizontal: 4));
}

class _FeatureChip extends StatelessWidget {
  final String label;
  const _FeatureChip(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppTheme.surfaceHigh,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.cardBorder)),
    child: Text(label,
      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11,
          fontWeight: FontWeight.w500)));
}

class _QA {
  final String label, sub, route;
  final IconData icon;
  final Color color;
  const _QA(this.label, this.icon, this.color, this.sub, this.route);
}

class _QuickActionCard extends StatelessWidget {
  final _QA item;
  const _QuickActionCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => context.push(item.route),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.r14),
          border: Border.all(color: AppTheme.cardBorder)),
        child: Row(children: [
          Container(width: 42, height: 42,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(13)),
            child: Icon(item.icon, color: item.color, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.label, style: const TextStyle(color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 2),
              Text(item.sub, style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 11)),
            ])),
        ]),
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  final String emoji, title, sub, tag;
  final Color tagColor;
  final bool badgeDot;
  final VoidCallback onTap;
  const _DailyCard({required this.emoji, required this.title,
    required this.sub, required this.tag, required this.tagColor,
    required this.onTap, this.badgeDot = false});

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.r14),
        border: Border.all(color: tagColor.withOpacity(0.25)),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [tagColor.withOpacity(0.07), AppTheme.cardBg])),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          if (badgeDot) Positioned(top: 0, right: 0,
            child: Container(width: 8, height: 8,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppTheme.red))),
        ]),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: tagColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
          child: Text(tag, style: TextStyle(color: tagColor,
              fontSize: 10, fontWeight: FontWeight.w700))),
      ]),
    ));
}
