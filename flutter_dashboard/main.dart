// flutter_dashboard/lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cross_border_protection/screens/dashboard_screen.dart';
import 'package:cross_border_protection/services/firebase_service.dart'; // Import your Firebase service

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  // IMPORTANT: Replace with your actual Firebase options.
  // You can get these from your Firebase project settings -> Project settings -> General -> Your apps -> Add app -> Flutter
  // Or manually create a FirebaseOptions object.
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "YOUR_API_KEY",
      appId: "YOUR_APP_ID",
      messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
      projectId: "YOUR_PROJECT_ID",
      storageBucket: "YOUR_STORAGE_BUCKET",
      // Add other options like databaseURL, measurementId if needed
    ),
  );

  // Initialize your Firebase service (optional, but good practice)
  FirebaseService.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wildlife Protection System',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter', // Using Inter font as per instructions
      ),
      home: const DashboardScreen(),
    );
  }
}