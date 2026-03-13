// ============================================================
// lib/screens/mechanic/mechanics_map_screen.dart  — v2
//
// Uber-style nearby mechanics screen.
// • OSM map with two marker types: breakdown (red car) + mechanic (blue wrench)
// • Tap mechanic marker → bottom sheet with details + call + request
// • Scrollable "Nearby Mechanics" list below map, sorted by distance
// • Retains existing filter bar and mechanic card UI
// • Falls back to mock data when backend is unavailable
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
import '../../widgets/ui_components.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../utils/constants.dart';

class MechanicsMapScreen extends StatefulWidget {
  /// If opened from BreakdownLocationPickerScreen, the confirmed request
  /// is passed in so the map pre-centers on it.
  final BreakdownRequest? breakdownRequest;

  const MechanicsMapScreen({super.key, this.breakdownRequest});

  @override
  State<MechanicsMapScreen> createState() => _MechanicsMapScreenState();
}

class _MechanicsMapScreenState extends State<MechanicsMapScreen>
    with TickerProviderStateMixin {

  // ── Map ────────────────────────────────────────────────────
  final _mapCtrl = MapController();
  LatLng _userLocation = const LatLng(20.5937, 78.9629); // India default
  bool _locationReady = false;

  // ── Data ───────────────────────────────────────────────────
  List<MechanicModel> _mechanics = [];
  bool _loading = true;
  String _selectedFilter = 'All';
  final _filters = ['All', 'Puncture', 'Engine', 'AC', 'Battery', 'Towing', 'Emergency'];

  // ── Selected marker ────────────────────────────────────────
  MechanicModel? _selected;

  // ── Panel animation ────────────────────────────────────────
  late AnimationController _sheetCtrl;
  late Animation<Offset> _sheetSlide;

  // ── Map/list toggle ────────────────────────────────────────
  bool _showMap = true;

  @override
  void initState() {
    super.initState();
    _sheetCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 320));
    _sheetSlide = Tween<Offset>(
        begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOutCubic));
    _init();
  }

  @override
  void dispose() {
    _sheetCtrl.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }

  // ── Init: get location → load mechanics ───────────────────
  Future<void> _init() async {
    // If breakdown location was passed in, use it as center
    if (widget.breakdownRequest != null) {
      _userLocation = LatLng(
        widget.breakdownRequest!.latitude,
        widget.breakdownRequest!.longitude,
      );
      _locationReady = true;
    } else {
      final pos = await LocationService().getCurrentPosition();
      if (pos != null && mounted) {
        _userLocation = LatLng(pos.latitude, pos.longitude);
        _locationReady = true;
      }
    }
    await _loadMechanics();
    if (mounted && _locationReady) {
      _mapCtrl.move(_userLocation, 15.0);
    }
  }

  // ── Load mechanics (backend with mock fallback) ────────────
  Future<void> _loadMechanics() async {
    if (!mounted) return;
    setState(() { _loading = true; _mechanics = []; });

    List<MechanicModel> result = [];

    // Try backend first
    try {
      result = await ApiService().getNearbyMechanics(
        lat: _userLocation.latitude,
        lng: _userLocation.longitude,
        specialization: _selectedFilter == 'All' ? null : _selectedFilter.toLowerCase(),
      );
    } catch (_) {
      // Backend unavailable — use mock data
      result = _selectedFilter == 'All'
          ? MockMechanicService().getNearby(userLocation: _userLocation)
          : MockMechanicService().getBySpecialization(
              userLocation: _userLocation,
              specialization: _selectedFilter);
    }

    if (mounted) setState(() { _mechanics = result; _loading = false; });
  }

  // ── Tap mechanic ───────────────────────────────────────────
  void _selectMechanic(MechanicModel m) {
    setState(() => _selected = m);
    _sheetCtrl.forward();
    // Pan map to mechanic location
    _mapCtrl.move(LatLng(m.lat, m.lng), 16.0);
    HapticFeedback.lightImpact();
  }

  void _deselect() {
    _sheetCtrl.reverse().then((_) {
      if (mounted) setState(() => _selected = null);
    });
  }

  // ── Phone call ─────────────────────────────────────────────
  Future<void> _callMechanic(String? phone) async {
    if (phone == null) return;
    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  // ── BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(children: [
        _buildAppBar(),
        _buildFilterBar(),
        // Map / List toggle buttons
        _buildViewToggle(),
        Expanded(child: _showMap ? _buildMapView() : _buildListView()),
      ]),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      color: AppTheme.navyLight,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 6, right: 16, bottom: 8,
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nearby Mechanics',
              style: TextStyle(fontFamily: 'Rajdhani', fontSize: 19,
                  fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            Text('Tap a marker to see details',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ])),
        // Register shop FAB
        Pressable(
          onTap: () => context.push('/mechanic-register'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.r12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_business_rounded, color: AppTheme.primary, size: 15),
              SizedBox(width: 5),
              Text('Register', style: TextStyle(color: AppTheme.primary,
                  fontSize: 11, fontWeight: FontWeight.w700)),
            ])),
        ),
      ]),
    );
  }

  // ── Filter chips ───────────────────────────────────────────
  Widget _buildFilterBar() {
    return Container(
      height: 46,
      color: AppTheme.navyLight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final f = _filters[i];
          final sel = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Pressable(
              onTap: () {
                setState(() => _selectedFilter = f);
                _loadMechanics();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel ? AppTheme.primary : AppTheme.cardBorder)),
                child: Center(child: Text(f, style: TextStyle(
                  color: sel ? Colors.white : AppTheme.textSecondary,
                  fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500))),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Map / List toggle ──────────────────────────────────────
  Widget _buildViewToggle() {
    return Container(
      color: AppTheme.navyLight,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.cardBorder)),
        child: Row(children: [
          _ToggleBtn(
            label: 'Map', icon: Icons.map_rounded,
            active: _showMap,
            onTap: () => setState(() => _showMap = true)),
          _ToggleBtn(
            label: 'List', icon: Icons.format_list_bulleted_rounded,
            active: !_showMap,
            onTap: () => setState(() => _showMap = false)),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // MAP VIEW
  // ══════════════════════════════════════════════════════════
  Widget _buildMapView() {
    return Stack(children: [
      // ── Map
      FlutterMap(
        mapController: _mapCtrl,
        options: MapOptions(
          initialCenter: _userLocation,
          initialZoom: 15.0,
          minZoom: 10.0,
          maxZoom: 18.0,
          onTap: (_, __) => _deselect(),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
        ),
        children: [
          // OSM tiles with dark tint
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.raahi.app',
            tileBuilder: _darkTile,
            maxZoom: 18,
          ),

          // ── Mechanic markers (blue wrench)
          if (!_loading)
            MarkerLayer(markers: _mechanics.map((m) {
              final isSelected = _selected?.id == m.id;
              return Marker(
                point: LatLng(m.lat, m.lng),
                width: isSelected ? 56 : 46,
                height: isSelected ? 56 : 46,
                child: _MechanicMarker(
                  mechanic: m,
                  selected: isSelected,
                  onTap: () => _selectMechanic(m),
                ),
              );
            }).toList()),

          // ── Breakdown location marker (red car icon)
          if (widget.breakdownRequest != null)
            MarkerLayer(markers: [
              Marker(
                point: LatLng(
                  widget.breakdownRequest!.latitude,
                  widget.breakdownRequest!.longitude),
                width: 52, height: 60,
                child: _BreakdownMarker(),
              ),
            ]),

          // ── User blue dot
          if (_locationReady && widget.breakdownRequest == null)
            MarkerLayer(markers: [
              Marker(
                point: _userLocation,
                width: 22, height: 22,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4285F4),
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [BoxShadow(
                      color: const Color(0xFF4285F4).withOpacity(0.4),
                      blurRadius: 8, spreadRadius: 2)]),
                ),
              ),
            ]),
        ],
      ),

      // ── Loading overlay
      if (_loading) Positioned.fill(child: IgnorePointer(
        child: Container(
          color: AppTheme.bg.withOpacity(0.45),
          child: const Center(child: CircularProgressIndicator(
              color: AppTheme.primary, strokeWidth: 3)),
        ),
      )),

      // ── Recenter FAB
      Positioned(
        right: 12, top: 12,
        child: Pressable(
          onTap: () => _mapCtrl.move(_userLocation, 15.0),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.r12),
              border: Border.all(color: AppTheme.cardBorder),
              boxShadow: AppTheme.cardShadow),
            child: const Icon(Icons.my_location_rounded,
                color: AppTheme.primary, size: 20)),
        ),
      ),

      // ── Mechanic count badge
      Positioned(
        left: 12, top: 12,
        child: AnimatedOpacity(
          opacity: _loading ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.cardBg.withOpacity(0.92),
              borderRadius: BorderRadius.circular(AppTheme.r12),
              border: Border.all(color: AppTheme.cardBorder)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: _mechanics.isNotEmpty ? AppTheme.green : AppTheme.textMuted)),
              const SizedBox(width: 6),
              Text('${_mechanics.length} mechanics found',
                style: const TextStyle(color: AppTheme.textSecondary,
                    fontSize: 11, fontWeight: FontWeight.w600)),
            ])),
        ),
      ),

      // ── Bottom: Mechanic detail sheet + list section
      Positioned(
        bottom: 0, left: 0, right: 0,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Selected mechanic bottom sheet
          if (_selected != null)
            SlideTransition(
              position: _sheetSlide,
              child: _MechanicDetailSheet(
                mechanic: _selected!,
                onClose: _deselect,
                onCall: () => _callMechanic(_selected!.phone),
                onRequest: () {
                  _deselect();
                  context.push('/request-help');
                },
              ),
            ),

          // Compact list strip at bottom when no mechanic selected
          if (_selected == null && !_loading && _mechanics.isNotEmpty)
            _buildMapBottomStrip(),
        ]),
      ),
    ]);
  }

  // ── Compact horizontal mechanic strip below map ────────────
  Widget _buildMapBottomStrip() {
    return Container(
      height: 130,
      color: AppTheme.bg.withOpacity(0.94),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(children: [
            const Text('Nearby Mechanics',
              style: TextStyle(fontFamily: 'Rajdhani', fontSize: 15,
                  fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6)),
              child: Text('${_mechanics.length}',
                style: const TextStyle(color: AppTheme.primary,
                    fontSize: 11, fontWeight: FontWeight.w700))),
            const Spacer(),
            Pressable(
              onTap: () => setState(() => _showMap = false),
              child: const Text('See all →',
                style: TextStyle(color: AppTheme.primary, fontSize: 12,
                    fontWeight: FontWeight.w600))),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            itemCount: _mechanics.length,
            itemBuilder: (_, i) => _MechanicChip(
              mechanic: _mechanics[i],
              onTap: () => _selectMechanic(_mechanics[i]),
            ),
          ),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════
  // LIST VIEW (full scrollable list)
  // ══════════════════════════════════════════════════════════
  Widget _buildListView() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_mechanics.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.build_circle_outlined, color: AppTheme.textMuted, size: 56),
          const SizedBox(height: 14),
          const Text('No mechanics found nearby',
            style: TextStyle(color: AppTheme.textSecondary,
                fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Try a different filter or expand your search',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 20),
          Pressable(
            onTap: () { setState(() => _selectedFilter = 'All'); _loadMechanics(); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.r12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
              child: const Text('Reset Filter',
                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)))),
        ]));
    }

    // Interleave ad after every 3rd real card
    final totalItems = _mechanics.length + (_mechanics.length ~/ 3);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      itemCount: totalItems + 1, // +1 for section header
      itemBuilder: (_, rawIdx) {
        if (rawIdx == 0) return _buildListHeader();
        final i = rawIdx - 1;
        if ((i + 1) % 4 == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: AdBannerWidget(adUnitId: AppConstants.bannerMechanicId));
        }
        final mechIdx = i - (i ~/ 4);
        if (mechIdx >= _mechanics.length) return const SizedBox.shrink();
        final m = _mechanics[mechIdx];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _MechanicCard(
            mechanic: m,
            onTap: () {
              setState(() => _showMap = true);
              WidgetsBinding.instance.addPostFrameCallback((_) => _selectMechanic(m));
            },
            onCall: () => _callMechanic(m.phone),
          ),
        );
      },
    );
  }

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        const Text('Sorted by distance',
          style: TextStyle(fontFamily: 'Rajdhani', fontSize: 14,
              fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primary.withOpacity(0.25))),
          child: Text('${_mechanics.length} found',
            style: const TextStyle(color: AppTheme.primary,
                fontSize: 11, fontWeight: FontWeight.w700))),
      ]),
    );
  }

  // ── Dark tile builder ──────────────────────────────────────
  Widget _darkTile(BuildContext ctx, Widget tile, TileImage img) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.80, 0, 0, 0, 0,
        0, 0.83, 0, 0, 0,
        0, 0, 0.88, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: tile,
    );
  }
}

