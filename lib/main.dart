import 'package:flutter/material.dart';
import 'login_screen.dart'; // Import the LoginScreen
import 'home_screen.dart'; // Import the HomeScreen
import 'dashboard.dart'; // Import the DashboardScreen
import 'services_screen.dart'; // Import the ServicesScreen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove debug banner
      title: 'Velo Care', // App title
      initialRoute: '/', // Set the initial route to LoginScreen
      routes: {
        '/': (context) => LoginScreen(), // Route for LoginScreen
        '/home': (context) => HomeScreen(), // Route for HomeScreen
        '/dashboard': (context) =>
            DashboardScreen(), // Route for DashboardScreen
        '/services': (context) => ServicesScreen(), // Route for ServicesScreen
      },
    );
  }
}
