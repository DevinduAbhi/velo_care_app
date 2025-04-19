import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class OBDPage extends StatefulWidget {
  const OBDPage({super.key});

  @override
  State<OBDPage> createState() => _OBDPageState();
}

class _OBDPageState extends State<OBDPage> {
  FlutterBluePlus flutterBlue = FlutterBluePlus();
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  bool _isConnecting = false;
  List<String> _obdData = [];
  String _connectionStatus = 'Disconnected';

  @override
  void initState() {
    super.initState();
    _checkBluetooth();
  }

  Future<void> _checkBluetooth() async {
    bool isAvailable = await FlutterBluePlus.isAvailable;
    if (!isAvailable) {
      _showMessage('Bluetooth not available on this device');
      return;
    }
  }

  Future<void> _scanDevices() async {
    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (!_devices.contains(result.device) &&
            result.device.name.isNotEmpty) {
          setState(() {
            _devices.add(result.device);
          });
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting...';
    });

    try {
      await device.connect(autoConnect: false);
      setState(() {
        _connectedDevice = device;
        _connectionStatus = 'Connected to ${device.name}';
        _isConnecting = false;
      });
      _listenToOBDData(device);
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection failed';
        _isConnecting = false;
      });
      _showMessage('Failed to connect: ${e.toString()}');
    }
  }

  void _listenToOBDData(BluetoothDevice device) {
    device.services.listen((services) {
      for (BluetoothService service in services) {
        if (service.uuid.toString().contains('obd')) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            characteristic.value.listen((value) {
              if (value.isNotEmpty) {
                setState(() {
                  _obdData.add(String.fromCharCodes(value));
                  if (_obdData.length > 10) _obdData.removeAt(0);
                });
              }
            });
          }
        }
      }
    });
  }

  Future<void> _disconnectDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      setState(() {
        _connectedDevice = null;
        _connectionStatus = 'Disconnected';
        _obdData.clear();
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OBD-II Integration'),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.search),
            onPressed: _isScanning ? _stopScan : _scanDevices,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Connection Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    const Icon(Icons.bluetooth, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      _connectionStatus,
                      style: TextStyle(
                        color: _connectedDevice != null
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_connectedDevice != null) ...[
                      const SizedBox(height: 8),
                      Text('Device: ${_connectedDevice!.name}'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _disconnectDevice,
                        child: const Text('Disconnect'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Device List
            Expanded(
              child: _devices.isEmpty
                  ? Center(
                      child: Text(
                        _isScanning ? 'Scanning...' : 'No devices found',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        return ListTile(
                          leading: const Icon(Icons.bluetooth_drive),
                          title: Text(device.name),
                          subtitle: Text(device.id.toString()),
                          trailing: _isConnecting
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: () => _connectToDevice(device),
                                  child: const Text('Connect'),
                                ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),

            // OBD Data Display
            const Text('OBD Data:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _obdData.isEmpty
                    ? const Center(child: Text('No data received'))
                    : ListView.builder(
                        itemCount: _obdData.length,
                        itemBuilder: (context, index) {
                          return Text(_obdData[index]);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _stopScan() {
    FlutterBluePlus.stopScan();
    setState(() {
      _isScanning = false;
    });
  }
}
