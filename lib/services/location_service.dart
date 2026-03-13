import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';
import 'socket_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastPosition;
  Timer? _locationTimer;
  bool _isTracking = false;
  bool _isAvailable = false;

  Position? get lastPosition => _lastPosition;

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _lastPosition = pos;
      return pos;
    } catch (e) {
      return _lastPosition;
    }
  }

  void startTracking({bool isAvailable = false}) {
    _isAvailable = isAvailable;
    _isTracking = true;

    // Start periodic ping every 15 seconds
    _locationTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _sendLocationPing(),
    );

    // Also send immediately
    _sendLocationPing();
  }

  void setAvailability(bool available) {
    _isAvailable = available;
  }

  Future<void> _sendLocationPing() async {
    if (!_isTracking) return;
    final pos = await getCurrentPosition();
    if (pos == null) return;

    // Update via REST
    ApiService().updateLocation(pos.latitude, pos.longitude, _isAvailable);

    // Update via WebSocket
    SocketService().pingLocation(pos.latitude, pos.longitude, _isAvailable);
  }

  void stopTracking() {
    _isTracking = false;
    _locationTimer?.cancel();
  }

  // Calculate distance between two points
  double distanceBetween(
    double startLat, double startLng,
    double endLat, double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) / 1000; // km
  }
}
