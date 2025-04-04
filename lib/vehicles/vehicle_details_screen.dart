import 'package:flutter/material.dart';

class VehicleDetailsScreen extends StatelessWidget {
  final Map<String, String> vehicle;

  VehicleDetailsScreen({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text("${vehicle['make']} ${vehicle['model']} Details")),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Make: ${vehicle['make']}", style: TextStyle(fontSize: 18)),
            Text("Model: ${vehicle['model']}", style: TextStyle(fontSize: 18)),
            Text("Year: ${vehicle['year']}", style: TextStyle(fontSize: 18)),
            Text("VIN: ${vehicle['vin']}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Feature coming soon!")));
              },
              child: Text("View Maintenance History"),
            ),
          ],
        ),
      ),
    );
  }
}
