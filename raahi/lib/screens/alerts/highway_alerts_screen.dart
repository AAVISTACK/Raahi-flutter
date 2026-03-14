// ============================================================
// lib/screens/alerts/highway_alerts_screen.dart
// Real-time highway alerts — jam, weather, police, toll, road
// Community can post + vote
// ============================================================

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/ui_components.dart';

class HighwayAlertsScreen extends StatefulWidget {
  const HighwayAlertsScreen({super.key});
  @override
  State<HighwayAlertsScreen> createState() => _HighwayAlertsScreenState();
}

class _HighwayAlertsScreenState extends State<HighwayAlertsScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  List<dynamic> _alerts = [];
  bool _loading = true;
  String _filter = 'ALL';
  late TabController _tabCtrl;

  final _filters = ['ALL', 'JAM', 'WEATHER', 'POLICE', 'TOLL', 'ROAD'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _filters.length, vsync: this);
    _loadAlerts();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    setState(() => _loading = true);
    try {
      final params = _filter != 'ALL' ? '?type=$_filter' : '';
      final res = await _api.get('/daily/alerts$params');
      setState(() { _alerts = res['alerts'] ?? []; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _vote(int id, String vote) async {
    try {
      await _api.post('/daily/alerts/$id/vote', {'vote': vote});
      _loadAlerts();
    } catch (_) {}
  }

  Future<void> _showPostAlert() async {
    final titleCtrl    = TextEditingController();
    final bodyCtrl     = TextEditingController();
    final locationCtrl = TextEditingController();
    String type        = 'JAM';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.textMuted,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Alert Post Karo',
                style: TextStyle(fontFamily: 'Rajdhani', fontSize: 20,
                    fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 14),
            // Type selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _alertTypes.entries.map((e) =>
                GestureDetector(
                  onTap: () => setBS(() => type = e.key),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: type == e.key ? AppTheme.primary.withOpacity(0.15) : AppTheme.navyLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: type == e.key ? AppTheme.primary.withOpacity(0.5) : AppTheme.cardBorder,
                      ),
                    ),
                    child: Text('${e.value['icon']} ${e.key}',
                        style: TextStyle(
                          color: type == e.key ? AppTheme.primary : AppTheme.textSecondary,
                          fontSize: 12, fontWeight: FontWeight.w600,
                        )),
                  ),
                )).toList(),
            ),
            ),
            const SizedBox(height: 12),
            _field(titleCtrl, 'Title (jaise: NH-44 pe jam)', maxLines: 1),
            const SizedBox(height: 8),
            _field(locationCtrl, 'Location (jaise: Ambala, Haryana)', maxLines: 1),
            const SizedBox(height: 8),
            _field(bodyCtrl, 'Detail mein batao kya hua...', maxLines: 3),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.isEmpty || bodyCtrl.text.isEmpty || locationCtrl.text.isEmpty) return;
                  try {
                    await _api.post('/daily/alerts', {
                      'type': type,
                      'title': titleCtrl.text,
                      'body': bodyCtrl.text,
                      'location': locationCtrl.text,
                    });
                    if (mounted) Navigator.pop(ctx);
                    _loadAlerts();
                    _snack('Alert post ho gaya! Drivers ko help milegi 🙏', isSuccess: true);
                  } catch (e) {
                    _snack('Post nahi hua. Dobara try karo.');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Post Karo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        filled: true, fillColor: AppTheme.navyLight,
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppTheme.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppTheme.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.5))),
      ),
    );
  }

  void _snack(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isSuccess ? AppTheme.green : AppTheme.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        backgroundColor: AppTheme.navyLight,
        title: const Text('Highway Alerts',
            style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 20)),
        actions: [
          IconButton(onPressed: _loadAlerts, icon: const Icon(Icons.refresh)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(children: _filters.map((f) =>
              GestureDetector(
                onTap: () { setState(() => _filter = f); _loadAlerts(); },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _filter == f ? AppTheme.primary : AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _filter == f ? AppTheme.primary : AppTheme.cardBorder,
                    ),
                  ),
                  child: Text(
                    _filter == f && f != 'ALL'
                        ? '${_alertTypes[f]?['icon'] ?? ''} $f'
                        : f,
                    style: TextStyle(
                      color: _filter == f ? Colors.white : AppTheme.textSecondary,
                      fontSize: 12, fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPostAlert,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_alert),
        label: const Text('Alert Post Karo', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _alerts.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadAlerts,
                  color: AppTheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: _alerts.length,
                    itemBuilder: (_, i) => _buildAlertCard(_alerts[i]),
                  ),
                ),
    );
  }

  Widget _buildAlertCard(Map alert) {
    final type     = alert['type'] as String? ?? 'OTHER';
    final meta     = _alertTypes[type] ?? _alertTypes['OTHER']!;
    final severity = alert['severity'] as String? ?? 'MEDIUM';
    final sevColor = severity == 'HIGH' ? AppTheme.red
        : severity == 'MEDIUM' ? AppTheme.yellow : AppTheme.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (meta['color'] as Color).withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (meta['color'] as Color).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(meta['icon'] as String, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(alert['title'] ?? '',
                  style: const TextStyle(color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.location_on, size: 12, color: AppTheme.textMuted),
                const SizedBox(width: 3),
                Expanded(child: Text(alert['location'] ?? '',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    overflow: TextOverflow.ellipsis)),
              ]),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: sevColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(severity,
                  style: TextStyle(color: sevColor, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(alert['body'] ?? '',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.person_outline, size: 12, color: AppTheme.textMuted),
            const SizedBox(width: 4),
            Text(alert['postedBy'] ?? 'Driver',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            const Spacer(),
            // Helpful vote
            GestureDetector(
              onTap: () => _vote(alert['id'], 'helpful'),
              child: Row(children: [
                const Icon(Icons.thumb_up_outlined, size: 14, color: AppTheme.green),
                const SizedBox(width: 4),
                Text('${alert['helpful'] ?? 0}',
                    style: const TextStyle(color: AppTheme.green, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(width: 14),
            GestureDetector(
              onTap: () => _vote(alert['id'], 'not_helpful'),
              child: Row(children: [
                const Icon(Icons.thumb_down_outlined, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text('${alert['notHelpful'] ?? 0}',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🛣️', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        const Text('Koi alert nahi', style: TextStyle(color: AppTheme.textPrimary,
            fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Highway pe kuch dikha? Post karo!',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _showPostAlert,
          icon: const Icon(Icons.add_alert),
          label: const Text('Pehla Alert Post Karo'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
        ),
      ]),
    );
  }

  static const _alertTypes = {
    'JAM':     {'icon': '🚦', 'label': 'Traffic Jam',    'color': AppTheme.red},
    'WEATHER': {'icon': '🌫️', 'label': 'Weather',        'color': AppTheme.cyan},
    'POLICE':  {'icon': '👮', 'label': 'Police/Checkup', 'color': AppTheme.yellow},
    'TOLL':    {'icon': '💳', 'label': 'Toll Update',    'color': AppTheme.purple},
    'ROAD':    {'icon': '⚠️', 'label': 'Road Damage',   'color': AppTheme.yellow},
    'OTHER':   {'icon': '📢', 'label': 'Other',          'color': AppTheme.textSecondary},
  };
}
