import 'package:flutter/material.dart';
import 'dashboard.dart'; // Import the DashboardScreen
import 'vehicles/add_vehicle_screen.dart'; // Import the AddVehicleScreen
import 'reminder_dialog.dart'; // Import the ReminderDialog
import 'settings_screen.dart'; // Import the SettingsScreen

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "Devindu Abhishek";
  String vehicleImage = "assets/car.jpg";
  String mileage = "80,308 km";
  String lastUpdated = "updated 4 minutes ago";
  List<Map<String, String>> vehicles = [];
  List<Map<String, dynamic>> reminders = [
    {"title": "Oil Change", "dueIn": "5,751 km"},
    {"title": "Tire Rotation", "dueIn": "2,000 km"},
    {"title": "Brake Check", "dueIn": "1,500 km"},
  ];

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Velo Care", style: TextStyle(color: Colors.black)),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Vehicle',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildVehicleView();
      case 1:
        return _buildOverviewView();
      case 2:
        return DashboardScreen(); // Display the DashboardScreen here
      case 3:
        return SettingsScreen(); // Navigate to the SettingsScreen
      default:
        return _buildVehicleView();
    }
  }

  Widget _buildVehicleView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle Card
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 4,
            color: Colors.grey[200],
            child: Column(
              children: [
                Stack(
                  children: [
                    Image.asset(
                      vehicleImage,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.directions_car, size: 60),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editCurrentVehicle(context),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text("Current Mileage",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(mileage,
                              style:
                                  TextStyle(fontSize: 18, color: Colors.blue)),
                          SizedBox(width: 10),
                          Text(lastUpdated,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Reminders Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Reminders",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: Colors.blue),
                onPressed: () => _addNewReminder(context),
              ),
            ],
          ),

          // Reminders List
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              return Card(
                margin: EdgeInsets.only(bottom: 10),
                elevation: 2,
                child: ListTile(
                  leading: Icon(Icons.notifications_active, color: Colors.blue),
                  title: Text(reminders[index]["title"],
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Due in ${reminders[index]["dueIn"]}"),
                  trailing: IconButton(
                    icon: Icon(Icons.edit, size: 20),
                    onPressed: () => _editReminder(index, context),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewView() {
    return Center(child: Text("Overview View"));
  }

  // Vehicle Editing
  void _editCurrentVehicle(BuildContext context) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddVehicleScreen(
          initialData: {
            'model': 'Current Vehicle',
            'mileage': mileage,
            'image': vehicleImage
          },
        ),
      ),
    );
    if (updated != null) {
      setState(() {
        vehicleImage = updated['image'] ?? vehicleImage;
        mileage = updated['mileage'] ?? mileage;
        lastUpdated = "Updated just now";
      });
    }
  }

  // Reminder Management
  void _addNewReminder(BuildContext context) async {
    final newReminder = await showDialog(
      context: context,
      builder: (context) => ReminderDialog(),
    );
    if (newReminder != null) {
      setState(() => reminders.add(newReminder));
    }
  }

  void _editReminder(int index, BuildContext context) async {
    final updated = await showDialog(
      context: context,
      builder: (context) => ReminderDialog(
        initialData: reminders[index],
      ),
    );
    if (updated != null) {
      setState(() => reminders[index] = updated);
    }
  }
}
