import 'package:flutter/material.dart';
import 'vehicle_details_screen.dart';

class VehicleListScreen extends StatelessWidget {
  final List<Map<String, String>> vehicles = [
    {"make": "Toyota", "model": "Corolla", "year": "2019", "vin": "1234567890"},
    {"make": "Honda", "model": "Civic", "year": "2021", "vin": "0987654321"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Vehicles")),
      body: ListView.builder(
        itemCount: vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = vehicles[index];
          return ListTile(
            leading: Icon(Icons.directions_car, color: Colors.blue),
            title: Text(
                "${vehicle['make']} ${vehicle['model']} (${vehicle['year']})"),
            subtitle: Text("VIN: ${vehicle['vin']}"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VehicleDetailsScreen(vehicle: vehicle),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
