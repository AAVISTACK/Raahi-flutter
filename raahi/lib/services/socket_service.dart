import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/constants.dart';

typedef LocationCallback = void Function(double lat, double lng, int? eta);
typedef JobCallback = void Function(Map<String, dynamic> data);

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  // Callbacks
  JobCallback? onNewJobRequest;
  JobCallback? onJobStatusChange;
  LocationCallback? onHelperLocation;
  JobCallback? onJobTaken;
  JobCallback? onSosAlert;

  void connect(String token) {
    _socket = IO.io(
      AppConstants.wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      print('[Socket] Connected ✓');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      print('[Socket] Disconnected');
    });

    // Listen to events
    _socket!.on('job:new_request', (data) {
      onNewJobRequest?.call(Map<String, dynamic>.from(data));
    });

    _socket!.on('job:status_change', (data) {
      onJobStatusChange?.call(Map<String, dynamic>.from(data));
    });

    _socket!.on('job:helper_location', (data) {
      final d = Map<String, dynamic>.from(data);
      onHelperLocation?.call(
        (d['lat'] as num).toDouble(),
        (d['lng'] as num).toDouble(),
        d['eta'] as int?,
      );
    });

    _socket!.on('job:taken', (data) {
      onJobTaken?.call(Map<String, dynamic>.from(data));
    });

    _socket!.on('sos:nearby_alert', (data) {
      onSosAlert?.call(Map<String, dynamic>.from(data));
    });
  }

  // Send driver location ping (called every 15s)
  void pingLocation(double lat, double lng, bool isAvailable) {
    if (_isConnected) {
      _socket!.emit('driver:ping', {
        'lat': lat,
        'lng': lng,
        'is_available': isAvailable,
      });
    }
  }

  // Send location during active job
  void updateJobLocation(String jobId, double lat, double lng) {
    if (_isConnected) {
      _socket!.emit('job:location_update', {
        'job_id': jobId,
        'lat': lat,
        'lng': lng,
      });
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
  }

  bool get isConnected => _isConnected;
}
