import 'package:flutter/material.dart';

class ServicesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Services")),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _buildServiceItem(Icons.build, "Car Service"),
            _buildServiceItem(Icons.settings, "Alignment"),
            _buildServiceItem(Icons.ac_unit, "AC Repair"),
            _buildServiceItem(Icons.local_car_wash, "Oil Change"),
            _buildServiceItem(Icons.battery_charging_full, "Batteries"),
            _buildServiceItem(Icons.cleaning_services, "Detailing"),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(IconData icon, String title) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          // Placeholder for navigation
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
