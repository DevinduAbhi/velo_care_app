import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:velo_care/firebase_options.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'dashboard.dart';
import 'services_screen.dart';
import 'dashboard/reminders.dart';
import 'themes/theme_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeNotifier _themeNotifier = ThemeNotifier();

  @override
  void dispose() {
    _themeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Velo Care',
          theme: ThemeData(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              secondary: Colors.blueAccent,
            ),
            useMaterial3: true,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.dark(
              primary: Colors.blueAccent,
              secondary: Colors.lightBlue,
            ),
            useMaterial3: true,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          themeMode: themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => LoginScreen(themeNotifier: _themeNotifier),
            '/home': (context) => HomePage(themeNotifier: _themeNotifier),
            '/dashboard': (context) => const DashboardScreen(),
            '/services': (context) => ServicesScreen(),
            '/reminders': (context) => const ReminderPage(),
          },
        );
      },
    );
  }
}