// ════════════════════════════════════════════════════════════
// MARKER — Mechanic (blue wrench circle)
// ════════════════════════════════════════════════════════════
class _MechanicMarker extends StatelessWidget {
  final MechanicModel mechanic;
  final bool selected;
  final VoidCallback onTap;
  const _MechanicMarker(
      {required this.mechanic, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: selected ? 56 : 46,
        height: selected ? 56 : 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppTheme.cyan : const Color(0xFF1565C0),
          border: Border.all(color: Colors.white, width: selected ? 3 : 2),
          boxShadow: [
            BoxShadow(
              color: (selected ? AppTheme.cyan : const Color(0xFF1565C0))
                  .withOpacity(selected ? 0.6 : 0.4),
              blurRadius: selected ? 20 : 10,
              spreadRadius: selected ? 3 : 1),
          ],
        ),
        child: Icon(
          Icons.build_rounded,
          color: Colors.white,
          size: selected ? 24 : 20,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// MARKER — Breakdown location (red car icon)
// ════════════════════════════════════════════════════════════
class _BreakdownMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.red,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [BoxShadow(
            color: AppTheme.red.withOpacity(0.55),
            blurRadius: 16, spreadRadius: 2)]),
        child: const Icon(Icons.car_repair_rounded, color: Colors.white, size: 24)),
      // Stem
      Container(width: 2.5, height: 8,
        color: AppTheme.red.withOpacity(0.8)),
      // Shadow dot
      Container(width: 8, height: 4,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4))),
    ]);
  }
}

