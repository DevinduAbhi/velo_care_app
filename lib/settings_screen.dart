import 'package:flutter/material.dart';
import 'vehicles/add_vehicle_screen.dart'; // Import the AddVehicleScreen
import 'login_screen.dart'; // Import the LoginScreen

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false; // Store the theme state

  // Function to toggle dark mode
  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Profile Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: EdgeInsets.only(bottom: 20),
              child: ListTile(
                leading: Icon(Icons.account_circle, color: Colors.blue),
                title: Text('Profile'),
                subtitle: Text('Edit your profile details'),
                onTap: () {
                  // Navigate to Profile screen or action
                },
              ),
            ),

            // Add Vehicle Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: EdgeInsets.only(bottom: 20),
              child: ListTile(
                leading: Icon(Icons.directions_car,
                    color: Colors.blue), // Change to car icon
                title: Text('Add Vehicle'),
                subtitle: Text('Add a new vehicle to your profile'),
                onTap: () {
                  // Navigate to Add Vehicle screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddVehicleScreen()),
                  );
                },
              ),
            ),

            // About Us Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: EdgeInsets.only(bottom: 20),
              child: ListTile(
                leading: Icon(Icons.info, color: Colors.blue),
                title: Text('About Us'),
                subtitle: Text('Learn more about the app'),
                onTap: () {
                  _showAboutUsDialog(context);
                },
              ),
            ),

            // Help Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: EdgeInsets.only(bottom: 20),
              child: ListTile(
                leading: Icon(Icons.help, color: Colors.blue),
                title: Text('Help & Support'),
                subtitle: Text('Get help with the app'),
                onTap: () {
                  // Navigate to Help screen or action
                },
              ),
            ),

            // Contact Us Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: EdgeInsets.only(bottom: 20),
              child: ListTile(
                leading: Icon(Icons.contact_mail, color: Colors.blue),
                title: Text('Contact Us'),
                subtitle: Text('Reach out to support team'),
                onTap: () {
                  // Navigate to Contact Us screen or action
                },
              ),
            ),

            // Dark Mode Toggle
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: EdgeInsets.only(bottom: 20),
              child: ListTile(
                leading: Icon(Icons.brightness_6, color: Colors.blue),
                title: Text('Dark Mode'),
                subtitle: Text('Toggle between dark and light mode'),
                trailing: Switch(
                  value: _isDarkMode,
                  onChanged: _toggleTheme,
                  activeColor: Colors.blue,
                ),
              ),
            ),

            // Log Out Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: EdgeInsets.only(bottom: 20),
              child: ListTile(
                leading: Icon(Icons.exit_to_app, color: Colors.red),
                title: Text('Log Out'),
                onTap: () {
                  // Navigate back to the login screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show About Us dialog
  void _showAboutUsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('About Us'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Velo Care is a car maintenance app that helps users manage their vehicle maintenance schedule.'),
                SizedBox(height: 10),
                Text('Version: 1.0.0'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
