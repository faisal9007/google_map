import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Position? _previousPosition;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _polylineCoordinates = [];

  Timer? _locationTimer;
  bool _isInitialized = false;

  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(23.8103, 90.4125), // Default to Dhaka, Bangladesh
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _initializeLocationTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocationTracking() async {
    // Check and request location permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorDialog('Location services are disabled. Please enable them.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorDialog('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorDialog(
        'Location permissions are permanently denied. Please enable them in settings.',
      );
      return;
    }

    // Get initial location and start tracking
    await _updateLocation();
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    // Update location every 10 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateLocation();
    });
  }

  Future<void> _updateLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _previousPosition = _currentPosition;
        _currentPosition = position;

        // Add current location to polyline coordinates
        LatLng currentLatLng = LatLng(position.latitude, position.longitude);
        _polylineCoordinates.add(currentLatLng);

        // Update marker
        _updateMarker(currentLatLng);

        // Update polyline
        _updatePolyline();

        // Animate camera to new location
        if (_mapController != null) {
          _animateToLocation(currentLatLng);
        }

        if (!_isInitialized) {
          _isInitialized = true;
        }
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
      _showErrorDialog('Failed to get location: $e');
    }
  }

  void _updateMarker(LatLng position) {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: position,
        infoWindow: InfoWindow(
          title: 'My current location',
          snippet: 'Lat: ${position.latitude.toStringAsFixed(6)}, '
              'Lng: ${position.longitude.toStringAsFixed(6)}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  void _updatePolyline() {
    if (_polylineCoordinates.length < 2) return;

    _polylines.clear();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('location_path'),
        points: _polylineCoordinates,
        color: Colors.blue,
        width: 5,
        patterns: [PatternItem.dot, PatternItem.gap(10)],
      ),
    );
  }

  void _animateToLocation(LatLng position) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: 16.0,
          tilt: 0,
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Real-Time Location Tracker',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        elevation: 4,
        actions: [
          if (_currentPosition != null)
            IconButton(
              icon: const Icon(Icons.my_location, color: Colors.white),
              onPressed: () {
                if (_currentPosition != null) {
                  _animateToLocation(
                    LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                  );
                }
              },
              tooltip: 'Center on my location',
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _updateLocation,
            tooltip: 'Refresh location',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _defaultLocation,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;

              // If we already have a position, animate to it
              if (_currentPosition != null) {
                _animateToLocation(
                  LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                );
              }
            },
          ),

          // Status indicator
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildStatusCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _isInitialized ? Icons.gps_fixed : Icons.gps_not_fixed,
                  color: _isInitialized ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isInitialized ? 'Tracking Active' : 'Initializing...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isInitialized ? Colors.green : Colors.orange,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (_currentPosition != null) ...[
              const SizedBox(height: 8),
              Text(
                'Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'Points tracked: ${_polylineCoordinates.length}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}