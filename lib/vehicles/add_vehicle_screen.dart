import 'package:flutter/material.dart';

class AddVehicleScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData; // Accept initial data for editing

  // Constructor
  AddVehicleScreen({this.initialData});

  @override
  _AddVehicleScreenState createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  late TextEditingController modelController;
  late TextEditingController mileageController;
  String? imagePath; // Store the selected image path

  // List of predefined images in assets
  final List<String> availableImages = [
    'assets/car1.jpg',
    'assets/car2.jpg',
    'assets/car3.jpg',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with initial data if available
    modelController =
        TextEditingController(text: widget.initialData?['model'] ?? '');
    mileageController =
        TextEditingController(text: widget.initialData?['mileage'] ?? '');
    imagePath = widget.initialData?['image']; // Set initial image if any
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.initialData == null ? 'Add Vehicle' : 'Edit Vehicle'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Model Input
            TextField(
              controller: modelController,
              decoration: InputDecoration(labelText: 'Model'),
            ),
            // Mileage Input
            TextField(
              controller: mileageController,
              decoration: InputDecoration(labelText: 'Mileage'),
            ),
            SizedBox(height: 20),

            // Image Selection Section
            imagePath == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Select an Image"),
                      SizedBox(height: 10),
                      // List of predefined images for selection
                      Wrap(
                        spacing: 10,
                        children: availableImages.map((image) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                imagePath = image; // Set the selected image
                              });
                            },
                            child: Image.asset(
                              image,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Image.asset(
                        imagePath!,
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            imagePath = null; // Clear the selected image
                          });
                        },
                        child: Text('Change Image'),
                      ),
                    ],
                  ),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                // Return the updated data when user saves
                Navigator.pop(context, {
                  'model': modelController.text,
                  'mileage': mileageController.text,
                  'image': imagePath,
                });
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
