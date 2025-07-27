// flutter_dashboard/lib/screens/map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cross_border_protection/services/firebase_service.dart';
import 'package:cross_border_protection/models/sensor_data.dart';
import 'package:cross_border_protection/models/alert.dart';

class MapScreen extends StatefulWidget {
  final bool isInteractive;
  final LatLng initialCenter;
  final double initialZoom;

  const MapScreen({
    super.key,
    this.isInteractive = true,
    required this.initialCenter,
    required this.initialZoom,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final FirebaseService _firebaseService = FirebaseService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isInteractive
          ? AppBar(
              title: const Text('Live Wildlife & Hazard Map'),
              backgroundColor: Colors.green,
            )
          : null, // No app bar if not interactive (for dashboard preview)
      body: StreamBuilder<List<SensorData>>(
        stream: _firebaseService.getSensorDataStream(),
        builder: (context, sensorSnapshot) {
          if (sensorSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (sensorSnapshot.hasError) {
            return Center(child: Text('Error loading sensor data: ${sensorSnapshot.error}'));
          }
          final List<SensorData> sensorDataList = sensorSnapshot.data ?? [];

          return StreamBuilder<List<Alert>>(
            stream: _firebaseService.getAlertsStream(),
            builder: (context, alertSnapshot) {
              if (alertSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (alertSnapshot.hasError) {
                return Center(child: Text('Error loading alerts: ${alertSnapshot.error}'));
              }
              final List<Alert> alertList = alertSnapshot.data ?? [];

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: widget.initialCenter,
                  zoom: widget.initialZoom,
                  minZoom: 2.0,
                  maxZoom: 18.0,
                  interactiveFlags: widget.isInteractive
                      ? InteractiveFlag.all
                      : InteractiveFlag.none, // Disable interaction for preview
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.cross_border_protection',
                  ),
                  MarkerLayer(
                    markers: [
                      // Markers for Sensor Data
                      ...sensorDataList.map((data) {
                        return Marker(
                          point: LatLng(data.latitude, data.longitude),
                          width: 80,
                          height: 80,
                          child: GestureDetector(
                            onTap: () {
                              _showSensorDataDetails(context, data);
                            },
                            child: Column(
                              children: [
                                Icon(
                                  data.nodeType == 'collar'
                                      ? Icons.pets
                                      : data.nodeType == 'weather_station'
                                          ? Icons.cloud
                                          : Icons.person_pin_circle, // Default for motion/other
                                  color: data.isAnomaly ? Colors.red : Colors.blue,
                                  size: 30,
                                ),
                                Text(
                                  data.nodeId,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: data.isAnomaly ? Colors.red : Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                      // Markers for Alerts
                      ...alertList.map((alert) {
                        Color alertColor;
                        switch (alert.severity) {
                          case 'critical':
                            alertColor = Colors.red.shade800;
                            break;
                          case 'high':
                            alertColor = Colors.orange.shade800;
                            break;
                          case 'medium':
                            alertColor = Colors.yellow.shade800;
                            break;
                          default:
                            alertColor = Colors.green.shade800;
                        }
                        return Marker(
                          point: LatLng(alert.latitude, alert.longitude),
                          width: 80,
                          height: 80,
                          child: GestureDetector(
                            onTap: () {
                              _showAlertDetails(context, alert);
                            },
                            child: Column(
                              children: [
                                Icon(
                                  _getAlertIcon(alert.alertType),
                                  color: alertColor,
                                  size: 30,
                                ),
                                Text(
                                  alert.alertType.replaceAll('_', ' ').toCapitalized(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: alertColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  IconData _getAlertIcon(String alertType) {
    switch (alertType) {
      case 'intrusion':
        return Icons.security;
      case 'animal_movement':
        return Icons.directions_run;
      case 'flood':
        return Icons.water;
      case 'fire':
        return Icons.local_fire_department;
      case 'anomaly_detection':
        return Icons.warning;
      default:
        return Icons.notifications_active;
    }
  }

  void _showSensorDataDetails(BuildContext context, SensorData data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sensor Data: ${data.nodeId}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Node Type: ${data.nodeType.toCapitalized()}'),
                Text('Latitude: ${data.latitude.toStringAsFixed(4)}'),
                Text('Longitude: ${data.longitude.toStringAsFixed(4)}'),
                Text('Temperature: ${data.temperature.toStringAsFixed(1)}°C'),
                Text('Humidity: ${data.humidity.toStringAsFixed(1)}%'),
                if (data.gasLevel != null) Text('Gas Level: ${data.gasLevel!.toStringAsFixed(1)}%'),
                Text('Battery: ${data.batteryVoltage.toStringAsFixed(2)}V'),
                Text('Anomaly Detected: ${data.isAnomaly ? 'Yes' : 'No'}'),
                Text('Timestamp: ${DateFormat('HH:mm:ss dd/MM/yyyy').format(data.timestamp.toLocal())}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAlertDetails(BuildContext context, Alert alert) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert: ${alert.alertType.replaceAll('_', ' ').toCapitalized()}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('From Node: ${alert.nodeId}'),
                Text('Severity: ${alert.severity.toUpperCase()}'),
                Text('Message: ${alert.message}'),
                Text('Latitude: ${alert.latitude.toStringAsFixed(4)}'),
                Text('Longitude: ${alert.longitude.toStringAsFixed(4)}'),
                Text('Timestamp: ${DateFormat('HH:mm:ss dd/MM/yyyy').format(alert.timestamp.toLocal())}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

// Extension to capitalize strings (copied from dashboard_screen.dart for self-containment)
extension StringExtension on String {
  String toCapitalized() => length > 0 ?'${this[0].toUpperCase()}${substring(1).toLowerCase()}':'';
}