// ════════════════════════════════════════════════════════════
// BOTTOM SHEET — Mechanic detail (Uber-style)
// ════════════════════════════════════════════════════════════
class _MechanicDetailSheet extends StatelessWidget {
  final MechanicModel mechanic;
  final VoidCallback onClose, onCall, onRequest;
  const _MechanicDetailSheet({
    required this.mechanic,
    required this.onClose,
    required this.onCall,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.r20),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 28, offset: const Offset(0, -4))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle + close
          Row(children: [
            const Spacer(),
            Container(width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(2))),
            const Spacer(),
            GestureDetector(onTap: onClose,
              child: const Icon(Icons.close_rounded,
                  color: AppTheme.textMuted, size: 20)),
          ]),
          const SizedBox(height: 12),

          // Header row
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF0D3366),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.5))),
              child: const Icon(Icons.build_rounded,
                  color: Color(0xFF4DB6FF), size: 26)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(mechanic.shopName,
                    style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 18,
                        fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
                  if (mechanic.isVerified)
                    const Icon(Icons.verified_rounded, color: AppTheme.cyan, size: 16),
                ]),
                const SizedBox(height: 3),
                Text(mechanic.shopAddress,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
          ]),

          const SizedBox(height: 14),

          // Stats row
          Row(children: [
            _Stat(
              icon: Icons.star_rounded, color: AppTheme.yellow,
              value: mechanic.ratingAvg.toStringAsFixed(1),
              label: 'Rating'),
            const SizedBox(width: 10),
            if (mechanic.distanceKm != null)
              _Stat(
                icon: Icons.near_me_rounded, color: AppTheme.cyan,
                value: '${mechanic.distanceKm!.toStringAsFixed(1)} km',
                label: 'Distance'),
            const SizedBox(width: 10),
            _Stat(
              icon: mechanic.isOpen
                  ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: mechanic.isOpen ? AppTheme.green : AppTheme.red,
              value: mechanic.isOpen ? 'Open' : 'Closed',
              label: 'Status'),
            const SizedBox(width: 10),
            _Stat(
              icon: Icons.work_history_rounded, color: AppTheme.primary,
              value: '${mechanic.totalJobs}+',
              label: 'Jobs'),
          ]),

          // Specializations
          if (mechanic.specializations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 6, runSpacing: 6,
              children: mechanic.specializations.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.cardBorder)),
                child: Text(s, style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
              )).toList()),
          ],

          const SizedBox(height: 16),
          const Divider(color: AppTheme.cardBorder, height: 1),
          const SizedBox(height: 14),

          // Action buttons
          Row(children: [
            // Call
            Expanded(
              child: Pressable(
                onTap: onCall,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.r14),
                    border: Border.all(color: AppTheme.green.withOpacity(0.3))),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_rounded, color: AppTheme.green, size: 18),
                      SizedBox(width: 7),
                      Text('Call', style: TextStyle(color: AppTheme.green,
                          fontWeight: FontWeight.w700, fontSize: 15)),
                    ])),
              ),
            ),
            const SizedBox(width: 10),
            // Request assistance
            Expanded(flex: 2,
              child: GlowButton(
                label: 'Request Assistance',
                icon: Icons.emergency_rounded,
                height: 48, fontSize: 15, radius: AppTheme.r14,
                onTap: onRequest,
              )),
          ]),
        ]),
      ),
    );
  }
}

