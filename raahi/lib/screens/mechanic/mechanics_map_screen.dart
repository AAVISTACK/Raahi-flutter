// ============================================================
// lib/screens/mechanic/mechanics_map_screen.dart — v3
//
// Ola/Google Maps style full-screen mechanic finder.
// • Full-screen flutter_map (OSM tiles)
// • Green pin = available mechanic, Red pin = busy/closed
// • Floating filter chips at top
// • Mechanic list bottom sheet (draggable)
// • Tap marker/card → detail sheet with Call + Request buttons
// • Floating SOS button (bottom-right)
// • Falls back to mock data when backend unavailable
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/mock_mechanic_service.dart';
import '../../models/breakdown_request.dart';
import 'dart:ui' as ui;

class MechanicsMapScreen extends StatefulWidget {
  final BreakdownRequest? breakdownRequest;
  const MechanicsMapScreen({super.key, this.breakdownRequest});

  @override
  State<MechanicsMapScreen> createState() => _MechanicsMapScreenState();
}

class _MechanicsMapScreenState extends State<MechanicsMapScreen>
    with TickerProviderStateMixin {

  // ── Map ────────────────────────────────────────────────────
  final _mapCtrl    = MapController();
  LatLng _userLoc   = const LatLng(20.5937, 78.9629);
  bool   _locReady  = false;

  // ── Data ───────────────────────────────────────────────────
  List<MechanicModel> _mechanics = [];
  bool   _loading        = true;
  String _filter         = 'All';
  static const _filters  = ['All','Puncture','Engine','AC','Battery','Towing','Emergency'];

  // ── Selection ──────────────────────────────────────────────
  MechanicModel? _selected;

  // ── Bottom sheet controller ────────────────────────────────
  final DraggableScrollableController _sheetCtrl = DraggableScrollableController();

  // ── Detail sheet animation ─────────────────────────────────
  late AnimationController _detailAnim;
  late Animation<Offset>   _detailSlide;

  @override
  void initState() {
    super.initState();
    _detailAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _detailSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _detailAnim, curve: Curves.easeOutCubic));
    _init();
  }

  @override
  void dispose() {
    _detailAnim.dispose();
    _mapCtrl.dispose();
    _sheetCtrl.dispose();
    super.dispose();
  }

  // ── Init ───────────────────────────────────────────────────
  Future<void> _init() async {
    if (widget.breakdownRequest != null) {
      _userLoc  = LatLng(widget.breakdownRequest!.latitude, widget.breakdownRequest!.longitude);
      _locReady = true;
    } else {
      final pos = await LocationService().getCurrentPosition();
      if (pos != null && mounted) {
        _userLoc  = LatLng(pos.latitude, pos.longitude);
        _locReady = true;
      }
    }
    await _loadMechanics();
    if (mounted && _locReady) _mapCtrl.move(_userLoc, 14.5);
  }

  Future<void> _loadMechanics() async {
    if (!mounted) return;
    setState(() { _loading = true; _mechanics = []; });

    List<MechanicModel> result = [];
    try {
      result = await ApiService().getNearbyMechanics(
        lat: _userLoc.latitude,
        lng: _userLoc.longitude,
        specialization: _filter == 'All' ? null : _filter.toLowerCase(),
      );
    } catch (_) {
      result = _filter == 'All'
          ? MockMechanicService().getNearby(userLocation: _userLoc)
          : MockMechanicService().getBySpecialization(
              userLocation: _userLoc, specialization: _filter);
    }

    if (mounted) setState(() { _mechanics = result; _loading = false; });
  }

  void _selectMechanic(MechanicModel m) {
    setState(() => _selected = m);
    _detailAnim.forward();
    _mapCtrl.move(LatLng(m.lat, m.lng), 16.0);
    HapticFeedback.lightImpact();
    // Collapse list sheet so detail is visible
    _sheetCtrl.animateTo(0.08,
        duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  void _deselect() {
    _detailAnim.reverse().then((_) {
      if (mounted) setState(() => _selected = null);
    });
  }

  Future<void> _call(String? phone) async {
    if (phone == null) return;
    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  Future<void> _requestMechanic(MechanicModel m) async {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Request Sent!', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          '${m.shopName} ko request bhej di gayi hai.\nWoh jald hi contact karenge.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.bg,
      body: Stack(children: [

        // ── FULL SCREEN MAP ───────────────────────────────────
        _buildMap(),

        // ── TOP OVERLAY: back + title + filter chips ──────────
        Positioned(
          top: 0, left: 0, right: 0,
          child: _buildTopBar(),
        ),

        // ── MECHANICS LIST BOTTOM SHEET ───────────────────────
        if (!_loading && _mechanics.isNotEmpty)
          _buildListSheet(),

        // ── LOADING INDICATOR ─────────────────────────────────
        if (_loading)
          Positioned(
            bottom: 120, left: 0, right: 0,
            child: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          ),

        // ── SELECTED MECHANIC DETAIL SHEET ────────────────────
        if (_selected != null)
          _buildDetailSheet(),

        // ── FLOATING BUTTONS (right side) ─────────────────────
        Positioned(
          right: 16,
          bottom: _mechanics.isNotEmpty ? 200 : 24,
          child: _buildFloatingButtons(),
        ),

        // ── SOS BUTTON (bottom-right) ─────────────────────────
        Positioned(
          right: 16,
          bottom: _mechanics.isNotEmpty ? 140 : 24,
          child: _buildSosButton(),
        ),

      ]),
    );
  }

  // ── MAP LAYER ──────────────────────────────────────────────
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapCtrl,
      options: MapOptions(
        initialCenter: _userLoc,
        initialZoom: 14.5,
        onTap: (_, __) => _deselect(),
      ),
      children: [
        // OSM Tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.raahi.app',
          tileProvider: NetworkTileProvider(),
        ),

        // Mechanic markers
        MarkerLayer(
          markers: _mechanics.map((m) => _mechanicMarker(m)).toList(),
        ),

        // User location marker
        if (_locReady)
          MarkerLayer(markers: [_userMarker()]),

        // Breakdown location marker (if passed)
        if (widget.breakdownRequest != null)
          MarkerLayer(markers: [_breakdownMarker()]),
      ],
    );
  }

  Marker _mechanicMarker(MechanicModel m) {
    final isAvailable = m.isOpen;
    final isSelected  = _selected?.id == m.id;
    return Marker(
      point: LatLng(m.lat, m.lng),
      width: isSelected ? 52 : 44,
      height: isSelected ? 62 : 52,
      child: GestureDetector(
        onTap: () => _selectMechanic(m),
        child: _PinWidget(
          color: isAvailable ? AppTheme.green : AppTheme.red,
          icon: Icons.build_rounded,
          label: m.shopName,
          isSelected: isSelected,
        ),
      ),
    );
  }

  Marker _userMarker() => Marker(
    point: _userLoc,
    width: 50,
    height: 50,
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primary,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.5), blurRadius: 12)],
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
    ),
  );

  Marker _breakdownMarker() => Marker(
    point: LatLng(widget.breakdownRequest!.latitude, widget.breakdownRequest!.longitude),
    width: 44,
    height: 52,
    child: _PinWidget(
      color: AppTheme.yellow,
      icon: Icons.car_crash_rounded,
      label: 'Breakdown',
      isSelected: false,
    ),
  );

  // ── TOP BAR ────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 12, right: 12, bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [AppTheme.bg.withOpacity(0.95), Colors.transparent],
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Back + Title row
        Row(children: [
          _FloatBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => context.pop(),
            tooltip: 'Back',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Nearby Mechanics',
                  style: TextStyle(color: AppTheme.textPrimary,
                      fontSize: 17, fontWeight: FontWeight.w700)),
              Text(
                _loading ? 'Dhundh raha hai...'
                    : _mechanics.isEmpty ? 'Koi mechanic nahi mila'
                    : '${_mechanics.where((m) => m.isOpen).length} available  •  ${_mechanics.length} total',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ]),
          ),
          _FloatBtn(
            icon: Icons.refresh_rounded,
            onTap: _loadMechanics,
            tooltip: 'Refresh',
          ),
        ]),

        const SizedBox(height: 8),

        // Filter chips
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemCount: _filters.length,
            itemBuilder: (_, i) {
              final f = _filters[i];
              final selected = _filter == f;
              return GestureDetector(
                onTap: () { setState(() => _filter = f); _loadMechanics(); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary : AppTheme.cardBg.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppTheme.primary : AppTheme.cardBorder),
                  ),
                  child: Text(f,
                    style: TextStyle(
                      color: selected ? Colors.white : AppTheme.textSecondary,
                      fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  // ── MECHANICS LIST SHEET ───────────────────────────────────
  Widget _buildListSheet() {
    return DraggableScrollableSheet(
      controller: _sheetCtrl,
      initialChildSize: 0.32,
      minChildSize: 0.08,
      maxChildSize: 0.65,
      snap: true,
      snapSizes: const [0.08, 0.32, 0.65],
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 20)],
          ),
          child: Column(children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.cardBorder,
                borderRadius: BorderRadius.circular(2)),
            ),
            // Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                const Icon(Icons.build_circle_outlined, color: AppTheme.primary, size: 16),
                const SizedBox(width: 6),
                Text('${_mechanics.length} mechanics mile',
                  style: const TextStyle(color: AppTheme.textPrimary,
                      fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.green, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text('${_mechanics.where((m) => m.isOpen).length} available',
                      style: const TextStyle(color: AppTheme.green, fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            // Cards list
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 16),
                itemCount: _mechanics.length,
                itemBuilder: (_, i) => _MechanicCard(
                  mechanic: _mechanics[i],
                  isSelected: _selected?.id == _mechanics[i].id,
                  onTap: () => _selectMechanic(_mechanics[i]),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  // ── DETAIL SHEET ───────────────────────────────────────────
  Widget _buildDetailSheet() {
    final m = _selected!;
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: SlideTransition(
        position: _detailSlide,
        child: GestureDetector(
          onVerticalDragEnd: (d) {
            if (d.primaryVelocity != null && d.primaryVelocity! > 200) _deselect();
          },
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 24)],
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Drag handle
              Container(width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(2))),

              // Header row
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Avatar
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.build_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.shopName,
                    style: const TextStyle(color: AppTheme.textPrimary,
                        fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, color: AppTheme.textMuted, size: 13),
                    const SizedBox(width: 3),
                    Expanded(child: Text(m.shopAddress,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 5),
                  Row(children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (m.isOpen ? AppTheme.green : AppTheme.red).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 6, height: 6,
                          decoration: BoxDecoration(
                            color: m.isOpen ? AppTheme.green : AppTheme.red,
                            shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text(m.isOpen ? 'Available' : 'Busy',
                          style: TextStyle(
                            color: m.isOpen ? AppTheme.green : AppTheme.red,
                            fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star_rounded, color: AppTheme.yellow, size: 14),
                    const SizedBox(width: 3),
                    Text('${m.ratingAvg.toStringAsFixed(1)}  •  ${m.totalJobs} jobs',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    if (m.distanceKm != null) ...[
                      const SizedBox(width: 8),
                      Text('${m.distanceKm!.toStringAsFixed(1)} km',
                        style: const TextStyle(color: AppTheme.cyan, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    ],
                  ]),
                ])),
                // Close
                GestureDetector(
                  onTap: _deselect,
                  child: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 22)),
              ]),

              const SizedBox(height: 14),

              // Specializations
              if (m.specializations.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(spacing: 6, runSpacing: 6,
                    children: m.specializations.take(5).map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.cardBorder)),
                      child: Text(s, style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                    )).toList()),
                ),

              const SizedBox(height: 18),

              // Action buttons
              Row(children: [
                // Call
                Expanded(child: GestureDetector(
                  onTap: () => _call(m.phone),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder)),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.call_rounded, color: AppTheme.green, size: 18),
                      SizedBox(width: 8),
                      Text('Call', style: TextStyle(color: AppTheme.green,
                          fontSize: 14, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                )),
                const SizedBox(width: 10),
                // Request
                Expanded(flex: 2, child: GestureDetector(
                  onTap: () => _requestMechanic(m),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(
                        color: AppTheme.primary.withOpacity(0.35),
                        blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.handyman_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Request Mechanic', style: TextStyle(color: Colors.white,
                          fontSize: 14, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                )),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  // ── FLOATING BUTTONS ───────────────────────────────────────
  Widget _buildFloatingButtons() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _FloatBtn(
        icon: Icons.add_rounded,
        onTap: () { _mapCtrl.move(_mapCtrl.camera.center,
            (_mapCtrl.camera.zoom + 1).clamp(5, 18)); },
        tooltip: 'Zoom in',
      ),
      const SizedBox(height: 8),
      _FloatBtn(
        icon: Icons.remove_rounded,
        onTap: () { _mapCtrl.move(_mapCtrl.camera.center,
            (_mapCtrl.camera.zoom - 1).clamp(5, 18)); },
        tooltip: 'Zoom out',
      ),
      const SizedBox(height: 8),
      _FloatBtn(
        icon: Icons.my_location_rounded,
        onTap: () { if (_locReady) _mapCtrl.move(_userLoc, 15.0); },
        tooltip: 'My location',
        accent: true,
      ),
    ]);
  }

  // ── SOS BUTTON ─────────────────────────────────────────────
  Widget _buildSosButton() {
    return GestureDetector(
      onTap: () { HapticFeedback.heavyImpact(); context.push('/sos'); },
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: AppTheme.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppTheme.red.withOpacity(0.5),
                blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sos_rounded, color: Colors.white, size: 22),
            Text('SOS', style: TextStyle(color: Colors.white,
                fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ── PIN WIDGET ─────────────────────────────────────────────
class _PinWidget extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final bool isSelected;

  const _PinWidget({
    required this.color,
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (isSelected)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          margin: const EdgeInsets.only(bottom: 3),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.4))),
          child: Text(label,
            style: const TextStyle(color: AppTheme.textPrimary,
                fontSize: 9, fontWeight: FontWeight.w700),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      Container(
        width: isSelected ? 38 : 32,
        height: isSelected ? 38 : 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: isSelected ? 2.5 : 2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.4),
              blurRadius: isSelected ? 12 : 6)],
        ),
        child: Icon(icon, color: Colors.white, size: isSelected ? 18 : 15),
      ),
      // Pin tail
      CustomPaint(
        size: const Size(10, 6),
        painter: _PinTailPainter(color: color),
      ),
    ]);
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;
  const _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter old) => old.color != color;
}

