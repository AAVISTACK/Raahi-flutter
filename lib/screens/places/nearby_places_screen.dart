// ============================================================
// lib/screens/places/nearby_places_screen.dart
// Highway pe nearby dhabas, parking, toilets, ATM, fuel
// OSM Overpass API — completely FREE
// ============================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';

class NearbyPlacesScreen extends StatefulWidget {
  const NearbyPlacesScreen({super.key});
  @override
  State<NearbyPlacesScreen> createState() => _NearbyPlacesScreenState();
}

class _NearbyPlacesScreenState extends State<NearbyPlacesScreen> {
  final _api      = ApiService();
  final _location = LocationService();
  List<dynamic> _places = [];
  bool _loading   = true;
  String _type    = 'dhaba';
  double? _lat, _lng;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      final pos = await _location.getCurrentPosition();
      _lat = pos.latitude;
      _lng = pos.longitude;
      await _loadPlaces();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadPlaces() async {
    if (_lat == null || _lng == null) return;
    setState(() => _loading = true);
    try {
      final res = await _api.get('/daily/places?lat=$_lat&lng=$_lng&type=$_type');
      setState(() { _places = res['places'] ?? []; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _openMap(double lat, double lng, String name) async {
    final url = Uri.parse('https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=16/$lat/$lng');
    if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _call(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        backgroundColor: AppTheme.navyLight,
        title: const Text('Nearby Places',
            style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 20)),
        actions: [
          IconButton(onPressed: _loadPlaces, icon: const Icon(Icons.refresh, color: AppTheme.primary)),
        ],
      ),
      body: Column(children: [
        // Type selector
        Container(
          color: AppTheme.navyLight,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: _placeTypes.entries.map((e) =>
              GestureDetector(
                onTap: () { setState(() => _type = e.key); _loadPlaces(); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: _type == e.key
                        ? (e.value['color'] as Color).withOpacity(0.15)
                        : AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _type == e.key
                          ? (e.value['color'] as Color).withOpacity(0.5)
                          : AppTheme.cardBorder,
                    ),
                  ),
                  child: Row(children: [
                    Text(e.value['icon'] as String, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                    Text(e.value['label'] as String,
                        style: TextStyle(
                          color: _type == e.key
                              ? e.value['color'] as Color
                              : AppTheme.textSecondary,
                          fontSize: 13, fontWeight: FontWeight.w600,
                        )),
                  ]),
                ),
              )).toList(),
          ),
        ),

        // Places list
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _places.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _loadPlaces,
                      color: AppTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: _places.length,
                        itemBuilder: (_, i) => _buildPlaceCard(_places[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _buildPlaceCard(Map place) {
    final meta    = _placeTypes[_type] ?? _placeTypes['dhaba']!;
    final dist    = place['distance'];
    final open24h = place['open24h'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: (meta['color'] as Color).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(meta['icon'] as String,
                style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(place['name'] ?? 'Unknown',
                style: const TextStyle(color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Row(children: [
              Icon(Icons.near_me, size: 12, color: meta['color'] as Color),
              const SizedBox(width: 4),
              Text('${dist ?? '?'} km door',
                  style: TextStyle(color: meta['color'] as Color,
                      fontSize: 12, fontWeight: FontWeight.w600)),
              if (open24h) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('24hr',
                      style: TextStyle(color: AppTheme.green, fontSize: 9,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ]),
          ])),
          // Action buttons
          Row(children: [
            if (place['phone'] != null)
              GestureDetector(
                onTap: () => _call(place['phone']),
                child: Container(
                  width: 36, height: 36,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.call, color: AppTheme.green, size: 18),
                ),
              ),
            GestureDetector(
              onTap: () => _openMap(
                (place['lat'] as num).toDouble(),
                (place['lng'] as num).toDouble(),
                place['name'] ?? '',
              ),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.map_outlined, color: AppTheme.primary, size: 18),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    final meta = _placeTypes[_type]!;
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(meta['icon'] as String, style: TextStyle(fontSize: 48, color: meta['color'] as Color)),
      const SizedBox(height: 12),
      Text('Nearby ${meta['label']} nahi mila',
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      const Text('Radius badha ke try karo',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
    ]));
  }

  static const _placeTypes = {
    'dhaba':   {'icon': '🍽️', 'label': 'Dhabas',    'color': AppTheme.yellow},
    'parking': {'icon': '🅿️', 'label': 'Parking',   'color': AppTheme.cyan},
    'toilet':  {'icon': '🚻', 'label': 'Toilet',    'color': AppTheme.green},
    'atm':     {'icon': '💳', 'label': 'ATM',       'color': AppTheme.purple},
    'fuel':    {'icon': '⛽', 'label': 'Petrol Pump','color': AppTheme.primary},
    'hotel':   {'icon': '🏨', 'label': 'Hotel',     'color': AppTheme.textSecondary},
  };
}
