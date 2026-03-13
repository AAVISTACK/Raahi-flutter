// ============================================================
// lib/screens/tips/daily_tips_screen.dart
// Raahi Bhaiya ka Aaj Ka Tip — daily rotating driver tips
// ============================================================

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class DailyTipsScreen extends StatefulWidget {
  const DailyTipsScreen({super.key});
  @override
  State<DailyTipsScreen> createState() => _DailyTipsScreenState();
}

class _DailyTipsScreenState extends State<DailyTipsScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  Map? _todayTip;
  Map? _tomorrowTip;
  bool _loading = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _loadTip();
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  Future<void> _loadTip() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/daily/tips');
      setState(() {
        _todayTip    = res['today'];
        _tomorrowTip = res['tomorrow'];
        _loading     = false;
      });
      _animCtrl.forward(from: 0);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        backgroundColor: AppTheme.navyLight,
        title: const Text('Raahi Bhaiya ka Tip',
            style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _todayTip == null
              ? const Center(child: Text('Tip load nahi hua', style: TextStyle(color: AppTheme.textSecondary)))
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildAajKaTip(),
                        const SizedBox(height: 20),
                        _buildCalTip(),
                        const SizedBox(height: 20),
                        _buildAllCategories(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildAajKaTip() {
    final tip = _todayTip!;
    final catMeta = _catMeta[tip['category']] ?? _catMeta['Maintenance']!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (catMeta['color'] as Color).withOpacity(0.15),
            AppTheme.cardBg,
          ],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (catMeta['color'] as Color).withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: const Text('🌅 AAJ KA TIP',
                style: TextStyle(color: AppTheme.primary, fontSize: 10,
                    fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (catMeta['color'] as Color).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${catMeta['icon']} ${tip['category']}',
                style: TextStyle(color: catMeta['color'] as Color,
                    fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 16),
        Text(tip['icon'] ?? '💡',
            style: const TextStyle(fontSize: 40)),
        const SizedBox(height: 10),
        Text(tip['title'] ?? '',
            style: const TextStyle(
              fontFamily: 'Rajdhani', fontSize: 24,
              fontWeight: FontWeight.w800, color: AppTheme.textPrimary,
            )),
        const SizedBox(height: 10),
        Text(tip['tip'] ?? '',
            style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 15, height: 1.7,
            )),
        if (tip['savings'] != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.green.withOpacity(0.25)),
            ),
            child: Row(children: [
              const Icon(Icons.savings_outlined, color: AppTheme.green, size: 16),
              const SizedBox(width: 8),
              Text('Savings: ${tip['savings']}',
                  style: const TextStyle(color: AppTheme.green,
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildCalTip() {
    if (_tomorrowTip == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(children: [
        const Text('🔮', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('KAL KA TIP',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 10,
                  fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 2),
          Text('${_tomorrowTip!['category']}: ${_tomorrowTip!['title']}',
              style: const TextStyle(color: AppTheme.textSecondary,
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ])),
        const Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 18),
      ]),
    );
  }

  Widget _buildAllCategories() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('CATEGORIES',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 11,
              fontWeight: FontWeight.w700, letterSpacing: 1.5)),
      const SizedBox(height: 10),
      GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2, childAspectRatio: 2.5, mainAxisSpacing: 8, crossAxisSpacing: 8,
        children: _catMeta.entries.map((e) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (e.value['color'] as Color).withOpacity(0.2)),
          ),
          child: Row(children: [
            Text(e.value['icon'] as String, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(e.key, style: TextStyle(color: e.value['color'] as Color,
                fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        )).toList(),
      ),
    ]);
  }

  static const _catMeta = {
    'Maintenance': {'icon': '🔧', 'color': AppTheme.cyan},
    'Fuel':        {'icon': '⛽', 'color': AppTheme.yellow},
    'Safety':      {'icon': '🛡️', 'color': AppTheme.red},
    'Route':       {'icon': '🗺️', 'color': AppTheme.green},
  };
}
