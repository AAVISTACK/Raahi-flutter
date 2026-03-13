// ============================================================
// lib/screens/streak/streak_screen.dart
// Daily check-in streak — gamification for retention
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});
  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  Map? _streakData;
  bool _loading       = true;
  bool _checkingIn    = false;
  bool _justCheckedIn = false;

  late AnimationController _celebCtrl;
  late Animation<double>    _celebAnim;

  @override
  void initState() {
    super.initState();
    _celebCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _celebAnim = CurvedAnimation(parent: _celebCtrl, curve: Curves.elasticOut);
    _loadStreak();
  }

  @override
  void dispose() { _celebCtrl.dispose(); super.dispose(); }

  Future<void> _loadStreak() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/daily/streak');
      setState(() { _streakData = res; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _checkIn() async {
    setState(() => _checkingIn = true);
    HapticFeedback.mediumImpact();
    try {
      final res = await _api.post('/daily/streak/checkin', {});
      setState(() {
        _checkingIn    = false;
        _justCheckedIn = true;
        _streakData = {
          ..._streakData ?? {},
          'streak':         res['streak'],
          'longest':        res['longest'],
          'checkedInToday': true,
        };
      });
      _celebCtrl.forward(from: 0);
      if (res['milestone'] != null) {
        await Future.delayed(const Duration(milliseconds: 300));
        _showMilestone(res['milestone'], res['streak']);
      }
    } catch (_) {
      setState(() => _checkingIn = false);
    }
  }

  void _showMilestone(String milestone, int streak) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(milestone.split(' ')[0], style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(milestone,
                style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 26,
                    fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Raahi pe $streak din se aate ho!\nShukria bhai 🙏',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 44),
              ),
              child: const Text('Shukriya!', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        backgroundColor: AppTheme.navyLight,
        title: const Text('Daily Streak',
            style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _streakData == null
              ? const Center(child: Text('Data load nahi hua', style: TextStyle(color: AppTheme.textSecondary)))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildStreakHero(),
                    const SizedBox(height: 20),
                    _buildMilestonesRow(),
                    const SizedBox(height: 20),
                    _buildWeekView(),
                    const SizedBox(height: 20),
                    _buildWhyCheckIn(),
                  ],
                ),
    );
  }

  Widget _buildStreakHero() {
    final streak      = _streakData?['streak'] ?? 0;
    final longest     = _streakData?['longest'] ?? 0;
    final doneToday   = _streakData?['checkedInToday'] ?? false;
    final nextMile    = _streakData?['nextMilestone'];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: doneToday
              ? [AppTheme.green.withOpacity(0.15), AppTheme.cardBg]
              : [AppTheme.primary.withOpacity(0.12), AppTheme.cardBg],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: doneToday
              ? AppTheme.green.withOpacity(0.3)
              : AppTheme.primary.withOpacity(0.25),
        ),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(children: [
        // Streak number
        ScaleTransition(
          scale: _justCheckedIn ? _celebAnim : const AlwaysStoppedAnimation(1.0),
          child: Column(children: [
            Text(streak == 0 ? '🆕' : streak >= 30 ? '👑' : streak >= 7 ? '🔥' : '✨',
                style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 6),
            Text('$streak',
                style: TextStyle(
                  fontFamily: 'Rajdhani', fontSize: 72, fontWeight: FontWeight.w800,
                  color: doneToday ? AppTheme.green : AppTheme.primary,
                  height: 1,
                )),
            const Text('DIN KI STREAK',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11,
                    fontWeight: FontWeight.w700, letterSpacing: 2)),
          ]),
        ),
        const SizedBox(height: 16),

        // Stats row
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _statChip('🏆 Best', '$longest din', AppTheme.yellow),
          const SizedBox(width: 10),
          if (nextMile != null)
            _statChip('🎯 Next', '$nextMile din', AppTheme.cyan),
        ]),
        const SizedBox(height: 18),

        // Check-in button
        if (!doneToday)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _checkingIn ? null : _checkIn,
              icon: _checkingIn
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('☀️', style: TextStyle(fontSize: 18)),
              label: const Text('Aaj Check-in Karo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.green.withOpacity(0.3)),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.check_circle, color: AppTheme.green, size: 20),
              SizedBox(width: 8),
              Text('Aaj check-in ho gaya ✓',
                  style: TextStyle(color: AppTheme.green, fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
      ]),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.7),
            fontSize: 10, fontWeight: FontWeight.w700)),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800,
            fontFamily: 'Rajdhani')),
      ]),
    );
  }

  Widget _buildMilestonesRow() {
    final streak = _streakData?['streak'] ?? 0;
    final milestones = [
      {'days': 3,  'icon': '🔥', 'label': '3 Din'},
      {'days': 7,  'icon': '⭐', 'label': '1 Hafta'},
      {'days': 14, 'icon': '💎', 'label': '2 Hafte'},
      {'days': 30, 'icon': '👑', 'label': '1 Mahina'},
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('MILESTONES',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 11,
              fontWeight: FontWeight.w700, letterSpacing: 1.5)),
      const SizedBox(height: 10),
      Row(children: milestones.map((m) {
        final done = streak >= (m['days'] as int);
        return Expanded(child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: done ? AppTheme.primary.withOpacity(0.12) : AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: done ? AppTheme.primary.withOpacity(0.4) : AppTheme.cardBorder,
            ),
          ),
          child: Column(children: [
            Text(m['icon'] as String,
                style: TextStyle(fontSize: 22, color: done ? null : const Color(0x444A6480))),
            const SizedBox(height: 4),
            Text(m['label'] as String,
                style: TextStyle(
                  color: done ? AppTheme.primary : AppTheme.textMuted,
                  fontSize: 10, fontWeight: FontWeight.w700,
                )),
          ]),
        ));
      }).toList()),
    ]);
  }

  Widget _buildWeekView() {
    final streak    = _streakData?['streak'] ?? 0;
    final doneToday = _streakData?['checkedInToday'] ?? false;
    final days      = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final todayIdx  = DateTime.now().weekday % 7;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('IS HAFTE',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 11,
              fontWeight: FontWeight.w700, letterSpacing: 1.5)),
      const SizedBox(height: 10),
      Row(children: List.generate(7, (i) {
        final isToday   = i == todayIdx;
        final isPast    = i < todayIdx;
        final isChecked = isPast || (isToday && doneToday);
        final inStreak  = streak > 0 && (isPast || (isToday && doneToday));

        return Expanded(child: Container(
          margin: const EdgeInsets.only(right: 4),
          height: 52,
          decoration: BoxDecoration(
            color: inStreak
                ? AppTheme.primary.withOpacity(0.15)
                : isToday
                    ? AppTheme.navyLight
                    : AppTheme.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isToday
                  ? AppTheme.primary.withOpacity(0.5)
                  : inStreak
                      ? AppTheme.primary.withOpacity(0.2)
                      : AppTheme.cardBorder,
              width: isToday ? 1.5 : 1,
            ),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(days[i],
                style: TextStyle(
                  color: isToday ? AppTheme.primary : AppTheme.textMuted,
                  fontSize: 10, fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 3),
            Icon(
              isChecked ? Icons.check_circle : Icons.circle_outlined,
              color: isChecked ? AppTheme.primary : AppTheme.cardBorder,
              size: 18,
            ),
          ]),
        ));
      })),
    ]);
  }

  Widget _buildWhyCheckIn() {
    final perks = [
      {'icon': '🏆', 'text': '7 din streak — Trust Score +5'},
      {'icon': '💎', 'text': '14 din — Priority jobs mein dikhoge'},
      {'icon': '👑', 'text': '30 din — Royal Driver badge'},
      {'icon': '🎁', 'text': 'Future mein rewards aur cashback'},
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('CHECK-IN KE FAYDE',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        ...perks.map((p) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Text(p['icon']!, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Text(p['text']!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ]),
        )),
      ]),
    );
  }
}
