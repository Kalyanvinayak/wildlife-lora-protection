// flutter_dashboard/lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:cross_border_protection/screens/map_screen.dart';
import 'package:cross_border_protection/services/firebase_service.dart';
import 'package:cross_border_protection/models/sensor_data.dart';
import 'package:cross_border_protection/models/alert.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService.instance;
  String _selectedNodeId = ''; // For filtering sensor data by node
  final List<String> _nodeIds = ['All Nodes']; // Populate with actual node IDs later

  @override
  void initState() {
    super.initState();
    // You might want to fetch existing node IDs from Firestore once
    // or rely on the sensor data stream to populate them.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wildlife Protection Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                // Force a rebuild to refresh streams
              });
            },
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Real-time Map'),
            const SizedBox(height: 10),
            Container(
              height: 300, // Fixed height for the map preview
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MapScreen(
                  isInteractive: false, // Make it non-interactive for preview
                  initialCenter: const LatLng(27.5, 90.0), // Central point for initial view
                  initialZoom: 9.0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapScreen(
                        isInteractive: true, // Make it interactive for full view
                        initialCenter: const LatLng(27.5, 90.0),
                        initialZoom: 9.0,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map),
                label: const Text('View Full Map'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 5,
                ),
              ),
            ),
            const SizedBox(height: 30),

            _buildSectionTitle('Sensor Data Overview'),
            _buildNodeFilterDropdown(),
            const SizedBox(height: 10),
            _buildSensorDataList(),
            const SizedBox(height: 30),

            _buildSectionTitle('Recent Alerts'),
            const SizedBox(height: 10),
            _buildAlertsList(),
            const SizedBox(height: 30),

            _buildSectionTitle('System Health & Controls'),
            _buildHealthMetrics(),
            const SizedBox(height: 20),
            _buildManualAlertButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildNodeFilterDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedNodeId.isEmpty ? 'All Nodes' : _selectedNodeId,
      decoration: InputDecoration(
        labelText: 'Filter by Node ID',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: _nodeIds.map((String node) {
        return DropdownMenuItem<String>(
          value: node,
          child: Text(node),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedNodeId = newValue == 'All Nodes' ? '' : newValue!;
        });
      },
    );
  }

  Widget _buildSensorDataList() {
    return StreamBuilder<List<SensorData>>(
      stream: _firebaseService.getSensorDataStream(nodeId: _selectedNodeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No sensor data available.'));
        }

        // Update node IDs for the filter dropdown
        final uniqueNodeIds = snapshot.data!.map((e) => e.nodeId).toSet().toList();
        _nodeIds.clear();
        _nodeIds.add('All Nodes');
        _nodeIds.addAll(uniqueNodeIds);

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final data = snapshot.data![index];
                return ListTile(
                  leading: Icon(
                    data.isAnomaly ? Icons.warning_amber : Icons.sensors,
                    color: data.isAnomaly ? Colors.red : Colors.blue,
                  ),
                  title: Text('Node ID: ${data.nodeId} (${data.nodeType})'),
                  subtitle: Text(
                    'Lat: ${data.latitude.toStringAsFixed(4)}, Lon: ${data.longitude.toStringAsFixed(4)}\n'
                    'Temp: ${data.temperature.toStringAsFixed(1)}°C, Hum: ${data.humidity.toStringAsFixed(1)}%\n'
                    'Battery: ${data.batteryVoltage.toStringAsFixed(2)}V ${data.isAnomaly ? '(Anomaly Detected!)' : ''}\n'
                    'Time: ${DateFormat('HH:mm:ss dd/MM').format(data.timestamp.toLocal())}',
                  ),
                  isThreeLine: true,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertsList() {
    return StreamBuilder<List<Alert>>(
      stream: _firebaseService.getAlertsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No recent alerts.'));
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final alert = snapshot.data![index];
                Color severityColor;
                switch (alert.severity) {
                  case 'critical':
                    severityColor = Colors.red;
                    break;
                  case 'high':
                    severityColor = Colors.orange;
                    break;
                  case 'medium':
                    severityColor = Colors.yellow.shade800;
                    break;
                  default:
                    severityColor = Colors.green;
                }

                return ListTile(
                  leading: Icon(Icons.notifications_active, color: severityColor),
                  title: Text('${alert.alertType.toUpperCase()} from ${alert.nodeId}'),
                  subtitle: Text(
                    'Severity: ${alert.severity.toUpperCase()}\n'
                    'Message: ${alert.message}\n'
                    'Time: ${DateFormat('HH:mm:ss dd/MM').format(alert.timestamp.toLocal())}',
                  ),
                  isThreeLine: true,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHealthMetrics() {
    // This section would display aggregated health metrics
    // For now, it's a placeholder. You'd fetch this from Firebase/FastAPI.
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gateway Status: Online', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Active Nodes: 5', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Average Battery: 3.9V', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Last ML Model Update: 2025-07-27', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildManualAlertButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          _showManualAlertDialog();
        },
        icon: const Icon(Icons.add_alert),
        label: const Text('Trigger Manual Alert'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 5,
        ),
      ),
    );
  }

  void _showManualAlertDialog() {
    final TextEditingController _nodeIdController = TextEditingController(text: 'MANUAL_001');
    final TextEditingController _messageController = TextEditingController(text: 'Manual test alert');
    String _selectedAlertType = 'test_alert';
    String _selectedSeverity = 'medium';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Trigger Manual Alert'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nodeIdController,
                  decoration: const InputDecoration(labelText: 'Node ID (e.g., MANUAL_001)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedAlertType,
                  decoration: const InputDecoration(labelText: 'Alert Type'),
                  items: <String>['test_alert', 'intrusion', 'animal_movement', 'flood', 'fire']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.replaceAll('_', ' ').toCapitalized()),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _selectedAlertType = newValue;
                    }
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedSeverity,
                  decoration: const InputDecoration(labelText: 'Severity'),
                  items: <String>['low', 'medium', 'high', 'critical']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.toCapitalized()),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _selectedSeverity = newValue;
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(labelText: 'Message'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Trigger Alert'),
              onPressed: () async {
                try {
                  // For manual alerts, we'll use a dummy location or current device location
                  // For simplicity, using a fixed location here
                  const double dummyLat = 27.505;
                  const double dummyLon = 90.005;

                  await _firebaseService.addAlert(
                    Alert(
                      id: '', // Will be generated by Firestore
                      alertType: _selectedAlertType,
                      nodeId: _nodeIdController.text,
                      latitude: dummyLat,
                      longitude: dummyLon,
                      severity: _selectedSeverity,
                      message: _messageController.text,
                      timestamp: DateTime.now(),
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Manual alert triggered successfully!')),
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to trigger alert: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String toCapitalized() => length > 0 ?'${this[0].toUpperCase()}${substring(1).toLowerCase()}':'';
}