// ── Stat pill ──────────────────────────────────────────────
class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value, label;
  const _Stat({required this.icon, required this.color,
    required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2))),
    child: Column(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color,
          fontWeight: FontWeight.w700, fontSize: 12)),
      Text(label, style: const TextStyle(
          color: AppTheme.textMuted, fontSize: 9)),
    ]),
  ));
}

// ════════════════════════════════════════════════════════════
// COMPACT CHIP — horizontal strip below map
// ════════════════════════════════════════════════════════════
class _MechanicChip extends StatelessWidget {
  final MechanicModel mechanic;
  final VoidCallback onTap;
  const _MechanicChip({required this.mechanic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 190,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.r14),
          border: Border.all(color: AppTheme.cardBorder)),
        child: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0D3366),
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.build_rounded,
                color: Color(0xFF4DB6FF), size: 18)),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(mechanic.shopName,
                style: const TextStyle(color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700, fontSize: 12),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.star_rounded, color: AppTheme.yellow, size: 11),
                const SizedBox(width: 3),
                Text(mechanic.ratingAvg.toStringAsFixed(1),
                  style: const TextStyle(color: AppTheme.yellow,
                      fontSize: 11, fontWeight: FontWeight.w700)),
                if (mechanic.distanceKm != null) ...[
                  const SizedBox(width: 6),
                  Text('${mechanic.distanceKm!.toStringAsFixed(1)} km',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 10)),
                ],
              ]),
            ])),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// FULL LIST CARD — list view
