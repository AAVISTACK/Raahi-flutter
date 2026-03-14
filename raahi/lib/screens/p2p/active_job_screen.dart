import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../services/ad_service.dart';
import '../../services/safety_service.dart';
import '../../services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ActiveJobScreen extends StatefulWidget {
  final String jobId;
  const ActiveJobScreen({super.key, required this.jobId});

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  HelpJob? _job;
  bool _loading = true;
  Timer? _pollTimer;
  int _searchingDots = 1;

  @override
  void initState() {
    super.initState();
    _loadJob();
    _startPolling();

    // Listen to WebSocket updates
    SocketService().onJobStatusChange = (data) {
      if (data['job_id'] == widget.jobId) {
        _loadJob();
      }
    };
  }

  Future<void> _loadJob() async {
    try {
      final job = await ApiService().getJob(widget.jobId);
      if (mounted) setState(() { _job = job; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startPolling() {
    // Animate searching dots
    _pollTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (mounted) setState(() => _searchingDots = (_searchingDots % 3) + 1);
    });
    // Refresh job every 5s
    Timer.periodic(const Duration(seconds: 5), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_job?.status == JobStatus.completed || _job?.status == JobStatus.cancelled) {
        t.cancel(); return;
      }
      _loadJob();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    SocketService().onJobStatusChange = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: const Text('Help Request'),
        backgroundColor: AppTheme.navyLight,
        actions: [
          if (_job?.status == JobStatus.pending)
            TextButton(
              onPressed: () => _cancelJob(),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.red)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.saffron))
          : _job == null
              ? const Center(child: Text('Job nahi mila', style: TextStyle(color: AppTheme.textSecondary)))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final job = _job!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Status card
          _buildStatusCard(job),
          const SizedBox(height: 20),

          // Job details
          _buildJobDetails(job),
          const SizedBox(height: 20),

          // Helper info (if matched)
          if (job.helper != null) _buildHelperCard(job),

          // OTP verification (if in progress)
          if (job.status == JobStatus.matched) _buildOtpSection(job),

          // Complete button (if in progress)
          if (job.status == JobStatus.inProgress) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _completeJob,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green),
                child: const Text('Job Complete Hai ✓', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
              ),
            ),
          ],

          // Completed state
          if (job.status == JobStatus.completed) _buildCompletedCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard(HelpJob job) {
    final dots = '.' * _searchingDots;

    final (icon, label, color) = switch (job.status) {
      JobStatus.pending => (Icons.search_rounded, 'Drivers dhundh rahe hain$dots', AppTheme.yellow),
      JobStatus.matched => (Icons.person_pin_rounded, 'Driver aa raha hai!', AppTheme.cyan),
      JobStatus.inProgress => (Icons.handshake_rounded, 'Help chal rahi hai', AppTheme.green),
      JobStatus.completed => (Icons.check_circle_rounded, 'Help ho gayi! 🎉', AppTheme.green),
      JobStatus.cancelled => (Icons.cancel_rounded, 'Cancel ho gaya', AppTheme.red),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
                if (job.status == JobStatus.matched && job.estimatedEta != null)
                  Text('ETA: ~${job.estimatedEta} minutes',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDetails(HelpJob job) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          _row('Problem', job.problemType.toUpperCase()),
          if (job.problemDesc != null && job.problemDesc!.isNotEmpty)
            _row('Description', job.problemDesc!),
          _row('Reward', '₹${job.rewardAmount.toInt()}'),
          _row('Job ID', '#${job.id.substring(0, 8).toUpperCase()}'),
        ],
      ),
    );
  }

  Widget _buildHelperCard(HelpJob job) {
    final helper = job.helper!;
    // Auto share location with emergency contacts when helper arrives
    _autoShareLocation(helper);
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.verified_user_rounded, color: AppTheme.green, size: 14),
              const SizedBox(width: 4),
              const Text('Verified Helper', style: TextStyle(
                  color: AppTheme.green, fontSize: 11, fontWeight: FontWeight.w600)),
              const Spacer(),
              // Report button
              GestureDetector(
                onTap: () => _showReportDialog(helper.id, job.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.red.withOpacity(0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.flag_rounded, color: AppTheme.red, size: 12),
                    SizedBox(width: 4),
                    Text('Report', style: TextStyle(color: AppTheme.red, fontSize: 11)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Container(
                width: 52, height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [AppTheme.cyan, AppTheme.green]),
                ),
                child: Center(child: Text(
                  (helper.name ?? 'D')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 22),
                )),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(helper.name ?? 'Driver', style: const TextStyle(
                      color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: AppTheme.yellow, size: 14),
                    Text(' ${helper.ratingAvg.toStringAsFixed(1)}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    Text(' · ${helper.totalHelps} helps',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ]),
                  Text(helper.phone, style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 11)),
                ],
              )),
              IconButton(
                onPressed: () async {
                  final uri = Uri.parse('tel:${helper.phone}');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.green.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_rounded, color: AppTheme.green, size: 20),
                ),
              ),
            ]),
          ],
        ),
      ),
      const SizedBox(height: 10),
      // "I Feel Unsafe" button
      GestureDetector(
        onTap: () => _showUnsafeAlert(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.shield_rounded, color: Color(0xFF7C3AED), size: 16),
            SizedBox(width: 8),
            Text('Main Safe Nahi Hoon — Alert Bhejo',
                style: TextStyle(color: Color(0xFF7C3AED),
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ]);
  }

  // Auto share location when helper is matched
  bool _locationShared = false;
  Future<void> _autoShareLocation(UserModel helper) async {
    if (_locationShared) return;
    _locationShared = true;
    final pos = await LocationService().getCurrentPosition();
    if (pos == null) return;
    await SafetyService().shareLiveLocationWithContacts(
      lat: pos.latitude, lng: pos.longitude,
      helperName: helper.name ?? 'Helper',
      helperPhone: helper.phone,
    );
  }

  void _showUnsafeAlert() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.navyLight,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Icon(Icons.shield_rounded, color: Color(0xFF7C3AED), size: 48),
          const SizedBox(height: 12),
          const Text('Safety Alert Bhejein?', style: TextStyle(
              color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Tumhare emergency contacts ko location + helper details SMS ho jaayengi. Police 112 call option bhi milega.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.cardBorder),
                  foregroundColor: AppTheme.textMuted),
              child: const Text('Cancel'),
            )),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final pos = await LocationService().getCurrentPosition();
                if (pos != null && _job != null) {
                  await SafetyService().sendUnsafeAlert(
                    lat: pos.latitude, lng: pos.longitude,
                    helperName: _job!.helper?.name,
                    helperPhone: _job!.helper?.phone,
                  );
                }
                if (mounted) context.push('/sos');
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
              child: const Text('Alert Bhejo 🆘', style: TextStyle(fontWeight: FontWeight.w700)),
            )),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showReportDialog(String helperId, String jobId) {
    String? selectedReason;
    final reasons = ['Batameezi ki', 'Intimidate kiya', 'Galat jagah le gaya',
                     'Payment se mana kiya', 'Kuch aur'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.navyLight,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (_, setS) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.cardBorder,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Helper Report Karo', style: TextStyle(
                color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...reasons.map((r) => GestureDetector(
              onTap: () => setS(() => selectedReason = r),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selectedReason == r
                      ? AppTheme.red.withOpacity(0.1) : AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selectedReason == r
                        ? AppTheme.red.withOpacity(0.4) : AppTheme.cardBorder,
                  ),
                ),
                child: Row(children: [
                  Icon(selectedReason == r
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                      color: selectedReason == r ? AppTheme.red : AppTheme.textMuted,
                      size: 18),
                  const SizedBox(width: 10),
                  Text(r, style: TextStyle(
                      color: selectedReason == r ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontSize: 14)),
                ]),
              ),
            )),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: selectedReason == null ? null : () async {
                  Navigator.pop(ctx);
                  // TODO: API call to report
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Report submit ho gaya. Hum review karenge.')));
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
                child: const Text('Report Submit Karo',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Widget _buildOtpSection(HelpJob job) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cyan.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cyan.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.key_rounded, color: AppTheme.cyan, size: 32),
          const SizedBox(height: 8),
          const Text('Helper ke aane par yeh OTP dikhao',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          if (job.helperOtp != null)
            Text(job.helperOtp!,
                style: const TextStyle(
                  fontSize: 36, fontWeight: FontWeight.w800,
                  color: AppTheme.cyan, letterSpacing: 8,
                )),
        ],
      ),
    );
  }

  Widget _buildCompletedCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          const Text('Bahut Accha!', style: TextStyle(
              color: AppTheme.green, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Aapko help mil gayi. Rating zaroor do!',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Home Jao'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        const Spacer(),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Future<void> _cancelJob() async {
    context.pop();
  }

  Future<void> _completeJob() async {
    await ApiService().completeJob(widget.jobId);
    _loadJob();
  }
}
