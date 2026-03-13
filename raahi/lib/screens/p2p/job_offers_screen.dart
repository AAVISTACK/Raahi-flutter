// ============================================================
// lib/screens/p2p/job_offers_screen.dart
// Helper Feed — sirf opt-in users ko dikhta hai
// + FOMO onboarding (ek baar, 3-4 sec)
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/socket_service.dart';
import '../../services/api_service.dart';
import '../../services/helper_prefs_service.dart';

class JobOffersScreen extends StatefulWidget {
  const JobOffersScreen({super.key});
  @override
  State<JobOffersScreen> createState() => _JobOffersScreenState();
}

class _JobOffersScreenState extends State<JobOffersScreen> {
  final List<Map<String, dynamic>> _pendingOffers = [];
  final List<HelpJob> _myJobs = [];
  bool _loadingHistory = true;
  bool _helperMode = false;

  // FOMO fake request
  Map<String, dynamic>? _fomoRequest;
  Timer? _fomoTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _helperMode = await HelperPrefsService().isHelperMode();
    await _loadHistory();
    if (_helperMode) {
      _setupSocket();
      _checkFomo();
    }
  }

  void _setupSocket() {
    SocketService().onNewJobRequest = (data) {
      if (mounted) {
        setState(() => _pendingOffers.insert(0, data));
        _showJobOfferDialog(data, isFomo: false);
      }
    };
  }

  // ── FOMO Logic ───────────────────────────────────────────
  Future<void> _checkFomo() async {
    final should = await HelperPrefsService().shouldShowFomo();
    if (!should || !mounted) return;

    // Fake request data — generic, koi location nahi
    final fake = {
      'id': 'fomo_fake',
      'problem_type': 'puncture',
      'distance_km': 2.3,
      'reward_amount': 200,
      'requester_name': 'Nearby Driver',
      'is_fomo': true,
    };

    setState(() => _fomoRequest = fake);
    _showJobOfferDialog(fake, isFomo: true);
    await HelperPrefsService().markFomoDone();

    // 3 sec baad auto dismiss
    _fomoTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst || r.settings.name != 'fomo_sheet');
        setState(() => _fomoRequest = null);
        // "Kisi aur ne le liya" snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.flash_on_rounded, color: AppTheme.saffron, size: 16),
              SizedBox(width: 8),
              Text('Kisi aur driver ne pehle accept kar liya!',
                  style: TextStyle(color: AppTheme.textPrimary)),
            ]),
            backgroundColor: AppTheme.navyLight,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  Future<void> _loadHistory() async {
    try {
      final jobs = await ApiService().getMyJobs();
      if (mounted) setState(() { _myJobs.addAll(jobs); _loadingHistory = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  void _showJobOfferDialog(Map<String, dynamic> offer, {required bool isFomo}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      routeSettings: const RouteSettings(name: 'fomo_sheet'),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isDismissible: !isFomo, // FOMO auto close hoga
      builder: (_) => _JobOfferSheet(
        offer: offer,
        isFomo: isFomo,
        onAccept: isFomo ? null : () async {
          Navigator.pop(context);
          try {
            await ApiService().acceptJob(offer['id']);
            if (mounted) context.push('/active-job/${offer['id']}');
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Koi aur driver ne pehle accept kar liya!')),
              );
            }
          }
        },
        onDecline: isFomo ? null : () => Navigator.pop(context),
      ),
    );
  }

  @override
  void dispose() {
    _fomoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: const Text('Helper Dashboard'),
        backgroundColor: AppTheme.navyLight,
        actions: [
          // Helper mode toggle in appbar
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Text(_helperMode ? 'Active' : 'Off',
                    style: TextStyle(
                        color: _helperMode ? AppTheme.green : AppTheme.textMuted,
                        fontSize: 12)),
                const SizedBox(width: 4),
                Switch(
                  value: _helperMode,
                  activeColor: AppTheme.green,
                  onChanged: (v) async {
                    await HelperPrefsService().setHelperMode(v);
                    setState(() => _helperMode = v);
                    if (v) {
                      _setupSocket();
                      _checkFomo();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: !_helperMode
          ? _buildOptInPrompt()
          : _loadingHistory
              ? const Center(child: CircularProgressIndicator(color: AppTheme.saffron))
              : _myJobs.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
    );
  }

  // ── Opt-in prompt — helper mode off hai ──────────────────
  Widget _buildOptInPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.saffron.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.handshake_rounded, color: AppTheme.saffron, size: 52),
            ),
            const SizedBox(height: 24),
            const Text('Drivers Ki Help Karo\nPaise Kamao',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.3)),
            const SizedBox(height: 12),
            const Text(
              'Helper mode on karo — jab koi nearby driver mein problem aaye, tumhe request dikhegi. Help karo, seedha cash lo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            // Benefits
            _benefitRow(Icons.payments_rounded, AppTheme.green, 'Seedha cash — app ka koi cut nahi'),
            _benefitRow(Icons.location_off_rounded, AppTheme.cyan, 'Sirf nearby requests dikhegi'),
            _benefitRow(Icons.toggle_on_rounded, AppTheme.saffron, 'Jab chahein on/off karo'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  await HelperPrefsService().setHelperMode(true);
                  setState(() => _helperMode = true);
                  _setupSocket();
                  // FOMO 10 min baad — timer pehle se shuru ho gaya setHelperMode mein
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Helper mode on! Nearby requests aane pe notify honge.'),
                      backgroundColor: AppTheme.green,
                    ),
                  );
                },
                child: const Text('Helper Mode On Karo 🤝',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefitRow(IconData icon, Color color, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 10),
      Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
    ]),
  );

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.access_time_rounded, color: AppTheme.textMuted, size: 56),
          const SizedBox(height: 16),
          const Text('Abhi koi request nahi',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Jab nearby koi help maangega,\ntumhe notification aayegi',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _myJobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final job = _myJobs[i];
        final (color, label) = switch (job.status) {
          JobStatus.completed => (AppTheme.green, 'Complete ✓'),
          JobStatus.cancelled => (AppTheme.red, 'Cancel'),
          JobStatus.inProgress => (AppTheme.cyan, 'Chal Raha Hai'),
          _ => (AppTheme.yellow, 'Pending'),
        };
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            children: [
              Text(
                ProblemType.all.firstWhere(
                  (p) => p.id == job.problemType,
                  orElse: () => ProblemType.all.last,
                ).icon,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.problemType.toUpperCase(),
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.payments_outlined, color: AppTheme.saffron, size: 14),
                      const SizedBox(width: 4),
                      Text('₹${job.rewardAmount.toInt()} cash',
                          style: const TextStyle(color: AppTheme.saffron, fontSize: 12)),
                    ]),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(label,
                    style: TextStyle(
                        color: color, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Job Offer Bottom Sheet ────────────────────────────────────
class _JobOfferSheet extends StatefulWidget {
  final Map<String, dynamic> offer;
  final bool isFomo;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const _JobOfferSheet({
    required this.offer,
    required this.isFomo,
    this.onAccept,
    this.onDecline,
  });

  @override
  State<_JobOfferSheet> createState() => _JobOfferSheetState();
}

class _JobOfferSheetState extends State<_JobOfferSheet> {
  late Timer _countdownTimer;
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    if (widget.isFomo) {
      // Visual countdown for FOMO
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted) setState(() => _countdown--);
        if (_countdown <= 0) t.cancel();
      });
    }
  }

  @override
  void dispose() {
    if (widget.isFomo) _countdownTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: AppTheme.cardBorder,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          // Pulsing icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.saffron.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notification_important_rounded,
                color: AppTheme.saffron, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Nearby Driver Ko Help Chahiye!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.navy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              _row('Problem', (offer['problem_type'] ?? 'puncture').toString().toUpperCase()),
              _row('Distance', '${offer['distance_km']?.toStringAsFixed(1) ?? '2.3'} km door'),
              _row('Payment', '₹${offer['reward_amount']?.toInt() ?? 200} — Cash in hand 💵'),
            ]),
          ),
          const SizedBox(height: 8),
          // Cash note
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.green.withOpacity(0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, color: AppTheme.green, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Payment directly cash mein — app beech mein nahi aata',
                  style: TextStyle(color: AppTheme.green, fontSize: 11),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          // Buttons — FOMO mein sirf countdown dikhao
          if (!widget.isFomo)
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onDecline,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.cardBorder),
                    foregroundColor: AppTheme.textSecondary,
                  ),
                  child: const Text('Nahi', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: widget.onAccept,
                  child: const Text('Haan, Jaaunga! 🤝',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ])
          else
            // FOMO — sirf countdown bar
            Column(children: [
              Text('Koi aur driver dekh raha hai...',
                  style: TextStyle(
                      color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _countdown / 3,
                backgroundColor: AppTheme.cardBorder,
                color: AppTheme.saffron,
              ),
            ]),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Text(l, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      const Spacer(),
      Text(v,
          style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13)),
    ]),
  );
}
