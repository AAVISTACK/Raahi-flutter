import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
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
    // First check with permission_handler for ACCESS_FINE_LOCATION
    PermissionStatus status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
    }
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    if (!status.isGranted) return false;

    // Also verify location service is enabled via Geolocator
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      // Always check / request permission before accessing location
      final granted = await requestPermission();
      if (!granted) return _lastPosition;

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
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) / 1000; // km
  }
}
