import 'package:flutter/material.dart';
import 'dashboard/storage.dart';
import 'dashboard/obd.dart';
import 'dashboard/reminders.dart';
import 'dashboard/services_screen.dart';
import 'dashboard/tips.dart';
import 'dashboard/mechanic_finder_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Dashboard",
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: IconThemeData(
          color: Theme.of(context).appBarTheme.titleTextStyle?.color,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildDashboardItem(
                context,
                "assets/reminders.png",
                "Reminders",
                navigateTo: const ReminderPage(),
              ),
              _buildDashboardItem(
                context,
                "assets/mechanic.png",
                "Mechanic Finder",
                navigateTo: const MechanicFinderScreen(),
              ),
              _buildDashboardItem(
                context,
                "assets/document.png",
                "Document Storage",
                navigateTo: StoragePage(),
              ),
              _buildDashboardItem(
                context,
                "assets/obd.png",
                "OBD II Integration",
                navigateTo: const OBDPage(),
              ),
              _buildDashboardItem(context, "assets/tips.png", "Car Care Tips",
                  navigateTo: const CarTipsPage()),
              _buildDashboardItem(context, "assets/services.png", "Services",
                  navigateTo: const ServicesScreen()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardItem(
    BuildContext context,
    String imagePath,
    String title, {
    Widget? navigateTo,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Theme.of(context).cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: navigateTo != null
            ? () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => navigateTo,
                    transitionDuration: const Duration(milliseconds: 300),
                    transitionsBuilder: (_, a, __, c) =>
                        FadeTransition(opacity: a, child: c),
                  ),
                );
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  imagePath,
                  height: 40,
                  width: 40,
                  fit: BoxFit.contain,
                  color: null,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