// ── MECHANIC CARD ──────────────────────────────────────────
class _MechanicCard extends StatelessWidget {
  final MechanicModel mechanic;
  final bool isSelected;
  final VoidCallback onTap;

  const _MechanicCard({
    required this.mechanic,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final m = mechanic;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceHigh : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          // Status dot + icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: (m.isOpen ? AppTheme.green : AppTheme.red).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (m.isOpen ? AppTheme.green : AppTheme.red).withOpacity(0.3)),
            ),
            child: Icon(Icons.build_rounded,
              color: m.isOpen ? AppTheme.green : AppTheme.red, size: 20),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.shopName,
              style: const TextStyle(color: AppTheme.textPrimary,
                  fontSize: 13, fontWeight: FontWeight.w700),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.star_rounded, color: AppTheme.yellow, size: 12),
              const SizedBox(width: 3),
              Text('${m.ratingAvg.toStringAsFixed(1)}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const SizedBox(width: 6),
              Expanded(child: Text(
                m.specializations.take(2).join(' • '),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ])),
          // Right: distance + status
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (m.distanceKm != null)
              Text('${m.distanceKm!.toStringAsFixed(1)} km',
                style: const TextStyle(color: AppTheme.cyan,
                    fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: (m.isOpen ? AppTheme.green : AppTheme.red).withOpacity(0.12),
                borderRadius: BorderRadius.circular(6)),
              child: Text(m.isOpen ? '● Open' : '● Busy',
                style: TextStyle(
                  color: m.isOpen ? AppTheme.green : AppTheme.red,
                  fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── FLOATING BUTTON ────────────────────────────────────────
class _FloatBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool accent;

  const _FloatBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        color: accent ? AppTheme.primary : AppTheme.cardBg,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
      ),
      child: Icon(icon,
        color: accent ? Colors.white : AppTheme.textPrimary, size: 18),
    ),
  );
}
