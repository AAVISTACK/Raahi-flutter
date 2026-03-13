// ============================================================
// lib/screens/p2p/request_help_screen.dart  — Production v3
// Breakdown / Roadside Help — polished form with animations
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../widgets/ui_components.dart';

class RequestHelpScreen extends StatefulWidget {
  const RequestHelpScreen({super.key});
  @override
  State<RequestHelpScreen> createState() => _RequestHelpScreenState();
}

class _RequestHelpScreenState extends State<RequestHelpScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedProblem;
  final _priceCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  bool _loading = false;
  bool _fetchingLocation = false;
  String? _locationAddress;

  final _quickPrices = [50, 100, 150, 200, 300, 500];

  // Step tracker
  late AnimationController _stepCtrl;
  late Animation<double> _stepAnim;

  @override
  void initState() {
    super.initState();
    _stepCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _stepAnim = CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOut);
    _getLocation();
  }

  @override
  void dispose() {
    _stepCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _fetchingLocation = true);
    final pos = await LocationService().getCurrentPosition();
    if (pos != null && mounted) {
      setState(() {
        _locationAddress = 'Lat ${pos.latitude.toStringAsFixed(4)}, '
            'Lng ${pos.longitude.toStringAsFixed(4)}';
        _fetchingLocation = false;
      });
      _stepCtrl.forward();
    } else {
      setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _createJob() async {
    if (_selectedProblem == null) {
      _snack('Problem select karo pehle', isError: true); return;
    }
    final priceText = _priceCtrl.text.trim();
    if (priceText.isEmpty) {
      _snack('Price daalo', isError: true); return;
    }
    final price = double.tryParse(priceText);
    if (price == null || price < 20) {
      _snack('Minimum ₹20 price daalo', isError: true); return;
    }
    final pos = LocationService().lastPosition;
    if (pos == null) {
      _snack('GPS on karo', isError: true); return;
    }

    setState(() => _loading = true);
    try {
      final job = await ApiService().createJob(
        lat: pos.latitude, lng: pos.longitude,
        problemType: _selectedProblem!,
        problemDesc: _descCtrl.text.trim(),
        rewardAmount: price,
      );
      if (mounted) context.pushReplacement('/active-job/${job.id}');
    } catch (e) {
      if (mounted) _snack('Error aaya. Dobara try karo.', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.red.withOpacity(0.9) : AppTheme.green,
    ));
  }

  // ── BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.navyLight,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Request Roadside Help'),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildLocationCard()),
          SliverToBoxAdapter(child: _buildSectionHeader(
            '1', 'What happened?', Icons.help_outline_rounded)),
          SliverToBoxAdapter(child: _buildProblemGrid()),
          SliverToBoxAdapter(child: _buildSectionHeader(
            '2', 'Describe the issue', Icons.edit_note_rounded)),
          SliverToBoxAdapter(child: _buildDescField()),
          SliverToBoxAdapter(child: _buildSectionHeader(
            '3', 'Your offer (Cash)', Icons.payments_rounded)),
          SliverToBoxAdapter(child: _buildPriceSection()),
          SliverToBoxAdapter(child: _buildCashNote()),
          if (_selectedProblem != null && _priceCtrl.text.isNotEmpty)
            SliverToBoxAdapter(child: _buildSummaryCard()),
          SliverToBoxAdapter(child: _buildSubmitButton()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ── Location Card ──────────────────────────────────────────
  Widget _buildLocationCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: AppCard(
        borderColor: _locationAddress != null
            ? AppTheme.green.withOpacity(0.3) : AppTheme.cardBorder,
        gradient: _locationAddress != null
            ? LinearGradient(colors: [AppTheme.green.withOpacity(0.06), AppTheme.cardBg],
                begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: (_locationAddress != null ? AppTheme.green : AppTheme.red).withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppTheme.r12),
            ),
            child: Icon(
              _locationAddress != null
                  ? Icons.location_on_rounded
                  : Icons.location_off_rounded,
              color: _locationAddress != null ? AppTheme.green : AppTheme.red,
              size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              _fetchingLocation ? 'Detecting location...'
                  : _locationAddress != null ? 'Location detected'
                  : 'Location unavailable',
              style: TextStyle(
                color: _locationAddress != null ? AppTheme.green : AppTheme.textPrimary,
                fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              _fetchingLocation ? 'Please wait...'
                  : _locationAddress ?? 'Enable GPS and retry',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          if (_fetchingLocation)
            const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
          else if (_locationAddress != null)
            Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle, color: AppTheme.green),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 16))
          else
            Pressable(
              onTap: _getLocation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
                child: const Text('Retry',
                  style: TextStyle(color: AppTheme.primary, fontSize: 11,
                    fontWeight: FontWeight.w700)),
              ),
            ),
        ]),
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────
  Widget _buildSectionHeader(String num, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(children: [
        Container(
          width: 26, height: 26,
          decoration: const BoxDecoration(
            shape: BoxShape.circle, gradient: AppTheme.primaryGradient),
          child: Center(child: Text(num,
            style: const TextStyle(color: Colors.white, fontSize: 12,
              fontWeight: FontWeight.w800, fontFamily: 'Rajdhani'))),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: AppTheme.primary, size: 16),
        const SizedBox(width: 6),
        Text(title,
          style: const TextStyle(
            fontFamily: 'Rajdhani', fontSize: 16, fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary, letterSpacing: 0.3)),
      ]),
    );
  }

  // ── Problem Grid ──────────────────────────────────────────
  Widget _buildProblemGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10, crossAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemCount: ProblemType.all.length,
        itemBuilder: (_, i) {
          final p = ProblemType.all[i];
          return ProblemTile(
            emoji: p.icon,
            label: p.labelHindi,
            selected: _selectedProblem == p.id,
            onTap: () => setState(() => _selectedProblem = p.id),
          );
        },
      ),
    );
  }

  // ── Description Field ─────────────────────────────────────
  Widget _buildDescField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _descCtrl,
        maxLines: 3,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.5),
        decoration: const InputDecoration(
          hintText: 'e.g. Tyre puncture, NH-44 pe hoon, spare bhi nahi hai...',
          hintMaxLines: 2,
        ),
      ),
    );
  }

  // ── Price Section ─────────────────────────────────────────
  Widget _buildPriceSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        // Price input
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(AppTheme.r12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppTheme.cardBorder))),
              child: const Text('₹',
                style: TextStyle(
                  fontFamily: 'Rajdhani', color: AppTheme.primary,
                  fontSize: 24, fontWeight: FontWeight.w800)),
            ),
            Expanded(
              child: TextField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontFamily: 'Rajdhani', color: AppTheme.textPrimary,
                  fontSize: 28, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(
                    fontFamily: 'Rajdhani', color: AppTheme.textMuted,
                    fontSize: 28, fontWeight: FontWeight.w400),
                  filled: false, border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Text('cash', style: TextStyle(
                color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // Quick chips
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _quickPrices.map((r) => PriceChip(
            label: '₹$r',
            selected: _priceCtrl.text == r.toString(),
            onTap: () => setState(() => _priceCtrl.text = r.toString()),
          )).toList(),
        ),
      ]),
    );
  }

  // ── Cash Note ─────────────────────────────────────────────
  Widget _buildCashNote() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.green.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppTheme.r12),
          border: Border.all(color: AppTheme.green.withOpacity(0.2)),
        ),
        child: const Row(children: [
          Icon(Icons.payments_rounded, color: AppTheme.green, size: 18),
          SizedBox(width: 10),
          Expanded(child: Text(
            'Payment directly to helper in cash. Raahi takes 0% commission.',
            style: TextStyle(color: AppTheme.green, fontSize: 12, height: 1.45))),
        ]),
      ),
    );
  }

  // ── Summary Card ──────────────────────────────────────────
  Widget _buildSummaryCard() {
    final prob = ProblemType.all
        .firstWhere((p) => p.id == _selectedProblem, orElse: () => ProblemType.all.first);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: AppCard(
        borderColor: AppTheme.primary.withOpacity(0.3),
        gradient: LinearGradient(
          colors: [AppTheme.primary.withOpacity(0.06), AppTheme.cardBg],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        child: Row(children: [
          Text(prob.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(prob.labelHindi,
              style: const TextStyle(color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 3),
            Text('₹${_priceCtrl.text} cash in hand',
              style: const TextStyle(color: AppTheme.primary,
                fontWeight: FontWeight.w600, fontSize: 13)),
          ])),
          const StatusBadge(label: 'Ready', color: AppTheme.green, pulse: true),
        ]),
      ),
    );
  }

  // ── Submit Button ─────────────────────────────────────────
  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GlowButton(
        label: 'Find Nearby Helpers',
        icon: Icons.search_rounded,
        isLoading: _loading,
        height: 56,
        fontSize: 18,
        onTap: _createJob,
      ),
    );
  }
}
