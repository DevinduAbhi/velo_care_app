import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velo_care/firebase_options.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'dashboard.dart';
import 'dashboard/services_screen.dart';
import 'dashboard/reminders.dart';
import 'dashboard/obd.dart';
import 'themes/theme_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

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
      themeMode: themeNotifier.themeMode, // Changed back to themeMode
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(
              themeNotifier: Provider.of<ThemeNotifier>(context, listen: false),
            ),
        '/home': (context) => HomePage(
              themeNotifier: Provider.of<ThemeNotifier>(context, listen: false),
            ),
        '/dashboard': (context) => const DashboardScreen(),
        '/services': (context) => const ServicesScreen(),
        '/reminders': (context) => const ReminderPage(),
        '/obd': (context) => const OBDPage(),
      },
    );
  }
}
