// ============================================================
// lib/services/mock_mechanic_service.dart
//
// Mock mechanic data service.
// Generates realistic nearby mechanics offset from any LatLng.
// Replace with ApiService().getNearbyMechanics() when backend ready.
// ============================================================

import 'package:latlong2/latlong.dart';
import '../models/models.dart';

class MockMechanicService {
  static final MockMechanicService _i = MockMechanicService._();
  factory MockMechanicService() => _i;
  MockMechanicService._();

  // Distance calculator (latlong2)
  static const _dist = Distance();

  // ── Static seed data ────────────────────────────────────────
  // Offsets are in degrees (~0.001° ≈ 111m). Chosen to scatter
  // mechanics within ~1.5 km of user location.
  static const _seeds = [
    _MechanicSeed(
      id: 'mech_001',
      name: 'Sharma Auto Garage',
      phone: '+91 98765 00001',
      latOffset: 0.0006,  // ~66 m N
      lngOffset: -0.0001, // ~11 m W
      rating: 4.5,
      totalJobs: 312,
      specializations: ['Puncture', 'Engine', 'Oil Change'],
      subscriptionTier: 'pro',
      isVerified: true,
      isOpen: true,
      address: 'Near NH-44, Sector 14',
    ),
    _MechanicSeed(
      id: 'mech_002',
      name: 'City Car Repair',
      phone: '+91 98765 00002',
      latOffset: 0.0013, // ~144 m N
      lngOffset: 0.0014, // ~156 m E
      rating: 4.2,
      totalJobs: 189,
      specializations: ['AC', 'Battery', 'Electrical'],
      subscriptionTier: 'basic',
      isVerified: true,
      isOpen: true,
      address: 'Main Bazaar Road',
    ),
    _MechanicSeed(
      id: 'mech_003',
      name: 'FastFix Mechanics',
      phone: '+91 98765 00003',
      latOffset: -0.0007, // ~77 m S
      lngOffset: -0.0011, // ~122 m W
      rating: 4.7,
      totalJobs: 521,
      specializations: ['Towing', 'Accident Repair', 'Engine'],
      subscriptionTier: 'pro',
      isVerified: true,
      isOpen: true,
      address: 'Industrial Area Phase 2',
    ),
    _MechanicSeed(
      id: 'mech_004',
      name: 'Singh Motors',
      phone: '+91 98765 00004',
      latOffset: 0.0022,  // ~244 m N
      lngOffset: -0.0019, // ~211 m W
      rating: 3.9,
      totalJobs: 98,
      specializations: ['Puncture', 'Oil Change'],
      subscriptionTier: 'basic',
      isVerified: false,
      isOpen: false,
      address: 'Guru Nanak Chowk',
    ),
    _MechanicSeed(
      id: 'mech_005',
      name: 'Highway Rescue Workshop',
      phone: '+91 98765 00005',
      latOffset: -0.0031, // ~344 m S
      lngOffset: 0.0028,  // ~311 m E
      rating: 4.8,
      totalJobs: 744,
      specializations: ['Towing', 'Emergency', 'Puncture', 'Battery'],
      subscriptionTier: 'pro',
      isVerified: true,
      isOpen: true,
      address: 'NH-44 Service Lane, KM 142',
    ),
    _MechanicSeed(
      id: 'mech_006',
      name: 'Ravi Tyre Centre',
      phone: '+91 98765 00006',
      latOffset: 0.0041,  // ~456 m N
      lngOffset: 0.0033,  // ~367 m E
      rating: 4.1,
      totalJobs: 263,
      specializations: ['Puncture', 'Tyre Balancing', 'Wheel Alignment'],
      subscriptionTier: 'basic',
      isVerified: true,
      isOpen: true,
      address: 'Near Bus Stand, Market Road',
    ),
    _MechanicSeed(
      id: 'mech_007',
      name: 'Quick Battery Point',
      phone: '+91 98765 00007',
      latOffset: -0.0055, // ~611 m S
      lngOffset: -0.0042, // ~467 m W
      rating: 4.3,
      totalJobs: 157,
      specializations: ['Battery', 'Electrical', 'Jumpstart'],
      subscriptionTier: 'basic',
      isVerified: false,
      isOpen: true,
      address: 'Opposite Petrol Pump, GT Road',
    ),
    _MechanicSeed(
      id: 'mech_008',
      name: 'Verma Auto Works',
      phone: '+91 98765 00008',
      latOffset: 0.0068,  // ~755 m N
      lngOffset: -0.0057, // ~633 m W
      rating: 4.6,
      totalJobs: 389,
      specializations: ['Engine', 'AC', 'Suspension', 'Oil Change'],
      subscriptionTier: 'pro',
      isVerified: true,
      isOpen: false,
      address: 'Transport Nagar, Block C',
    ),
  ];

  // ── Public API ──────────────────────────────────────────────

  /// Returns mechanics near [userLocation], sorted by distance.
  /// [radiusKm] filters out mechanics beyond this range.
  List<MechanicModel> getNearby({
    required LatLng userLocation,
    double radiusKm = 5.0,
  }) {
    final result = <MechanicModel>[];

    for (final seed in _seeds) {
      final mechLat = userLocation.latitude + seed.latOffset;
      final mechLng = userLocation.longitude + seed.lngOffset;
      final mechLL = LatLng(mechLat, mechLng);

      // Distance in km
      final distM = _dist.as(
        LengthUnit.Meter,
        userLocation,
        mechLL,
      );
      final distKm = distM / 1000;

      if (distKm > radiusKm) continue;

      result.add(MechanicModel(
        id: seed.id,
        userId: 'user_${seed.id}',
        shopName: seed.name,
        shopAddress: seed.address,
        lat: mechLat,
        lng: mechLng,
        specializations: seed.specializations,
        subscriptionTier: seed.subscriptionTier,
        isVerified: seed.isVerified,
        ratingAvg: seed.rating,
        totalJobs: seed.totalJobs,
        isOpen: seed.isOpen,
        phone: seed.phone,
        distanceKm: double.parse(distKm.toStringAsFixed(2)),
      ));
    }

    // Sort: open first, then by distance
    result.sort((a, b) {
      if (a.isOpen != b.isOpen) return a.isOpen ? -1 : 1;
      return (a.distanceKm ?? 99).compareTo(b.distanceKm ?? 99);
    });

    return result;
  }

  /// Filter by specialization keyword
  List<MechanicModel> getBySpecialization({
    required LatLng userLocation,
    required String specialization,
  }) {
    final all = getNearby(userLocation: userLocation);
    if (specialization == 'All') return all;
    return all
        .where((m) => m.specializations
            .any((s) => s.toLowerCase().contains(specialization.toLowerCase())))
        .toList();
  }
}

// ── Private seed record ────────────────────────────────────
class _MechanicSeed {
  final String id, name, phone, address, subscriptionTier;
  final double latOffset, lngOffset, rating;
  final int totalJobs;
  final List<String> specializations;
  final bool isVerified, isOpen;

  const _MechanicSeed({
    required this.id,
    required this.name,
    required this.phone,
    required this.latOffset,
    required this.lngOffset,
    required this.rating,
    required this.totalJobs,
    required this.specializations,
    required this.subscriptionTier,
    required this.isVerified,
    required this.isOpen,
    required this.address,
  });
}
