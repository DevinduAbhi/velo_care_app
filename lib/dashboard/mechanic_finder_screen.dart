import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class MechanicFinderScreen extends StatefulWidget {
  const MechanicFinderScreen({super.key});

  @override
  State<MechanicFinderScreen> createState() => _MechanicFinderScreenState();
}

class _MechanicFinderScreenState extends State<MechanicFinderScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  LatLng? _userLocation;
  bool _isLoading = true;
  List<MechanicShop> _mechanicShops = [];
  List<MechanicShop> _filteredShops = [];
  bool _showSearchResults = false;

  static const LatLng _sriLankaCenter = LatLng(7.8731, 80.7718);
  static const double _defaultZoom = 7.5;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _searchFocusNode.addListener(_handleSearchFocus);
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchFocus() {
    setState(() {
      _showSearchResults =
          _searchFocusNode.hasFocus && _searchController.text.isNotEmpty;
    });
  }

  Future<void> _fetchCountrywideMechanics() async {
    setState(() => _isLoading = true);
    try {
      const bbox = '5.916,79.521,9.835,81.879';
      final query = '''
        [out:json];
        (
          node["shop"="car_repair"]($bbox);
          node["amenity"="garage"]($bbox);
          way["shop"="car_repair"]($bbox);
          way["amenity"="garage"]($bbox);
        );
        out center;
        >;
        out skel qt;
      ''';

      final response = await http
          .get(
            Uri.parse(
                'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}'),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        if (decoded['elements'] is List) {
          final shops = _parseOverpassData(decoded);
          if (shops.isNotEmpty) {
            setState(() {
              _mechanicShops = shops;
              _filteredShops = shops;
            });
            return;
          }
        }
        throw Exception('No valid mechanic data found');
      }
      throw Exception('API request failed');
    } catch (e) {
      developer.log('Mechanic fetch error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Using sample data'),
          duration: Duration(seconds: 2),
        ),
      );
      _loadFallbackData();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<MechanicShop> _parseOverpassData(Map<String, dynamic> data) {
    try {
      final elements = (data['elements'] as List?) ?? [];
      return elements
          .map((e) {
            try {
              final tags = (e['tags'] as Map<String, dynamic>?) ?? {};

              String name = _extractName(tags);

              double? lat, lon;

              if (e['lat'] != null && e['lon'] != null) {
                lat = (e['lat'] as num?)?.toDouble();
                lon = (e['lon'] as num?)?.toDouble();
              } else if (e['center'] != null) {
                final center = e['center'] as Map<String, dynamic>;
                lat = (center['lat'] as num?)?.toDouble();
                lon = (center['lon'] as num?)?.toDouble();
              } else if (e['geometry'] is List) {
                final geometry = e['geometry'] as List;
                final firstPoint = geometry.firstWhere(
                  (p) => p['lat'] != null && p['lon'] != null,
                  orElse: () => null,
                );
                if (firstPoint != null) {
                  lat = (firstPoint['lat'] as num?)?.toDouble();
                  lon = (firstPoint['lon'] as num?)?.toDouble();
                }
              }

              if (lat == null || lon == null) {
                developer
                    .log('Skipping element ${e['id']} - no valid coordinates');
                return null;
              }

              return MechanicShop(
                id: (e['id']?.toString()) ?? '0',
                name: name.isNotEmpty ? name : 'Auto Service ${e['id']}',
                location: LatLng(lat, lon),
                phone: (tags['phone'] as String?) ?? '',
                rating: (tags['rating'] != null)
                    ? double.tryParse(tags['rating'].toString()) ?? 0.0
                    : 0.0,
                services: _getServicesFromTags(tags),
              );
            } catch (e) {
              developer.log('Error parsing element: $e');
              return null;
            }
          })
          .whereType<MechanicShop>()
          .toList();
    } catch (e) {
      developer.log('Error parsing API response: $e');
      return [];
    }
  }

  String _extractName(Map<String, dynamic> tags) {
    final possibleNameFields = [
      'name',
      'operator',
      'brand',
      'description',
      'note',
      'alt_name'
    ];

    for (var field in possibleNameFields) {
      if (tags[field] is String && (tags[field] as String).isNotEmpty) {
        return tags[field] as String;
      }
    }
    return '';
  }

  List<String> _getServicesFromTags(Map<String, dynamic> tags) {
    final services = <String>[];
    if (tags['service:vehicle:car_repair'] == 'yes') services.add('Car Repair');
    if (tags['service:vehicle:tyres'] == 'yes') services.add('Tire Service');
    if (tags['service:vehicle:oil'] == 'yes') services.add('Oil Change');
    if (tags['service:vehicle:battery'] == 'yes') services.add('Battery');
    return services.isNotEmpty ? services : ['Vehicle Services'];
  }

  void _loadFallbackData() {
    setState(() {
      _mechanicShops = [
        MechanicShop(
          id: '1',
          name: 'Colombo Auto Masters',
          location: const LatLng(6.9271, 79.8612),
          phone: '+94112234567',
          rating: 4.5,
          services: ['Engine Repair', 'AC Service'],
        ),
        MechanicShop(
          id: '2',
          name: 'Kandy Quick Fix',
          location: const LatLng(7.2906, 80.6337),
          phone: '+94119876543',
          rating: 4.2,
          services: ['Tire Repair', 'Battery'],
        ),
        MechanicShop(
          id: '3',
          name: 'Galle Auto Care',
          location: const LatLng(6.0535, 80.2209),
          phone: '+94114567890',
          rating: 4.0,
          services: ['Oil Change', 'Brakes'],
        ),
      ];
      _filteredShops = _mechanicShops;
    });
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services disabled';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions denied';
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(
          () => _userLocation = LatLng(position.latitude, position.longitude));
      await _fetchCountrywideMechanics();
    } catch (e) {
      developer.log('Location error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Using default location'),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() => _userLocation = _sriLankaCenter);
      await _fetchCountrywideMechanics();
    }
  }

  void _zoomToLocation(LatLng location, [double zoom = 15.0]) {
    _mapController.move(location, zoom);
    setState(() => _showSearchResults = false);
  }

  void _filterShops(String query) {
    setState(() {
      _filteredShops = _mechanicShops
          .where((shop) =>
              shop.name.toLowerCase().contains(query.toLowerCase()) ||
              shop.services.any((service) =>
                  service.toLowerCase().contains(query.toLowerCase())))
          .toList();
      _showSearchResults = query.isNotEmpty && _searchFocusNode.hasFocus;
    });
  }

  Future<void> _callMechanic(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not make call'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openDirections(LatLng destination) async {
    final Uri launchUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=driving',
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open maps'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map View
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _userLocation ?? _sriLankaCenter,
              zoom: _userLocation != null ? 14 : _defaultZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.velo_care',
              ),
              MarkerLayer(
                markers: [
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 40,
                      height: 40,
                      builder: (ctx) => const Icon(
                        Icons.person_pin_circle,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  ..._filteredShops.map((shop) => Marker(
                        point: shop.location,
                        width: 40,
                        height: 40,
                        builder: (ctx) => GestureDetector(
                          onTap: () => _showShopDetails(shop),
                          child: const Icon(
                            Icons.car_repair,
                            color: Colors.red,
                            size: 32,
                          ),
                        ),
                      )),
                ],
              ),
            ],
          ),

          // App Bar
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Mechanic Finder',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_userLocation != null)
                      IconButton(
                        icon:
                            const Icon(Icons.my_location, color: Colors.white),
                        onPressed: () => _zoomToLocation(_userLocation!),
                      ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _fetchCountrywideMechanics,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search mechanics...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            _filterShops('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: _filterShops,
              ),
            ),
          ),

          // Search Results
          if (_showSearchResults)
            Positioned(
              top: MediaQuery.of(context).padding.top + 120,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _filteredShops.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No results found'),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          shrinkWrap: true,
                          itemCount: _filteredShops.length,
                          itemBuilder: (context, index) {
                            final shop = _filteredShops[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: const Icon(Icons.car_repair,
                                    color: Colors.blue),
                                title: Text(shop.name),
                                subtitle: Text(
                                  shop.services.join(' • '),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: const Icon(Icons.arrow_forward),
                                onTap: () {
                                  _zoomToLocation(shop.location);
                                  _showShopDetails(shop);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),

          // Loading Indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Zoom Controls
          Positioned(
            bottom: 100,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomIn',
                  onPressed: () => _mapController.move(
                    _mapController.center,
                    _mapController.zoom + 1,
                  ),
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoomOut',
                  onPressed: () => _mapController.move(
                    _mapController.center,
                    _mapController.zoom - 1,
                  ),
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showShopDetails(MechanicShop shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with close button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.car_repair, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shop.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.star,
                                      color: Colors.amber[600], size: 18),
                                  const SizedBox(width: 4),
                                  Text('${shop.rating}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Services
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Services Offered',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: shop.services
                              .map((service) => Chip(
                                    label: Text(service),
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                  // Contact & Directions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.phone),
                            label: const Text('Call'),
                            onPressed: () => _callMechanic(shop.phone),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.directions),
                            label: const Text('Directions'),
                            onPressed: () => _openDirections(shop.location),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class MechanicShop {
  final String id;
  final String name;
  final LatLng location;
  final String phone;
  final double rating;
  final List<String> services;

  MechanicShop({
    required this.id,
    required this.name,
    required this.location,
    required this.phone,
    required this.rating,
    required this.services,
  });
}
