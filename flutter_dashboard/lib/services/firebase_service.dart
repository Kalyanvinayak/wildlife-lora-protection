// flutter_dashboard/lib/services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_border_protection/models/alert.dart';
import 'package:cross_border_protection/models/sensor_data.dart';

class FirebaseService {
  // Singleton pattern for FirebaseService
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  static FirebaseService get instance => _instance;

  late FirebaseFirestore _firestore;

  void init() {
    _firestore = FirebaseFirestore.instance;
  }

  // --- Sensor Data Operations ---

  /// Stream of real-time sensor data updates.
  Stream<List<SensorData>> getSensorDataStream({String? nodeId}) {
    Query query = _firestore.collection('sensor_data')
        .orderBy('timestamp', descending: true)
        .limit(50); // Limit to latest 50 entries for dashboard

    if (nodeId != null && nodeId.isNotEmpty) {
      query = query.where('node_id', isEqualTo: nodeId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => SensorData.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  /// Get a single snapshot of historical sensor data.
  Future<List<SensorData>> getHistoricalSensorData({String? nodeId, int limit = 100}) async {
    Query query = _firestore.collection('sensor_data')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (nodeId != null && nodeId.isNotEmpty) {
      query = query.where('node_id', isEqualTo: nodeId);
    }

    final querySnapshot = await query.get();
    return querySnapshot.docs.map((doc) => SensorData.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  // --- Alert Operations ---

  /// Stream of real-time alert updates.
  Stream<List<Alert>> getAlertsStream({String? alertType, String? severity}) {
    Query query = _firestore.collection('alerts')
        .orderBy('timestamp', descending: true)
        .limit(20); // Limit to latest 20 alerts

    if (alertType != null && alertType.isNotEmpty) {
      query = query.where('alert_type', isEqualTo: alertType);
    }
    if (severity != null && severity.isNotEmpty) {
      query = query.where('severity', isEqualTo: severity);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Alert.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  /// Get a single snapshot of historical alerts.
  Future<List<Alert>> getHistoricalAlerts({String? alertType, String? severity, int limit = 50}) async {
    Query query = _firestore.collection('alerts')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (alertType != null && alertType.isNotEmpty) {
      query = query.where('alert_type', isEqualTo: alertType);
    }
    if (severity != null && severity.isNotEmpty) {
      query = query.where('severity', isEqualTo: severity);
    }

    final querySnapshot = await query.get();
    return querySnapshot.docs.map((doc) => Alert.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  /// Add a new alert (can be triggered manually from dashboard for testing/manual alerts)
  Future<void> addAlert(Alert alert) async {
    await _firestore.collection('alerts').add(alert.toMap());
  }

  // --- Command Operations (for villager devices) ---
  // This is primarily managed by the backend, but the dashboard could
  // theoretically send commands directly if needed (e.g., manual siren trigger).
  // For this setup, we'll assume commands are primarily issued by the FastAPI backend.
}