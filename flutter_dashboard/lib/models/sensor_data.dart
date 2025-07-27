// flutter_dashboard/lib/models/sensor_data.dart

class SensorData {
  final String id; // Document ID from Firestore
  final String nodeId;
  final String nodeType;
  final double latitude;
  final double longitude;
  final double temperature;
  final double humidity;
  final double? gasLevel;
  final double batteryVoltage;
  final DateTime timestamp;
  final bool isAnomaly; // Added from backend ML prediction

  SensorData({
    required this.id,
    required this.nodeId,
    required this.nodeType,
    required this.latitude,
    required this.longitude,
    required this.temperature,
    required this.humidity,
    this.gasLevel,
    required this.batteryVoltage,
    required this.timestamp,
    this.isAnomaly = false,
  });

  factory SensorData.fromFirestore(Map<String, dynamic> data, String id) {
    return SensorData(
      id: id,
      nodeId: data['node_id'] ?? 'N/A',
      nodeType: data['node_type'] ?? 'N/A',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      temperature: (data['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (data['humidity'] as num?)?.toDouble() ?? 0.0,
      gasLevel: (data['gas_level'] as num?)?.toDouble(),
      batteryVoltage: (data['battery_voltage'] as num?)?.toDouble() ?? 0.0,
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
      isAnomaly: data['is_anomaly'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'node_id': nodeId,
      'node_type': nodeType,
      'latitude': latitude,
      'longitude': longitude,
      'temperature': temperature,
      'humidity': humidity,
      'gas_level': gasLevel,
      'battery_voltage': batteryVoltage,
      'timestamp': timestamp.toIso8601String(),
      'is_anomaly': isAnomaly,
    };
  }
}