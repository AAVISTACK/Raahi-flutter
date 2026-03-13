// ============================================================
// lib/screens/breakdown/breakdown_location_picker_screen.dart
//
// Uber-style location picker using OpenStreetMap (flutter_map).
// • Centers map on GPS location on launch
// • Centered pin stays fixed; map drags underneath
// • "Confirm Breakdown Location" returns lat/lng to caller
// • Returns a BreakdownRequest when confirmed
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_theme.dart';
import '../../models/breakdown_request.dart';
import '../../services/location_service.dart';
import '../../widgets/ui_components.dart';

class BreakdownLocationPickerScreen extends StatefulWidget {
  /// Optional pre-filled issue description (e.g. from AI diagnosis result)
  final String initialIssue;

  const BreakdownLocationPickerScreen({
    super.key,
    this.initialIssue = '',
  });

  @override
  State<BreakdownLocationPickerScreen> createState() =>
      _BreakdownLocationPickerScreenState();
}

class _BreakdownLocationPickerScreenState
    extends State<BreakdownLocationPickerScreen>
    with TickerProviderStateMixin {

  // ── Map state ─────────────────────────────────────────────
  final MapController _mapCtrl = MapController();

  // Default: India center — overridden once GPS resolves
  LatLng _center = const LatLng(20.5937, 78.9629);
  bool _locationReady = false;
  bool _fetchingLocation = true;
  bool _isMoving = false;

  // ── Confirm button state ───────────────────────────────────
  bool _confirming = false;

  // ── Pin bounce animation ───────────────────────────────────
  late AnimationController _pinCtrl;
  late Animation<double> _pinAnim;

  // ── Slide-up panel animation ───────────────────────────────
  late AnimationController _panelCtrl;
  late Animation<Offset> _panelSlide;

  // ── Address display ────────────────────────────────────────
  String _addressLabel = 'Fetching location...';

  @override
  void initState() {
    super.initState();

    // Pin bounce on drop
    _pinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _pinAnim = Tween<double>(begin: -12, end: 0).animate(
      CurvedAnimation(parent: _pinCtrl, curve: Curves.bounceOut));

    // Bottom panel slides up
    _panelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _panelSlide = Tween<Offset>(
      begin: const Offset(0, 1), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _panelCtrl, curve: Curves.easeOutCubic));

    _initLocation();
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _panelCtrl.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }

  // ── Get GPS, center map ────────────────────────────────────
  Future<void> _initLocation() async {
    setState(() => _fetchingLocation = true);

    final pos = await LocationService().getCurrentPosition();

    if (pos != null && mounted) {
      final ll = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _center = ll;
        _locationReady = true;
        _fetchingLocation = false;
      });
      _mapCtrl.move(ll, 16.0);
      _updateAddressLabel(ll);
      _pinCtrl.forward();
      _panelCtrl.forward();
    } else if (mounted) {
      setState(() {
        _fetchingLocation = false;
        _addressLabel = 'GPS unavailable — drag to set location';
      });
      _panelCtrl.forward();
    }
  }

  // ── Update address text when map stops ─────────────────────
  void _updateAddressLabel(LatLng ll) {
    // Shows coordinates; replace with reverse geocoding if geocoding package used
    setState(() {
      _addressLabel =
          '${ll.latitude.toStringAsFixed(5)}° N, '
          '${ll.longitude.toStringAsFixed(5)}° E';
    });
  }

  // ── Called when map is tapped/dragged ─────────────────────
  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveStart) {
      setState(() => _isMoving = true);
      _pinCtrl.reverse();
    } else if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
      final newCenter = _mapCtrl.camera.center;
      setState(() {
        _center = newCenter;
        _isMoving = false;
      });
      _pinCtrl.forward();
      _updateAddressLabel(newCenter);
    }
  }

  // ── Confirm and return ─────────────────────────────────────
  Future<void> _confirmLocation() async {
    setState(() => _confirming = true);
    HapticFeedback.mediumImpact();

    final request = BreakdownRequest(
      latitude: _center.latitude,
      longitude: _center.longitude,
      issueDescription: widget.initialIssue.isNotEmpty
          ? widget.initialIssue
          : 'Breakdown at selected location',
      timestamp: DateTime.now(),
    );

    await Future.delayed(const Duration(milliseconds: 200)); // tactile pause

    if (mounted) {
      Navigator.of(context).pop(request);
    }
  }

  // ── Re-center on GPS ───────────────────────────────────────
  Future<void> _recenter() async {
    final pos = await LocationService().getCurrentPosition();
    if (pos != null && mounted) {
      final ll = LatLng(pos.latitude, pos.longitude);
      _mapCtrl.move(ll, 16.0);
      setState(() => _center = ll);
      _updateAddressLabel(ll);
    }
  }

  // ── BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // ── Map fills entire screen
          _buildMap(),

          // ── Centered crosshair pin (fixed to screen center)
          _buildCenteredPin(),

          // ── Top gradient fade so AppBar blends into map
          _buildTopGradient(),

          // ── GPS loading overlay
          if (_fetchingLocation) _buildLoadingOverlay(),

          // ── Right-side recenter FAB
          _buildRecenterButton(),

          // ── Bottom panel
          _buildBottomPanel(),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      leading: Pressable(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.bg.withOpacity(0.85),
            borderRadius: BorderRadius.circular(AppTheme.r12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: const Icon(Icons.arrow_back_rounded,
              color: AppTheme.textPrimary, size: 20),
        ),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.bg.withOpacity(0.88),
          borderRadius: BorderRadius.circular(AppTheme.r12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.car_repair_rounded,
              color: AppTheme.primary, size: 16),
          const SizedBox(width: 7),
          const Text('Set Breakdown Location',
            style: TextStyle(
              fontFamily: 'Rajdhani', fontSize: 15,
              fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ]),
      ),
      centerTitle: true,
    );
  }

  // ── Map ────────────────────────────────────────────────────
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapCtrl,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 14.0,
        minZoom: 5.0,
        maxZoom: 18.0,
        onMapEvent: _onMapEvent,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        // OSM tile layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.raahi.app',
          tileBuilder: _darkTileBuilder,
          maxZoom: 18,
        ),

        // User's GPS dot (blue dot)
        if (_locationReady)
          MarkerLayer(markers: [
            Marker(
              point: _center,
              width: 20, height: 20,
              child: Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withOpacity(0.4),
                        blurRadius: 8, spreadRadius: 2),
                  ],
                ),
              ),
            ),
          ]),
      ],
    );
  }

  // Subtle dark tint on OSM tiles to match app theme
  Widget _darkTileBuilder(BuildContext context, Widget tile,
      TileImage tileImage) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.82, 0, 0, 0, 0,
        0, 0.85, 0, 0, 0,
        0, 0, 0.90, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: tile,
    );
  }

  // ── Centered pin (stays fixed on screen, map moves under it)
  Widget _buildCenteredPin() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dragging lift effect
          AnimatedBuilder(
            animation: _pinAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _pinAnim.value - (_isMoving ? 8 : 0)),
              child: child,
            ),
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(_isMoving ? 0.55 : 0.38),
                    blurRadius: _isMoving ? 28 : 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.car_repair_rounded,
                  color: Colors.white, size: 26),
            ),
          ),
          // Pin stem
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 2.5,
            height: _isMoving ? 22 : 14,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Shadow dot on map
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: _isMoving ? 18 : 10,
            height: _isMoving ? 18 : 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.25),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top gradient ───────────────────────────────────────────
  Widget _buildTopGradient() {
    return Positioned(
      top: 0, left: 0, right: 0,
      height: 110,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.bg.withOpacity(0.65),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Loading overlay ────────────────────────────────────────
  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: AppTheme.bg.withOpacity(0.55),
          child: const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(width: 32, height: 32,
                child: CircularProgressIndicator(
                    color: AppTheme.primary, strokeWidth: 3)),
              SizedBox(height: 14),
              Text('Finding your location...',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Recenter FAB ───────────────────────────────────────────
  Widget _buildRecenterButton() {
    return Positioned(
      right: 16,
      bottom: 200, // above bottom panel
      child: Pressable(
        onTap: _recenter,
        child: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(AppTheme.r12),
            border: Border.all(color: AppTheme.cardBorder),
            boxShadow: AppTheme.cardShadow,
          ),
          child: const Icon(Icons.my_location_rounded,
              color: AppTheme.primary, size: 22),
        ),
      ),
    );
  }

  // ── Bottom panel ───────────────────────────────────────────
  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: SlideTransition(
        position: _panelSlide,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: const Border(top: BorderSide(color: AppTheme.cardBorder)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.4),
                  blurRadius: 32, offset: const Offset(0, -8)),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Handle bar
                Container(width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBorder,
                    borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 16),

                // Location label card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHigh,
                    borderRadius: BorderRadius.circular(AppTheme.r12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.location_on_rounded,
                          color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Breakdown location',
                          style: TextStyle(color: AppTheme.textMuted,
                              fontSize: 10, letterSpacing: 0.5)),
                        const SizedBox(height: 3),
                        Text(_addressLabel,
                          style: const TextStyle(color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    )),
                    if (_isMoving)
                      const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.primary)),
                  ]),
                ),

                const SizedBox(height: 12),

                // Confirm button
                GlowButton(
                  label: 'Confirm Breakdown Location',
                  icon: Icons.check_circle_rounded,
                  height: 56,
                  fontSize: 17,
                  radius: AppTheme.r16,
                  isLoading: _confirming,
                  onTap: _fetchingLocation || _isMoving ? null : _confirmLocation,
                ),

                const SizedBox(height: 8),

                Text(
                  'Drag the map to adjust your exact location',
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
