// flutter_dashboard/lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cross_border_protection/models/sensor_data.dart';
import 'package:cross_border_protection/models/alert.dart';

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:8000'; // Replace with your FastAPI backend URL

  // --- Sensor Data Endpoints (primarily used by gateway, but dashboard could fetch directly) ---

  /// Fetches historical sensor data from FastAPI.
  Future<List<SensorData>> fetchSensorDataHistory({String? nodeId, int limit = 100}) async {
    final Map<String, String> queryParams = {
      'limit': limit.toString(),
    };
    if (nodeId != null && nodeId.isNotEmpty) {
      queryParams['node_id'] = nodeId;
    }

    final uri = Uri.parse('$_baseUrl/sensor_data_history/').replace(queryParameters: queryParams);
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((item) => SensorData.fromFirestore(item, item['id'] ?? 'temp_id')).toList();
        } else {
          throw Exception('API error: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('Failed to load sensor data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching sensor data history: $e');
      rethrow;
    }
  }

  // --- Alert Endpoints ---

  /// Fetches historical alerts from FastAPI.
  Future<List<Alert>> fetchAlertsHistory({String? alertType, String? severity, int limit = 100}) async {
    final Map<String, String> queryParams = {
      'limit': limit.toString(),
    };
    if (alertType != null && alertType.isNotEmpty) {
      queryParams['alert_type'] = alertType;
    }
    if (severity != null && severity.isNotEmpty) {
      queryParams['severity'] = severity;
    }

    final uri = Uri.parse('$_baseUrl/alerts_history/').replace(queryParameters: queryParams);
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((item) => Alert.fromFirestore(item, item['id'] ?? 'temp_id')).toList();
        } else {
          throw Exception('API error: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('Failed to load alerts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching alerts history: $e');
      rethrow;
    }
  }

  /// Sends a manual alert to the FastAPI backend.
  Future<void> sendAlert({
    required String alertType,
    required String nodeId,
    required double latitude,
    required double longitude,
    required String severity,
    required String message,
  }) async {
    final uri = Uri.parse('$_baseUrl/alerts/');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'alert_type': alertType,
          'node_id': nodeId,
          'latitude': latitude,
          'longitude': longitude,
          'severity': severity,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          print('Alert sent successfully: ${jsonResponse['message']}');
        } else {
          throw Exception('API error: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('Failed to send alert: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error sending alert: $e');
      rethrow;
    }
  }

  /// Fetches commands for a specific device (used by villager device, not dashboard directly)
  Future<Map<String, dynamic>?> fetchDeviceCommand(String deviceId) async {
    final uri = Uri.parse('$_baseUrl/commands/$deviceId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success' && jsonResponse['command'] != null) {
          return jsonResponse['command'];
        } else {
          return null; // No command or status not success
        }
      } else {
        throw Exception('Failed to fetch command: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching device command: $e');
      return null;
    }
  }

  /// Clears commands for a specific device (used by villager device, not dashboard directly)
  Future<void> clearDeviceCommands(String deviceId) async {
    final uri = Uri.parse('$_baseUrl/commands/clear/$deviceId');
    try {
      final response = await http.post(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          print('Commands cleared for $deviceId');
        } else {
          throw Exception('API error: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('Failed to clear commands: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error clearing commands: $e');
      rethrow;
    }
  }
}