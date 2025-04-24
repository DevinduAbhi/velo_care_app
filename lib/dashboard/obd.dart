import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class OBDPage extends StatefulWidget {
  const OBDPage({Key? key}) : super(key: key);

  @override
  _OBDPageState createState() => _OBDPageState();
}

class _OBDPageState extends State<OBDPage> with SingleTickerProviderStateMixin {
  final flutterReactiveBle = FlutterReactiveBle();
  late StreamSubscription<ConnectionStateUpdate> _connection;
  late QualifiedCharacteristic _obdCharacteristic;
  bool _isConnected = false;
  bool _isScanning = false;
  List<DiscoveredDevice> _devices = [];
  Map<String, String> _vehicleData = {};
  String _statusMessage = 'Initialize OBD-II connection';
  late AnimationController _animationController;
  late Animation<double> _animation;

  // OBD-II Service UUID
  final Uuid serviceUuid = Uuid.parse("00001101-0000-1000-8000-00805F9B34FB");
  final Uuid characteristicUuid =
      Uuid.parse("00001101-0000-1000-8000-00805F9B34FB");

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  Future<void> _scanDevices() async {
    setState(() {
      _isScanning = true;
      _devices = [];
      _statusMessage = 'Scanning for Bluetooth devices...';
      _animationController.repeat(reverse: true);
    });

    flutterReactiveBle.scanForDevices(
      withServices: [],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      if (device.name.contains("OBD") ||
          device.name.contains("ELM") ||
          device.name.contains("Vgate")) {
        if (!_devices.any((d) => d.id == device.id)) {
          setState(() {
            _devices.add(device);
          });
        }
      }
    }, onError: (error) {
      setState(() {
        _statusMessage = 'Scan error: $error';
        _isScanning = false;
        _animationController.stop();
      });
    });
  }

  Future<void> _connectToDevice(String deviceId) async {
    setState(() {
      _statusMessage = 'Connecting to device...';
    });

    final completer = Completer<void>();

    _connection = flutterReactiveBle.connectToDevice(id: deviceId).listen(
      (connectionState) async {
        if (connectionState.connectionState ==
            DeviceConnectionState.connected) {
          try {
            final characteristics =
                await flutterReactiveBle.discoverServices(deviceId);
            final service = characteristics.firstWhere(
              (s) => s.serviceId == serviceUuid,
              orElse: () => throw Exception("OBD service not found"),
            );

            _obdCharacteristic = QualifiedCharacteristic(
              serviceId: service.serviceId,
              characteristicId: characteristicUuid,
              deviceId: deviceId,
            );

            await _initializeObdConnection();

            if (mounted) {
              setState(() {
                _isConnected = true;
                _statusMessage = 'Connected to OBD-II device';
                _isScanning = false;
                _animationController.stop();
              });
            }
            completer.complete();
          } catch (e) {
            if (mounted) {
              setState(() {
                _statusMessage = 'Connection error: $e';
                _isConnected = false;
              });
            }
            completer.completeError(e);
          }
        } else if (connectionState.connectionState ==
            DeviceConnectionState.disconnected) {
          if (mounted) {
            setState(() {
              _isConnected = false;
              _statusMessage = 'Disconnected from device';
            });
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _statusMessage = 'Connection error: $error';
            _isConnected = false;
          });
        }
        completer.completeError(error);
      },
    );

    return completer.future;
  }

  Future<void> _initializeObdConnection() async {
    await _sendObdCommand("ATZ");
    await Future.delayed(const Duration(seconds: 1));
    await _sendObdCommand("ATE0");
    await _sendObdCommand("ATH0");
    await _sendObdCommand("ATSP0");
    if (mounted) {
      setState(() {
        _statusMessage = 'OBD-II initialized';
      });
    }
  }

  Future<String> _sendObdCommand(String command) async {
    try {
      await flutterReactiveBle.writeCharacteristicWithResponse(
        _obdCharacteristic,
        value: utf8.encode("$command\r"),
      );

      final responseStream =
          flutterReactiveBle.subscribeToCharacteristic(_obdCharacteristic);
      final completer = Completer<String>();
      final subscription = responseStream.listen((data) {
        final response = String.fromCharCodes(data).trim();
        if (response.isNotEmpty && response.endsWith('>')) {
          completer.complete(response.replaceAll('>', '').trim());
        }
      });

      final response = await completer.future;
      await subscription.cancel();
      return response;
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Command error: $e';
        });
      }
      return '';
    }
  }

  Future<void> _getVehicleData() async {
    if (!_isConnected) return;

    setState(() {
      _statusMessage = 'Fetching vehicle data...';
      _vehicleData = {};
    });

    try {
      final commands = <String, Map<String, dynamic>>{
        'Engine RPM': {
          'cmd': '010C',
          'process': (String response) => _parseObdResponse(response, 4) / 4
        },
        'Vehicle Speed': {
          'cmd': '010D',
          'process': (String response) => _parseObdResponse(response, 2)
        },
        'Coolant Temp': {
          'cmd': '0105',
          'process': (String response) => _parseObdResponse(response, 2) - 40
        },
        'Throttle Position': {
          'cmd': '0111',
          'process': (String response) =>
              _parseObdResponse(response, 2) * 100 / 255
        },
        'Fuel Level': {
          'cmd': '012F',
          'process': (String response) => _parseObdResponse(response, 2)
        },
        'Intake Pressure': {
          'cmd': '010B',
          'process': (String response) => _parseObdResponse(response, 2)
        },
      };

      final newData = <String, String>{};

      for (final entry in commands.entries) {
        try {
          final cmd = entry.value['cmd'] as String;
          final process = entry.value['process'] as dynamic Function(String);
          final response = await _sendObdCommand(cmd);
          if (response.isNotEmpty) {
            final value = process(response);
            newData[entry.key] =
                '${value.toStringAsFixed(entry.key == 'Throttle Position' ? 1 : 0)}${_getUnitForParameter(entry.key)}';
          }
        } catch (e) {
          newData[entry.key] = 'Error';
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (mounted) {
        setState(() {
          _vehicleData = newData;
          _statusMessage = 'Vehicle data updated';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error fetching data: $e';
        });
      }
    }
  }

  String _getUnitForParameter(String parameter) {
    switch (parameter) {
      case 'Coolant Temp':
        return ' °C';
      case 'Vehicle Speed':
        return ' km/h';
      case 'Intake Pressure':
        return ' kPa';
      default:
        return '%';
    }
  }

  double _parseObdResponse(String response, int bytes) {
    try {
      final cleanResponse =
          response.replaceAll(RegExp(r'[^0-9A-F]'), '').toUpperCase();
      if (cleanResponse.length < bytes * 2) {
        throw Exception('Invalid response length');
      }
      final hexValue =
          cleanResponse.substring(cleanResponse.length - bytes * 2);
      return int.parse(hexValue, radix: 16).toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  @override
  void dispose() {
    _connection.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OBD-II Vehicle Data'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
                _isConnected ? Icons.bluetooth_connected : Icons.bluetooth),
            color: _isConnected ? Colors.greenAccent : theme.iconTheme.color,
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isScanning
                                ? theme.colorScheme.primary
                                    .withOpacity(_animation.value * 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isConnected
                                    ? Icons.check_circle
                                    : Icons.error_outline,
                                color: _isConnected
                                    ? Colors.greenAccent
                                    : theme.colorScheme.error,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _statusMessage,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: _isConnected
                                        ? Colors.greenAccent
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.search,
                          label: 'Scan',
                          isActive: _isScanning,
                          onPressed: _isScanning ? null : _scanDevices,
                          theme: theme,
                        ),
                        _buildActionButton(
                          icon: Icons.bluetooth,
                          label: 'Connect',
                          isActive: _isConnected,
                          onPressed: _isConnected || _devices.isEmpty
                              ? null
                              : () async {
                                  try {
                                    await _connectToDevice(_devices.first.id);
                                  } catch (e) {
                                    if (mounted) {
                                      setState(() {
                                        _statusMessage =
                                            'Connection failed: $e';
                                      });
                                    }
                                  }
                                },
                          theme: theme,
                        ),
                        _buildActionButton(
                          icon: Icons.refresh,
                          label: 'Refresh',
                          isActive: false,
                          onPressed: _isConnected ? _getVehicleData : null,
                          theme: theme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _devices.isNotEmpty && !_isConnected
                  ? _buildDeviceList(theme)
                  : _buildVehicleDataView(theme, isDarkMode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback? onPressed,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? theme.colorScheme.primary.withOpacity(0.2)
                : theme.colorScheme.surface.withOpacity(0.5),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon),
            color: isActive
                ? theme.colorScheme.primary
                : onPressed == null
                    ? theme.disabledColor
                    : theme.iconTheme.color,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: onPressed == null
                ? theme.disabledColor
                : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceList(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Available OBD-II Devices',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _devices.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: theme.dividerColor.withOpacity(0.1),
              ),
              itemBuilder: (context, index) {
                final device = _devices[index];
                return ListTile(
                  leading: const Icon(Icons.bluetooth_drive),
                  title: Text(
                    device.name.isEmpty ? 'Unknown Device' : device.name,
                    style: theme.textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    device.id,
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    try {
                      await _connectToDevice(device.id);
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _statusMessage = 'Connection failed: $e';
                        });
                      }
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDataView(ThemeData theme, bool isDarkMode) {
    if (_vehicleData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.car_repair,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Connect to OBD-II to view vehicle data',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Text(
          'Live Vehicle Data',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: _vehicleData.entries.map((entry) {
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isDarkMode
                    ? theme.colorScheme.surface.withOpacity(0.8)
                    : theme.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        entry.key,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.value,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
