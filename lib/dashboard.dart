import 'package:flutter/material.dart';
import 'services_screen.dart'; // Import the ServicesScreen

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dashboard")),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _buildDashboardItem(context, Icons.car_repair, "Maintenance Logs"),
            _buildDashboardItem(context, Icons.calendar_today, "Reminders"),
            _buildDashboardItem(context, Icons.location_on, "Mechanic Finder"),
            _buildDashboardItem(context, Icons.receipt, "Document Storage"),
            _buildDashboardItem(
                context, Icons.directions_car, "OBD II Integration"),
            _buildDashboardItem(context, Icons.info, "Car Care Tips"),
            _buildDashboardItem(
                context, Icons.build, "Services"), // New Services option
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem(
      BuildContext context, IconData icon, String title) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          if (title == "Services") {
            Navigator.pushNamed(context, '/services'); // Use named route
          }
          // Placeholder for other navigation
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