// ════════════════════════════════════════════════════════════
class _MechanicCard extends StatelessWidget {
  final MechanicModel mechanic;
  final VoidCallback onTap, onCall;
  const _MechanicCard(
      {required this.mechanic, required this.onTap, required this.onCall});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.r14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF0D3366),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                    color: const Color(0xFF1565C0).withOpacity(0.4))),
              child: const Icon(Icons.build_rounded,
                  color: Color(0xFF4DB6FF), size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(mechanic.shopName,
                    style: const TextStyle(color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700, fontSize: 15))),
                  if (mechanic.isVerified)
                    const Padding(padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.verified_rounded,
                          color: AppTheme.cyan, size: 15)),
                  if (mechanic.subscriptionTier == 'pro')
                    Container(
                      margin: const EdgeInsets.only(left: 5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.yellow.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4)),
                      child: const Text('PRO', style: TextStyle(
                          color: AppTheme.yellow, fontSize: 9,
                          fontWeight: FontWeight.w800))),
                ]),
                const SizedBox(height: 2),
                Text(mechanic.shopAddress,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
          ]),

          const SizedBox(height: 12),

          Row(children: [
            // Rating
            _Badge(icon: Icons.star_rounded, color: AppTheme.yellow,
                text: mechanic.ratingAvg.toStringAsFixed(1)),
            const SizedBox(width: 7),
            // Distance
            if (mechanic.distanceKm != null)
              _Badge(icon: Icons.near_me_rounded, color: AppTheme.cyan,
                  text: '${mechanic.distanceKm!.toStringAsFixed(1)} km'),
            const SizedBox(width: 7),
            // Open/Closed
            _Badge(
              icon: mechanic.isOpen
                  ? Icons.check_circle_outline_rounded
                  : Icons.cancel_outlined,
              color: mechanic.isOpen ? AppTheme.green : AppTheme.red,
              text: mechanic.isOpen ? 'Open' : 'Closed'),
            const Spacer(),
            // Call button
            Pressable(
              onTap: onCall,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.r12),
                  border: Border.all(color: AppTheme.green.withOpacity(0.3))),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.phone_rounded, color: AppTheme.green, size: 14),
                  SizedBox(width: 5),
                  Text('Call', style: TextStyle(color: AppTheme.green,
                      fontSize: 12, fontWeight: FontWeight.w700)),
                ]))),
          ]),

          if (mechanic.specializations.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 4,
              children: mechanic.specializations.take(4).map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(5)),
                child: Text(s, style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 10)),
              )).toList()),
          ],
        ]),
      ),
    );
  }
}

// ── Small badge pill ───────────────────────────────────────
class _Badge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _Badge({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.2))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 12),
      const SizedBox(width: 3),
      Text(text, style: TextStyle(color: color,
          fontSize: 11, fontWeight: FontWeight.w600)),
    ]));
}

// ── Map/List toggle button ─────────────────────────────────
class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ToggleBtn({required this.label, required this.icon,
    required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 14,
            color: active ? Colors.white : AppTheme.textMuted),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppTheme.textMuted)),
        ]),
      ),
    ),
  );
}
