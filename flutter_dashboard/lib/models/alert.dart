// flutter_dashboard/lib/models/alert.dart

class Alert {
  final String id; // Document ID from Firestore
  final String alertType;
  final String nodeId;
  final double latitude;
  final double longitude;
  final String severity;
  final String message;
  final DateTime timestamp;

  Alert({
    required this.id,
    required this.alertType,
    required this.nodeId,
    required this.latitude,
    required this.longitude,
    required this.severity,
    required this.message,
    required this.timestamp,
  });

  factory Alert.fromFirestore(Map<String, dynamic> data, String id) {
    return Alert(
      id: id,
      alertType: data['alert_type'] ?? 'N/A',
      nodeId: data['node_id'] ?? 'N/A',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      severity: data['severity'] ?? 'low',
      message: data['message'] ?? 'No message',
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'alert_type': alertType,
      'node_id': nodeId,
      'latitude': latitude,
      'longitude': longitude,
      'severity': severity,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}