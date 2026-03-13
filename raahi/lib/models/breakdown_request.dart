// ============================================================
// lib/models/breakdown_request.dart
// Breakdown request model — created when user confirms location
// ============================================================

class BreakdownRequest {
  final double latitude;
  final double longitude;
  final String issueDescription;
  final DateTime timestamp;

  const BreakdownRequest({
    required this.latitude,
    required this.longitude,
    required this.issueDescription,
    required this.timestamp,
  });

  // For sending to backend
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'issue_description': issueDescription,
    'timestamp': timestamp.toIso8601String(),
  };

  factory BreakdownRequest.fromJson(Map<String, dynamic> json) => BreakdownRequest(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    issueDescription: json['issue_description'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  BreakdownRequest copyWith({
    double? latitude,
    double? longitude,
    String? issueDescription,
    DateTime? timestamp,
  }) => BreakdownRequest(
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    issueDescription: issueDescription ?? this.issueDescription,
    timestamp: timestamp ?? this.timestamp,
  );

  @override
  String toString() =>
      'BreakdownRequest(lat: $latitude, lng: $longitude, '
      'issue: $issueDescription, time: $timestamp)';
}
