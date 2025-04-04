import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:velo_care/firebase_options.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'dashboard.dart';
import 'services_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Important for async initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp()); // This should be outside of Firebase.initializeApp
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Velo Care',
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/services': (context) => ServicesScreen(),
      },
    );
  }
}
