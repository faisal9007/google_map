import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        trafficEnabled: true,
        zoomGesturesEnabled: true,
        zoomControlsEnabled: true,
        myLocationEnabled: false,
        myLocationButtonEnabled: true,
        initialCameraPosition: CameraPosition(
          target: LatLng(25.39225596256982, 49.56149897116456),
          zoom: 16,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
        },

      ),
    );
  }
}
